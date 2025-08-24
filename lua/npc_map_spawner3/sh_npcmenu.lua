local MAX_PRESET_NPCS = 125 -- How many NPCs is a preset allowed to have

if CLIENT then
    NPCMS.NPCMenu = NPCMS.NPCMenu or {}

    local chatcol1 = Color(75, 255, 0)
    local chatcol2 = Color(255, 75, 0)

        -- The NPC List menu
    function NPCMS.NPCMenu:CreateNPCMenu(panel)
        panel:ControlHelp("\nPresets:")
        self.PresetBox = vgui.Create("DComboBox", panel)
        self.PresetBox:SetHeight(25)
        self.PresetBox:Dock(TOP)
        self.PresetBox:DockMargin(10, 10, 10, 10)
        self:CallPopulatePresetBox()

        function self.PresetBox:OnSelect(a, b, presetFile)
            print(a, b, presetFile)
            if !isstring(presetFile) then return end
            
            net.Start("NPCMS_SelectPreset")
            net.WriteString(presetFile)
            net.SendToServer()
        end
        local PresetBox = self.PresetBox

        self.PresetBox:AddChoice("Empty", "Empty")
        self.PresetBox:ChooseOptionID(1)

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
        
        local buttonSavePreset = panel:Button("Save Preset")
        buttonSavePreset.DoClick = function()
            -- Save current preset if any
            local preset = NPCMS.NPCMenu:GetSelectedPreset()
            if preset && isstring(preset) && preset != "" && presetName!= "Empty" then
                self:ClearPresets(PresetBox && PresetBox:GetSelectedID())

                net.Start("NPCMS_AddPreset")
                net.WriteString(preset)
                net.SendToServer()
            else
                chat.AddText(chatcol2, "NPC MAP SPAWNER: No preset selected!")
            end
        end

        -- Refresh list
        local buttonRefresh = panel:Button("Refresh")
        function buttonRefresh:DoClick()
            net.Start("NPCMS_Refresh")
            net.SendToServer()
        end
        -- Refresh now
        net.Start("NPCMS_Refresh")
        net.SendToServer()
    end

    function NPCMS.NPCMenu:CallPopulatePresetBox()
        net.Start("NPCMS_TellServerFetchPresets")
        net.SendToServer()
    end

    net.Receive("NPCMS_SendPresetNameToCl", function()
        if !NPCMS.NPCMenu.PresetBox then return end
        local f = net.ReadString()
        local presetName = string.Replace(f, ".json", "")
        NPCMS.NPCMenu.PresetBox:AddChoice(presetName, f)
    end)

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
        local npclist = list.Get("NPC")

        if ZBaseInstalled then
            table.Merge(npclist, table.Copy(ZBaseNPCs))
        end

        local npctbl = npclist[data.menucls]

        if !npctbl then
            chat.AddText(chatcol2, "NPC MAP SPAWNER: Could not find '"..data.menucls.."', addon missing?")
            return
        end

        if self.NPC_List && self.NPC_List.AddLine then
            local line = self.NPC_List:AddLine( data.sv_idx, npctbl.Name )
            line.OnRightClick = function()

                -- NPC line options
                local options = DermaMenu()
                options:AddOption("Remove", function()

                    net.Start("NPCMS_RemoveNPC")
                    net.WriteUInt(data.sv_idx, 16)
                    net.SendToServer()

                end)
                options:AddOption("Settings", function()
                    self:OpenSettings( data )
                end)
                options:Open()
        
            end

            local tooltip = ""
            for k, v in pairs(data) do
                tooltip = tooltip..k..": "..tostring(v).."\n"
            end
            line:SetTooltip(tooltip)
            line:SetTooltipDelay(0)

            -- Sort by NPC name
            self.NPC_List:SortByColumn( 2 )
        end
    end

        -- Add NPC to list from spawnmenu by player
    net.Receive("NPCMS_AddNPCToList", function()
        if NPCMS && NPCMS.NPCMenu && NPCMS.NPCMenu.NPC_List then
            NPCMS.NPCMenu:AddNPCToList( net.ReadTable() )
        end
    end)

    net.Receive("NPCMS_ClearNPCList", function()
        if NPCMS && NPCMS.NPCMenu && NPCMS.NPCMenu.NPC_List then
            NPCMS.NPCMenu:ClearList()
        end
    end)

    function NPCMS.NPCMenu:ClearPresets( presetToSelectAfterClear )
        if self.PresetBox then
            self.PresetBox:Clear()
            self.PresetBox:AddChoice("Empty", "Empty")
        end

        timer.Simple(0.2, function()
            if self && self.PresetBox then
                self.PresetBox:ChooseOptionID(presetToSelectAfterClear or 1)
            end
        end)
    end

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

            if string.lower( entry:GetText() ) == "default" then return end
            if string.lower( entry:GetText() ) == "empty" then return end

            self:ClearPresets()

            net.Start("NPCMS_AddPreset")
            net.WriteString(entry:GetText())
            net.SendToServer()

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

    function NPCMS.NPCMenu:RemovePreset()
        local presetName = NPCMS.NPCMenu:GetSelectedPreset()
        if !presetName then return end
        if presetName == "Empty" then return end

        local frame = Derma_Query("Remove \""..presetName.."\" permanently?", "Remove Preset", "Remove", function()

            self:ClearPresets()

            net.Start("NPCMS_RemovePreset")
            net.WriteString(presetName)
            net.SendToServer()

        end, "Keep")
    end

    net.Receive("NPCMS_DoAddNPCFromSpawnMenu", function()
        local npc_type = net.ReadString()
        local wep = net.ReadString()

        -- Truly one of the code
        local shouldPutInList = false

        local npclistExists = NPCMS
        && NPCMS.NPCMenu
        && NPCMS.NPCMenu.NPC_List

        local cp = npclistExists && NPCMS.NPCMenu.NPC_List:GetParent()
        :GetParent()
        :GetParent()
        :GetParent()
        :GetParent()
        local npcmsTabId = cp && cp:GetTabID()
        local Tab = npcmsTabId && g_SpawnMenu:GetToolMenu():GetToolPanel( npcmsTabId )
        local isTabActive = Tab && Tab.PropertySheetTab:IsActive()

        shouldPutInList = isTabActive && cp && cp:GetTable().ActiveCPName == "NPC Map Spawner"

        net.Start("NPCMS_DoAddNPCFromSpawnMenu")
        net.WriteBool(shouldPutInList)
        net.WriteString(npc_type)
        net.WriteString(wep)
        net.SendToServer()
    end)
