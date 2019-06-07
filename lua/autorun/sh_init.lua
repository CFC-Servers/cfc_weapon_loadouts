AddCSLuaFile()

local LoadoutCommands = {}
LoadoutCommands["create"] = "!saveloadout"
LoadoutCommands["delete"] = "!deleteloadout"
LoadoutCommands["list"]   = "!loadouts"
LoadoutCommands["equip"]  = "!loadout"

local LoadoutCommandFunctions = {}

local DEBUG = true

local LOADOUT_DIR = "cfc_weapon_loadouts"

local CurrentLoadouts = {}

-- NOTE: Creates dir in "/garrysmod/data/"
local createDirectory = file.CreateDir

local function makePath(...)
    local path = ""
    for i, v in ipairs( arg ) do
        if i == 1 then
            path = v
        else
            path = path .. "/" .. v
        end
    end

    return path
end

local function IsValidPlayer(ply)
    local isValidPlayer = IsValid( ply ) and ply:IsPlayer()

    return isValidPlayer
end

local function existsInDataDirectory( dir )
    return file.Exists( dir, "DATA" )
end

local function baseLoadoutDirectoryExists()
    return existsInDataDirectory( LOADOUT_DIR )
end

local function createBaseLoadoutDirectory()
    createDirectory( LOADOUT_DIR )
end

local function getPlayerLoadoutDirectory(ply)
    local loadoutDirectory = makePath( LOADOUT_DIR, string.lower(ply:SteamID()) )
    local loadoutDirectoryExists = existsInDataDirectory( loadoutDirectory )

    return loadoutDirectory, loadoutDirectoryExists
end

local function playerLoadoutExists(loadoutDirectory, loadout)
    local loadoutFile = makePath( loadoutDirectory, loadout )
    
    return existsInDataDirectory( loadoutFile )
end


-- Returns the type of chat command and the loadout if valid, false if not
local function isValidChatCommand(chatString)
    if not string.StartWith(chatString, "!") then return false end

    local lowercaseChatString = string.lower( chatString )

    -- A chat command needs exactly 2 words
    local chatSplitBySpaces = string.Split( lowercaseChatString, " " )
    if table.Count( chatSplitBySpaces ) ~= 2 then return false end
    
    local spokenCommand, loadout = chatSplitBySpaces[1], chatSplitBySpaces[2]

    for operation, command in pairs( LoadoutCommands ) do
        if spokenCommand == command then
            return operation, loadout
        end
    end

    return false
end

local function getPlayerWeaponsAsString(ply)
    local weapons = ply:GetWeapons()
    
    local weaponString = ""

    for _, wep in ply:GetWeapons() do
        weaponString = weaponString .. wep:GetClass() .. "\n"
    end
        
    return weaponString
end

local function getWeaponsFromLoadout(loadoutPath)
    local weaponString = file.Read( loadoutPath )

    return string.Split( weaponString, "\n" )
end


LoadoutCommandFunctions["create"] = function(ply, loadoutPath)
    local weaponString = getPlayerWeaponsAsString( ply )

    file.Write( loadoutPath, weaponString )
end

LoadoutCommandFunctions["delete"] = function(ply, loadoutPath)
    file.Delete( loadoutPath )
end

LoadoutCommandFunctions["list"] = function(ply, loadoutPath)
    local weaponClasses = getWeaponsFromLoadout( loadoutPath )

    ply:ChatPrint("LOADOUT:")

    -- TODO: Make this not a totally shit way to report a loadout
    for _, class in ipairs( weaponClasses ) do
        ply:ChatPrint("\t" .. class )
    end
end

LoadoutCommandFunctions["equip"] = function(ply, loadoutPath)
    -- TODO: Maybe not take literally everything
    ply:StripWeapons()

    local weaponClasses = getWeaponsFromLoadout( loadoutPath )

    for _, class in ipairs( weaponClasses ) do
        ply:Give( class )
    end
end


local function checkChatForLoadoutCommand( ply, text, teamOnly, playerIsDead )
    if not IsValidPlayer( ply ) then return end

    local operation, loadout = isValidChatCommand( text )
    if not operation then return end
    
    playerLoadoutDirectory = getPlayerLoadoutDirectory( ply )
    if not existsInDataDirectory( playerLoadoutDirectory ) then createDirectory( playerLoadoutDirectory ) end

    local playerLoadoutFile = makePath( playerLoadoutDirectory, loadout )

    if operation == "create" then
        -- You can't create a loadout when you're dead, dumbass
        if playerIsDead then return end

        if existsInDataDirectory( playerLoadoutFile ) then
            ply:ChatPrint( 'You cannot overwrite a loadout! Please use the command "' .. LoadoutCommands['delete'] .. " " .. loadout .. '" before re-creating ' .. loadout ) 
        end
    else
        if not existsInDataDirectory( playerLoadoutFile ) then
            ply:ChatPrint( 'Loadout ' .. loadout .. ' does not exist!' )
            return end
        end
    end

    LoadoutCommandFunctions[operation]( ply, playerLoadoutFile )
end

hook.Remove( "OnPlayerChat", "CFC_LoadoutManager" )
hook.Add( "OnPlayerChat", "CFC_LoadoutManager", checkChatForLoadoutCommand )


if not baseLoadoutDirectoryExists() then createBaseLoadoutDirectory() end

