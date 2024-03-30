if CLIENT then
    NPCMS.NPCMenu = NPCMS.NPCMenu or {}


    local chatcol1 = Color(75, 255, 0)


    function NPCMS.NPCMenu:CreateNPCMenu(panel)

        panel:ControlHelp("\nPresets:")


        self.PresetBox = vgui.Create("DComboBox", panel)
        self.PresetBox:SetHeight(25)
        self.PresetBox:Dock(TOP)
        self.PresetBox:DockMargin(10, 10, 10, 10)
        self.PresetBox.OnSelect = presetBoxChooseOption


        local buttonAddPreset = panel:Button("Save Preset")
        -- buttonAddPreset.DoClick = addPresetButton


        local buttonRemovePreset = panel:Button("Remove Preset")
        -- buttonRemovePreset.DoClick = removePresetButton


        -- net.Start("ZippyHorde_SelectPreset")
        -- net.WriteString("default")
        -- net.SendToServer()
        -- self.LastPresetChoice = "default"
        -- net.Start("ZippyHorde_GetPresets")
        -- net.SendToServer()


        local NPCSelectingEnabled = panel:CheckBox("NPC Spawnmenu Select")
        function NPCSelectingEnabled:OnChange( val )
            net.Start("NPCMS_NPCSelecting")
            net.WriteBool(val)
            net.SendToServer()
        end
        panel:ControlHelp("When enabling this, clicking the NPC icons in the spawnmenu will add the NPCs to this list, instead of spawning them.")


        panel:ControlHelp("\nNPC List:")
        self.NPC_List = vgui.Create("DListView", panel)
        self.NPC_List:SetHeight(400)
        self.NPC_List:Dock(TOP)
        self.NPC_List:DockMargin(10, 10, 10, 10)
        self.NPC_List:AddColumn("Name")
        self.NPC_List:AddColumn("Cls")
        self.NPC_List:AddColumn("MenuCls")
        self.NPC_List:AddColumn("1/X")
        
    end

    function NPCMS.NPCMenu:GetSelectedPreset()
        return self.PresetBox:GetSelected() or self.LastPresetChoice or "default"
    end


        -- Adds NPCs to the list
    function NPCMS.NPCMenu:AddNPCToList( spawnmenuclass )
        local npclist = conv.getSpawnMenuNPCs()
        local npctbl = npclist[spawnmenuclass]
        if npctbl then
            self.NPC_List:AddLine( npctbl.Name, spawnmenuclass, npctbl.Class, 1 )
        end
    end


        -- Add NPC to list from spawnmenu by player
    net.Receive("NPCMS_AddNPCToList", function()
        local spawnmenuclass = net.ReadString()
        NPCMS.NPCMenu:AddNPCToList( spawnmenuclass )
        chat.AddText(chatcol1, "NPC MAP SPAWNER: Added '"..spawnmenuclass.."' to the current preset.")
    end)



    -- local function addPresetButton()

    --     local frame = vgui.Create("DFrame")
    --     local width = 350
    --     local height = 110
    --     frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    --     frame:SetSize(width, height)
    --     frame:SetTitle("Preset Name")
    --     frame:MakePopup()

    --     local entry = vgui.Create("DTextEntry", frame)
    --     entry:SetText("a preset")

    --     local function finish()

    --         if entry:GetText() == "default" then return end

    --         net.Start("ZippyHorde_NewPreset")
    --         net.WriteString(entry:GetText())
    --         net.SendToServer()

    --         frame:Close()

    --     end

    --     -- Finish rename when we press enter:
    --     frame.OnKeyCodePressed = function( _,key )
    --         if (key == KEY_ENTER) then finish() end
    --     end

    --     local text = vgui.Create("DLabel", frame)
    --     text:SetText("New preset name:")
    --     text:Dock(TOP)

    --     local button = vgui.Create("DButton",frame)
    --     button:Dock(BOTTOM)
    --     button:SetText("Save Preset")
    --     button.DoClick = function()
    --         finish()
    --     end

    --     entry:Dock(FILL)
    --     entry:DockMargin(0,3,0,6)

    -- end


    -- local function removePresetButton()

    --     local presetName = NPCMS.NPCMenu:GetSelectedPreset()

    --     if !presetName then return end
    --     if presetName == "default" then return end


    --     local frame = Derma_Message("Remove \""..presetName.."\" permanently?", "Remove Preset", "Remove")

    --     -- Button that removes the group:
    --     local remove_button = vgui.Create("DButton",frame)
    --     remove_button:Dock(BOTTOM)
    --     remove_button:SetText("Remove")
    --     remove_button.DoClick = function()

    --         -- net.Start("ZippyHorde_RemovePreset")
    --         -- net.WriteString(presetName)
    --         -- net.SendToServer()

    --         frame:Close()

    --     end

    -- end
end




if SERVER then

    util.AddNetworkString("NPCMS_NPCSelecting")
    util.AddNetworkString("NPCMS_AddNPCToList")


        -- Enable spawn menu selecting NPCs for this player
    net.Receive("NPCMS_NPCSelecting", function(_, ply)

        if !ply:IsSuperAdmin() then return end

        local Enabled = net.ReadBool() 
        ply.NPCMS_NPCSelectingEnabled = Enabled
        ply:PrintMessage(HUD_PRINTTALK, Enabled && "NPC MAP SPAWNER: NPC spawnmenu selecting enabled." or "NPC MAP SPAWNER: NPC Spawnmenu Selecting disabled.")

    end)


        -- Select NPCs to add to the NPC list when clicking the icons in the spawnmenu
    hook.Add("PlayerSpawnNPC", "NPCMapSpawner_Selecting", function( ply, npc_type, wep )
        if ply.NPCMS_NPCSelectingEnabled then

            net.Start("NPCMS_AddNPCToList")
            net.WriteString(npc_type)
            net.Send(ply)

            return false
    
        end
    end)

end






