ArrayList g_teamsModelsList[4];
Menu g_modelsMenu;

ConVar mp_forcecamera,
	mp_playercashawards,
	mp_teamcashawards,
	sv_allow_thirdperson,
	sm_select_skin_time,
	sm_buyzone_only,
	sm_map_change_reload_cfg;

Handle g_skinTimer,
	g_cookieT,
	g_cookieCT;

#if ARMS_FIX
Handle g_getPlayerViewModelArmConfigForPlayerModel;
#endif

bool g_vipCoreExist;
char g_feature[] = "Vip Model";

enum struct ModelsList {
	char name[PLATFORM_MAX_PATH];
	char modelPlayer[PLATFORM_MAX_PATH];
	char arms[PLATFORM_MAX_PATH];
	char voPrefix[64];
	int flags;
	bool vip;
}
enum struct ClientModelCacheMask {
	int ctModelPos;
	int tModelPos;
}
enum struct ClientModelSettings {
	StringMap modelsCache;
	bool openModelsMenu[MAXPLAYERS + 1];
}
ClientModelSettings g_clientModelSettings;