local UICOLOR = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
local weaponCategorised = {}
local allWeapons = {}

local window
local weaponList
local scrollDock
local panel1
local panel2
local panel3
local loadoutPreviewList
local loadoutListEditor

file.CreateDir("cfc_loadout")

hook.Add( "InitPostEntity", "Ready", function()
    net.Start( "CFC_Loadout_InitialSpawn" )
    net.SendToServer()
end )

net.Receive( "CFC_Loadout_SendRestrictions", function()
    allWeapons = list.Get( "Weapon" )
    local group = LocalPlayer():GetUserGroup()
    local weaponTable = net.ReadTable()

    for _, weapon in pairs( allWeapons ) do
        local weaponClass =  weapon.ClassName
        local weaponPerms = weaponTable[ weaponClass ]
        local isRestricted

        if istable( weaponPerms ) then
            isRestricted = table.HasValue( weaponPerms, group )
        end

        if weapon.Spawnable and isRestricted ~= true then
            weaponCategorised[ weapon.Category ] = weaponCategorised[ weapon.Category ] or {}
            table.insert( weaponCategorised[ weapon.Category ], weapon )
        end
    end
end )

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
    sheet:AddSheet( "Loadout editor", panel2, "icon16/wrench.png" )

    panel3 = vgui.Create( "DPanel", sheet )
    --panel3.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "Weapon selection", panel3, "icon16/gun.png" )

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
        local fileName = line:GetValue( 1 )
        currentSelectionWeapons = getLoadoutJsonTable( fileName )

        net.Start( "CFC_Loadout_WeaponTable" )
        net.WriteTable( currentSelectionWeapons )
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
        populateWeaponList()
    end

    loadoutListEditor = vgui.Create ( "DListView" , panel2 )
    loadoutListEditor:SetPos( ScrW() * 0.3315, ScrH() * 0.01 )
    loadoutListEditor:SetSize( ScrW() * 0.075, ScrH() * 0.4325 )
    loadoutListEditor:SetMultiSelect( false )
    loadoutListEditor:AddColumn( "Saved Loadouts" )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )

    function loadoutListEditor:DoDoubleClick( _, line )
        local fileName = line:GetValue( 1 )
        currentSelectionWeapons = getLoadoutJsonTable( fileName )
        populateWeaponList()
    end

    local loadoutEntry = vgui.Create ( "DTextEntry" , panel2 )
    loadoutEntry:SetSize( 200, 20 )
    loadoutEntry:SetPos( ( window:GetWide() - loadoutEntry:GetWide() ) / 2, 100 )

    local loadoutAddButton = vgui.Create( "DButton", panel2 )
    loadoutAddButton:SetSize( 200, 20 )
    loadoutAddButton:SetPos( ( window:GetWide() - loadoutAddButton:GetWide() ) / 2, 125 )
    loadoutAddButton:SetText( "Add loadout with current weapons" )

    loadoutAddButton.DoClick = function()
        local fileName = string.match( loadoutEntry:GetValue(), "[a-zA-Z0-9_]*" )
        if fileName == "" then
            loadoutAddButton:SetText( "Please enter a valid name." )
            timer.Simple( 1, function ()
                if IsValid( loadoutAddButton ) then
                    loadoutAddButton:SetText( "Add loadout with current weapons" )
                end
            end)
        elseif currentSelectionWeapons[1] == nil then
            loadoutAddButton:SetText( "Please add weapons to the loadout." )
            timer.Simple( 1, function ()
                if IsValid( loadoutAddButton ) then
                    loadoutAddButton:SetText( "Add loadout with current weapons" )
                end
            end)
        else
            loadoutFileCreate( fileName )
        end
    end

    local loadoutRemoveButton = vgui.Create( "DButton", panel2 )
    loadoutRemoveButton:SetSize( 200, 20 )
    loadoutRemoveButton:SetPos( ( window:GetWide() - loadoutRemoveButton:GetWide() ) / 2, 150 )
    loadoutRemoveButton:SetText( "Remove selected loadouts" )
    loadoutRemoveButton.DoClick = function()
        for k, line in pairs( loadoutListEditor.Lines ) do
            if line:IsLineSelected() then
                loadoutFileDelete( line:GetValue( 1 ) )
            end
        end
    end

    -----------------------
    -- Panel 3 panel3   ---
    -----------------------

    scrollDock = vgui.Create( "DScrollPanel", panel3 )
    scrollDock:Dock( FILL )

    local weaponCats = vgui.Create( "DListLayout", scrollDock )
    --weaponCats.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    --weaponCats:SetPadding( 0 )
    --weaponCats:Dock( FILL )
    weaponCats:SetSize( 630, 100 )

    for catName, v in SortedPairs( weaponCategorised ) do
        local X = 0
        local Y = 20

        weaponCatPanel = vgui.Create( "DCollapsibleCategory", weaponCats )
        weaponCatPanel:SetLabel( catName )
        weaponCatPanel:SetExpanded( false )
        --weaponCatPanel.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
        --weaponCats:AddSheet( catName, weaponCatPanel )

        for _, ent in SortedPairsByMemberValue( v, "PrintName" ) do

            createWeaponIcon( X, Y, ent )

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
    local weaponIcon = vgui.Create( "ContentIcon", weaponCatPanel )
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

function createWeaponIconPreview( X, Y, ent, panel )
    local weaponIcon = vgui.Create( "ContentIcon", panel )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName
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

function loadoutFileCheck( loadoutList )
    local files = file.Find( "cfc_loadout/*.json", "DATA", "dateasc" )
    loadoutList:Clear()
    for _, filename in pairs( files ) do
        local name = string.Replace( filename, ".json", "" )
        loadoutList:AddLine( name )
    end
end

function loadoutFileCreate( fileName)
    local jsonTable = util.TableToJSON( currentSelectionWeapons, true )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTable )

    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

function loadoutFileDelete( loadoutName )
    file.Delete( "cfc_loadout/" .. loadoutName .. ".json" )
    loadoutFileCheck( loadoutPreviewList )
    loadoutFileCheck( loadoutListEditor )
end

function getLoadoutJsonTable( loadoutFileName )
    local fileContent = file.Read( "cfc_loadout/" .. loadoutFileName .. ".json", "DATA" )
    return util.JSONToTable( fileContent )
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
