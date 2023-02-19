public void MainInit() {
	g_teamsModelslist[CS_TEAM_T] = new ArrayList(sizeof Modelslist);
	g_teamsModelslist[CS_TEAM_CT] = new ArrayList(sizeof Modelslist);

	g_cookieT = RegClientCookie("sm_model_id_t", "Terrorists Skins", CookieAccess_Private);
	g_cookieCT = RegClientCookie("sm_model_id_ct", "Counter-Terrorists Skins", CookieAccess_Private);

	RegAdminCmd("sm_reloadmodels", ReloadModels, ADMFLAG_CHANGEMAP, "Force reload models cfg");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("exit_buyzone", Event_ExitBuyzone, EventHookMode_Pre);
}

public void VIP_OnVIPLoaded() {
	VIP_RegisterFeature(g_feature, BOOL, HIDE);
}

public void OnClientCookiesCached(int client) {
	if (IsFakeClient(client)) {
		return;
	}

	g_clientModelSettings.openModelsMenu[client] = false;

	char modelslistData[PLATFORM_MAX_PATH];
	GetClientCookie(client, g_cookieCT, modelslistData, sizeof modelslistData);
	g_clientModelSettings.ctModelPos[client] = modelslistData[0] ? StringToInt(modelslistData) : 0;
	GetClientCookie(client, g_cookieT, modelslistData, sizeof modelslistData);
	g_clientModelSettings.tModelPos[client] = modelslistData[0] ? StringToInt(modelslistData) : 0;
}

public void OnClientDisconnect(int client) {
	if (IsFakeClient(client)) {
		return;
	}

	char modelslistData[PLATFORM_MAX_PATH];
	if (g_clientModelSettings.ctModelPos[client]) {
		IntToString(g_clientModelSettings.ctModelPos[client], modelslistData, sizeof modelslistData);
		SetClientCookie(client, g_cookieCT, modelslistData);
	}

	if (g_clientModelSettings.tModelPos[client]) {
		IntToString(g_clientModelSettings.tModelPos[client], modelslistData, sizeof modelslistData);
		SetClientCookie(client, g_cookieT, modelslistData);
	}
}

