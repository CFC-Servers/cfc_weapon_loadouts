util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )
util.AddNetworkString( "CFC_Loadout_InitialSpawn" )
util.AddNetworkString( "CFC_Loadout_SendRestrictions" )

local function giveWeapons( ply )
    if ply.cfcLoadoutWeapons == nil then return end

    for _, weapon in pairs( ply.cfcLoadoutWeapons ) do
        local canSpawn = URS.Check( ply, "swep", weapon )

        if canSpawn ~= false then
            ply:Give( weapon )
            local weaponEnt = ply:GetWeapon( weapon )
            local ammoType = weaponEnt:GetPrimaryAmmoType()
            ply:SetAmmo( 1000, ammoType )
        end
    end

    return true
end

net.Receive( "CFC_Loadout_WeaponTable", function( _, ply )
    local weaponTable = net.ReadTable( )
    ply.cfcLoadoutWeapons = weaponTable
end )

net.Receive( "CFC_Loadout_Resetweapons", function( _, ply )
    ply.cfcLoadoutWeapons = nil
end )

hook.Add( "PlayerLoadout", "CFC_Loadout_GiveWeaponsOnSpawn", giveWeapons, HOOK_HIGH )

net.Receive( "CFC_Loadout_InitialSpawn", function( _, ply )
    local restrictedTable = URS.restrictions.swep
    net.Start( "CFC_Loadout_SendRestrictions" )
    net.WriteTable( restrictedTable )
    net.Send( ply )
end )