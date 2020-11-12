local uiColor = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
--local allLocalPresets

local function openLoadout()
    -- Window init
    local window = vgui.Create( "DFrame" )

    if ScrW() > 640 then
        window:SetSize( ScrW() * 0.5, ScrH() * 0.5 )
    else
        window:SetSize( 640, 480 )
    end

    window:Center()
    window:SetTitle( "" )
    window:SetDraggable( false )
    window:ShowCloseButton( true )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 5, 25, w - 10, 50, uiColor )
    end
    -- Sheet and Panels

    local sheet = vgui.Create( "DPropertySheet", window )
    sheet:Dock( FILL )

    local panel1 = vgui.Create( "DPanel", sheet )
    sheet:AddSheet( "panel1", panel1, "icon16/cross.png" )

    local panel2 = vgui.Create( "DPanel", sheet )
    sheet:AddSheet( "panel2", panel2, "icon16/tick.png" )

    -- Panel 1 panel1

    -- Panel 2 panel2

    local weaponList = vgui.Create ( "DListView" , panel2 )
    weaponList:SetPos( 0, window:GetTall() - 530 )
    weaponList:SetSize( 150, window:GetTall() - 50 )
    weaponList:AddColumn( "Selected Weapons" )

    for _, line in pairs( currentSelectionWeapons ) do
        weaponList:AddLine( line )
    end

    function weaponList:DoDoubleClick( line )
        weaponList:RemoveLine( line )
    end

    local presetList = vgui.Create ( "DListView" , panel2 )
    presetList:SetPos( window:GetWide() - 170, window:GetTall() - 530 )
    presetList:SetSize( 150, window:GetTall() - 50 )
    presetList:AddColumn( "Saved Presets" )

    local weaponEntry = vgui.Create ( "DTextEntry" , panel2 )
    weaponEntry:SetPos( window:GetWide() / 2 - 150, 30 )
    weaponEntry:SetSize( 200, 20 )

    local weaponAddButton = vgui.Create( "DButton", panel2 )
    weaponAddButton:SetPos( (window:GetWide() - weaponAddButton:GetWide()) / 2, window:GetTall() - weaponAddButton:GetTall() - 440 )
    weaponAddButton:SetSize( 200, 20 )
    weaponAddButton:SetText( "Add weapon" )

    weaponAddButton.DoClick = function()
        local weaponClass = ents.FindByClass( weaponEntry:GetValue() )
        if weaponClass[1] ~= nil then
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

    -- Close button

    local closeButton = vgui.Create( "DImageButton", window )
    closeButton:SetText( "X" )
    closeButton:SetImage( "icon16/cross.png" )
    closeButton:SetSize( 16, 16 )
    closeButton:SetPos( window:GetWide() - closeButton:GetWide() - 13, 45 - closeButton:GetTall() )
    closeButton.DoClick = function() window:Close() end
end

concommand.Add( "cfc_loadout", openLoadout )

hook.Add( "OnPlayerChat", "CFC_Loadout_OpenLoadoutCommand", function( ply, msg )
    if not string.StartWith( msg, "!loadout" ) then return end

    if ply == LocalPlayer() then
        openLoadout()
    end

    return true
end )
