local UICOLOR = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
local allWeapons = list.Get( "Weapon" )
local weaponCategorised = {}

for _, weapon in pairs( allWeapons ) do
    if weapon.Spawnable then
        weaponCategorised[ weapon.Category ] = weaponCategorised[ weapon.Category ] or {}
        table.insert( weaponCategorised[ weapon.Category ], weapon )
    end
end

allWeapons = _

file.CreateDir("cfc_loadout")

local function openLoadout()
    -- Functions

    -- Window init
    local window = vgui.Create( "DFrame" )
    window:SetSize( 640, 480 )
    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, UICOLOR )
    end
    -- Sheet and Panels

    local sheet = vgui.Create( "DPropertySheet", window )
    sheet.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    sheet:SetPadding( 0 )
    sheet:Dock( FILL )

    local panel1 = vgui.Create( "DPanel", sheet )
    panel1.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "panel1", panel1, "icon16/cross.png" )

    local panel2 = vgui.Create( "DPanel", sheet )
    panel2.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "panel2", panel2, "icon16/tick.png" )

    local panel3 = vgui.Create( "DPanel", sheet )
    panel3.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "panel2", panel3, "icon16/tick.png" )

    -- Panel 1 panel1

    -- Panel 2 panel2

    local weaponList = vgui.Create ( "DListView" , panel2 )
    weaponList:SetPos( 5, 5)
    weaponList:SetSize( 150, 415 )
    weaponList:AddColumn( "Selected Weapons" )

    for _, line in pairs( currentSelectionWeapons ) do
        weaponList:AddLine( line )
    end

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
            weaponList:AddLine( weaponEntry:GetValue() )
            table.insert( currentSelectionWeapons, weaponEntry:GetValue() )
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
        for k, line in pairs( weaponList.Lines ) do
            if line:IsLineSelected() then
                weaponList:RemoveLine(k)
            end
        end
    end

    local presetList = vgui.Create ( "DListView" , panel2 )
    presetList:SetPos( 475, 5)
    presetList:SetSize( 150, 415 )
    presetList:AddColumn( "Saved Presets" )

    function presetFileCheck ()
        local files = file.Find( "cfc_loadout/*.json", "DATA", "dateasc" )
        presetList:Clear()
        for _, filename in pairs( files ) do
            local name = string.Replace( filename, ".json", "" )
            presetList:AddLine( name )
        end
    end

    presetFileCheck()

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
        else
            local currentWeaponsList = {}
            for _, line in pairs( weaponList:GetLines() ) do
                table.insert( currentWeaponsList, line:GetValue( 1 ) )
            end
            local jsonTable = util.TableToJSON( currentWeaponsList, true )
            file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTable )

            presetFileCheck()
        end
    end

    local presetRemoveButton = vgui.Create( "DButton", panel2 )
    presetRemoveButton:SetSize( 200, 20 )
    presetRemoveButton:SetPos( ( window:GetWide() - presetRemoveButton:GetWide() ) / 2, 150 )
    presetRemoveButton:SetText( "Remove selected presets" )
    presetRemoveButton.DoClick = function()
        for k, line in pairs( presetList.Lines ) do
            if line:IsLineSelected() then
                file.Delete( "cfc_loadout/" .. line:GetValue( 1 ) .. ".json" )
                presetList:RemoveLine( k )
            end
        end
    end
    -- Panel 3 panel3

    local scrollDock = vgui.Create( "DScrollPanel", panel3 )
    scrollDock:Dock( FILL )

    local X = 0
    local Y = 0

    for CategoryName, v in SortedPairs( weaponCategorised ) do
        for _, ent in SortedPairsByMemberValue( v, "PrintName" ) do
            local weaponIcon = vgui.Create( "ContentIcon", scrollDock )
            weaponIcon:SetPos( X, Y )
            weaponIcon:SetName( ent.PrintName or ent.ClassName )
            weaponIcon:SetSpawnName( ent.ClassName )
            weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
            weaponIcon.Clicked = false
            weaponIcon.weaponClass = ent.ClassName

            weaponIcon.DoClick = function()

            if weaponIcon.Clicked == false then
                weaponIcon.Clicked = true
                table.insert( currentSelectionWeapons, weaponIcon.weaponClass )
            else
                weaponIcon.Clicked = true
                print( weaponIcon.Clicked )
                for I, value in pairs( currentSelectionWeapons ) do
                    if value ~= weaponIcon.weaponClass then return end
                    table.remove( currentSelectionWeapons, I )
                    break
                end
            end
        end

            X = X + 120
            if X >= 600 then
                X = 0
                Y = Y + 120
            end
        end
    end

    --PrintTable( weaponCategorised )
    -- le funny button

    local button = vgui.Create( "DButton", window )
    button:SetText( "Close" )
    button.DoClick = function() window:Close() end
    button:SetSize( 100, 40 )
    button:SetPos( (window:GetWide() - button:GetWide()) / 2, window:GetTall() - button:GetTall() - 10 )
end

concommand.Add( "cfc_loadout", openLoadout )

hook.Add( "OnPlayerChat", "CFC_Loadout_OpenLoadoutCommand", function( ply, msg )
    if not string.StartWith( msg, "!loadout" ) then return end

    if ply == LocalPlayer() then
        openLoadout()
    end

    return true
end )
