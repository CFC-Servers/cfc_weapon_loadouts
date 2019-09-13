AddCSLuaFile()

local LOADOUT_COMMAND_PREFIX = "!"

local LoadoutCommands = {}
LoadoutCommands["create"] = "saveloadout"
LoadoutCommands["delete"] = "deleteloadout"
LoadoutCommands["list"]   = "loadouts"
LoadoutCommands["equip"]  = "loadout"
LoadoutCommands["help"] = "loadouthelp"

local LoadoutDescriptions = {}
LoadoutDescriptions["create"] = "Creates a loadout of the name provided (A-Z, 0-9 only)"
LoadoutDescriptions["delete"] = "Deletes the loadout of the name provided"
LoadoutDescriptions["list"]   = "List all existing loadouts in chat"
LoadoutDescriptions["equip"]  = "Equip the loadout of the name provided"
LoadoutDescriptions["help"]       = "Shows help message"

local LOADOUT_DIR = "cfc_weapon_loadouts"

local DEFAULT_LOADOUT = "weapon_fists\n" ..    
                        "weapon_pistol\n" ..
                        "weapon_crowbar\n" ..
                        "weapon_physgun\n" ..
                        "weapon_physcannon"


-- LOGGING -- 

local DEBUG = 1
local INFO = 2
local ERROR = 3

local DEBUG_ENABLED = true

local function log(msg, level)
    if level == nil then level = INFO end

    if level == DEBUG and DEBUG_ENABLED then
        print( "[CFC Loadouts] (DEBUG): " .. msg )
    elseif level == INFO then
        print( "[CFC Loadouts] (INFO): " .. msg )
    elseif level == ERROR then
        print( "[CFC Loadouts] (ERROR): " .. msg )
    end
end

-- END LOGGING -- 


local function IsValidPlayer(ply)
    local isValidPlayer = IsValid( ply ) and ply:IsPlayer()

    return isValidPlayer
end

local function splitByNewLine(toSplit)
    return string.Split(toSplit, "\n")
end


-- FILE OPERATIONS --

local function makePath(...)
    local madePath = ""
    local args = {...}

    for i, v in ipairs( args ) do
        if i == 1 then
            madePath = v
        else
            madePath = madePath .. "/" .. v
        end
    end

    return madePath
end

-- NOTE: Creates dir in "/garrysmod/data/"
local function createDirectory(directory)
    log("Creating directory: " .. directory, DEBUG)
    file.CreateDir( directory )
end

local function existsInDataDirectory( path )
    return file.Exists( path, "DATA" )
end

local function baseLoadoutDirectoryExists()
    return existsInDataDirectory( LOADOUT_DIR )
end

local function createBaseLoadoutDirectory()
    createDirectory( LOADOUT_DIR )
end

local function getPlayerLoadoutDirectory(ply)
    local loadoutDirectory = makePath( LOADOUT_DIR, ply:SteamID64() )
    local loadoutDirectoryExists = existsInDataDirectory( loadoutDirectory )

    return loadoutDirectory, loadoutDirectoryExists
end

local function getLoadoutFilename(loadoutPath)
    return loadoutPath .. ".txt"
end

local function playerLoadoutExists(ply, loadoutName)
    local loadoutDirectory = getPlayerLoadoutDirectory( ply )
    local filename = getLoadoutFilename( loadoutName )
    local loadoutFilepath = makePath( loadoutDirectory, filename )

    log("Checking if " .. loadoutFilepath .. " exists...", DEBUG)

    return existsInDataDirectory( loadoutFilepath )
end

local function createFile(filename, text)
    file.Write( filename, text )

    timer.Simple(2, function()
        if not existsInDataDirectory( filename ) then log( "ERROR! Failed to create file " .. filename, ERROR) end
    end)
end

local function createLoadoutFile(ply, loadoutPath, weaponsString)
    local filename = getLoadoutFilename( loadoutPath )
    
    createFile( filename, weaponsString )
end

-- END FILE OPERATIONS --


