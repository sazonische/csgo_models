public void MainInit() {
	g_teamsModelsList[CS_TEAM_T] = new ArrayList(sizeof ModelsList);
	g_teamsModelsList[CS_TEAM_CT] = new ArrayList(sizeof ModelsList);
	g_clientModelSettings.modelsCache = new StringMap();

	g_cookieT = RegClientCookie("sm_model_id_t", "Terrorists Skins", CookieAccess_Private);
	g_cookieCT = RegClientCookie("sm_model_id_ct", "Counter-Terrorists Skins", CookieAccess_Private);

	RegAdminCmd("sm_reloadmodels", ReloadModels, ADMFLAG_CHANGEMAP, "Force reload models cfg");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("exit_buyzone", Event_ExitBuyZone, EventHookMode_Pre);
}

public void VIP_OnVIPLoaded() {
	VIP_RegisterFeature(g_feature, BOOL, HIDE);
}

public void OnClientCookiesCached(int client) {
	if (IsFakeClient(client)) {
		return;
	}

	g_clientModelSettings.openModelsMenu[client] = false;
	char cookieData[PLATFORM_MAX_PATH];

	if (!Client.GetModelListPos(client, CS_TEAM_CT)) {
		GetClientCookie(client, g_cookieCT, cookieData, sizeof cookieData);
		int ctModelPos = StringToInt(cookieData);
		Client.SetModelListPos(client, CS_TEAM_CT, Gameplay.IsValidModelPos(CS_TEAM_CT, ctModelPos) ? ctModelPos : 0);
	}

	if (!Client.GetModelListPos(client, CS_TEAM_T)) {
		GetClientCookie(client, g_cookieT, cookieData, sizeof cookieData);
		int tModelPos = StringToInt(cookieData);
		Client.SetModelListPos(client, CS_TEAM_T, Gameplay.IsValidModelPos(CS_TEAM_T, tModelPos) ? tModelPos : 0);
	}
}

public void OnClientDisconnect(int client) {
	if (IsFakeClient(client)) {
		return;
	}

	char modelsListData[PLATFORM_MAX_PATH];

	int ctModelPos = Client.GetModelListPos(client, CS_TEAM_CT);
	if (ctModelPos) {
		IntToString(ctModelPos, modelsListData, sizeof modelsListData);
		SetClientCookie(client, g_cookieCT, modelsListData);
	}

	int tModelPos = Client.GetModelListPos(client, CS_TEAM_T);
	if (tModelPos) {
		IntToString(tModelPos, modelsListData, sizeof modelsListData);
		SetClientCookie(client, g_cookieT, modelsListData);
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

public Action Event_ExitBuyZone(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (sm_buyzone_only.BoolValue && IsValidClient(client) && g_clientModelSettings.openModelsMenu[client]) {
		CancelClientMenu(client);
	}
	return Plugin_Continue;
}

public Action MdlCh_PlayerSpawn(int client, bool custom, char[] model, int modelMaxLen, char[] voPrefix, int prefixMaxLen) {
	if (!IsValidClient(client) || GetEntProp(client, Prop_Send, "m_iPlayerState") != 0) {
		return Plugin_Continue;
	}

	int clientTeam = GetClientTeam(client);
	int modelPos = Client.GetModelListPos(client, clientTeam);
	if (!Gameplay.IsValidModelPos(clientTeam, modelPos)) {
		modelPos = 0;
	}

	ModelsList modelsListData;
	g_teamsModelsList[clientTeam].GetArray(modelPos, modelsListData);

	if (custom && !modelsListData.modelPlayer[0]) {
		return Plugin_Continue;
	}

	if (!Client.IsHaveRightsToTheModel(client, modelsListData)) {
		Client.SetModelListPos(client, clientTeam, 0);
		return Plugin_Continue;
	}

	if (clientTeam >= 2) {
		if (modelsListData.modelPlayer[0]) {
			strcopy(model, modelMaxLen, modelsListData.modelPlayer);
		}

		if (modelsListData.voPrefix[0]) {
			strcopy(voPrefix, prefixMaxLen, modelsListData.voPrefix);	
		}

#if ARMS_FIX
		int myWearables = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if (myWearables == -1) {
			Address playerViewmodelArmConfig = view_as<Address>(SDKCall(g_getPlayerViewModelArmConfigForPlayerModel, modelsListData.modelPlayer));
			Address associatedGloveModel = view_as<Address>(LoadFromAddress(playerViewmodelArmConfig + view_as<Address>(8), NumberType_Int32));
			if (LoadFromAddress(associatedGloveModel, NumberType_Int8) == 0 && modelsListData.arms[0] == EOS) {
				modelsListData.arms = "models/weapons/v_models/arms/glove_hardknuckle/v_glove_hardknuckle_blue.mdl";
			}
		} else if (modelsListData.arms[0]) {
			AcceptEntityInput(myWearables, "KillHierarchy");
		}

		SetEntPropString(client, Prop_Send, "m_szArmsModel", modelsListData.arms);	
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
		g_getPlayerViewModelArmConfigForPlayerModel = EndPrepSDKCall();
		
		if (!g_getPlayerViewModelArmConfigForPlayerModel) {
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