public Action Command_Say(int client, const char[] command, int argc) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}

	static char modelsMenuCmds[][] = {
		".models", "!models", "models", ".model", "!model", "model",
		".agent", "!agent", "agent", ".agents", "!agents", "agents",
	};

	char buffer[24];
	GetCmdArgString(buffer, sizeof buffer);
	StripQuotes(buffer);
	TrimString(buffer);

	for (int i = 0; i < sizeof modelsMenuCmds; i++) {
		if (strcmp(buffer, modelsMenuCmds[i], false) == 0) {
			if (!IsPlayerAlive(client)) {
				PrintCenterText(client, "%t", "Only alive select nodel");
				ClientCommand(client, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if (!(GetEntityFlags(client) & FL_ONGROUND)) {
				PrintCenterText(client, "%t", "Only the ground");
				ClientCommand(client, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if (sm_buyzone_only.BoolValue && !GetEntProp(client, Prop_Send, "m_bInBuyZone")) {			
				PrintCenterText(client, "%t", "Only available in the purchase area");
				ClientCommand(client, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if (sm_select_skin_time.FloatValue > 0.0 && g_skinTimer == null) {
				PrintCenterText(client, "%t", "Time to choose is up");	
				ClientCommand(client, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			}
			DisplayModelsMenu(client, MENU_TIME_FOREVER);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast) {
	if (sm_select_skin_time.FloatValue > 0.0) {
		if (g_skinTimer != null) {
			delete g_skinTimer;
		}
		g_skinTimer = CreateTimer(sm_select_skin_time.FloatValue, Timer_DisableSkin);
	}
	return Plugin_Continue;
}

public Action Timer_DisableSkin(Handle timer) {
	g_skinTimer = null;
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && g_clientModelSettings.openModelsMenu[client]) {
			CancelClientMenu(client);
		}
	}
	return Plugin_Stop;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_clientModelSettings.openModelsMenu[client]) {
		CancelClientMenu(client);
	}
	return Plugin_Continue;
}

public Action Event_ExitBuyzone(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (sm_buyzone_only.BoolValue && IsValidClient(client) && g_clientModelSettings.openModelsMenu[client]) {
		CancelClientMenu(client);
	}
	return Plugin_Continue;
}

public Action MdlCh_PlayerSpawn(int client, bool bCustom, char[] sModel, int iModelMaxlen, char[] sVoPrefix, int iPrefixMaxlen) {
	if (!IsValidClient(client) || GetEntProp(client, Prop_Send, "m_iPlayerState") != 0) {
		return Plugin_Continue;
	}

	Modelslist modelslistData;
	int clientTeam = GetClientTeam(client);
	int modelPos = Client.GetModelListPos(clientTeam,client);
	if (!Client.IsValidModelPos(client,clientTeam)) {
		modelPos = 0;
	}

	Gameplay.GetModelArrayList(clientTeam).GetArray(modelPos, modelslistData);

	if (bCustom && !modelslistData.modelPlayer[0]) {
		return Plugin_Continue;
	}

	if (clientTeam >= 2) {
		if (modelslistData.modelPlayer[0]) {
			strcopy(sModel, iModelMaxlen, modelslistData.modelPlayer);
		}

		if (modelslistData.voPrefix[0]) {
			strcopy(sVoPrefix, iPrefixMaxlen, modelslistData.voPrefix);	
		}

#if ARMS_FIX
		int myWearables = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if (myWearables == -1) {
			Address playerViewmodelArmConfig = view_as<Address>(SDKCall(g_getPlayerViewmodelArmConfigForPlayerModel, modelslistData.modelPlayer));
			Address associatedGloveModel = view_as<Address>(LoadFromAddress(playerViewmodelArmConfig + view_as<Address>(8), NumberType_Int32));
			if (LoadFromAddress(associatedGloveModel, NumberType_Int8) == 0 && modelslistData.arms[0] == EOS) {
				modelslistData.arms = "models/weapons/v_models/arms/glove_hardknuckle/v_glove_hardknuckle_blue.mdl";
			}
		} else if (modelslistData.arms[0]) {
			AcceptEntityInput(myWearables, "KillHierarchy");
		}

		SetEntPropString(client, Prop_Send, "m_szArmsModel", modelslistData.arms);	
#endif
	}

	return Plugin_Changed;
}

#if ARMS_FIX
public void LoadArmsReplace() {
	GameData data = new GameData("CustomPlayerArms.games");
	
	if (data) {
		Address s_playerViewmodelArmConfigs = data.GetAddress("s_playerViewmodelArmConfigs");
		
		if (s_playerViewmodelArmConfigs == Address_Null) {
			SetFailState("Couldn't get the address s_playerViewmodelArmConfigs");
		}

		for (int i = 2; i < 4; i++) {
			int pStr = LoadFromAddress(s_playerViewmodelArmConfigs + view_as<Address>(i * 4), NumberType_Int32);
			StoreToAddress(view_as<Address>(pStr), 0, NumberType_Int8);
		}
		
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(data, SDKConf_Signature, "GetPlayerViewmodelArmConfigForPlayerModel");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_getPlayerViewmodelArmConfigForPlayerModel = EndPrepSDKCall();
		
		if (!g_getPlayerViewmodelArmConfigForPlayerModel) {
			SetFailState("Failed to create a call GetPlayerViewmodelArmConfigForPlayerModel");
		}

		delete data;
	} else {
		SetFailState("Failed to load GameData");
	}
}
#endif

public Action ReloadModels(int client, int args) {
	ReadModelsCfg();
	return Plugin_Continue;
}

stock bool IsValidClient(int client) {
	return 0 < client && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
