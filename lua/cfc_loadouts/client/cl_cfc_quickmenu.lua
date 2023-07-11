local menuOpened = false
local extendMenu = false
local parentPanel = nil

local uiScale = ScrH() / 1080


function onCMenuOpen()
    menuOpened = true

    local w = 400 * uiScale
    local h = 220 * uiScale
    parentPanel = vgui.Create( "DFrame" ) -- Using DPanel to not restrict the players natural movement when opening the context menu
    parentPanel:SetPos( ScrW() / 2 - ( w / 2 ), ScrH() - ( extendMenu and h or h / 4 ) + 5 )
    parentPanel:SetSize( w, h )
    parentPanel:MakePopup( true )
    parentPanel:SetKeyboardInputEnabled( false )
    parentPanel:SetSizable( false )
    parentPanel:SetDraggable( false )
    parentPanel:ShowCloseButton( false )
    parentPanel:SetTitle( "" )

    function parentPanel:Paint( w2, h2 )
        draw.RoundedBox( 8, 0, h - ( h / 1.29 ), w2, h2, Color( 42, 47, 74, 255 ) )
    end

    local popUpButton = vgui.Create( "DButton", parentPanel )
    popUpButton:DockMargin( w / 2.5, 0, w / 2.5, 5 )
    popUpButton:Dock( TOP )
    popUpButton:SetText( extendMenu and "v" or "^" )
    popUpButton:SetMouseInputEnabled( true )
    popUpButton:SetTextColor( Color( 255, 255, 255 ) )

    function popUpButton:Paint()
        draw.RoundedBox( 0, 0, 0, w, h, Color( 42, 47, 74, 255 ) )
    end

    function popUpButton:DoClick()
        if not IsValid( parentPanel ) then return end
        parentPanel:MoveTo( ScrW() / 2 - ( w / 2 ), ScrH() - ( extendMenu and h / 4 or h ) + 5, 0.5, 0.1 )
        self:SetText( extendMenu and "^" or "v" )
        extendMenu = not extendMenu
    end

    local loadoutPreviewList = vgui.Create( "DListView", parentPanel )
    loadoutPreviewList:Dock( FILL )
    loadoutPreviewList:SetMultiSelect( false )
    loadoutPreviewList:AddColumn( "Loadouts" )

    CFCLoadouts.loadoutFileCheck( { loadoutPreviewList } )

    local loadoutResetButton = vgui.Create( "DButton", parentPanel )
    loadoutResetButton:Dock( BOTTOM )
    loadoutResetButton:SetText( "Reset to default" )
    CFCLoadouts.paintButton( loadoutResetButton )

    loadoutResetButton.DoClick = function()
        net.Start( "CFC_Loadout_Resetweapons" )
        net.SendToServer()

        surface.PlaySound( ")weapons/357/357_reload1.wav" )
    end

    local loadoutSelectButton = vgui.Create( "DButton", parentPanel )
    loadoutSelectButton:Dock( BOTTOM )
    loadoutSelectButton:SetText( "Select Loadout" )
    CFCLoadouts.paintButton( loadoutSelectButton )

    loadoutSelectButton.DoClick = function()
        local _, line = loadoutPreviewList:GetSelectedLine()
        if line == nil then return end
        local selectedWeapons = CFCLoadouts.getLoadoutJsonTable( line:GetValue( 1 ) )
        net.Start( "CFC_Loadout_WeaponTable" )
        net.WriteTable( selectedWeapons )
        net.SendToServer()

        EmitSound( Sound( "Weapon_357.Reload" ), LocalPlayer():GetPos(), 1, CHAN_AUTO, 1, 75, 0, 100 )
    end
end

hook.Add( "ContextMenuOpened", "CFC_Loadout_CMenuOpen", onCMenuOpen )

function onCMenuClose()
    menuOpened = false
    if not IsValid( parentPanel ) then return end
    parentPanel:Close()
end

hook.Add( "ContextMenuClosed", "CFC_Loadout_CMenuOpen", onCMenuClose )

function shouldDrawElement( element )
    if menuOpened and element == "CHudWeaponSelection" then return false end
end

hook.Add( "HUDShouldDraw", "CFC_Loadout_HudDraw", shouldDrawElement, HOOK_LOW )
