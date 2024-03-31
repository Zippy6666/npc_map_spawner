-- For NPC Spawning
-- Uses the spawn menu to find stuff about NPCs


local dev = GetConVar("developer")
local NPC = FindMetaTable("NPC")


NPCMS.SpawnedNPCs = {}
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


    -- Decide which NPC we should spawn
    -- Return npc class in spawn menu
function NPCMS:GetNPCClsToSpawn()
    local SPAWNDATA = table.Random(self.CurrentSpawnableNPCs)
    return SPAWNDATA.menucls
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
    return nodepos
end


    -- Try spawning an NPC of type 'spawnmenuclass' at 'nodepos'
function NPCMS:SpawnNPC( spawnmenuclass, nodepos )

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
    local npc = ents.CreateSpawnMenuNPC( spawnmenuclass, pos )
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
end


function NPCMS:OnRemoveNPC( npc )
    -- Remove from spawned table
    table.RemoveByValue(self.SpawnedNPCs, npc)
end