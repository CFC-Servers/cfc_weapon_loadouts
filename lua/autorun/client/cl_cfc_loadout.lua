local uiColor = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
--local allLocalPresets

local function openLoadout()
    PrintTable( list.Get( "Weapon" ) )
    -- Window init
    local window = vgui.Create( "DFrame" )
    window:SetSize( 640, 480 )
    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, uiColor )
    end
    -- Sheet and Panels

    local sheet = vgui.Create( "DPropertySheet", window )
    sheet.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 41, 48, 86, 255 ) ) end
    sheet:SetPadding( 0 )
    sheet:Dock( FILL )

    local panel2 = vgui.Create( "DPanel", sheet )
    panel2.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "panel1", panel2, "icon16/cross.png" )

    local panel1 = vgui.Create( "DPanel", sheet )
    panel1.Paint = function( self, w, h ) draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end
    sheet:AddSheet( "panel2", panel1, "icon16/tick.png" )

    -- Panel 1 panel1

    -- Panel 2 panel2

    local weaponList = vgui.Create ( "DListView" , panel2 )
    weaponList:SetPos( 5, 5)
    weaponList:SetSize( 150, 415 )
    weaponList:AddColumn( "Selected Weapons" )

    for _, line in pairs( currentSelectionWeapons ) do
        weaponList:AddLine( line )
    end

    function weaponList:DoDoubleClick( line )
        weaponList:RemoveLine( line )
    end

    local presetList = vgui.Create ( "DListView" , panel2 )
    presetList:SetPos( 475, 5)
    presetList:SetSize( 150, 415 )
    presetList:AddColumn( "Saved Presets" )

    local weaponEntry = vgui.Create ( "DTextEntry" , panel2 )
    weaponEntry:SetSize( 200, 20 )
    weaponEntry:SetPos( ( window:GetWide() - weaponEntry:GetWide() ) / 2, 5 )

    local weaponAddButton = vgui.Create( "DButton", panel2 )
    weaponAddButton:SetSize( 200, 20 )
    weaponAddButton:SetPos( ( window:GetWide() - weaponAddButton:GetWide() ) / 2, 30 )
    weaponAddButton:SetText( "Add weapon" )

    weaponAddButton.DoClick = function()
        local foundWeapon = ents.FindByName( weaponEntry:GetValue() )
        if foundWeapon ~= nil then
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
    -- le funny button

    local button = vgui.Create( "DButton", window )
    button:SetText( "Close" )
    button.DoClick = function() window:Close() end
    button:SetSize( 100, 40 )
    button:SetPos( (window:GetWide() - button:GetWide()) / 2, window:GetTall() - button:GetTall() - 10 )

    -- Testing stuff, ignore

    print( "Window wide: "..window:GetWide() )
    print( "Window tall: "..window:GetTall() )
end

concommand.Add( "cfc_loadout", openLoadout )

hook.Add( "OnPlayerChat", "CFC_Loadout_OpenLoadoutCommand", function( ply, msg )
    if not string.StartWith( msg, "!loadout" ) then return end

    if ply == LocalPlayer() then
        openLoadout()
    end

    return true
end )
