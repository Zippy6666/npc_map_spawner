local NPC_Limit = 125 -- How many NPCs is a preset allowed to have


-- Should be adjusted according to NPC_Limit
-- https://wiki.facepunch.com/gmod/net.WriteUInt
local NPC_Limit_BitCount = 7



if CLIENT then
    NPCMS.NPCMenu = NPCMS.NPCMenu or {}


    local chatcol1 = Color(75, 255, 0)

        -- The NPC List menu
    function NPCMS.NPCMenu:CreateNPCMenu(panel)
        panel:ControlHelp("\nPresets:")
        self.PresetBox = vgui.Create("DComboBox", panel)
        self.PresetBox:SetHeight(25)
        self.PresetBox:Dock(TOP)
        self.PresetBox:DockMargin(10, 10, 10, 10)


        local buttonAddPreset = panel:Button("Add Preset")
        buttonAddPreset.DoClick = function()
            self:AddPreset()
        end

        local buttonRemovePreset = panel:Button("Remove Preset")
        buttonRemovePreset.DoClick = function()
            self:RemovePreset()
        end


        -- NPC List: Serves as the client 'CurrentSpawnableNPCs'
        panel:ControlHelp("\nNPC List:")
        self.NPC_List = vgui.Create("DListView", panel)
        self.NPC_List:SetHeight(400)
        self.NPC_List:Dock(TOP)
        self.NPC_List:DockMargin(10, 10, 10, 10)
        local idxcolumn = self.NPC_List:AddColumn("i")
        idxcolumn:SetFixedWidth( 30 )
        self.NPC_List:AddColumn("Name")
        self.NPC_List:SetMultiSelect(false)
        


        -- Refresh list
        local buttonRefresh = panel:Button("Refresh")
        function buttonRefresh:DoClick()
            net.Start("NPCMS_Refresh")
            net.SendToServer()
        end
        -- Refresh now
        net.Start("NPCMS_Refresh")
        net.SendToServer()
        

        local NPCSelectingEnabled = panel:CheckBox("NPC Spawnmenu Select")
        NPCSelectingEnabled:SetChecked(LocalPlayer():GetNWBool("NPCMS_NPCSelectingEnabled", false))
        function NPCSelectingEnabled:OnChange( val )
            net.Start("NPCMS_NPCSelecting")
            net.WriteBool(val)
            net.SendToServer()
        end
        panel:ControlHelp("When enabling this, clicking the NPC icons in the spawnmenu will add the NPCs to this list.")

    end

    function NPCMS.NPCMenu:GetSelectedPreset()
        return self.PresetBox:GetSelected() -- or self.LastPresetChoice or "default"
    end


    function NPCMS.NPCMenu:ClearList()
        for k in ipairs(self.NPC_List:GetLines()) do
            self.NPC_List:RemoveLine(k)
        end
    end


        -- Adds NPCs to the client's list
    function NPCMS.NPCMenu:AddNPCToList( data )
        local npclist = conv.getSpawnMenuNPCs()
        local npctbl = npclist[data.spawnmenuclass]
        if !npctbl then return end


        local line = self.NPC_List:AddLine( data.server_idx, npctbl.Name )
        line.OnRightClick = function()

            -- NPC line options
            local options = DermaMenu()
            options:AddOption("Remove", function()
                net.Start("NPCMS_RemoveNPC")
                net.WriteUInt(data.server_idx, NPC_Limit_BitCount)
                net.SendToServer()
            end)
            options:AddOption("Settings", function()

            end)
            options:Open()
    
        end

        -- Sort by NPC name
        self.NPC_List:SortByColumn( 2 )
    end



        -- Add NPC to list from spawnmenu by player
    net.Receive("NPCMS_AddNPCToList", function()
        local spawnmenuclass = net.ReadString()
        local server_idx = net.ReadUInt(NPC_Limit_BitCount)

        local data = {spawnmenuclass=spawnmenuclass, server_idx=server_idx}

        if NPCMS && NPCMS.NPCMenu && NPCMS.NPCMenu.NPC_List then
            NPCMS.NPCMenu:AddNPCToList( data )
        end
    end)


    net.Receive("NPCMS_ClearNPCList", function()
        if NPCMS && NPCMS.NPCMenu && NPCMS.NPCMenu.NPC_List then
            NPCMS.NPCMenu:ClearList()
        end
    end)


    function NPCMS.NPCMenu:AddPreset()
        local frame = vgui.Create("DFrame")
        local width = 350
        local height = 110
        frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
        frame:SetSize(width, height)
        frame:SetTitle("Preset Name")
        frame:MakePopup()

        local entry = vgui.Create("DTextEntry", frame)
        entry:SetText("a preset")

        local function finish()

            if entry:GetText() == "default" then return end

            -- net.Start("ZippyHorde_NewPreset")
            -- net.WriteString(entry:GetText())
            -- net.SendToServer()

            frame:Close()

        end

        -- Finish rename when we press enter:
        frame.OnKeyCodePressed = function( _,key )
            if (key == KEY_ENTER) then finish() end
        end

        local text = vgui.Create("DLabel", frame)
        text:SetText("New preset name:")
        text:Dock(TOP)

        local button = vgui.Create("DButton",frame)
        button:Dock(BOTTOM)
        button:SetText("Add Preset")
        button.DoClick = function()
            finish()
        end

        entry:Dock(FILL)
        entry:DockMargin(0,3,0,6)
    end


    function NPCMS:RemovePreset()
        local presetName = NPCMS.NPCMenu:GetSelectedPreset()

        if !presetName then return end
        if presetName == "default" then return end


        local frame = Derma_Message("Remove \""..presetName.."\" permanently?", "Remove Preset", "Remove")

        -- Button that removes the group:
        local remove_button = vgui.Create("DButton",frame)
        remove_button:Dock(BOTTOM)
        remove_button:SetText("Remove")
        remove_button.DoClick = function()

            -- net.Start("ZippyHorde_RemovePreset")
            -- net.WriteString(presetName)
            -- net.SendToServer()

            frame:Close()

        end
    end