elseif SERVER then
    util.AddNetworkString("NPCMS_AddNPCToList")
    util.AddNetworkString("NPCMS_ClearNPCList")
    util.AddNetworkString("NPCMS_Refresh")
    util.AddNetworkString("NPCMS_RemoveNPC")
    util.AddNetworkString("NPCMS_AddPreset")
    util.AddNetworkString("NPCMS_RemovePreset")
    util.AddNetworkString("NPCMS_TellServerFetchPresets")
    util.AddNetworkString("NPCMS_SendPresetNameToCl")
    util.AddNetworkString("NPCMS_SelectPreset")
    util.AddNetworkString("NPCMS_ChangeNPCSettings")
    util.AddNetworkString("NPCMS_RemoveAllNPCs")
    util.AddNetworkString("NPCMS_DoAddNPCFromSpawnMenu")

    -- A table containing SPAWNDATAs
    -- Spawn data contains all info about an NPC that can be spawned (menu class, chance, etc)
    NPCMS.CurrentSpawnableNPCs = {}

        -- Add an NPC
        -- Adds to the table and broadcasts to all clients so that the NPC shows up in their lists if available
    function NPCMS:AddToCurrentSpawnableNPCs(menucls)
        -- New SPAWNDATA object
        local SPAWNDATA = {}
        SPAWNDATA.menucls = menucls
        SPAWNDATA.chance = 1
        SPAWNDATA.code = ""
        SPAWNDATA.num = 0

        -- Insert spawn data into table
        local idx = table.insert(self.CurrentSpawnableNPCs, SPAWNDATA)
        SPAWNDATA.sv_idx = idx

        -- Notify
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Added '"..SPAWNDATA.menucls.."' to the spawner.")

        -- Update lists
        net.Start("NPCMS_AddNPCToList")
        net.WriteTable(SPAWNDATA)
        net.Broadcast()
    end

    net.Receive("NPCMS_ChangeNPCSettings", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        local SPAWNDATA_NEW = net.ReadTable()

        for k, SPAWNDATA in ipairs(NPCMS.CurrentSpawnableNPCs) do
            if SPAWNDATA.sv_idx == SPAWNDATA_NEW.sv_idx then
                NPCMS.CurrentSpawnableNPCs[k] = SPAWNDATA_NEW
                MsgC(Color(0,255,0), "NPC ", k, " is now: ")
                PrintTable(SPAWNDATA_NEW)
                NPCMS:RefreshClientNPCList( ply )
                return
            end
        end
        
        conv.devPrint(Color(255,0,0), "Tried editing a NPC that did not exist.")
    end)

        -- Remove an NPC
    net.Receive("NPCMS_RemoveNPC", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        local idx = net.ReadUInt(16) -- Index for spawn data to remove

        for k, v in ipairs(NPCMS.CurrentSpawnableNPCs) do
            if v.sv_idx == idx then
                table.remove(NPCMS.CurrentSpawnableNPCs, k)
                break
            end
        end
        NPCMS:RefreshClientNPCList( ply )
    end)

    function NPCMS:RefreshPresetsToClient( ply )
        local files = file.Find("npcms_presets/*", "DATA")

        for _, f in ipairs(files) do
            net.Start("NPCMS_SendPresetNameToCl")
            net.WriteString(f)
            net.Send(ply)
        end
    end

    function NPCMS:RefreshClientNPCList( ply )

        net.Start("NPCMS_ClearNPCList")
        net.Send(ply)

        for idx, SPAWNDATA in ipairs(NPCMS.CurrentSpawnableNPCs) do
            net.Start("NPCMS_AddNPCToList")
            net.WriteTable(SPAWNDATA)
            net.Send(ply)
        end

    end

        -- Create a new preset of the current NPCs
    net.Receive("NPCMS_AddPreset", function(_, ply)
        -- Create folder with all the presets if there isnt any
        if !file.Exists("npcms_presets", "DATA") then
            file.CreateDir("npcms_presets")
        end

        -- Write new preset file
        local newPresetName = "npcms_presets/"..net.ReadString()..".json"
        file.Write(newPresetName, util.TableToJSON(NPCMS.CurrentSpawnableNPCs, true))
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Saved preset '"..newPresetName.."'")

        NPCMS:RefreshPresetsToClient(ply)
    end)

        -- Create a new preset of the current NPCs
    net.Receive("NPCMS_RemovePreset", function(_, ply)
    
        if !file.Exists("npcms_presets", "DATA") then return end

        local presetPath = "npcms_presets/"..net.ReadString()..".json"
        file.Delete(presetPath, "DATA")
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Removed preset '"..presetPath.."'")

        NPCMS:RefreshPresetsToClient(ply)

    end)

    net.Receive("NPCMS_Refresh", function(_, ply)
        if !ply:IsSuperAdmin() then return end
        NPCMS:RefreshClientNPCList( ply )
    end)

    net.Receive("NPCMS_DoAddNPCFromSpawnMenu", function(_, ply)
        if ply:IsSuperAdmin() then
            local shouldAddToMenu = net.ReadBool()
            local npc_type = net.ReadString()
            local wep = net.ReadString()

            if shouldAddToMenu == true then
                
                if #NPCMS.CurrentSpawnableNPCs >= MAX_PRESET_NPCS then
                    PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Cannot add any more NPCs to this preset! Limit reached ("..MAX_PRESET_NPCS..")")
                    return false
                end

                NPCMS:AddToCurrentSpawnableNPCs(npc_type)

            else
                ply:ConCommand("gmod_spawnnpc "..npc_type.." "..wep)
                ply.DontAddSpawnmenuNPCToNPCMS = true
                conv.devPrint("doing regular spawn")
            end
        end
    end)

        -- Select NPCs to add to the NPC list when clicking the icons in the spawnmenu
    hook.Add("PlayerSpawnNPC", "NPCMapSpawner_Selecting", function( ply, npc_type, wep )
        if !ply:IsSuperAdmin() then return end

        if !ply.DontAddSpawnmenuNPCToNPCMS then
            net.Start("NPCMS_DoAddNPCFromSpawnMenu")
            net.WriteString(npc_type)
            net.WriteString(wep)
            net.Send(ply)
            return false
        else
            ply.DontAddSpawnmenuNPCToNPCMS = false
        end
    end)

    net.Receive("NPCMS_TellServerFetchPresets", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        NPCMS:RefreshPresetsToClient(ply)
    end)

    net.Receive("NPCMS_SelectPreset", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        local str = net.ReadString()

        if str == "Empty" then
            table.Empty(NPCMS.CurrentSpawnableNPCs)
            PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: No preset active.")
            NPCMS:RefreshClientNPCList(ply)
            return
        end

        local pfile = "npcms_presets/"..str
        if file.Exists(pfile, "DATA") then
            NPCMS.CurrentSpawnableNPCs = util.JSONToTable( file.Read(pfile, "DATA") )
            PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Selected preset '"..pfile.."'")
        end

        NPCMS:RefreshClientNPCList(ply)
    end)

    net.Receive("NPCMS_RemoveAllNPCs", function()
        for k, v in ipairs(NPCMS.SpawnedNPCs) do
            if IsValid(v) then 
                v:Remove() 
            end
        end
    end)
end