local function createWeaponsString(weaponsTable)
    local weaponsString = ""

    for _, wep in pairs( weaponsTable ) do
        weaponsString = weaponsString .. wep:GetClass() .. "\n"
    end
    string.TrimRight( weaponsString, "\n" )

    return weaponsString
end

local function getPlayerWeaponsAsStringAndTable(ply)
    local weaponsString = createWeaponsString( ply:GetWeapons() )

    return weaponsString, splitByNewLine( weaponsString )
end

local function getWeaponsFromLoadoutFile(filename)
    log("Reading " .. filename .. "!", DEBUG)

    local weaponsString = file.Read( filename )
    if weaponsString == nil then return log( "ERROR! Could not read " .. filename .. "!", ERROR ) end

    return splitByNewLine( weaponsString )
end

local function listLoadout( loadout )
    log("Listing loadout " .. loadout.filename, DEBUG)

    loadout.owner:ChatPrint("LOADOUT (" .. loadout.name .. "):")

    -- TODO: Make this not a totally shit way to report a loadout
    for _, class in ipairs( loadout.weapons ) do
        loadout.owner:ChatPrint( "\t" .. class )
    end
end

local function initializeLoadout(ply, loadoutName)
    local playerLoadoutDirectory, directoryExists = getPlayerLoadoutDirectory( ply )
    if not directoryExists then createDirectory( playerLoadoutDirectory ) end
    
    local filename = makePath( playerLoadoutDirectory, getLoadoutFilename(loadoutName) )
    
    local loadout = {}
    loadout["path"] = path
    loadout["name"] = loadoutName
    loadout["filename"] = filename
    loadout["owner"] = ply

    return loadout
end

local function initializeLoadoutFromFile(ply, loadoutName)
    local loadout = initializeLoadout( ply, loadoutName )
    loadout["weapons"] = getWeaponsFromLoadoutFile( loadout.filename )

    return loadout
end


local function initializeNewLoadout(ply, loadoutName)
    local loadout = initializeLoadout( ply, loadoutName )
    local weaponsString, weaponsTable = getPlayerWeaponsAsStringAndTable( ply )

    loadout["weapons"] = weaponsTable

    createFile( loadout.filename, weaponsString )

    return loadout
end

local function setPlayerEquippedLoadout(ply, loadout)
    if not IsValidPlayer( ply ) then return end

    ply:SetNWString( "CFC_Loadout", loadout )

    ply:ChatPrint('The loadout "' .. loadout .. '" will be equipped next time you spawn in PvP!')
end

local function getPlayerEquippedLoadout(ply)
    if not IsValidPlayer( ply ) then return end

    return ply:GetNWString( "CFC_Loadout", "" )
end

local function createDefaultLoadoutForPlayer(ply)
    local playerLoadoutDirectory = getPlayerLoadoutDirectory( ply )
    local weaponsString = DEFAULT_LOADOUT

    local filePath = makePath( playerLoadoutDirectory, 'default' )

    createLoadoutFile( ply, filePath, weaponsString )

    setPlayerEquippedLoadout( ply, 'default' )
end


-- PUBLIC LOADOUT FUNCTIONS --


-- LOADOUT
--  "path": /directory/to/path
--  "name": "name_of_loadout"
--  "filename": "name_of_loadout".txt
--  "weight": weight (TODO)
--  "owner": Player
--  "weapons": {[1] m9k_something, [2] m9k_else}

CFC_Loadouts  = {}

local function IsValidLoadout(loadout)
    if #loadout.weapons == 0 then return false end
    
    if not IsValidPlayer( loadout.owner ) then return false end

    return true
end

function CFC_Loadouts:getLoadout(ply, loadoutName)
    if not IsValidPlayer( ply ) then return end

    if not playerLoadoutExists( ply, loadoutName ) then return ply:ChatPrint( 'Loadout "' .. loadoutName .. '" does not exist!' ) end

    return initializeLoadoutFromFile( ply, loadoutName )
end

