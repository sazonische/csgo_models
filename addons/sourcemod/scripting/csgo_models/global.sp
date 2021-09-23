ArrayList g_aTeamsModelslist[4];
Menu g_ModelsMenu = null;
ConVar mp_forcecamera, mp_playercashawards, mp_teamcashawards, g_CvarSkinSelectTime = null, g_CvarBuyZoneOnly = null, g_CvarMapChangeReloadCfg = null;
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
		return g_aTeamsModelslist[iTeam];
	}

	int GetCountTeamModels(int iTeam) {
		return g_aTeamsModelslist[iTeam].Length;
	}

	bool IsValidModelPos(int iClient, int iTeam) {
		return (this.CtModelPos[iClient] <= (g_aTeamsModelslist[iTeam].Length -1));
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
		static const int HIDE_RADAR_CSGO = 1 << 12, HIDE_CROSSHAIR_CSGO = 1<<8;
		if(bDraw) {
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0); 
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 0);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 120);
			mp_forcecamera.ReplicateToClient(iClient,"1");
			mp_playercashawards.ReplicateToClient(iClient,"0");
			mp_teamcashawards.ReplicateToClient(iClient,"0");
			SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 0.0);
			SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
			SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR_CSGO);
		} else {
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", -1);
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 1);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
			char sCvar[2];
			IntToString(mp_forcecamera.IntValue, sCvar, sizeof sCvar);
			mp_forcecamera.ReplicateToClient(iClient, sCvar);
			IntToString(mp_playercashawards.IntValue, sCvar, sizeof sCvar);
			mp_playercashawards.ReplicateToClient(iClient, sCvar);
			IntToString(mp_teamcashawards.IntValue, sCvar, sizeof sCvar);
			mp_teamcashawards.ReplicateToClient(iClient, sCvar);
			SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
			SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);	
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