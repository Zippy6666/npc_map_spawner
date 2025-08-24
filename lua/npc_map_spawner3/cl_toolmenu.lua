-- Tool/options menu
hook.Add("PopulateToolMenu", "NPCMS3", function()
    spawnmenu.AddToolMenuOption("Utilities", "AI", "NPC Map Spawner", "NPC Map Spawner", "", "", function(panel)
        local buttonremoveall = panel:Button("Clear Spawned NPCs")
        function buttonremoveall:DoClick()
            net.Start("NPCMS_RemoveAllNPCs")
            net.SendToServer()
        end
        
        NPCMS.NPCMenu:CreateNPCMenu(panel)

        panel:CheckBox("Enabled", "npc_map_spawner_enable")
        panel:ControlHelp("Enable NPC map spawning.")

        panel:CheckBox("Show Info", "npc_map_spawner_show_info")
        panel:ControlHelp("Show spawn routine info on the screen. Requires 'developer' to be set to '1' or more.")

        panel:NumSlider("Desired NPCs", "npc_map_spawner_maxnpcs", 1, 1000, 0)
        panel:ControlHelp("If the number of NPCs spawned by the spawner is more than this, it won't try spawning any more.")

        panel:NumSlider("Spawn Attempts", "npc_map_spawner_poscount", 1, 100, 0)
        panel:ControlHelp("How many spawns should it try to do each routine?")

        panel:NumSlider("Cooldown", "npc_map_spawner_cooldown", 0, 60, 2)
        panel:ControlHelp("How many seconds do we wait between spawn routines.")

        panel:NumSlider("Minimum Distance", "npc_map_spawner_mindist", 0, 50000, 0)
        panel:NumSlider("Maximum Distance", "npc_map_spawner_maxdist", 0, 50000, 0)
        panel:ControlHelp("Minimum and maximum distance to spawn away from players.")

        panel:CheckBox("Visibility Check", "npc_map_spawner_visibility")
        panel:ControlHelp("Do a visibility check when finding a spawn position. If the spawn position can be seen by a player, it will be discarded.")

        local buttonreset = panel:Button("Reset Settings")
        function buttonreset:DoClick()
            net.Start("NPCMS_ResetSettings")
            net.SendToServer()
        end
    end)
end)
