local uiColor = Color( 36, 41, 67, 255 )

local currentSelectionWeapons = {}
--local allLocalPresets

local function openLoadout()
    -- Window init
    PrintTable( currentSelectionWeapons )
    local window = vgui.Create( "DFrame" )

    if ScrW() > 640 then
        window:SetSize( ScrW() * 0.5, ScrH() * 0.5 )
    else
        window:SetSize( 640, 480 )
    end

    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, uiColor )
    end
    -- Sheet and Panels

    local sheet = vgui.Create( "DPropertySheet", window )
    sheet.Paint = function( self, w, h )  draw.RoundedBox( 4, 0, 0, w, h, Color( 50, 58, 103, 255 ) ) end 
    sheet:Dock( FILL )

    local panel1 = vgui.Create( "DPanel", sheet )
    panel1.Paint = function( self, w, h ) end 
    sheet:AddSheet( "test", panel1, "icon16/cross.png" )

    local panel2 = vgui.Create( "DPanel", sheet )
    panel2.Paint = function( self, w, h )  end 
    sheet:AddSheet( "test 2", panel2, "icon16/tick.png" )

    -- Panel 1 panel1

    -- Panel 2 panel2

    local weaponList = vgui.Create ( "DListView" , panel2 )
    weaponList:SetPos( 20, window:GetTall() - 470 )
    weaponList:SetSize( 150, window:GetTall() - 40 )
    weaponList:AddColumn( "Selected Weapons" )

    for _, line in pairs( currentSelectionWeapons ) do
        weaponList:AddLine( line )
    end

    function weaponList:DoDoubleClick( line )
        weaponList:RemoveLine( line )
    end

    local presetList = vgui.Create ( "DListView" , panel2 )
    presetList:SetPos( window:GetWide() - 160, 40 )
    presetList:SetSize( 150, window:GetTall() - 40 )
    presetList:AddColumn( "Saved Presets" )

    local weaponEntry = vgui.Create ( "DTextEntry" , panel2 )
    weaponEntry:SetPos( window:GetWide() / 2 - 100, 30 )
    weaponEntry:SetSize( 200, 20 )

    local weaponAddButton = vgui.Create( "DButton", panel2 )
    weaponAddButton:SetPos( window:GetWide() / 2 - 100,60 )
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
