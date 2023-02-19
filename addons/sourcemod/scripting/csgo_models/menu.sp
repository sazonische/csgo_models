
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

	Modelslist modelslistData;
	int clientTeam = GetClientTeam(client);
	int modelPos = Client.GetModelListPos(clientTeam,client);
	if (!Client.IsValidModelPos(client,clientTeam))
		modelPos = 0;

	Gameplay.GetModelArrayList(clientTeam).GetArray(modelPos, modelslistData);

	switch (action) {
		case MenuAction_Display: {
			static char prefix[32];
			FormatEx(prefix, sizeof prefix, "%s%s", modelslistData.flags ? "[ADMIN]" : "", (g_vipCoreExist && modelslistData.vip) ? "[VIP]" : "");
			if (TranslationPhraseExists(modelslistData.name)) {
				FormatEx(menuBuffer, sizeof menuBuffer, "%T\n%T %s", "Models menu", client, modelslistData.name, client, prefix);
			} else {
				FormatEx(menuBuffer, sizeof menuBuffer, "%T\n%s %s", "Models menu", client, modelslistData.name, prefix);
			}
			menu.SetTitle(menuBuffer);

			if (modelslistData.flags && !(GetUserFlagBits(client) & modelslistData.flags)) {
				PrintCenterText(client, "%t", "Only to privileged players");
			}

			if (g_vipCoreExist && modelslistData.vip && !VIP_IsClientVIP(client) && !VIP_IsClientFeatureUse(client, g_feature)) {
				PrintCenterText(client, "%t", "Only to VIP players");
			}
		}
		case MenuAction_DisplayItem: {
			Client.SetThirdPerson(client, true);
			switch (param) {
				case 0: {
					FormatEx(menuBuffer, sizeof menuBuffer, "%T", modelslistData.modelPlayer[0] ? "Next" : "Select model", client);
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
			bool resetModel = true;
			if (modelslistData.flags && (GetUserFlagBits(client) & modelslistData.flags)) {
				resetModel = false;
			}

			if (g_vipCoreExist && modelslistData.vip && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, g_feature)) {
				resetModel = false;
			}

			if (!modelslistData.flags && !modelslistData.vip) {
				resetModel = false;
			}

			if (resetModel) {
				PrintCenterText(client, "%t", modelslistData.flags ? "Only to VIP players" : "Only to VIP players");
				Client.SetModelListPos(clientTeam, client, 0);
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
				case 0: modelPos = ++modelPos >= Gameplay.GetCountTeamModels(clientTeam) ? 0 : modelPos;
				case 1: modelPos = --modelPos <= -1 ? (Gameplay.GetCountTeamModels(clientTeam) -1) : modelPos;
				case 2: modelPos = 0;
			}

			Client.SetModelListPos(clientTeam, client, modelPos);
			Client.RebuildModel(client);
			DisplayModelsMenu(client, MENU_TIME_FOREVER);
		}
	}
	return 0;
}