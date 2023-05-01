methodmap Gameplay {
	public static bool IsValidModelPos(int team, int modelPos) {
		return modelPos <= (g_teamsModelsList[team].Length -1);
	}

	public static void AddStandardModelIndex(int team) {
		ModelsList modelsListData;
		modelsListData.name = "Standard";
		modelsListData.modelPlayer = "";
		modelsListData.arms = "";
		modelsListData.voPrefix = "";
		modelsListData.flags = 0;
		g_teamsModelsList[team].ShiftUp(0); 
		g_teamsModelsList[team].SetArray(0,modelsListData);
	}
}

methodmap Client {
	public static int GetModelListPos(int client, int team) {
		char steamId[10];
		ClientModelCacheMask data;
		IntToString(GetSteamAccountID(client), steamId, sizeof steamId);
		g_clientModelSettings.modelsCache.GetArray(steamId, data, sizeof ClientModelCacheMask);
		return (team == CS_TEAM_CT) ? data.ctModelPos : data.tModelPos;
	}

	public static void SetModelListPos(int client, int team, int iPos) {
		char steamId[10];
		ClientModelCacheMask data;
		IntToString(GetSteamAccountID(client), steamId, sizeof steamId);
		g_clientModelSettings.modelsCache.GetArray(steamId, data, sizeof ClientModelCacheMask);
		team == CS_TEAM_CT ? data.ctModelPos = iPos : data.tModelPos = iPos;
		g_clientModelSettings.modelsCache.SetArray(steamId, data, sizeof ClientModelCacheMask);
	}

	public static bool IsHaveRightsToTheModel(int client, ModelsList modelsListData) {
		if (modelsListData.flags && (GetUserFlagBits(client) & modelsListData.flags)) {
			return true;
		}

		if (g_vipCoreExist && modelsListData.vip && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, g_feature)) {
			return true;
		}

		if (!modelsListData.flags && !modelsListData.vip) {
			return true;
		}

		return false;
	}

	public static void SetThirdPerson(int client, bool draw) {
		static const int HIDE_RADAR_CSGO = 1 << 12, 
			HIDE_CROSSHAIR_CSGO = 1 << 8;
		if (draw) {
			sv_allow_thirdperson.ReplicateToClient(client, "1");
			mp_forcecamera.ReplicateToClient(client,"1");
			mp_playercashawards.ReplicateToClient(client,"0");
			mp_teamcashawards.ReplicateToClient(client,"0");
			ClientCommand(client, "crosshair 0");
			ClientCommand(client, "thirdperson");
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR_CSGO);
		} else {
			char conVarCache[2];
			ClientCommand(client, "firstperson");
			ClientCommand(client, "crosshair 1");
			sv_allow_thirdperson.ReplicateToClient(client, "0");
			IntToString(mp_forcecamera.IntValue, conVarCache, sizeof conVarCache);
			mp_forcecamera.ReplicateToClient(client, conVarCache);
			IntToString(mp_playercashawards.IntValue, conVarCache, sizeof conVarCache);
			mp_playercashawards.ReplicateToClient(client, conVarCache);
			IntToString(mp_teamcashawards.IntValue, conVarCache, sizeof conVarCache);
			mp_teamcashawards.ReplicateToClient(client, conVarCache);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);	
		}
	}
	
	public static void RebuildModel(int client) {
		if (!IsPlayerAlive(client))
			return;

		float origin[3], angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		int money = GetEntProp(client, Prop_Send, "m_iAccount");
		int health = GetEntProp(client, Prop_Send, "m_iHealth");
		int armorValue = GetEntProp(client, Prop_Send, "m_ArmorValue");
		int hasHelmet = GetEntProp(client, Prop_Send, "m_bHasHelmet");
		CS_RespawnPlayer(client);
		SetEntProp(client, Prop_Send, "m_iAccount", money);
		SetEntProp(client, Prop_Send, "m_iHealth", health);
		SetEntProp(client, Prop_Send, "m_ArmorValue", armorValue);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", hasHelmet);
		TeleportEntity(client, origin, angles);
	}
}
