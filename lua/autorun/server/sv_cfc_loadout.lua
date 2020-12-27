util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )

local function giveWeapons( ply )
    if ply.cfcLoadoutWeapons == nil then return end
    for _, weapon in pairs( ply.cfcLoadoutWeapons ) do
        --local canSpawn = hook.Run( "PlayerGiveSWEP", ply, weapon )
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
    local weaponTable = net.ReadTable()
    ply.cfcLoadoutWeapons = weaponTable
end )

net.Receive( "CFC_Loadout_Resetweapons", function( _, ply )
    ply.cfcLoadoutWeapons = nil
end )

hook.Add( "PlayerLoadout", "PlayerSpawnWeaponsLoadout", giveWeapons , HOOK_HIGH )
PrintTable( URS.restrictions["swep"] )
