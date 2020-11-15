local UICOLOR = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
local allWeapons = list.Get( "Weapon" )
local weaponCategorised = {}

local window
local weaponList
local scrollDock
local panel1
local panel2
local panel3
local presetPreviewList
local presetListEditor

for _, weapon in pairs( allWeapons ) do
    if weapon.Spawnable then
        weaponCategorised[ weapon.Category ] = weaponCategorised[ weapon.Category ] or {}
        table.insert( weaponCategorised[ weapon.Category ], weapon )
    end
end

allWeapons = _

file.CreateDir("cfc_loadout")

local function openLoadout()

    if window then window:Remove() end

    -- Window init
    window = vgui.Create( "DFrame" )
    window:SetSize( 640, 480 )
    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, UICOLOR )
    end

    -----------------------
    -- Sheet and Panels ---
    -----------------------

    local sheet = vgui.Create( "DPropertySheet", window )
    sheet.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    sheet:SetPadding( 0 )
    sheet:Dock( FILL )

    panel1 = vgui.Create( "DPanel", sheet )
    panel1.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Preset selection", panel1, "icon16/star.png" )

    panel2 = vgui.Create( "DPanel", sheet )
    panel2.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Preset editor", panel2, "icon16/wrench.png" )

    panel3 = vgui.Create( "DPanel", sheet )
    panel3.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Weapon selection", panel3, "icon16/gun.png" )

    -----------------------
    -- Panel 1 panel1   ---
    -----------------------

    presetPreviewList = vgui.Create ( "DListView" , panel1 )
    presetPreviewList:SetPos( 170, 20 )
    presetPreviewList:SetSize( 300, 300 )
    presetPreviewList:SetMultiSelect( false )
    presetPreviewList:AddColumn( "Local presets" )

    local presetSelectButton = vgui.Create( "DButton", panel1 )
    presetSelectButton:SetSize( 300, 30 )
    presetSelectButton:SetPos( ( window:GetWide() - presetSelectButton:GetWide() ) / 2, 325 )
    presetSelectButton:SetText( "Select preset" )

    -----------------------
    -- Panel 2 panel2   ---
    -----------------------

    weaponList = vgui.Create ( "DListView" , panel2 )
    weaponList:SetPos( 5, 5)
    weaponList:SetSize( 150, 415 )
    weaponList:AddColumn( "Selected Weapons" )

    populateWeaponList()

    local weaponEntry = vgui.Create ( "DTextEntry" , panel2 )
    weaponEntry:SetSize( 200, 20 )
    weaponEntry:SetPos( ( window:GetWide() - weaponEntry:GetWide() ) / 2, 5 )

    local weaponAddButton = vgui.Create( "DButton", panel2 )
    weaponAddButton:SetSize( 200, 20 )
    weaponAddButton:SetPos( ( window:GetWide() - weaponAddButton:GetWide() ) / 2, 30 )
    weaponAddButton:SetText( "Add weapon" )

    weaponAddButton.DoClick = function()
        local weaponsList = list.Get( "Weapon" )
        if weaponsList[weaponEntry:GetValue()] then
            addToSelectionWeapon ( weapon )
        else
            weaponAddButton:SetText( "Please enter a valid weapon." )
            timer.Simple( 1, function ()
                if IsValid( weaponAddButton ) then
                    weaponAddButton:SetText( "Add weapon" )
                end
            end)
        end
    end

    local weaponRemoveButton = vgui.Create( "DButton", panel2 )
    weaponRemoveButton:SetSize( 200, 20 )
    weaponRemoveButton:SetPos( ( window:GetWide() - weaponAddButton:GetWide() ) / 2, 55 )
    weaponRemoveButton:SetText( "Remove selected weapons" )
    weaponRemoveButton.DoClick = function()
        for _, line in pairs( weaponList.Lines ) do
            if line:IsLineSelected() then
                removeToSelectionWeapon( line:GetColumnText( 1 ) )
            end
        end
        print( "----" )
        PrintTable( currentSelectionWeapons )
        populateWeaponList()
    end

    presetListEditor = vgui.Create ( "DListView" , panel2 )
    presetListEditor:SetPos( 475, 5)
    presetListEditor:SetSize( 150, 415 )
    presetListEditor:AddColumn( "Saved Presets" )

    presetFileCheck( presetPreviewList )
    presetFileCheck( presetListEditor )

    local presetEntry = vgui.Create ( "DTextEntry" , panel2 )
    presetEntry:SetSize( 200, 20 )
    presetEntry:SetPos( ( window:GetWide() - presetEntry:GetWide() ) / 2, 100 )

    local presetAddButton = vgui.Create( "DButton", panel2 )
    presetAddButton:SetSize( 200, 20 )
    presetAddButton:SetPos( ( window:GetWide() - presetAddButton:GetWide() ) / 2, 125 )
    presetAddButton:SetText( "Add preset with current weapons" )

    presetAddButton.DoClick = function()
        local fileName = string.match( presetEntry:GetValue(), "[a-zA-Z0-9_]*" )
        if fileName == "" then
            presetAddButton:SetText( "Please enter a valid name." )
            timer.Simple( 1, function ()
                if IsValid( presetAddButton ) then
                    presetAddButton:SetText( "Add preset with current weapons" )
                end
            end)
        elseif currentSelectionWeapons[1] == nil then
            presetAddButton:SetText( "Please add weapons to the preset." )
            timer.Simple( 1, function ()
                if IsValid( presetAddButton ) then
                    presetAddButton:SetText( "Add preset with current weapons" )
                end
            end)
        end
        presetFileCreate( fileName )
    end

    local presetRemoveButton = vgui.Create( "DButton", panel2 )
    presetRemoveButton:SetSize( 200, 20 )
    presetRemoveButton:SetPos( ( window:GetWide() - presetRemoveButton:GetWide() ) / 2, 150 )
    presetRemoveButton:SetText( "Remove selected presets" )
    presetRemoveButton.DoClick = function()
        for k, line in pairs( presetListEditor.Lines ) do
            if line:IsLineSelected() then
                presetFileDelete( line:GetValue( 1 ) )
            end
        end
    end

    -----------------------
    -- Panel 3 panel3   ---
    -----------------------

    local weaponCats = vgui.Create( "DPropertySheet", panel3 )
    weaponCats.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    weaponCats:SetPadding( 0 )
    weaponCats:Dock( FILL )

    for test, v in SortedPairs( weaponCategorised ) do
        local X = 0
        local Y = 0

        weaponCatPanel = vgui.Create( "DPanel", weaponCats )
        weaponCatPanel.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
        weaponCats:AddSheet( test, weaponCatPanel )

        scrollDock = vgui.Create( "DScrollPanel", weaponCatPanel )
        scrollDock:Dock( FILL )

        for _, ent in SortedPairsByMemberValue( v, "PrintName" ) do

            createWeaponIcon ( X, Y, ent )

            X = X + 120
            if X >= 600 then
            X = 0
            Y = Y + 120
            end
        end
    end
