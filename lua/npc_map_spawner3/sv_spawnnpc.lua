-- For NPC Spawning
-- Uses the spawn menu to find stuff about NPCs


local dev = GetConVar("developer")
local NPC = FindMetaTable("NPC")


NPCMS.CurrentSpawnableNPCs = {}
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


function NPCMS:GetNPCClsToSpawn()
    local spawndata = table.Random(self.CurrentSpawnableNPCs)
    return spawndata.npcmenucls
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
    local wep = nil -- Default weapon for now
    ents.CreateSpawnMenuNPC( spawnmenuclass, pos, wep )



    return true

end
