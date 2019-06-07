AddCSLuaFile()

local LOADOUT_COMMAND_PREFIX = "!"

local LoadoutCommands = {}
LoadoutCommands["create"] = "saveloadout"
LoadoutCommands["delete"] = "deleteloadout"
LoadoutCommands["list"]   = "loadouts"
LoadoutCommands["equip"]  = "loadout"


local DEBUG = true

local LOADOUT_DIR = "cfc_weapon_loadouts"

local function loadprint(msg)
    print( "[CFC Loadouts] " .. msg )
end

local function DEBUGPRINT(msg, ply)
    if not DEBUG then return end

    debugMsg = "(DEBUG): " .. msg

    loadprint( debugMsg ) 
    if IsValidPlayer( ply ) then ply:ChatPrint( debugMsg )
end

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


-- Returns the type of chat command and the loadout if valid, nil if not
local function getChatCommand(chatString)
    if not string.StartWith( chatString, LOADOUT_COMMAND_PREFIX ) then return end

    local prefixRemoved = string.sub( chatString, 2 )
    local lowercaseCommandString = string.lower( prefixRemoved )

    -- A chat command that isn't just "list" needs exactly 2 words
    local commandSplitBySpaces = string.Split( lowercaseCommandString, " " )
    if table.Count( commandSplitBySpaces ) ~= 2 then
        if commandSplitBySpaces[1] == "list" then return "list" else return nil end
    end

    local spokenCommand, loadout = commandSplitBySpaces[1], commandSplitBySpaces[2]

    for operation, command in pairs( LoadoutCommands ) do
        if spokenCommand == command then
            return operation, loadout
        end
    end
end

local function getPlayerWeaponsAsString(ply)
    local weaponsString = ""

    for _, wep in ply:GetWeapons() do
        weaponsString = weaponsString .. wep:GetClass() .. "\n"
    end
        
    return weaponsString
end

local function getWeaponsFromLoadout(loadoutPath)
    local weaponsString = file.Read( loadoutPath )

    return string.Split( weaponString, "\n" )
end

local function listLoadout(ply, loadoutPath)
    local weaponClasses = getWeaponsFromLoadout( loadoutPath )

    ply:ChatPrint("LOADOUT (" .. loadoutPath .. "):")

    -- TODO: Make this not a totally shit way to report a loadout
    for _, class in ipairs( weaponClasses ) do
        ply:ChatPrint("\t" .. class )
    end
end

-- Returns false if the file does not exist after writing
local function createLoadoutFile(loadoutPath, weaponsString)
    file.Write( loadoutPath, weaponsString )
    if not existsInDataDirectory( loadoutPath ) then return false end

    return true
end


-- LOADOUT COMMAND FUNCTIONS --

local LoadoutCommandFunctions = {}

LoadoutCommandFunctions["create"] = function(ply, loadoutPath)
    DEBUGPRINT("Creating loadout " .. loadoutPath, ply)

    local weaponsString = getPlayerWeaponsAsString( ply )

    if createLoadoutFile( loadoutPath, weaponsString ) == false then
        loadPrint( "ERROR! Failed to create loadout " .. loadoutPath )
    end
end

LoadoutCommandFunctions["delete"] = function(ply, loadoutPath)
    DEBUGPRINT("Deleting loadout " .. loadoutPath, ply)
    file.Delete( loadoutPath )
end

LoadoutCommandFunctions["list"] = function(ply, loadoutPath)
    if loadoutPath ~= nil then return listLoadout( loadoutPath ) end

    DEBUGPRINT("Listing all loadouts for " .. ply:SteamID(), ply)

    -- List all loadouts
    local loadoutDirectory = getPlayerLoadoutDirectory( ply )
    local loadoutFiles, _ = file.Find( loadoutDirectory .. "/*", "DATA" )

    for _, file in ipairs( loadoutFiles ) do
        listLoadout( makePath(loadoutDirectory, file) )
    end
end

LoadoutCommandFunctions["equip"] = function(ply, loadoutPath)
    -- TODO: Maybe not take literally everything
    ply:StripWeapons()

    DEBUGPRINT("Equipping loadout " .. loadoutPath, ply)

    local weaponClasses = getWeaponsFromLoadout( loadoutPath )

    for _, class in ipairs( weaponClasses ) do
        ply:Give( class )
    end
end

-- END LOADOUT COMMAND FUNCTIONS --



-- HOOKS --

local function checkChatForLoadoutCommand( ply, text, teamOnly, playerIsDead )
    if not IsValidPlayer( ply ) then return end

    local operation, loadout = getChatCommand( text )
    if operation == nil then return end

    DEBUGPRINT("Found chat command " .. operation, ply)

    playerLoadoutDirectory, directoryExists = getPlayerLoadoutDirectory( ply )
    if not directoryExists then createDirectory( playerLoadoutDirectory ) end

    local playerLoadoutFile = ( loadout ~= nil ) and makePath( playerLoadoutDirectory, loadout ) or nil

    DEBUGPRINT("Player loadout file location is " .. playerLoadoutFile, ply)

    if operation == "create" then
        -- You can't create a loadout when you're dead, dumbass
        if playerIsDead then return end

        if existsInDataDirectory( playerLoadoutFile ) then
            ply:ChatPrint( 'You cannot overwrite a loadout! Please use the command "' .. LoadoutCommands['delete'] .. " " .. loadout .. '" before re-creating ' .. loadout ) 
        end
    elseif not existsInDataDirectory( playerLoadoutFile ) then
        ply:ChatPrint( 'Loadout ' .. loadout .. ' does not exist!' )
        return
    end

    DEBUGPRINT("Calling loadout command...", ply)

    LoadoutCommandFunctions[operation]( ply, playerLoadoutFile )
end

hook.Remove( "OnPlayerChat", "CFC_LoadoutManager" )
hook.Add( "OnPlayerChat", "CFC_LoadoutManager", checkChatForLoadoutCommand )

-- END HOOKS --


if not baseLoadoutDirectoryExists() then createBaseLoadoutDirectory() end

