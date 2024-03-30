-- NPCs are identified by their spawn menu class

local dev = GetConVar("developer")


NPCMS.NPCColCache = {} -- Table of NPC collisions
NPCMS.CollisionsBeingCached = {}


function NPCMS:CacheCollisions( spawnmenuclass )

    ents.GetInfo( spawnmenuclass, function( npc )

        if !IsValid(npc) then return end

        self.NPCColCache[spawnmenuclass] = {npc:OBBMins(), npc:OBBMaxs()}

        if dev:GetBool() then
            PrintMessage(HUD_PRINTTALK, "Cached "..spawnmenuclass.." collisions.")
        end

    end)

end


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


function NPCMS:GoodNPCPos( spawnmenuclass, nodepos )
    return nodepos
end


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
