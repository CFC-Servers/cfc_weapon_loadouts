-- Functions
CFCLoadouts = {}

function CFCLoadouts.createWeaponIcon( X, Y, ent )
    local weaponIcon = vgui.Create( "ContentIcon", weaponCatPanel )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName
    weaponIcon.selectionShape = vgui.Create( "DShape", weaponIcon )
    weaponIcon.selectionShape:SetType( "Rect" ) -- This is the only type it can be
    weaponIcon.selectionShape:SetPos( 3, 3 )
    weaponIcon.selectionShape:SetColor( Color( 10, 10, 10, 240 ) )
    weaponIcon.selectionShape:SetSize( 120, 120 )

    weaponIcon.DoClick = function()
        if weaponIcon.selectionShape:IsVisible() then
            weaponIcon.selectionShape:Hide()
        else
            weaponIcon.selectionShape:Show()
        end
    end

    return weaponIcon
end

function CFCLoadouts.paintButton( panel )
    panel:SetTextColor( Color( 255, 255, 255 ) )

    panel.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 255 ) )

        if self:IsDown() then
            draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 83, 227, 251, 255 ) )
        elseif self:IsHovered() then
            draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 35, 42, 69, 255 ) )
        else
            draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 42, 47, 74, 255 ) )
        end
    end
end

function CFCLoadouts.createWeaponIconPreview( X, Y, ent, panel )
    local weaponIcon = vgui.Create( "ContentIcon", panel )
    weaponIcon:SetPos( X, Y )
    weaponIcon:SetName( ent.PrintName or ent.ClassName )
    weaponIcon:SetSpawnName( ent.ClassName )
    weaponIcon:SetMaterial( "entities/" .. ent.ClassName .. ".png" )
    weaponIcon.weaponClass = ent.ClassName
end

function CFCLoadouts.loadoutFileCheck( loadoutListTable )
    for _, loadoutList in pairs( loadoutListTable ) do
        local files = file.Find( "cfc_loadout/*.json", "DATA", "dateasc" )
        loadoutList:Clear()

        for _, filename in pairs( files ) do
            local name = string.Replace( filename, ".json", "" )
            loadoutList:AddLine( name )
        end
    end
end

function CFCLoadouts.loadoutFileCreate( fileName, weaponsList )
    local jsonTableSave = util.TableToJSON( weaponsList, true )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTableSave )
end

function CFCLoadouts.loadoutFileSave( fileName, weaponsList )
    local jsonTableSave = util.TableToJSON( weaponsList, true )
    file.Write( "cfc_loadout/" .. fileName .. ".json", jsonTableSave )
end

function CFCLoadouts.getSelectedWeapons( shapeTable )
    local selectedWeapons = {}

    for weaponName, shape in pairs( shapeTable ) do
        if not shape:IsVisible() then
            table.insert( selectedWeapons, weaponName )
        end
    end

    return selectedWeapons
end

function CFCLoadouts.loadoutFileRename( originalName, newName )
    file.Rename( "cfc_loadout/" .. originalName .. ".json", "cfc_loadout/" .. newName .. ".json" )
end

function CFCLoadouts.loadoutFileDelete( loadoutName )
    file.Delete( "cfc_loadout/" .. loadoutName .. ".json" )
end

function CFCLoadouts.getLoadoutJsonTable( loadoutFileName )
    local fileContent = file.Read( "cfc_loadout/" .. loadoutFileName .. ".json", "DATA" )

    return util.JSONToTable( fileContent )
end

function CFCLoadouts.confirmationPopup( windowName, labelText, shouldTextInput, callback )
    local popupFrame = vgui.Create( "DFrame" )
    popupFrame:SetSize( 300, 150 )
    popupFrame:Center()
    popupFrame:SetTitle( windowName )
    popupFrame:SetVisible( true )
    popupFrame:SetDraggable( false )
    popupFrame:MakePopup()

    popupFrame.Paint = function( _, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, Color( 36, 41, 67, 255 ) )
        draw.RoundedBox( 8, 0, 0, w, 25, Color( 42, 47, 74, 255 ) )
    end

    local popupText = vgui.Create( "DLabel", popupFrame )
    popupText:SetText( labelText )
    local textWidth = popupText:GetTextSize()
    popupText:SetPos( ( popupFrame:GetWide() / 2 ) - ( textWidth / 2 ), 40 )
    popupText:SetSize( 300, 15 )
    local popupEntry

    if shouldTextInput then
        popupEntry = vgui.Create( "DTextEntry", popupFrame )
        popupEntry:SetPos( popupFrame:GetWide() * 0.18, 80 )
        popupEntry:SetSize( 200, 20 )
    end

    local popupButton = vgui.Create( "DButton", popupFrame )
    popupButton:SetText( "Confirm" )
    popupButton:SetPos( popupFrame:GetWide() * 0.18, 120 )
    popupButton:SetSize( 200, 20 )
    CFCLoadouts.paintButton( popupButton )

    popupButton.DoClick = function()
        if shouldTextInput then
            callback( popupEntry:GetValue() )
        else
            callback()
        end

        popupFrame:Close()
    end
end
