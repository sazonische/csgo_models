
public void BuildMain() {
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("exit_buyzone", Event_ExitBuyzone, EventHookMode_Pre);
}

public void OnClientCookiesCached(int iClient) {
	if(IsFakeClient(iClient))
		return;

	g_sModelSettings.OpenModelsMenu[iClient] = false;

	char szInfo[PLATFORM_MAX_PATH];
	GetClientCookie(iClient, g_hCookieCT, szInfo, sizeof szInfo);
	g_sModelSettings.CtModelPos[iClient] = szInfo[0] ? StringToInt(szInfo) : 0;
	GetClientCookie(iClient, g_hCookieT, szInfo, sizeof szInfo);
	g_sModelSettings.TmodelPos[iClient] = szInfo[0] ? StringToInt(szInfo) : 0;
}

public void OnClientDisconnect(int iClient) {
	if(IsFakeClient(iClient))
		return;

	char szInfo[PLATFORM_MAX_PATH];
	if(g_sModelSettings.CtModelPos[iClient]) {
		IntToString(g_sModelSettings.CtModelPos[iClient], szInfo, sizeof szInfo);
		SetClientCookie(iClient, g_hCookieCT, szInfo);
	}

	if(g_sModelSettings.TmodelPos[iClient]) {
		IntToString(g_sModelSettings.TmodelPos[iClient], szInfo, sizeof szInfo);
		SetClientCookie(iClient, g_hCookieT, szInfo);
	}
}

public Action Command_Say(int iClient, const char[] command, int argc) {
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	static char sModelsMenuCmds[][] = {
		".models",
		"!models",
		"models",
		".model",
		"!model",
		"model",
		".agent",
		"!agent",
		"agent",
		".agents",
		"!agents",
		"agents",
	};

	char sBuffer[24];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);
	TrimString(sBuffer);

	for(int i = 0; i < sizeof(sModelsMenuCmds); i++) {
		if(strcmp(sBuffer, sModelsMenuCmds[i], false) == 0) {
			if(!IsPlayerAlive(iClient)) {
				PrintCenterText(iClient, "%t", "Only alive select nodel");
				ClientCommand(iClient, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if(!(GetEntityFlags(iClient) & FL_ONGROUND)) {
				PrintCenterText(iClient, "%t", "Only the ground");
				ClientCommand(iClient, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if(g_CvarBuyZoneOnly.BoolValue && !GetEntProp(iClient, Prop_Send, "m_bInBuyZone")) {			
				PrintCenterText(iClient, "%t", "Only available in the purchase area");
				ClientCommand(iClient, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			} else if (g_CvarSkinSelectTime.FloatValue > 0.0 && g_hSkinTimer == null) {
				PrintCenterText(iClient, "%t", "Time to choose is up");	
				ClientCommand(iClient, "play player/suit_denydevice.wav");
				return Plugin_Continue;
			}
			DisplayModelsMenu(iClient, MENU_TIME_FOREVER);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast) {
	if(g_CvarSkinSelectTime.FloatValue > 0.0) {
		if(g_hSkinTimer != null)
			delete g_hSkinTimer;
		g_hSkinTimer = CreateTimer(g_CvarSkinSelectTime.FloatValue, Timer_DisableSkin);
	}
}

public Action Timer_DisableSkin(Handle timer) {
	g_hSkinTimer = null;
	for(int iClient = 1; iClient <= MaxClients; iClient++)
		if(IsValidClient(iClient) && g_sModelSettings.OpenModelsMenu[iClient])
			CancelClientMenu(iClient);

	return Plugin_Stop;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(iClient) && g_sModelSettings.OpenModelsMenu[iClient])
		CancelClientMenu(iClient);
	return Plugin_Continue;
}

public Action Event_ExitBuyzone(Event event, const char[] name, bool dontBroadcast) {
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(g_CvarBuyZoneOnly.BoolValue && IsValidClient(iClient) && g_sModelSettings.OpenModelsMenu[iClient])
		CancelClientMenu(iClient);
	return Plugin_Continue;
}

public Action MdlCh_PlayerSpawn(int iClient, bool bCustom, char[] sModel, int iModelMaxlen, char[] sVoPrefix, int iPrefixMaxlen) {
	if (IsFakeClient(iClient))	
		return Plugin_Continue;

	Modelslist info;
	int iClientTeam = GetClientTeam(iClient);
	int iActiveModelPos = g_sModelSettings.GetModelListPos(iClientTeam,iClient);
	if (!g_sModelSettings.IsValidModelPos(iClient,iClientTeam))
		iActiveModelPos = 0;

	g_sModelSettings.GetModelArrayList(iClientTeam).GetArray(iActiveModelPos, info);

	if (bCustom && !info.model_player[0])
		return Plugin_Continue;

	if (iClientTeam >= 2) {
		if (info.model_player[0])
			strcopy(sModel, iModelMaxlen, info.model_player);
		if (info.vo_prefix[0])
			strcopy(sVoPrefix, iPrefixMaxlen, info.vo_prefix);	
#if ARMS_FIX				
		int iMyWearables = GetEntPropEnt(iClient, Prop_Send, "m_hMyWearables");
		if (iMyWearables == -1) {
			Address pPlayerViewmodelArmConfig = view_as<Address>(SDKCall(g_hGetPlayerViewmodelArmConfigForPlayerModel, info.model_player));
			Address pAssociatedGloveModel = view_as<Address>(LoadFromAddress(pPlayerViewmodelArmConfig + view_as<Address>(8), NumberType_Int32));
			if(LoadFromAddress(pAssociatedGloveModel, NumberType_Int8) == 0 && info.arms[0] == EOS) {
				info.arms = "models/weapons/v_models/arms/glove_hardknuckle/v_glove_hardknuckle_blue.mdl";
			}
		} else if (info.arms[0]) {
			AcceptEntityInput(iMyWearables, "KillHierarchy");
		}

		SetEntPropString(iClient, Prop_Send, "m_szArmsModel", info.arms);	
#endif
	}

	return Plugin_Changed;
}

#if ARMS_FIX
public void LoadArmsReplace() {
	GameData hData = new GameData("CustomPlayerArms.games");
	
	if(hData) {
		Address s_playerViewmodelArmConfigs = hData.GetAddress("s_playerViewmodelArmConfigs");
		
		if(s_playerViewmodelArmConfigs == Address_Null)
			SetFailState("Couldn't get the address s_playerViewmodelArmConfigs");

		for(int i = 2; i < 4; i++) {
			int pStr = LoadFromAddress(s_playerViewmodelArmConfigs + view_as<Address>(i * 4), NumberType_Int32);
			StoreToAddress(view_as<Address>(pStr), 0, NumberType_Int8);
		}
		
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "GetPlayerViewmodelArmConfigForPlayerModel");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hGetPlayerViewmodelArmConfigForPlayerModel = EndPrepSDKCall();
		
		if(!g_hGetPlayerViewmodelArmConfigForPlayerModel)
			SetFailState("Failed to create a call GetPlayerViewmodelArmConfigForPlayerModel");

		delete hData;
	} else {
		SetFailState("Failed to load GameData");
	}
}
#endif

public Action ReloadModels(int client, int args) {
	ReadModelsCfg();
}

stock bool IsValidClient(int client) {
	return 0 < client && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
