util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )
util.AddNetworkString( "CFC_Loadout_InitialSpawn" )
util.AddNetworkString( "CFC_Loadout_SendRestrictions" )
include( "cfc_loadouts/server/sv_cfc_loadout.lua" )
AddCSLuaFile( "cfc_loadouts/client/cl_cfc_functions.lua" )
-- AddCSLuaFile( "cfc_loadouts/client/cl_cfc_interface.lua" )
AddCSLuaFile( "cfc_loadouts/client/cl_cfc_loadout.lua" )
AddCSLuaFile( "cfc_loadouts/client/cl_cfc_quickmenu.lua" )
