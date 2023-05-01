
void DisplayModelsMenu(int client, int time) {
	if (!g_modelsMenu) {
		g_modelsMenu = new Menu(ModelsMenu, MenuAction_Display|MenuAction_DisplayItem|MenuAction_End|MenuAction_Cancel);
		g_modelsMenu.ExitButton = true;
		g_modelsMenu.AddItem("", "");
		g_modelsMenu.AddItem("", "");
		g_modelsMenu.AddItem("", "");
	}
	g_clientModelSettings.openModelsMenu[client] = true;
	g_modelsMenu.Display(client, time);
}

int ModelsMenu(Menu menu, MenuAction action, int client, int param) {
	static char menuBuffer[256];

	if (action == MenuAction_End || !IsClientInGame(client))
		return 0;

	ModelsList modelsListData;
	int clientTeam = GetClientTeam(client);
	int modelPos = Client.GetModelListPos(client, clientTeam);
	if (!Gameplay.IsValidModelPos(clientTeam, modelPos)) {
		modelPos = 0;
	}

	g_teamsModelsList[clientTeam].GetArray(modelPos, modelsListData);

	switch (action) {
		case MenuAction_Display: {
			static char prefix[32];
			FormatEx(prefix, sizeof prefix, "%s%s", modelsListData.flags ? "[ADMIN]" : "", (g_vipCoreExist && modelsListData.vip) ? "[VIP]" : "");
			if (TranslationPhraseExists(modelsListData.name)) {
				FormatEx(menuBuffer, sizeof menuBuffer, "%T\n%T %s", "Models menu", client, modelsListData.name, client, prefix);
			} else {
				FormatEx(menuBuffer, sizeof menuBuffer, "%T\n%s %s", "Models menu", client, modelsListData.name, prefix);
			}
			menu.SetTitle(menuBuffer);

			if (modelsListData.flags && !(GetUserFlagBits(client) & modelsListData.flags)) {
				PrintCenterText(client, "%t", "Only to privileged players");
			}

			if (g_vipCoreExist && modelsListData.vip && !VIP_IsClientVIP(client) && !VIP_IsClientFeatureUse(client, g_feature)) {
				PrintCenterText(client, "%t", "Only to VIP players");
			}
		}
		case MenuAction_DisplayItem: {
			Client.SetThirdPerson(client, true);
			switch (param) {
				case 0: {
					FormatEx(menuBuffer, sizeof menuBuffer, "%T", modelsListData.modelPlayer[0] ? "Next" : "Select model", client);
					return RedrawMenuItem(menuBuffer);
				}
				case 1: {
					FormatEx(menuBuffer, sizeof menuBuffer, "%T", "Back", client);
					return RedrawMenuItem(menuBuffer);
				}
				case 2: {
					FormatEx(menuBuffer, sizeof menuBuffer, "%T", "Remove model", client);
					return RedrawMenuItem(menuBuffer);
				}
			}
			return 0;
		}
		case MenuAction_Cancel: {
			if (!Client.IsHaveRightsToTheModel(client, modelsListData)) {
				PrintCenterText(client, "%t", modelsListData.flags ? "Only to privileged players" : "Only to VIP players");
				Client.SetModelListPos(client, clientTeam, 0);
				Client.RebuildModel(client);
			}
			
			Client.SetThirdPerson(client, false);
			g_clientModelSettings.openModelsMenu[client] = false;
			if (sm_select_skin_time.FloatValue > 0.0 && g_skinTimer == null) {
				PrintCenterText(client, "%t", "Time to choose is up");	
			}
		}
		case MenuAction_Select: {
			switch (param) {
				case 0: modelPos = ++modelPos >= g_teamsModelsList[clientTeam].Length ? 0 : modelPos;
				case 1: modelPos = --modelPos <= -1 ? (g_teamsModelsList[clientTeam].Length -1) : modelPos;
				case 2: modelPos = 0;
			}

			Client.SetModelListPos(client, clientTeam, modelPos);
			Client.RebuildModel(client);
			DisplayModelsMenu(client, MENU_TIME_FOREVER);
		}
	}
	return 0;
}