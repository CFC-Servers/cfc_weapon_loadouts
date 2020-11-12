local uiColor = Color( 36, 41, 67, 255 )

local function openLoadout()
    local window = vgui.Create( "DFrame" )

    if ScrW() > 640 then
        window:SetSize( ScrW() * 0.3, ScrH() * 0.3 )
    else
        window:SetSize( 640, 480 )
    end

    window:Center()
    window:SetTitle( "CFC Loadout" )
    window:MakePopup()

    window.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, uiColor )
    end

    local weaponList = vgui.Create ( "DListView" , window )
    weaponList:SetPos( 10, 30 )
    weaponList:SetSize( 150, window:GetTall() - 40 )
    weaponList:AddColumn( "Selected Weapons" )

    function weaponList:DoDoubleClick( line )
        weaponList:RemoveLine( line )
    end

    local presetList = vgui.Create ( "DListView" , window )
    presetList:SetPos( window:GetWide() - 160, 30 )
    presetList:SetSize( 150, window:GetTall() - 40 )
    presetList:AddColumn( "Saved Presets" )

    local weaponEntry = vgui.Create ( "DTextEntry" , window )
    weaponEntry:SetPos( window:GetWide() / 2 - 100, 30 )
    weaponEntry:SetSize( 200, 20 )

    local weaponAddButton = vgui.Create( "DButton", window )
    weaponAddButton:SetPos( window:GetWide() / 2 - 100,60 )
    weaponAddButton:SetSize( 200, 20 )
    weaponAddButton:SetText( "Add weapon" )
    weaponAddButton.DoClick = function()
        if weapons.Get( weaponEntry:GetValue() ) ~= nil then
            weaponList:AddLine( weaponEntry:GetValue() )
        else
            weaponAddButton:SetText( "Please enter a valid weapon." )
            timer.Simple( 1, function ()
                if IsValid( weaponAddButton ) then
                    weaponAddButton:SetText( "Add weapon" )
                end
            end)
        end
    end

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
