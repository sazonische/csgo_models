public void ReadModelsCfg() {
	// ReadDownloadList
	char[] szDownloadsPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szDownloadsPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/");
	DirectoryListing DownloadsDirectory = OpenDirectory(szDownloadsPath);
	if(DownloadsDirectory != null) {
		char[] szDownloadsFile = new char[PLATFORM_MAX_PATH];
		FileType DownloadsType;
		while(DownloadsDirectory.GetNext(szDownloadsFile, PLATFORM_MAX_PATH, DownloadsType)) {
			if(DownloadsType != FileType_File || !StrEqual(szDownloadsFile[strlen(szDownloadsFile)-4], ".cfg", false))
				continue;
			BuildPath(Path_SM, szDownloadsPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/%s", szDownloadsFile);
			ReadDownloadList(szDownloadsPath);
		}
	} else LogError("Error opening directory \"%s\"", szDownloadsPath);
	delete DownloadsDirectory;

	if(!g_CvarMapChangeReloadCfg.BoolValue) // Reload the settings config when changing the map?
		return;

	// ReadConfigList
	char[] szConfigsPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szConfigsPath, PLATFORM_MAX_PATH, "configs/csgo_models_configs/");
	DirectoryListing ConfigsDirectory = OpenDirectory(szConfigsPath);
	if(ConfigsDirectory == null) {
		SetFailState("Error opening directory \"%s\"", szConfigsPath);
		return;
	}
	
	char[] szConfigsFile = new char[PLATFORM_MAX_PATH];
	FileType ConfigsType;
	g_aTeamsModelslist[CS_TEAM_T].Clear();
	g_aTeamsModelslist[CS_TEAM_CT].Clear();
	while(ConfigsDirectory.GetNext(szConfigsFile, PLATFORM_MAX_PATH, ConfigsType)) {
		if(ConfigsType != FileType_File || !StrEqual(szConfigsFile[strlen(szConfigsFile)-4], ".cfg", false))
			continue;
		BuildPath(Path_SM, szConfigsPath, PLATFORM_MAX_PATH, "configs/csgo_models_configs/%s", szConfigsFile);
		ReadConfigList(szConfigsPath);
	}
	AddArrayStandardInfo(CS_TEAM_T);
	AddArrayStandardInfo(CS_TEAM_CT);
	delete ConfigsDirectory;
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

public void ReadConfigList(const char[] sPath) {	
	KeyValues ModelsConfig = new KeyValues("model_players");
	
	if(!ModelsConfig.ImportFromFile(sPath))
		SetFailState("Error parsing config file '%s'", sPath);

	ModelsConfig.Rewind();
	if(ModelsConfig.JumpToKey("Terrorists") && ModelsConfig.GotoFirstSubKey()) {
		Modelslist info;
		do{
			ModelsConfig.GetSectionName(info.name, sizeof info.name);
			ModelsConfig.GetString("model_player", info.model_player, sizeof info.model_player);
			ModelsConfig.GetString("vo_prefix", info.vo_prefix, sizeof info.vo_prefix);
			ModelsConfig.GetString("arms", info.arms, sizeof info.arms);
			if(info.arms[0] && !IsModelPrecached(info.arms))
				PrecacheModel(info.arms);
			char sFlags[16];
			ModelsConfig.GetString("flags", sFlags, sizeof sFlags);
			info.flags = ReadFlagString(sFlags);
			info.vip = view_as<bool>(ModelsConfig.GetNum("vip", 0));
			g_aTeamsModelslist[CS_TEAM_T].PushArray(info);
		} while (ModelsConfig.GotoNextKey());
	}

	ModelsConfig.Rewind();
	if(ModelsConfig.JumpToKey("Counter-Terrorists") && ModelsConfig.GotoFirstSubKey()) {
		Modelslist info;
		do{
			ModelsConfig.GetSectionName(info.name, sizeof info.name);
			ModelsConfig.GetString("model_player", info.model_player, sizeof info.model_player);
			ModelsConfig.GetString("vo_prefix", info.vo_prefix, sizeof info.vo_prefix);
			ModelsConfig.GetString("arms", info.arms, sizeof info.arms);
			if(info.arms[0] && !IsModelPrecached(info.arms))
				PrecacheModel(info.arms);
			char sFlags[16];
			ModelsConfig.GetString("flags", sFlags, sizeof sFlags);
			info.flags = ReadFlagString(sFlags);
			info.vip = view_as<bool>(ModelsConfig.GetNum("vip", 0));
			g_aTeamsModelslist[CS_TEAM_CT].PushArray(info);
		} while (ModelsConfig.GotoNextKey());
	}
	delete ModelsConfig;
}

public void AddArrayStandardInfo(int iTeam) {
	Modelslist info;
	info.name = "Standard";info.model_player = "";info.arms = "";info.vo_prefix = "";info.flags = 0;
	g_aTeamsModelslist[iTeam].ShiftUp(0); g_aTeamsModelslist[iTeam].SetArray(0,info);
}