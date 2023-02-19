#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <modelch>

#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN

//#undef REQUIRE_PLUGIN
#define ARMS_FIX 1 // Set 0 to disable arms fix

#include "csgo_models/variables.sp"
#include "csgo_models/convars.sp"
#include "csgo_models/methods.sp"
#include "csgo_models/config.sp"
#include "csgo_models/menu.sp"
#include "csgo_models/main.sp"

public Plugin myinfo =  {
	name = "CS:GO Player Models (mmcs.pro)",
	author = "SAZONISCHE",
	description = "CS:GO Player Models",
	version = "3.0",
	url = "mmcs.pro"
};

public void OnPluginStart() {
	// Plugin only for csgo
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");

	LoadTranslations("csgo_models.phrases");
	LoadTranslations("csgo_models_names.phrases");

	ConvarsInit();
	MainInit();
#if ARMS_FIX
	LoadArmsReplace();	
#endif
}

public void OnMapStart() {
	ReadModelsCfg();
#if ARMS_FIX
	PrecacheModel("models/weapons/v_models/arms/glove_hardknuckle/v_glove_hardknuckle_blue.mdl");
#endif
}

public void OnAllPluginsLoaded() { if (LibraryExists("vip_core")) { g_vipCoreExist = true; } }
public void OnLibraryAdded(const char[] name) { if (StrEqual("vip_core", name)) { g_vipCoreExist = true; } }
public void OnLibraryRemoved(const char[] name) { if (StrEqual("vip_core", name)) { g_vipCoreExist = false; } }
