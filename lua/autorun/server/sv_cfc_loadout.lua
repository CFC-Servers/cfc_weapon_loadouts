util.AddNetworkString( "CFC_Loadout_WeaponTable" )
util.AddNetworkString( "CFC_Loadout_Resetweapons" )

net.Receive( "CFC_Loadout_WeaponTable", function( _, ply )
    local weaponTable = net.ReadTable()
    ply.loadoutWeapons = weaponTable
end )

net.Receive( "CFC_Loadout_Resetweapons", function( _, ply )
    ply.loadoutWeapons = nil
    PrintTable(ply.loadoutWeapons)
end )

hook.Add( "PlayerLoadout", "PlayerSpawnWeaponsLoadout", function( ply )
    if not ply.loadoutWeapons then return false end
    for _, weapon in pairs( ply.loadoutWeapons ) do
        hook.Run( "PlayerGiveSWEP", ply, weapon )
    end
    return true
end)