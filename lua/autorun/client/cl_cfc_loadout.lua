local UICOLOR = Color( 36, 41, 67, 255 )

local weaponCategorised = {}
local allWeapons = {}

local window
local scrollDock
local panel1
local panel2
local loadoutPreviewList
local loadoutListEditor

file.CreateDir("cfc_loadout")

hook.Add( "InitPostEntity", "Ready", function()
    net.Start( "CFC_Loadout_InitialSpawn" )
    net.SendToServer()
end )

--net.Receive( "CFC_Loadout_SendRestrictions", function()
    allWeapons = list.Get( "Weapon" )
    -- local group = LocalPlayer():GetUserGroup()
    --local weaponTable = net.ReadTable()

    for _, weapon in pairs( allWeapons ) do
        -- local weaponClass =  weapon.ClassName
        -- local weaponPerms = weaponTable[ weaponClass ]
        -- local isRestricted

        -- if istable( weaponPerms ) then
        --     isRestricted = table.HasValue( weaponPerms, group )
        -- end

        if weapon.Spawnable and isRestricted ~= true then
            weaponCategorised[ weapon.Category ] = weaponCategorised[ weapon.Category ] or {}
            table.insert( weaponCategorised[ weapon.Category ], weapon )
        end
    end
--end )

-- Functions

local function createWeaponIcon ( X, Y, ent )
    local weaponIcon = vgui.Create( "ContentIcon", weaponCatPanel )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName

    weaponIcon.selectionShape = vgui.Create( "DShape", weaponIcon )
    weaponIcon.selectionShape:SetType( "Rect" ) -- This is the only type it can be
    weaponIcon.selectionShape:SetPos( 5, 5 )
    weaponIcon.selectionShape:SetColor( Color( 255, 0, 255, 200 ) )
    weaponIcon.selectionShape:SetSize( 120, 120 )
    weaponIcon.selectionShape:Hide()
    weaponIcon.DoClick = function()
        if weaponIcon.selectionShape:IsVisible() then
            weaponIcon.selectionShape:Hide()
        else
            weaponIcon.selectionShape:Show()
        end
    end

    return weaponIcon
end

local function createWeaponIconPreview( X, Y, ent, panel )
    local weaponIcon = vgui.Create( "ContentIcon", panel )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName
end

local function loadoutFileCheck( loadoutList )
    local files = file.Find( "cfc_loadout/*.json", "DATA", "dateasc" )
    loadoutList:Clear()
    for _, filename in pairs( files ) do
        local name = string.Replace( filename, ".json", "" )
        loadoutList:AddLine( name )
    end
end

local function loadoutFileCreate( fileName )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTable )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

local function loadoutFileSave( fileName, weaponsList )
    local jsonTableSave = util.TableToJSON( weaponsList, true )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTableSave )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

local function getSelectedWeapons( shapeTable )
    local selectedWeapons = {}
    for weaponName, shape in pairs( shapeTable ) do
        if shape:IsVisible() then
            table.insert( selectedWeapons, weaponName )
        end
    end
    return selectedWeapons
end

local function loadoutFileRename( originalName, newName )
    file.Rename( "cfc_loadout/" .. originalName .. ".json", "cfc_loadout/" .. newName .. ".json" )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

local function loadoutFileDelete( loadoutName )
    file.Delete( "cfc_loadout/" .. loadoutName .. ".json" )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

local function getLoadoutJsonTable( loadoutFileName )
    local fileContent = file.Read( "cfc_loadout/" .. loadoutFileName .. ".json", "DATA" )
    return util.JSONToTable( fileContent )
end

