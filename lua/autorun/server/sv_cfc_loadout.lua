hook.Add( "PlayerLoadout", "PlayerSpawnWeaponsLoadout", function( ply )
    ply:Give( "weapon_pistol" )
    return true
end)