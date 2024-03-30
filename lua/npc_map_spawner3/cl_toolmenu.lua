-- Tool/options menu

hook.Add("PopulateToolMenu", "NPCSpawner", function()

    spawnmenu.AddToolMenuOption("Utilities", "AI", "NPC Map Spawner", "NPC Map Spawner", "", "", function(panel)

        panel:CheckBox("Enabled", "npc_map_spawner_enable")
        panel:ControlHelp("Enable NPC map spawning.")

        panel:CheckBox("Show Time", "npc_map_spawner_show_time")
        panel:ControlHelp("Show how long spawn routines took on the screen. Requires 'developer' to be set to '1' or more.")

        panel:NumSlider("Position Count", "npc_map_spawner_poscount", 1, 100, 0)
        panel:ControlHelp("How many positions should we find to spawn on every spawn routine?")

        panel:NumSlider("Cooldown", "npc_map_spawner_cooldown", 0, 60, 2)
        panel:ControlHelp("How many seconds do we wait between spawn routines.")

        panel:NumSlider("Minimum Distance", "npc_map_spawner_mindist", 0, 50000, 0)
        panel:NumSlider("Maximum Distance", "npc_map_spawner_maxdist", 0, 50000, 0)
        panel:ControlHelp("Minimum and maximum distance to spawn away from players.")

        panel:CheckBox("Visibility Check", "npc_map_spawner_visibility")
        panel:ControlHelp("Do a visibility check when finding a spawn position. If the spawn position can be seen by a player, it will be discarded.")

        NPCMS.NPCMenu:CreateNPCMenu(panel)
        
    end)

end)