end




if SERVER then

    util.AddNetworkString("NPCMS_NPCSelecting")
    util.AddNetworkString("NPCMS_AddNPCToList")
    util.AddNetworkString("NPCMS_ClearNPCList")
    util.AddNetworkString("NPCMS_Refresh")
    util.AddNetworkString("NPCMS_RemoveNPC")


    -- A table containing SPAWNDATAs
    -- Spawn data contains all info about an NPC that can be spawned (menu class, chance, etc)
    NPCMS.CurrentSpawnableNPCs = {} 


        -- Add an NPC
        -- Adds to the table and broadcasts to all clients so that the NPC shows up in their lists if available
    function NPCMS:AddToCurrentSpawnableNPCs(spawnmenuclass)

        -- New SPAWNDATA object
        local SPAWNDATA = {}
        SPAWNDATA.menucls = spawnmenuclass
        

        -- Insert spawn data into table
        local idx = table.insert(self.CurrentSpawnableNPCs, SPAWNDATA)


        -- Notify
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Added '"..SPAWNDATA.menucls.."' to the current preset.")


        -- Update lists
        net.Start("NPCMS_AddNPCToList")
        net.WriteString(SPAWNDATA.menucls)
        net.WriteUInt(idx, NPC_Limit_BitCount)
        net.Broadcast()

    end


        -- Remove an NPC
    net.Receive("NPCMS_RemoveNPC", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        local idx = net.ReadUInt(NPC_Limit_BitCount) -- Index for spawn data to remove
        local SPAWNDATA = NPCMS.CurrentSpawnableNPCs[idx] -- The spawn data to remove
        local spawnmenuclass = SPAWNDATA && SPAWNDATA.menucls

        if spawnmenuclass then
            table.remove(NPCMS.CurrentSpawnableNPCs, idx)
            PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Removed '"..spawnmenuclass.."' from the current preset.")
            NPCMS:RefreshClientNPCList( ply )
        end
    end)





    function NPCMS:RefreshClientNPCList( ply )

        net.Start("NPCMS_ClearNPCList")
        net.Send(ply)

        for idx, SPAWNDATA in ipairs(NPCMS.CurrentSpawnableNPCs) do
            net.Start("NPCMS_AddNPCToList")
            net.WriteString(SPAWNDATA.menucls)
            net.WriteUInt(idx, NPC_Limit_BitCount)
            net.Send(ply)
        end

    end


    net.Receive("NPCMS_Refresh", function(_, ply)
        if !ply:IsSuperAdmin() then return end
        NPCMS:RefreshClientNPCList( ply )
    end)


        -- Enable spawn menu selecting NPCs for this player
    net.Receive("NPCMS_NPCSelecting", function(_, ply)

        if !ply:IsSuperAdmin() then return end

        local Enabled = net.ReadBool() 
        ply:SetNWBool("NPCMS_NPCSelectingEnabled", Enabled)
        ply:PrintMessage(HUD_PRINTTALK, Enabled && "NPC MAP SPAWNER: NPC spawnmenu selecting enabled." or "NPC MAP SPAWNER: NPC Spawnmenu Selecting disabled.")

    end)


        -- Select NPCs to add to the NPC list when clicking the icons in the spawnmenu
    hook.Add("PlayerSpawnNPC", "NPCMapSpawner_Selecting", function( ply, npc_type, wep )
        if #NPCMS.CurrentSpawnableNPCs >= NPC_Limit then
            PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Cannot add any more NPCs to this preset! Limit reached ("..NPC_Limit..")")
            return false
        end

        if ply:GetNWBool("NPCMS_NPCSelectingEnabled") then

            NPCMS:AddToCurrentSpawnableNPCs(npc_type)
            return false
    
        end
    end)

end






