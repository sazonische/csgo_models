
void DisplayModelsMenu(int iClient, int iTime) {
	if(!g_ModelsMenu) {
		g_ModelsMenu = new Menu(ModelsMenu, MenuAction_Display | MenuAction_DisplayItem);
		g_ModelsMenu.ExitButton = true;
		g_ModelsMenu.AddItem("", "");
		g_ModelsMenu.AddItem("", "");
		g_ModelsMenu.AddItem("", "");		
	}
	g_sModelSettings.OpenModelsMenu[iClient] = true;
	g_ModelsMenu.Display(iClient, iTime);
}

int ModelsMenu(Menu menu, MenuAction action, int iClient, int iParam) {
	static char sMenuBuffer[128];

	if(action == MenuAction_End || !IsClientInGame(iClient))
		return 0;

	Modelslist info;
	int iClientTeam = GetClientTeam(iClient);
	int iActiveModelPos = g_sModelSettings.GetModelListPos(iClientTeam,iClient);
	g_sModelSettings.GetModelArrayList(iClientTeam).GetArray(iActiveModelPos, info);

	switch (action) {
		case MenuAction_Display: {
			if (TranslationPhraseExists(info.name))
				FormatEx(sMenuBuffer, sizeof(sMenuBuffer), "%T\n%T", "Models menu", iClient, info.name, iClient);
			else
				FormatEx(sMenuBuffer, sizeof(sMenuBuffer), "%T\n%s", "Models menu", iClient, info.name);
			menu.SetTitle(sMenuBuffer);
		}
		case MenuAction_DisplayItem: {
			g_sModelSettings.SetThirdPersonView(iClient, true);
			switch (iParam) {
				case 0: {
					FormatEx(sMenuBuffer, sizeof(sMenuBuffer), "%T", info.model_player[0] ? "Next" : "Select model", iClient);
					return RedrawMenuItem(sMenuBuffer);
				}
				case 1: {
					FormatEx(sMenuBuffer, sizeof(sMenuBuffer), "%T", "Back", iClient);
					return RedrawMenuItem(sMenuBuffer);
				}
				case 2: {
					FormatEx(sMenuBuffer, sizeof(sMenuBuffer), "%T", "Remove model", iClient);
					return RedrawMenuItem(sMenuBuffer);
				}
			}
			return 0;
		}
		case MenuAction_Cancel: {
			if(info.flags && !(GetUserFlagBits(iClient) & info.flags)) {
				g_sModelSettings.SetModelListPos(iClientTeam, iClient, 0);
				g_sModelSettings.RebuildModel(iClient);
			}
			g_sModelSettings.SetThirdPersonView(iClient, false);
			g_sModelSettings.OpenModelsMenu[iClient] = false;
			if (g_CvarSkinSelectTime.FloatValue > 0.0 && g_hSkinTimer == null)
				PrintCenterText(iClient, "%t", "Time to choose is up");	
		}
		case MenuAction_Select: {
			switch (iParam) {
				case 0: iActiveModelPos = ++iActiveModelPos >= g_sModelSettings.GetCountTeamModels(iClientTeam) ? 0 : iActiveModelPos;
				case 1: iActiveModelPos = --iActiveModelPos <= -1 ? (g_sModelSettings.GetCountTeamModels(iClientTeam) -1) : iActiveModelPos;
				case 2: iActiveModelPos = 0;
			}

			if(info.flags && !(GetUserFlagBits(iClient) & info.flags))
				PrintCenterText(iClient, "%t", "Only to privileged players");

			g_sModelSettings.SetModelListPos(iClientTeam, iClient, iActiveModelPos);
			g_sModelSettings.RebuildModel(iClient);
			DisplayModelsMenu(iClient, MENU_TIME_FOREVER);
		}
	}
	return 0;
}