function CFC_Loadouts:createLoadout(ply, loadoutName)
    if not IsValidPlayer( ply ) then return end
    
    -- You can't create a loadout when you're dead, dumbass
    if not ply:Alive() then return end

    return initializeNewLoadout( ply, loadoutName )
end

function CFC_Loadouts:equipLoadout(ply, loadout)
    if not IsValidPlayer( ply ) then return end

    if getPlayerEquippedLoadout( ply ) ~= loadout.name then setPlayerEquippedLoadout( ply, loadout.name ) end

    -- TODO: Maybe not take literally everything
    ply:StripWeapons()

    for _, weaponClass in pairs( loadout.weapons ) do
        if weaponClass then ply:Give( weaponClass ) end
    end

    ply:ChatPrint('Loadout "' .. loadout.name .. '" equipped.')

    return true
end


function CFC_Loadouts:deleteLoadout(loadout)
    file.Delete( loadout.filename )

    loadout = nil

    return true
end

-- END PUBLIC LOADOUT FUNCTIONS --


-- LOADOUT COMMAND FUNCTIONS --

local LoadoutCommandFunctions = {}

LoadoutCommandFunctions["create"] = function(ply, loadoutName)
    log("Creating loadout " .. loadoutName, DEBUG)

    if playerLoadoutExists( ply, loadoutName ) then
        local deleteCommand = LOADOUT_COMMAND_PREFIX .. LoadoutCommands['delete'] .. " " .. loadoutName
        local deleteMessage = 'You cannot overwrite a loadout! Please use the command "' .. deleteCommand .. '" before re-creating ' .. loadoutName

        ply:ChatPrint( deleteMessage )
        return
    end

    local loadout = CFC_Loadouts:createLoadout( ply, loadoutName )
    if loadout then ply:ChatPrint( 'Loadout "' .. loadoutName .. '" created.' ) end
end

LoadoutCommandFunctions["delete"] = function(ply, loadoutName)
    log("Deleting loadout " .. loadoutName, DEBUG)

    local loadout = CFC_Loadouts:getLoadout( ply, loadoutName )
    if loadout == nil then return end

    if CFC_Loadouts:deleteLoadout( loadout ) then ply:ChatPrint( 'Loadout "' .. loadoutName .. '" deleted.' ) end
end

-- I actually hate this
LoadoutCommandFunctions["list"] = function(ply, loadoutName)
    if loadoutName ~= nil then 
        local loadout = CFC_Loadouts:getLoadout( ply, loadoutName )

        if loadout then listLoadout( loadout ) end

        return
    end

    -- List all loadouts
    local loadoutDirectory, _ = getPlayerLoadoutDirectory( ply )
    local loadoutFiles, _ = file.Find( loadoutDirectory .. "/*.txt", "DATA" )

    log("Listing all loadouts for " .. ply:SteamID() .. "(" .. ply:SteamID64() .. ")", DEBUG)
    for _, filename in ipairs( loadoutFiles ) do
        loadoutName = string.Replace( filename, '.txt', '' )

        log("Getting loadout " .. loadoutName, DEBUG)

        local loadout = CFC_Loadouts:getLoadout( ply, loadoutName )

        listLoadout( loadout )
    end
end

LoadoutCommandFunctions["equip"] = function(ply, loadoutName)
    log("Equipping loadout " .. loadoutName, DEBUG)
 
    if loadoutName == nil then loadoutName = getPlayerEquippedLoadout( ply ) end

    local loadout = CFC_Loadouts:getLoadout( ply, loadoutName )
    if loadout == nil then return end

    setPlayerEquippedLoadout( ply, loadoutName )

    if not ply:GetNWBool( "CFC_PvP_Mode", false ) then return ply:ChatPrint('The loadout "' .. loadout.name .. '" will be equipped when you enter PvP!') end
end

LoadoutCommandFunctions["help"] = function(ply)
    for operation, command in pairs(LoadoutCommands) do
        local chatCommand = LOADOUT_COMMAND_PREFIX .. command
        local description = LoadoutDescriptions[operation]
        local message = string.format ('%s     %s', chatCommand, description )
        ply:ChatPrint( message )
    end
