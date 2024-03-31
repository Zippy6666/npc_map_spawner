local red = Color(255, 0 ,0)
local green = Color(0, 255, 0)
local blue = Color(0, 0, 255)
local white = Color(255,255,255)


    -- Executes a "spawn routine"
local NextSpawnRoutine = CurTime()
function NPCMS:SpawnRoutine()
    -- Track time
    local startTime = SysTime()


    -- No nodes on the map
    if table.IsEmpty(self.NodePositions) then
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: No nodegraph found!")
        NextSpawnRoutine = CurTime()+3
        return
    end

    -- No NPCs to spawn
    if table.IsEmpty(self.CurrentSpawnableNPCs) then
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: No NPCs to spawn!")
        NextSpawnRoutine = CurTime()+3
        return
    end


    -- Get spawn positions
    local spawnpositions = self:FindDesiredSpawnPositions(self.cvar_poscount:GetInt())
    for _, v in ipairs(spawnpositions) do
        local cls = self:GetNPCClsToSpawn()
        if cls then
            self:SpawnNPC( cls, v ) -- Spawn on each spawn position
        end
    end


    -- Set next spawn routine
    NextSpawnRoutine = CurTime()+self.cvar_cooldown:GetFloat() 


    -- Show info
    if self.cvar_show_info:GetBool() then

        local dur = self.cvar_cooldown:GetFloat()+0.03
        debugoverlay.ScreenText(0.01, 0.40, "Spawn routine time: "..(SysTime() - startTime), dur, white )
        debugoverlay.ScreenText(0.01, 0.42, "Spawned NPCs: "..#self.SpawnedNPCs, dur, white )

    end
end



    -- Tick function
function NPCMS:SpawnerTick()

    if !self.cvar_enable:GetBool() then return end -- Spawner killswitch
    if NextSpawnRoutine > CurTime() then return end -- Spawner on cooldown
    if #self.SpawnedNPCs >= self.cvar_maxnpcs:GetInt() then return end -- Too many NPCs

    self:SpawnRoutine()

end
hook.Add("Tick", "NPCMapSpawner3", function() NPCMS:SpawnerTick() end)



    -- Return a table of spawn positions that are ideal for the current settings
function NPCMS:FindDesiredSpawnPositions( count )
    local positions = {}
    local _, players = player.Iterator()
    local extraData = {
        visibilityCheck = self.cvar_visibility:GetBool()
    }
    for i = 1, count do

        -- Find a spawn position
        local ply = table.Random(players)
        if ply then
            local pos = self:FindSpawnPosition( ply, self.cvar_mindist:GetInt(), self.cvar_maxdist:GetInt(), extraData )
            if pos then
                table.insert(positions, pos)
            end
        end
    
    end
    return positions
end


    -- Finds a position in the map to spawn
    -- Returns a vector or false if none was found
    -- 'ply' - The player to spawn near
    -- 'mindist' - Min distance from said player
    -- 'maxdist' - Max distance from said player
    -- 'extradata.visibilityCheck' - Dont spawn on nodes that are visible to players
local visCheckUpVec = Vector(0, 0, 40)
function NPCMS:FindSpawnPosition( ply, mindist, maxdist, extradata )

    -- Shuffle order of nodes in table
    table.Shuffle(self.NodePositions)

    -- For each node pos...
    for k, pos in pairs(self.NodePositions) do
        local dist = ply:GetPos():DistToSqr(pos)


        -- Node not in distance, skip
        if dist < mindist^2 then
            continue
        end
        if dist > maxdist^2 then
            continue
        end
    

        -- Visibility check active and pos is visible, cancel the find
        if extradata.visibilityCheck && conv.playersSeePos( pos+visCheckUpVec ) then
            debugoverlay.Sphere(pos, 40, self, red)
            return false 
        end


        -- Success, return pos
        debugoverlay.Sphere(pos, 40, self, green)
        return pos
    
    end


    return false

end


    -- Notify that the npc map spawner is on when the player logs in
NPCMS.NotifySpawnerOn_Done = false
function NPCMS:NotifySpawnerOn()
    if !self.NotifySpawnerOn_Done && self.cvar_enable:GetBool() then
        timer.Simple(5, function()
            PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: The spawner is currently active!")
        end)
        self.NotifySpawnerOn_Done = true
    end
end
hook.Add("PlayerInitialSpawn", "NotifyNPCMapSpawnerIsOn", function() NPCMS:NotifySpawnerOn() end)


