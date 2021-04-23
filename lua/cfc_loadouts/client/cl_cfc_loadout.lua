--local UICOLOR = Color( 36, 41, 67, 255 )
local weaponCategorised = { }
local allWeapons = { }
file.CreateDir( "cfc_loadout" )
--WIPd
--hook.Add( "InitPostEntity", "CFC_Loadouts_ReadyClientCheck", function( )
net.Start( "CFC_Loadout_InitialSpawn" )
net.SendToServer( )

--end )
net.Receive( "CFC_Loadout_SendRestrictions", function( )
    allWeapons = list.Get( "Weapon" )
    local group = LocalPlayer( ):GetUserGroup( )
    local weaponTable = net.ReadTable( )

    for _, weapon in pairs( allWeapons ) do
        local weaponClass = weapon.ClassName
        local weaponPerms = weaponTable[ weaponClass ]
        local isRestricted

        if istable( weaponPerms ) then
            isRestricted = table.HasValue( weaponPerms, group )
        end

        if weapon.Spawnable and isRestricted ~= true then
            weaponCategorised[ weapon.Category ] = weaponCategorised[ weapon.Category ] or { }
            table.insert( weaponCategorised[ weapon.Category ], weapon )
        end
    end
end )

-- Derma stuff
function CFCLoadouts.openLoadout( )
    local window

    if window then
        window:Show( )
        window:MakePopup( )

        return
    end

    -- Window init
    window = vgui.Create( "DFrame" )
    window:SetSize( 800, 600 )
    window:Center( )
    window:SetTitle( "CFC Loadout" )
    window:SetDeleteOnClose( false )
    window:MakePopup( )

    window.Paint = function( _, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, Color( 36, 41, 67, 255 ) )
        draw.RoundedBox( 8, 0, 0, w, 25, Color( 42, 47, 74, 255 ) )
    end

    -----------------------
    -- Sheet and Panels ---
    -----------------------
    local sheet = vgui.Create( "DPropertySheet", window )
    sheet:SetPadding( 0 )
    sheet:Dock( FILL )
    local panel1 = vgui.Create( "DPanel", sheet )
    local panel1sheet = sheet:AddSheet( "Loadout selection", panel1, "icon16/star.png" )

    panel1.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 58, 103, 255 ) )
    end

    panel1sheet.Tab.Paint = function( self, w, h )
        if sheet:GetActiveTab( ) == self then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 58, 103, 255 ) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 40, 48, 93, 255 ) )
        end
    end

    local panel2 = vgui.Create( "DPanel", sheet )
    local panel2sheet = sheet:AddSheet( "Loadout editor", panel2, "icon16/gun.png" )

    panel2.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 58, 103, 255 ) )
    end

    panel2sheet.Tab.Paint = function( self, w, h )
        if sheet:GetActiveTab( ) == self then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 58, 103, 255 ) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 40, 48, 93, 255 ) )
        end
    end

    --panel3 = vgui.Create( "DPanel", sheet )
    --panel3.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    --sheet:AddSheet( "Weapon selection", panel3, "icon16/gun.png" )
    -----------------------
    -- Panel 1 panel1   ---
    -----------------------
    local weaponLoadoutPreview = vgui.Create( "DPanel", panel1 )
    weaponLoadoutPreview:SetPos( ScrW( ) * 0.0825, ScrH( ) * 0.01 )
    weaponLoadoutPreview:SetSize( ScrW( ) * 0.3225, ScrH( ) * 0.4875 )

    weaponLoadoutPreview.Paint = function( _, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 42, 47, 74, 255 ) )
    end

    local weaponLoadoutPreviewScroll = vgui.Create( "DScrollPanel", panel1 )
    weaponLoadoutPreviewScroll:SetPos( ScrW( ) * 0.0825, ScrH( ) * 0.01 )
    weaponLoadoutPreviewScroll:SetSize( ScrW( ) * 0.325, ScrH( ) * 0.5 )
    weaponLoadoutPreviewScroll:Hide( )
    local loadoutPreviewList = vgui.Create( "DListView", panel1 )
    loadoutPreviewList:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.01 )
    loadoutPreviewList:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.4325 )
    loadoutPreviewList:SetMultiSelect( false )
    loadoutPreviewList:AddColumn( "Loadouts" )

    loadoutPreviewList.OnRowSelected = function( _, _, line )
        weaponLoadoutPreview:Clear( )
        weaponLoadoutPreviewScroll:Clear( )
        local weaponTable = CFCLoadouts.getLoadoutJsonTable( line:GetValue( 1 ) )
        local panelToUse
        if weaponTable == nil then return end

        if #weaponTable > 20 then
            panelToUse = weaponLoadoutPreviewScroll
        else
            panelToUse = weaponLoadoutPreview
            weaponLoadoutPreviewScroll:Hide( )
        end

        panelToUse:Show( )
        local X = 5
        local Y = 5
        local lastWep = ""

        for _, weaponString in SortedPairsByMemberValue( weaponTable, "Category" ) do
            local weapon = allWeapons[ weaponString ]

            if weapon and lastWep ~= weapon then
                lastWep = weapon
                CFCLoadouts.createWeaponIconPreview( X, Y, weapon, panelToUse )
                X = X + 120

                if X >= 600 then
                    X = 5
                    Y = Y + 120
                end
            end
        end
    end

    local loadoutSelectButton = vgui.Create( "DButton", panel1 )
    loadoutSelectButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.445 )
    loadoutSelectButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.025 )
    loadoutSelectButton:SetText( "Select loadout" )
    CFCLoadouts.paintButton( loadoutSelectButton )

    loadoutSelectButton.DoClick = function( )
        local _, line = loadoutPreviewList:GetSelectedLine( )
        if line == nil then return end
        local selectedWeapons = CFCLoadouts.getLoadoutJsonTable( line:GetValue( 1 ) )
        net.Start( "CFC_Loadout_WeaponTable" )
        net.WriteTable( selectedWeapons )
        net.SendToServer( )
    end

    local resetSelectButton = vgui.Create( "DButton", panel1 )
    resetSelectButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.4725 )
    resetSelectButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.025 )
    resetSelectButton:SetText( "Select default loadout" )
    CFCLoadouts.paintButton( resetSelectButton )

    resetSelectButton.DoClick = function( )
        net.Start( "CFC_Loadout_Resetweapons" )
        net.SendToServer( )
    end

    -----------------------
    -- Panel 2 panel2   ---
    -----------------------
    local weaponIcons = { }
    local loadoutListEditor = vgui.Create( "DListView", panel2 )
    loadoutListEditor:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.01 )
    loadoutListEditor:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.4 )
    loadoutListEditor:SetMultiSelect( false )
    loadoutListEditor:AddColumn( "Saved Loadouts" )

    loadoutListEditor.OnRowSelected = function( _, _, line )
        local weaponTable = CFCLoadouts.getLoadoutJsonTable( line:GetValue( 1 ) )

        if weaponTable == nil then
            for weaponString in pairs( weaponIcons ) do
                local icon = weaponIcons[ weaponString ]
                icon:Hide( )
            end

            return
        end

        local placeHolder = { }

        for k, v in pairs( weaponTable ) do
            placeHolder[ v ] = k
        end

        weaponTable = placeHolder
        placeHolder = _

        for weaponString in pairs( weaponIcons ) do
            local icon = weaponIcons[ weaponString ]

            if not weaponTable[ weaponString ] then
                icon:Show( )
            else
                icon:Hide( )
            end
        end
    end

    -- table of all dlists that need to be rechecked when a file is changed
    local dlistFiles = { loadoutPreviewList, loadoutListEditor }

    CFCLoadouts.loadoutFileCheck( dlistFiles )

    function loadoutListEditor:DoDoubleClick( _, line )
        local fileName = line:GetValue( 1 )
        currentSelectionWeapons = CFCLoadouts.getLoadoutJsonTable( fileName )
    end

    local saveLoadoutButton = vgui.Create( "DButton", panel2 )
    saveLoadoutButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.4125 )
    saveLoadoutButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.02 )
    saveLoadoutButton:SetText( "Save to selected" )
    CFCLoadouts.paintButton( saveLoadoutButton )

    saveLoadoutButton.DoClick = function( )
        CFCLoadouts.confirmationPopup( "Save loadout", "Do you want to overwrite this loadout?", false, function( )
            local weaponsTable = CFCLoadouts.getSelectedWeapons( weaponIcons )
            local _, saveLine = loadoutListEditor:GetSelectedLine( )
            if saveLine == nil then return end
            CFCLoadouts.loadoutFileSave( saveLine:GetValue( 1 ), weaponsTable )
        end )
    end

    local renameLoadoutButton = vgui.Create( "DButton", panel2 )
    renameLoadoutButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.435 )
    renameLoadoutButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.02 )
    renameLoadoutButton:SetText( "Rename selected" )
    CFCLoadouts.paintButton( renameLoadoutButton )

    renameLoadoutButton.DoClick = function( )
        CFCLoadouts.confirmationPopup( "Rename loadout", "Please enter a new name for the loadout.", true, function( textEntryValue )
            local _, renameLine = loadoutListEditor:GetSelectedLine( )
            if saveLine == nil then return end
            CFCLoadouts.loadoutFileRename( renameLine:GetValue( 1 ), textEntryValue )
            CFCLoadouts.loadoutFileCheck( dlistFiles )
        end )
    end

    local newLoadoutButton = vgui.Create( "DButton", panel2 )
    newLoadoutButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.4575 )
    newLoadoutButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.02 )
    newLoadoutButton:SetText( "Create new" )
    CFCLoadouts.paintButton( newLoadoutButton )

    newLoadoutButton.DoClick = function( )
        CFCLoadouts.confirmationPopup( "New loadout", "Please enter a name for the new loadout.", true, function( textEntryValue )
            local weaponsTable = CFCLoadouts.getSelectedWeapons( weaponIcons )
            CFCLoadouts.loadoutFileCreate( textEntryValue, weaponsTable )
            CFCLoadouts.loadoutFileCheck( dlistFiles )
        end )
    end

    local deleteLoadoutButton = vgui.Create( "DButton", panel2 )
    deleteLoadoutButton:SetPos( ScrW( ) * 0.005, ScrH( ) * 0.48 )
    deleteLoadoutButton:SetSize( ScrW( ) * 0.075, ScrH( ) * 0.02 )
    deleteLoadoutButton:SetText( "Delete selected" )
    CFCLoadouts.paintButton( deleteLoadoutButton )

    deleteLoadoutButton.DoClick = function( )
        CFCLoadouts.confirmationPopup( "Delete loadout", "Are you sure you want to delete the selected loadout?", false, function( )
            for _, lineDel in pairs( loadoutListEditor.Lines ) do
                if lineDel:IsLineSelected( ) then
                    CFCLoadouts.loadoutFileDelete( lineDel:GetValue( 1 ) )
                end
            end

            CFCLoadouts.loadoutFileCheck( dlistFiles )
        end )
    end

    local scrollDock = vgui.Create( "DScrollPanel", panel2 )
    scrollDock:SetPos( ScrW( ) * 0.0825, ScrH( ) * 0.01 )
    scrollDock:SetSize( ScrW( ) * 0.325, ScrH( ) * 0.49 )
    local weaponCats = vgui.Create( "DListLayout", scrollDock )
    weaponCats:SetSize( ScrW( ) * 0.317, ScrH( ) * 0.4875 )

    for catName, v in SortedPairs( weaponCategorised ) do
        local X = 0
        local Y = 20
        weaponCatPanel = vgui.Create( "DCollapsibleCategory", weaponCats )
        weaponCatPanel:SetLabel( catName )
        weaponCatPanel:SetExpanded( false )

        weaponCatPanel.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 36, 41, 67, 255 ) )

            if self:IsHovered( ) then
                draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 35, 42, 69, 255 ) )
            else
                draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 42, 47, 74, 255 ) )
            end

            draw.RoundedBox( 0, 1, 1, w - 2, 18, Color( 52, 57, 84, 255 ) )
        end

        for _, ent in SortedPairsByMemberValue( v, "PrintName" ) do
            weaponIcons[ ent.ClassName ] = CFCLoadouts.createWeaponIcon( X, Y, ent ).selectionShape
            X = X + 120

            if X >= 600 then
                X = 0
                Y = Y + 120
            end
        end
    end
end

-- Console / Chat trigger
concommand.Add( "cfc_loadout", CFCLoadouts.openLoadout )

hook.Add( "OnPlayerChat", "CFC_Loadout_OpenLoadoutCommand", function( ply, msg )
    if not string.StartWith( msg, "!loadout" ) then return end

    if ply == LocalPlayer( ) then
        CFCLoadouts.openLoadout( )
    end

    return true
end )