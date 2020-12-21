#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <modelch>

//#undef REQUIRE_PLUGIN
#define ARMS_FIX 1 // Set 0 to disable arms fix

#include "csgo_models/global.sp"
#include "csgo_models/config.sp"
#include "csgo_models/menu.sp"
#include "csgo_models/main.sp"

public Plugin myinfo =  {
	name = "CS:GO Player Models (mmcs.pro)",
	author = "SAZONISCHE",
	description = "CS:GO Player Models",
	version = "1.0",
	url = "mmcs.pro"
};

public void OnPluginStart() {
	// Plugin only for csgo
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");

	LoadTranslations("csgo_models.phrases");
	LoadTranslations("csgo_models_names.phrases");
	g_aModelslist[CS_TEAM_T] = new ArrayList(sizeof(Modelslist));
	g_aModelslist[CS_TEAM_CT] = new ArrayList(sizeof(Modelslist));
	BuildMain();

#if ARMS_FIX
	LoadArmsReplace();	
#endif

	g_hCookieT = RegClientCookie("sm_model_id_t", "Terrorists Skins", CookieAccess_Private);
	g_hCookieCT = RegClientCookie("sm_model_id_ct", "Counter-Terrorists Skins", CookieAccess_Private);

	mp_forcecamera = FindConVar("mp_forcecamera");
	g_CvarByzoneOnly = CreateConVar("sm_byzone_only", "1", "Allow model selection only in the byzone.", 0, true, 0.0, true, 1.0);
	g_CvarSkinSelectTime = CreateConVar("sm_select_skin_time", "55.0", "After how many seconds to disable the model selection. '0 disable timer'", 0, true, 0.0);
	AutoExecConfig(true, "csgo_models");
}

public void OnMapStart() {
	ReadModelsCfg();
}
