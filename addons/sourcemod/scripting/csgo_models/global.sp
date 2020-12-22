ArrayList g_aModelslist[4];
Menu g_ModelsMenu = null;
ConVar mp_forcecamera, g_CvarSkinSelectTime = null, g_CvarBuyZoneOnly = null;
Handle g_hSkinTimer = null, g_hCookieT = null, g_hCookieCT = null;

#if ARMS_FIX
Handle g_hGetPlayerViewmodelArmConfigForPlayerModel;
#endif

enum struct Modelslist {
	char name[PLATFORM_MAX_PATH];
	char model_player[PLATFORM_MAX_PATH];
	char arms[PLATFORM_MAX_PATH];
	char vo_prefix[16];
	int flags;
	bool vip;
}

enum struct ModelSettings {
	int CtModelPos[MAXPLAYERS + 1];
	int TmodelPos[MAXPLAYERS + 1];
	bool OpenModelsMenu[MAXPLAYERS + 1];

	ArrayList GetModelArrayList(int iTeam) {
		return g_aModelslist[iTeam];
	}

	int GetCountTeamModels(int iTeam) {
		return g_aModelslist[iTeam].Length;
	}

	int GetModelListPos(int iTeam, int iClient) {
		return (iTeam == CS_TEAM_CT) ? this.CtModelPos[iClient] : this.TmodelPos[iClient];
	}

	void SetModelListPos(int iTeam, int iClient, int iPos) {
		if(iTeam == CS_TEAM_CT)
			this.CtModelPos[iClient] = iPos;
		else
			this.TmodelPos[iClient] = iPos;
	}

	void SetThirdPersonView(int iClient, bool bDraw) {
		if(bDraw) {
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0); 
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 0);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 120);
			mp_forcecamera.ReplicateToClient(iClient,"1");
			SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 0.0);	
		} else {
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", -1);
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 1);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
			char sCamMode[2];
			IntToString(mp_forcecamera.IntValue, sCamMode, sizeof sCamMode);
			mp_forcecamera.ReplicateToClient(iClient, sCamMode);
			SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 1.0);	
		}
	}
	
	void RebuildModel(int iClient) {
		if(!IsPlayerAlive(iClient))
			return;

		float fOrigin[3], fAngles[3];
		GetClientAbsOrigin(iClient, fOrigin);
		GetClientAbsAngles(iClient, fAngles);
		int iMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
		int iHealth = GetEntProp(iClient,Prop_Send,"m_iHealth");
		int iArmorValue = GetEntProp(iClient,Prop_Send,"m_ArmorValue");
		int bHasHelmet = GetEntProp(iClient,Prop_Send,"m_bHasHelmet");
		CS_RespawnPlayer(iClient);
		SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney);
		SetEntProp(iClient,Prop_Send,"m_iHealth", iHealth);
		SetEntProp(iClient,Prop_Send,"m_ArmorValue", iArmorValue);
		SetEntProp(iClient, Prop_Send, "m_bHasHelmet", bHasHelmet);
		TeleportEntity(iClient, fOrigin, fAngles, NULL_VECTOR);
	}
}
ModelSettings g_sModelSettings;