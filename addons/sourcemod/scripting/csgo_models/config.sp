public void ReadModelsCfg() {
	// ReadDownloadList
	char[] downloadsPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, downloadsPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/");
	DirectoryListing downloadsDirectory = OpenDirectory(downloadsPath);
	if (downloadsDirectory != null) {
		char[] downloadsFile = new char[PLATFORM_MAX_PATH];
		FileType downloadsType;
		while (downloadsDirectory.GetNext(downloadsFile, PLATFORM_MAX_PATH, downloadsType)) {
			if (downloadsType != FileType_File || !StrEqual(downloadsFile[strlen(downloadsFile)-4], ".cfg", false))
				continue;
			BuildPath(Path_SM, downloadsPath, PLATFORM_MAX_PATH, "configs/csgo_models_downloads/%s", downloadsFile);
			ReadDownloadList(downloadsPath);
		}
	} else LogError("Error opening directory \"%s\"", downloadsPath);
	delete downloadsDirectory;

	if (!sm_map_change_reload_cfg.BoolValue) // Reload the settings config when changing the map?
		return;

	// ReadConfigList
	char[] configsPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configsPath, PLATFORM_MAX_PATH, "configs/csgo_models_configs/");
	DirectoryListing configsDirectory = OpenDirectory(configsPath);
	if (configsDirectory == null) {
		SetFailState("Error opening directory \"%s\"", configsPath);
		return;
	}
	
	char[] configsFile = new char[PLATFORM_MAX_PATH];
	FileType configsType;
	g_teamsModelslist[CS_TEAM_T].Clear();
	g_teamsModelslist[CS_TEAM_CT].Clear();
	while (configsDirectory.GetNext(configsFile, PLATFORM_MAX_PATH, configsType)) {
		if (configsType != FileType_File || !StrEqual(configsFile[strlen(configsFile)-4], ".cfg", false))
			continue;
		BuildPath(Path_SM, configsPath, PLATFORM_MAX_PATH, "configs/csgo_models_configs/%s", configsFile);
		ReadConfigList(configsPath);
	}
	Gameplay.AddStandardModelIndex(CS_TEAM_T);
	Gameplay.AddStandardModelIndex(CS_TEAM_CT);
	delete configsDirectory;
}

public void ReadDownloadList(const char[] path) {
	File file = OpenFile(path, "r");
	if (file  == null) {
		return;
	}

	char[] line = new char[PLATFORM_MAX_PATH];
	int pos;
	while (!file.EndOfFile()) {
		file.ReadLine(line, PLATFORM_MAX_PATH);
		
		pos = StrContains((line), "//");
		if (pos != -1) {
			line[pos] = '\0';
		}

		pos = StrContains((line), "#");
		if (pos != -1) {
			line[pos] = '\0';
		}

		pos = StrContains((line), ";");
		if (pos != -1) {
			line[pos] = '\0';
		}

		TrimString(line);
		if (line[0]) {
			AddFileToDownloadsTable(line);
		}
	}
	delete file;
}

public void ReadConfigList(const char[] path) {
	KeyValues modelsConfig = new KeyValues("model_players");
	
	if (!modelsConfig.ImportFromFile(path)) {
		SetFailState("Error parsing config file '%s'", path);
	}

	modelsConfig.Rewind();
	if (modelsConfig.JumpToKey("Terrorists") && modelsConfig.GotoFirstSubKey()) {
		ReadConfigModel(modelsConfig, CS_TEAM_T);
	}

	modelsConfig.Rewind();
	if (modelsConfig.JumpToKey("Counter-Terrorists") && modelsConfig.GotoFirstSubKey()) {
		ReadConfigModel(modelsConfig, CS_TEAM_CT);
	}
	delete modelsConfig;
}

public void ReadConfigModel(KeyValues modelsConfig, int team) {
	Modelslist modelslistData;
	do {
		modelsConfig.GetSectionName(modelslistData.name, sizeof modelslistData.name);
		modelsConfig.GetString("model_player", modelslistData.modelPlayer, sizeof modelslistData.modelPlayer);
		modelsConfig.GetString("vo_prefix", modelslistData.voPrefix, sizeof modelslistData.voPrefix);
		modelsConfig.GetString("arms", modelslistData.arms, sizeof modelslistData.arms);
		if (modelslistData.arms[0] && !IsModelPrecached(modelslistData.arms))
			PrecacheModel(modelslistData.arms);
		char flags[16];
		modelsConfig.GetString("flags", flags, sizeof flags);
		modelslistData.flags = ReadFlagString(flags);
		modelslistData.vip = !!modelsConfig.GetNum("vip", 0);
		g_teamsModelslist[team].PushArray(modelslistData);
	} while (modelsConfig.GotoNextKey());
}