local function confirmationPopup( windowName, labelText, shouldTextInput, callback )
    local popupFrame = vgui.Create( "DFrame" )
    popupFrame:SetSize( 300, 150 )
    popupFrame:Center()
    popupFrame:SetTitle( windowName )
    popupFrame:SetVisible( true )
    popupFrame:SetDraggable( false )
    popupFrame:MakePopup()

    local popupText = vgui.Create( "DLabel", popupFrame )
    popupText:SetPos( popupFrame:GetWide() / ( #labelText * 0.15 ), 40 )
    popupText:SetSize( 300, 10 )
    popupText:SetText( labelText )

    local popupEntry

    if shouldTextInput then
        popupEntry = vgui.Create( "DTextEntry", popupFrame )
        popupEntry:SetPos( popupFrame:GetWide() * 0.18, 80 )
        popupEntry:SetSize( 200, 20 )
    end

    local popupButton = vgui.Create( "DButton", popupFrame )
    popupButton:SetText( "Confirm" )
    popupButton:SetPos (popupFrame:GetWide() * 0.18, 120 )
    popupButton:SetSize( 200, 20 )

    popupButton.DoClick = function()
        if shouldTextInput then
            callback( popupEntry:GetValue() )
        else
            callback()
        end
        popupFrame:Close()
    end
end

-- Derma stuff

local function openLoadout()
    -- Window init
    window = vgui.Create( "DFrame" )
    window:SetSize( 800, 600 )
    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:SetDeleteOnClose( false )
    window:MakePopup()

    -- window.Paint = function( self, w, h )
    --     draw.RoundedBox( 8, 0, 0, w, h, UICOLOR )
    -- end

    -----------------------
    -- Sheet and Panels ---
    -----------------------

    local sheet = vgui.Create( "DPropertySheet", window )
    --sheet.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    sheet:SetPadding( 0 )
    sheet:Dock( FILL )

    panel1 = vgui.Create( "DPanel", sheet )
    --panel1.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Loadout selection", panel1, "icon16/star.png" )

    panel2 = vgui.Create( "DPanel", sheet )
    --panel2.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Loadout editor", panel2, "icon16/gun.png" )

    --panel3 = vgui.Create( "DPanel", sheet )
    --panel3.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    --sheet:AddSheet( "Weapon selection", panel3, "icon16/gun.png" )

    -----------------------
    -- Panel 1 panel1   ---
    -----------------------

    local weaponLoadoutPreview = vgui.Create( "DPanel", panel1 )
    weaponLoadoutPreview:SetPos( ScrW() * 0.0825, ScrH() * 0.01 )
    weaponLoadoutPreview:SetSize( ScrW() * 0.3225, ScrH() * 0.4875 )

    local weaponLoadoutPreviewScroll = vgui.Create( "DScrollPanel", panel1 )
    weaponLoadoutPreviewScroll:SetPos( ScrW() * 0.0825, ScrH() * 0.01 )
    weaponLoadoutPreviewScroll:SetSize( ScrW() * 0.325, ScrH() * 0.5 )
    weaponLoadoutPreviewScroll:Hide()

    loadoutPreviewList = vgui.Create ( "DListView" , panel1 )
    loadoutPreviewList:SetPos( ScrW() * 0.005, ScrH() * 0.01 )
    loadoutPreviewList:SetSize( ScrW() * 0.075, ScrH() * 0.4325 )
    loadoutPreviewList:SetMultiSelect( false )
    loadoutPreviewList:AddColumn( "Loadouts" )
    loadoutPreviewList.OnRowSelected = function( _, _, line )
        weaponLoadoutPreview:Clear()
        weaponLoadoutPreviewScroll:Clear()

        local weaponTable = getLoadoutJsonTable( line:GetValue( 1 ) )
        local panelToUse

        if weaponTable == nil then return end

        if #weaponTable > 20 then
            panelToUse = weaponLoadoutPreviewScroll
        else
            panelToUse = weaponLoadoutPreview
            weaponLoadoutPreviewScroll:Hide()
        end
        panelToUse:Show()

        local X = 5
        local Y = 5
        local lastWep = ""
        for _, weaponString in SortedPairsByMemberValue( weaponTable, "Category" ) do
                local weapon = allWeapons[weaponString]
                if weapon and lastWep ~= weapon then
                    lastWep = weapon
                    createWeaponIconPreview( X, Y, weapon, panelToUse )

                    X = X + 120
                    if X >= 600 then
                        X = 5
                        Y = Y + 120
                    end
                end
        end
    end

    local loadoutSelectButton = vgui.Create( "DButton", panel1 )
    loadoutSelectButton:SetPos( ScrW() * 0.005, ScrH() * 0.445 )
    loadoutSelectButton:SetSize( ScrW() * 0.075, ScrH() * 0.025 )
    loadoutSelectButton:SetText( "Select loadout" )
    loadoutSelectButton.DoClick = function()
        local _, line = loadoutPreviewList:GetSelectedLine()
        local selectedWeapons = getLoadoutJsonTable( line:GetValue( 1 ) )

        net.Start( "CFC_Loadout_WeaponTable" )
        net.WriteTable( selectedWeapons )
        net.SendToServer()
    end

    local resetSelectButton = vgui.Create( "DButton", panel1 )
    resetSelectButton:SetPos( ScrW() * 0.005, ScrH() * 0.4725 )
    resetSelectButton:SetSize( ScrW() * 0.075, ScrH() * 0.025 )
    resetSelectButton:SetText( "Select default loadout" )
    resetSelectButton.DoClick = function()
        net.Start( "CFC_Loadout_Resetweapons" )
        net.SendToServer()
    end

    -----------------------
    -- Panel 2 panel2   ---
    -----------------------
    local weaponIcons = {}

    loadoutListEditor = vgui.Create ( "DListView" , panel2 )
    loadoutListEditor:SetPos( ScrW() * 0.005, ScrH() * 0.01 )
    loadoutListEditor:SetSize( ScrW() * 0.075, ScrH() * 0.4 )
    loadoutListEditor:SetMultiSelect( false )
    loadoutListEditor:AddColumn( "Saved Loadouts" )
    loadoutListEditor.OnRowSelected = function( _, _, line )
        local weaponTable = getLoadoutJsonTable( line:GetValue( 1 ) )

        if weaponTable == nil then
            for weaponString in pairs( weaponIcons ) do
                local icon = weaponIcons[weaponString]
                icon:Hide()
            end
        return
        end

        local placeHolder = {}

        for k,v in pairs( weaponTable ) do
            placeHolder[v] = k
        end

        weaponTable = placeHolder
        placeHolder = _

        for weaponString in pairs( weaponIcons ) do
            local icon = weaponIcons[weaponString]
            if weaponTable[weaponString] then
                icon:Show()
            else
                icon:Hide()
            end
        end
    end

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )

    function loadoutListEditor:DoDoubleClick( _, line )
        local fileName = line:GetValue( 1 )
        currentSelectionWeapons = getLoadoutJsonTable( fileName )
    end

    local saveLoadoutButton = vgui.Create( "DButton", panel2 )
    saveLoadoutButton:SetPos( ScrW() * 0.005, ScrH() * 0.4125 )
    saveLoadoutButton:SetSize( ScrW() * 0.075, ScrH() * 0.02 )
    saveLoadoutButton:SetText( "Save to selected" )
    saveLoadoutButton.DoClick = function()
        confirmationPopup( "Save loadout", "Do you want to overwrite this loadout?", false, function()
            local weaponsTable = getSelectedWeapons( weaponIcons )
            local _, saveLine = loadoutListEditor:GetSelectedLine()
            loadoutFileSave( saveLine:GetValue( 1 ), weaponsTable )
        end)
    end

    local renameLoadoutButton = vgui.Create( "DButton", panel2 )
    renameLoadoutButton:SetPos( ScrW() * 0.005, ScrH() * 0.435 )
    renameLoadoutButton:SetSize( ScrW() * 0.075, ScrH() * 0.02 )
    renameLoadoutButton:SetText( "Rename selected" )
    renameLoadoutButton.DoClick = function()
        confirmationPopup( "Rename loadout", "Please enter a name.", true, function( textEntryValue )
            local _, renameLine = loadoutListEditor:GetSelectedLine()
            loadoutFileRename( renameLine:GetValue( 1 ), textEntryValue )
        end)
    end

    local newLoadoutButton = vgui.Create( "DButton", panel2 )
    newLoadoutButton:SetPos( ScrW() * 0.005, ScrH() * 0.4575 )
    newLoadoutButton:SetSize( ScrW() * 0.075, ScrH() * 0.02 )
    newLoadoutButton:SetText( "Create new" )
    newLoadoutButton.DoClick = function()
        confirmationPopup(  "New loadout", "Please enter a name.", true, function( textEntryValue )
            loadoutFileCreate( textEntryValue )
        end)
    end

    local deleteLoadoutButton = vgui.Create( "DButton", panel2 )
    deleteLoadoutButton:SetPos( ScrW() * 0.005, ScrH() * 0.48 )
    deleteLoadoutButton:SetSize( ScrW() * 0.075, ScrH() * 0.02 )
    deleteLoadoutButton:SetText( "Delete selected" )
    deleteLoadoutButton.DoClick = function()
        confirmationPopup(  "Delete loadout", "Are you sure you want to delete the selected loadouts?", false, function()
            for k, lineDel in pairs( loadoutListEditor.Lines ) do
                if lineDel:IsLineSelected() then
                    loadoutFileDelete( lineDel:GetValue( 1 ) )
                end
            end
        end)
    end

    scrollDock = vgui.Create( "DScrollPanel", panel2 )
    scrollDock:SetPos( ScrW() * 0.0825, ScrH() * 0.01 )
    scrollDock:SetSize( ScrW() * 0.325, ScrH() * 0.49 )

    local weaponCats = vgui.Create( "DListLayout", scrollDock )
    --weaponCats.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    weaponCats:SetSize( ScrW() * 0.315, ScrH() * 0.4875 )

    for catName, v in SortedPairs( weaponCategorised ) do
        local X = 0
        local Y = 20

        weaponCatPanel = vgui.Create( "DCollapsibleCategory", weaponCats )
        weaponCatPanel:SetLabel( catName )
        weaponCatPanel:SetExpanded( false )
        --weaponCatPanel.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end

        for _, ent in SortedPairsByMemberValue( v, "PrintName" ) do
            weaponIcons[ent.ClassName] = createWeaponIcon( X, Y, ent ).selectionShape
            X = X + 120
        if X >= 600 then
            X = 0
            Y = Y + 120
            end
        end
    end
end

-- Console / Chat trigger

concommand.Add( "cfc_loadout", openLoadout )

hook.Add( "OnPlayerChat", "CFC_Loadout_OpenLoadoutCommand", function( ply, msg )
    if not string.StartWith( msg, "!loadout" ) then return end

    if ply == LocalPlayer() then
        openLoadout()
    end

    return true
end )