end
-- END LOADOUT COMMAND FUNCTIONS --


-- CHAT FUNCTIONS --

local function isValidLoadoutName(loadoutName)
    -- Only alnum
    return string.find( loadoutName, "[^%w]" ) == nil
end

-- Returns the type of chat command and the loadout if valid, nil if not
local function getChatCommand(chatString)
    if not string.StartWith( chatString, LOADOUT_COMMAND_PREFIX ) then return end

    local prefixRemoved = string.sub( chatString, 2 )
    local lowercaseCommandString = string.lower( prefixRemoved )

    -- A chat command that isn't just "list" needs exactly 2 words
    local commandSplitBySpaces = string.Split( lowercaseCommandString, " " )
    if table.Count( commandSplitBySpaces ) ~= 2 then
        if commandSplitBySpaces[1] == LoadoutCommands["list"] then return "list" end
        if commandSplitBySpaces[1] == LoadoutCommands["help"] then return "help" end
        return nil
    end

    local spokenCommand, loadoutName = commandSplitBySpaces[1], commandSplitBySpaces[2]

    for operation, command in pairs( LoadoutCommands ) do
        if spokenCommand == command then
            return operation, loadoutName
        end
    end
    
    log('No valid loadout command found in chat string "' .. chatString .. '"!', DEBUG)
end

-- END CHAT FUNCTIONS --


-- HOOKS --
local function checkChatForLoadoutCommand( ply, text, team )
    log("Checking if valid player...", DEBUG)
    if not IsValidPlayer( ply ) then return end

    local operation, loadoutName = getChatCommand( text )
    if operation == nil then return end

    if loadoutName and not isValidLoadoutName( loadoutName ) then 
        return ply:ChatPrint("Please use only the characters [0-9], _, and [A-Z] for your loadout names!") 
    end

    log("Found chat command " .. operation, DEBUG)

    LoadoutCommandFunctions[operation]( ply, loadoutName )
end
hook.Remove( "PlayerSay", "CFC_LoadoutManager" )
hook.Add( "PlayerSay", "CFC_LoadoutManager", checkChatForLoadoutCommand )

local function equipLoadoutOnPvpEnter(ply)
    local equipped = getPlayerEquippedLoadout( ply )
    local loadout = CFC_Loadouts:getLoadout( ply, equipped )

    log(ply:Nick() .. " entering PvP... Current loadout: " .. equipped, DEBUG)

    CFC_Loadouts:equipLoadout( ply, loadout )
end
hook.Remove( "CFC_PlayerEnterPvp", "CFC_LoadoutManager" )
hook.Add( "CFC_PlayerEnterPvp", "CFC_LoadoutManager", equipLoadoutOnPvpEnter )

local function equipLoadoutIfPvp(ply)
    if not ply:GetNWBool( "CFC_PvP_Mode", false ) then return end

    local equipped = getPlayerEquippedLoadout(ply)
    local loadout = CFC_Loadouts:getLoadout( ply, equipped )
    CFC_Loadouts:equipLoadout( ply, loadout )

    log(ply:Nick() .. " spawned in PvP... Current loadout: " .. equipped, DEBUG)
end
hook.Remove( "PlayerSpawn", "CFC_LoadoutManager" )
hook.Add( "PlayerSpawn", "CFC_LoadoutManager", equipLoadoutIfPvp )

local function giveDefaultLoadoutOnJoin(ply)
    if playerLoadoutExists( ply, 'default' ) then return setPlayerEquippedLoadout( ply, 'default' ) end

    createDefaultLoadoutForPlayer( ply )
end
hook.Remove( "PlayerInitialSpawn", "CFC_LoadoutManager" )
hook.Add( "PlayerInitialSpawn", "CFC_LoadoutManager", giveDefaultLoadoutOnJoin )


-- END HOOKS --


-- STARTUP --

if not baseLoadoutDirectoryExists() then createBaseLoadoutDirectory() end

log("Initialized.")

-- END STARTUP --
