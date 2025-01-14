-- Decide which NPC we should spawn
-- Return npc class in spawn menu
function NPCMS:GetNPCClsToSpawn()
    local legalNPCs = {}

    for _, SPAWNDATA in ipairs(self.CurrentSpawnableNPCs) do
        -- Too many npcs of this type spawned
        if isnumber(SPAWNDATA.num) && SPAWNDATA.num > 0 && self.NPCTypesSpawned[SPAWNDATA.sv_idx]
        && self.NPCTypesSpawned[SPAWNDATA.sv_idx] >= SPAWNDATA.num then
            continue 
        end

        if isnumber(SPAWNDATA.chance) && math.random(1, SPAWNDATA.chance) == 1 then
            table.insert(legalNPCs, SPAWNDATA)
        end
    end

    if #legalNPCs == 0 then return end

    local SPAWNDATA = legalNPCs[math.random(1, #legalNPCs)]

    return SPAWNDATA.menucls, SPAWNDATA
end