NPCMS.NPCMenu = NPCMS.NPCMenu or {} -- Do this wherever this object is used


function NPCMS.NPCMenu:CreateVGUITitled( vg, parent, title, optionalDock )
    local label = vgui.Create("DLabel", parent)
    label:SetText(title)
    label:Dock(optionalDock or TOP)
    label:DockMargin(3, 0, 0, 0)

    local dermathing = vgui.Create(vg, parent)
    dermathing:Dock(optionalDock or TOP)
    dermathing:DockMargin(3, 0, 3, 3)

    return dermathing
end


local numPanels = 3
function NPCMS.NPCMenu:OpenSettings( npc_reported_cur_settings )
    -- New settings to apply
    local newsettings = table.Copy(npc_reported_cur_settings)

    -- Base frame
    local width = 750
    local frame = vgui.Create("DFrame")
    frame:SetSize(width, 400)
    frame:SetTitle("NPC Settings")
    frame:Center()
    frame:MakePopup()

    -- Panel shit
    local panelmargins = 3
    local panels = {}
    for i = 1, numPanels do
        local panel = vgui.Create("DPanel", frame)
        panel:SetWidth(width/numPanels - panelmargins*2 - 2)
        panel:DockMargin(panelmargins,panelmargins,panelmargins,panelmargins)
        panel:Dock(LEFT)
        panel:SetBackgroundColor(Color(100, 100, 100))
        table.insert(panels, panel)
    end
    local pnl1, pnl2, pnl3 = panels[1], panels[2], panels[3]

    -- Chance
    local chancenum = self:CreateVGUITitled("DNumberWang", pnl1, "Chance 1/X")
    chancenum:SetValue(npc_reported_cur_settings.chance)
    chancenum.OnValueChanged = function( _, value )
        newsettings.chance = value
    end

    -- Save button
    local savebutton = self:CreateVGUITitled("DButton", pnl3, "Save the settings.", BOTTOM)
    savebutton:SetText("Save")
    savebutton.DoClick = function()
        net.Start("NPCMS_ChangeNPCSettings")
        net.WriteTable(newsettings)
        net.SendToServer()
        frame:Close()
    end
end