end

-- Functions

function populateWeaponList()
    weaponList:Clear()
    for _, line in pairs( currentSelectionWeapons ) do
        weaponList:AddLine( line )
    end
end

function createWeaponIcon ( X, Y, ent )
    local weaponIcon = vgui.Create( "ContentIcon", scrollDock )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName

    weaponIcon.selectionShape = vgui.Create( "DShape", weaponIcon )
    weaponIcon.selectionShape:SetType( "Rect" ) -- This is the only type it can be
    weaponIcon.selectionShape:SetPos( 5, 5 )
    weaponIcon.selectionShape:SetColor( Color( 255, 0, 255, 0 ) )
    weaponIcon.selectionShape:SetSize( 120, 120 )

    if table.HasValue( currentSelectionWeapons, weaponIcon.weaponClass ) then
        weaponIcon.Selected = true
        weaponIcon.selectionShape:SetColor( Color( 255, 0, 0, 200 ) )
    else
        weaponIcon.Selected = false
    end

    weaponIcon.DoClick = function()
        if weaponIcon.Selected == false then
            weaponIcon.Selected = true
            weaponIcon.selectionShape:SetColor( Color( 255, 0, 0, 200 ) )
            addToSelectionWeapon( weaponIcon.weaponClass )
        else
            weaponIcon.Selected = false
            weaponIcon.selectionShape:SetColor( Color( 255, 0, 0, 0 ) )
            removeToSelectionWeapon ( weaponIcon.weaponClass )
        end
        populateWeaponList()
    end
end

function addToSelectionWeapon( inputWeapon )
    table.insert( currentSelectionWeapons, inputWeapon )
    populateWeaponList()
end

function removeToSelectionWeapon( inputWeapon )
    for I, value in pairs( currentSelectionWeapons ) do
        if value == inputWeapon then
            table.remove( currentSelectionWeapons, I )
        end
    end
    populateWeaponList()
end

function presetFileCheck( presetList )
    local files = file.Find( "cfc_loadout/*.json", "DATA", "dateasc" )
    presetList:Clear()
    for _, filename in pairs( files ) do
        local name = string.Replace( filename, ".json", "" )
        presetList:AddLine( name )
    end
end

function presetFileCreate( fileName)
    local jsonTable = util.TableToJSON( currentSelectionWeapons, true )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTable )

    presetFileCheck( presetPreviewList )
    presetFileCheck( presetListEditor )
end

function presetFileDelete( presetName )
    file.Delete( "cfc_loadout/" .. presetName .. ".json" )
    presetFileCheck( presetPreviewList )
    presetFileCheck( presetListEditor )
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
