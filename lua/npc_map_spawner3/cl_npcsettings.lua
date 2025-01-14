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
    local width = ScrW()*0.75
    local height = ScrH()*0.75
    self.SettingsFrame = vgui.Create("DFrame")
    self.SettingsFrame:SetSize(width, height)
    self.SettingsFrame:SetTitle("NPC Settings")
    self.SettingsFrame:Center()
    self.SettingsFrame:MakePopup()
    self.SettingsFrame.OnKeyCodePressed = function( _, key )
        if key == KEY_ENTER then
            self:SaveSettings(newsettings)
        end
    end

    -- Panel shit
    local panelmargins = 3
    local panels = {}
    for i = 1, numPanels do
        local panel = vgui.Create("DPanel", self.SettingsFrame)
        panel:SetWidth(width/numPanels - panelmargins*2 - 2)
        panel:DockMargin(panelmargins,panelmargins,panelmargins,panelmargins)
        panel:Dock(LEFT)
        panel:SetBackgroundColor(Color(100, 100, 100))
        table.insert(panels, panel)
    end
    local pnl1, pnl2, pnl3 = panels[1], panels[2], panels[3]

    -- Chance
    local chancenum = self:CreateVGUITitled("DNumberWang", pnl1, "Chance 1/X")
    chancenum:SetValue(npc_reported_cur_settings.chance or 1)
    chancenum.OnValueChanged = function( _, value )
        newsettings.chance = value
    end

    -- How many NPCs
    local npcnum = self:CreateVGUITitled("DNumberWang", pnl1, "Max Spawned, 0 = No limit.")
    npcnum:SetValue(npc_reported_cur_settings.num or 0)
    npcnum.OnValueChanged = function( _, value )
        newsettings.num = value
    end

    -- Coding panel
    self.CodeEntry = self:CreateVGUITitled("DTextEntry", pnl2, "LUA to execute on spawn, the NPC is 'self'.")
    self.CodeEntry:SetHeight(height*0.75)
    self.CodeEntry:SetMultiline(true)
    self.CodeEntry:SetFont("TargetIDSmall")
    self.CodeEntry:SetTextColor(Color(180, 180, 160))
    self.CodeEntry:SetTabbingDisabled( true )
    self.CodeEntry:SetPlaceholderText("self:Give('weapon_pistol')")
    self.CodeEntry:SetText(npc_reported_cur_settings.code or "")


    -- Save button
    local savebutton = self:CreateVGUITitled("DButton", pnl3, "Save the settings.", BOTTOM)
    savebutton:SetText("Save")
    savebutton.DoClick = function()
        self:SaveSettings(newsettings)
    end
end


function NPCMS.NPCMenu:SaveSettings( newsettings )
    -- Save code
    newsettings.code = self.CodeEntry:GetText()

    -- Send to server
    net.Start("NPCMS_ChangeNPCSettings")
    net.WriteTable(newsettings)
    net.SendToServer()

    -- Close
    self.SettingsFrame:Close()
end