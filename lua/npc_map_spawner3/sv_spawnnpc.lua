-- For NPC Spawning
-- Uses the spawn menu to find stuff about NPCs


local dev = GetConVar("developer")
local NPC = FindMetaTable("NPC")


NPCMS.SpawnedNPCs = NPCMS.SpawnedNPCs or {}
NPCMS.NPCTypesSpawned = NPCMS.NPCTypesSpawned or {}
NPCMS.NPCColCache = {} -- Table of NPC collisions
NPCMS.CollisionsBeingCached = {}



    -- Saves NPC collisions and removes the NPC
function NPC:NPCMSCollCache( mySpawnmenuclass )
    NPCMS.NPCColCache[mySpawnmenuclass] = {self:OBBMins(), self:OBBMaxs()}
    if dev:GetBool() then
        PrintMessage(HUD_PRINTTALK, "NPC MAP SPAWNER: Cached "..mySpawnmenuclass.." collisions.")
    end
    self:Remove()
end


    -- Cache collisions for a specific NPC by 'spawnmenuclass'
function NPCMS:CacheCollisions( spawnmenuclass )

    local npc = ents.CreateSpawnMenuNPC(spawnmenuclass)
    if IsValid(npc) then
        npc:CallNextTick("NPCMSCollCache", spawnmenuclass)
    end

end


    -- Check if an NPC of type 'spawnmenuclass' would fit at 'pos'
    -- Returns true if it would, otherwise false
function NPCMS:DoCollCheck( spawnmenuclass, pos )
    local mins, maxs = self.NPCColCache[spawnmenuclass][1], self.NPCColCache[spawnmenuclass][2]

    local tr = util.TraceHull({
        start = pos,
        endpos = pos,
        mask = MASK_SOLID,
        mins = mins,
        maxs = maxs,
    })


    conv.overlay("Box", function()
        return {pos, mins, maxs}
    end)


    return !tr.Hit
end


    -- Get an appropriate position to spawn this NPC on
function NPCMS:GoodNPCPos( spawnmenuclass, nodepos )
    local mins = self.NPCColCache[spawnmenuclass][1]
    return nodepos+Vector(0, 0, math.abs(mins.z))
end


    -- Try spawning an NPC of type 'spawnmenuclass' at 'nodepos'
function NPCMS:SpawnNPC( spawnmenuclass, nodepos, SPAWNDATA )
    if !self.NPCColCache[spawnmenuclass] then
        -- Cache collisions first
        if !self.CollisionsBeingCached[spawnmenuclass] then
            self:CacheCollisions( spawnmenuclass )
            self.CollisionsBeingCached[spawnmenuclass] = true
        end

        -- maybe collect other data as well?

        return false -- Cancel
    end

    -- Get an ideal position for the NPC based on the node position
    local pos = self:GoodNPCPos(spawnmenuclass, nodepos)

    -- Do a collision check
    if !self:DoCollCheck( spawnmenuclass, pos ) then
        return false -- Failed, stop here
    end

    -- Spawn the NPC
    local npc = conv.createSpawnMenuNPC( spawnmenuclass, pos, nil, function( thisNPC )
        if SPAWNDATA.code && #SPAWNDATA.code > 0 then
            local gselfbefore = _G["self"]
            _G["self"] = thisNPC
            local err = RunString(SPAWNDATA.code, "ERROR!! ur dumb spawner code:", false)
            if err then PrintMessage(HUD_PRINTTALK, err) end
            _G["self"] = gselfbefore
        end
    end)

    npc.SPAWNDATA = SPAWNDATA


    if IsValid(npc) then

        self:OnNPCSpawned( npc )

        -- On remove call
        npc:CallOnRemove("NPCMapSpawnerRmv", function()
            self:OnRemoveNPC(npc)
        end)

    end

    return true

end


function NPCMS:OnNPCSpawned( npc )
    -- Add to spawned table
    table.insert(self.SpawnedNPCs, npc)

    self.NPCTypesSpawned[npc.SPAWNDATA.sv_idx] =
    self.NPCTypesSpawned[npc.SPAWNDATA.sv_idx] && self.NPCTypesSpawned[npc.SPAWNDATA.sv_idx] + 1 or 1
end


function NPCMS:OnRemoveNPC( npc )
    self.NPCTypesSpawned[npc.SPAWNDATA.sv_idx] = self.NPCTypesSpawned[npc.SPAWNDATA.sv_idx] - 1

    -- Remove from spawned table
    table.RemoveByValue(self.SpawnedNPCs, npc)
end