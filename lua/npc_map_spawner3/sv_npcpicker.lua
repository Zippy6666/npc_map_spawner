-- Decide which NPC we should spawn
-- Return npc class in spawn menu
function NPCMS:GetNPCClsToSpawn()
    local legalNPCs = {}

    for _, SPAWNDATA in ipairs(self.CurrentSpawnableNPCs) do
        if math.random(1, SPAWNDATA.chance) == 1 then
            table.insert(legalNPCs, SPAWNDATA)
        end
    end

    if #legalNPCs == 0 then return end

    local SPAWNDATA = legalNPCs[math.random(1, #legalNPCs)]

    return SPAWNDATA.menucls, SPAWNDATA
end