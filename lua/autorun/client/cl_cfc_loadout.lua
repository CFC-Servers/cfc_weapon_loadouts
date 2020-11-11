local uiColor = Color( 36, 41, 67, 255 )

local function openLoadout()
    local window = vgui.Create( "DFrame" )

    if ScrW() > 640 then
        window:SetSize( ScrW() * 0.75, ScrH() * 0.75 )
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
    weaponList:SetSize( 200, window:GetTall() - 40 )
    weaponList:AddColumn( "Selected Weapons" )

    local weaponEntry = vgui.Create ( "DTextEntry" , window )
    weaponEntry:SetPos( 215, 30 )
    weaponEntry:SetSize( 200, 20 )
    

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