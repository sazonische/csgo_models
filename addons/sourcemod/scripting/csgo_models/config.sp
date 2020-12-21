public void ReadModelsCfg() {
	char[] szPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/csgo_models.cfg");
	if(!FileExists(szPath))
		SetFailState("Config file '%s' was not found", szPath);
	
	KeyValues ModelsConfig = new KeyValues("model_players");
	
	if(!ModelsConfig.ImportFromFile(szPath))
		SetFailState("Error parsing config file '%s'", szPath);

	ModelsConfig.Rewind();
	if(ModelsConfig.JumpToKey("Terrorists") && ModelsConfig.GotoFirstSubKey()) {
		g_aModelslist[CS_TEAM_T].Clear();		
		Modelslist info;
		do{
			ModelsConfig.GetSectionName(info.name, sizeof info.name);
			ModelsConfig.GetString("model_player", info.model_player, sizeof info.model_player);
			ModelsConfig.GetString("vo_prefix", info.vo_prefix, sizeof info.vo_prefix);
			ModelsConfig.GetString("arms", info.arms, sizeof info.arms);
			if(info.arms[0]) PrecacheModel(info.arms[0]);
			char sFlags[16];
			ModelsConfig.GetString("flags", sFlags, sizeof sFlags);
			info.flags = ReadFlagString(sFlags);
			info.vip = view_as<bool>(ModelsConfig.GetNum("vip", 0));
			g_aModelslist[CS_TEAM_T].PushArray(info);
		} while (ModelsConfig.GotoNextKey());
		info.name = "Standard";info.model_player = "";info.arms = "";info.vo_prefix = "";info.flags = 0;
		g_aModelslist[CS_TEAM_T].ShiftUp(0); g_aModelslist[CS_TEAM_T].SetArray(0,info);
	}

	ModelsConfig.Rewind();
	if(ModelsConfig.JumpToKey("Counter-Terrorists") && ModelsConfig.GotoFirstSubKey()) {
		g_aModelslist[CS_TEAM_CT].Clear();
		Modelslist info;
		do{
			ModelsConfig.GetSectionName(info.name, sizeof info.name);
			ModelsConfig.GetString("model_player", info.model_player, sizeof info.model_player);
			ModelsConfig.GetString("vo_prefix", info.vo_prefix, sizeof info.vo_prefix);
			ModelsConfig.GetString("arms", info.arms, sizeof info.arms);
			if(info.arms[0]) PrecacheModel(info.arms[0]);
			char sFlags[16];
			ModelsConfig.GetString("flags", sFlags, sizeof sFlags);
			info.flags = ReadFlagString(sFlags);
			info.vip = view_as<bool>(ModelsConfig.GetNum("vip", 0));
			g_aModelslist[CS_TEAM_CT].PushArray(info);
		} while (ModelsConfig.GotoNextKey());
		info.name = "Standard";info.model_player = "";info.arms = "";info.vo_prefix = "";info.flags = 0;
		g_aModelslist[CS_TEAM_CT].ShiftUp(0); g_aModelslist[CS_TEAM_CT].SetArray(0,info);
	}
	delete ModelsConfig;

	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/");
	DirectoryListing Directory = OpenDirectory(szPath);
	if(Directory == null) {
		LogError("Error opening directory \"%s\"", szPath);
		return;
	}
	
	FileType type;
	char[] szFile = new char[64];
	while(Directory.GetNext(szFile, 64, type)) {
		if(type != FileType_File || !StrEqual(szFile[strlen(szFile)-4], ".cfg", false))
			continue;
		
		BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/%s", szFile);
		ReadDownloadList(szPath);
	}
	
	delete Directory;
}

public void ReadDownloadList(const char[] Path) {
	File file = OpenFile(Path, "r");
	if(file  == null)
		return;
	
	char[] sLine = new char[PLATFORM_MAX_PATH];
	int pos;
	while(!file.EndOfFile()) {
		file.ReadLine(sLine, PLATFORM_MAX_PATH);
		
		pos = StrContains((sLine), "//");
		if(pos != -1)
			sLine[pos] = '\0';
		
		pos = StrContains((sLine), "#");
		if(pos != -1)
			sLine[pos] = '\0';
		
		pos = StrContains((sLine), ";");
		if(pos != -1)
			sLine[pos] = '\0';
		
		TrimString(sLine);
		if(sLine[0])
			AddFileToDownloadsTable(sLine);
	}
	delete file;
}