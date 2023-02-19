methodmap Gameplay {
	public static ArrayList GetModelArrayList(int team) {
		return g_teamsModelslist[team];
	}

	public static int GetCountTeamModels(int team) {
		return g_teamsModelslist[team].Length;
	}

	public static void AddStandardModelIndex(int team) {
		Modelslist modelslistData;
		modelslistData.name = "Standard";
		modelslistData.modelPlayer = "";
		modelslistData.arms = "";
		modelslistData.voPrefix = "";
		modelslistData.flags = 0;
		g_teamsModelslist[team].ShiftUp(0); 
		g_teamsModelslist[team].SetArray(0,modelslistData);
	}
}

methodmap Client {
	public static int GetModelListPos(int team, int client) {
		return (team == CS_TEAM_CT) ? g_clientModelSettings.ctModelPos[client] : g_clientModelSettings.tModelPos[client];
	}

	public static void SetModelListPos(int team, int client, int iPos) {
		if (team == CS_TEAM_CT)
			g_clientModelSettings.ctModelPos[client] = iPos;
		else
			g_clientModelSettings.tModelPos[client] = iPos;
	}

	public static bool IsValidModelPos(int client, int team) {
		return (g_clientModelSettings.ctModelPos[client] <= (g_teamsModelslist[team].Length -1));
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
		int health = GetEntProp(client,Prop_Send,"m_iHealth");
		int armorValue = GetEntProp(client,Prop_Send,"m_ArmorValue");
		int hasHelmet = GetEntProp(client,Prop_Send,"m_bHasHelmet");
		CS_RespawnPlayer(client);
		SetEntProp(client, Prop_Send, "m_iAccount", money);
		SetEntProp(client,Prop_Send,"m_iHealth", health);
		SetEntProp(client,Prop_Send,"m_ArmorValue", armorValue);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", hasHelmet);
		TeleportEntity(client, origin, angles);
	}
}
