public void ConvarsInit() {
	mp_forcecamera = FindConVar("mp_forcecamera");
	mp_playercashawards = FindConVar("mp_playercashawards");
	mp_teamcashawards = FindConVar("mp_teamcashawards");
	sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");

	sm_map_change_reload_cfg = CreateConVar("sm_map_change_reload_cfg", "1", "Reload the model's settings config when changing the map?.", 0, true, 0.0, true, 1.0);
	sm_buyzone_only = CreateConVar("sm_buyzone_only", "1", "Allow model selection only in the buyzone.", 0, true, 0.0, true, 1.0);
	sm_select_skin_time = CreateConVar("sm_select_skin_time", "55.0", "After how many seconds to disable the model selection. '0 disable timer'", 0, true, 0.0);
	AutoExecConfig(true, "csgo_models");
}