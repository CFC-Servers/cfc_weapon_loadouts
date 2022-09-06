util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )
util.AddNetworkString( "CFC_Loadout_InitialSpawn" )
util.AddNetworkString( "CFC_Loadout_SendRestrictions" )

-- Hardcoded ammo id's to improve peformance, https://wiki.facepunch.com/gmod/Default_Ammo_Types
local weaponAmmoCounts = {
    [1] = 500, -- weapon_ar2 primary
    [2] = 10, -- weapon_ar2 altfire
    [3] = 100, -- weapon_pistol
    [4] = 500, -- weapon_smg1 primary
    [5] = 200, -- weapon_357
    [6] = 100, -- weapon_crossbow
    [7] = 100, -- weapon_shotgun
}

local function giveWeapons( ply )
    if ply.cfcLoadoutWeapons == nil then return end

    for _, weapon in pairs( ply.cfcLoadoutWeapons ) do
        local canSpawn = URS.Check( ply, "swep", weapon )
        local weaponTable = weapons.Get( weapon )

        if weaponTable and weaponTable.AdminOnly and not ply:IsAdmin() then
            canSpawn = false
        end

        if canSpawn ~= false then
            ply:Give( weapon )
        end
    end

    for k, v in ipairs( weaponAmmoCounts ) do
        ply:SetAmmo( v, k )
    end

    ply:Give( "weapon_physgun" )

    return true
end

net.Receive( "CFC_Loadout_WeaponTable", function( _, ply )
    local weaponTable = net.ReadTable( )
    ply.cfcLoadoutWeapons = weaponTable

    ply:ChatPrint( "[CFC Loadouts] Success - Your loadout will be applied upon respawning!")
end )

net.Receive( "CFC_Loadout_Resetweapons", function( _, ply )
    ply.cfcLoadoutWeapons = nil
    ply:ChatPrint( "[CFC Loadouts] Success - Your loadout was reset!")
end )

hook.Add( "CFC_PvP_ShouldGiveLoadout", "CFC_Loadouts", function( ply )
    if ply.cfcLoadoutWeapons then return false end
end )

hook.Add( "PlayerLoadout", "CFC_Loadout_GiveWeaponsOnSpawn", giveWeapons, HOOK_HIGH )

net.Receive( "CFC_Loadout_InitialSpawn", function( _, ply )
    local restrictedTable = URS.restrictions.swep
    net.Start( "CFC_Loadout_SendRestrictions" )
    net.WriteTable( restrictedTable )
    net.Send( ply )
end )
