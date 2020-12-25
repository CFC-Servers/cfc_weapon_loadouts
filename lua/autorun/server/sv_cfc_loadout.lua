util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )

local function giveWeapons( ply )
    if ply.loadoutWeapons == nil then return end
    for _, weapon in pairs( ply.loadoutWeapons ) do
        local canSpawn = hook.Run( "PlayerGiveSWEP", ply, weapon )
        if canSpawn == true then
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
    ply.loadoutWeapons = weaponTable
end )

net.Receive( "CFC_Loadout_Resetweapons", function( _, ply )
    ply.loadoutWeapons = nil
end )

hook.Add( "PlayerLoadout", "PlayerSpawnWeaponsLoadout", giveWeapons , HOOK_HIGH )
