-- Cvars

local cvarPrefix = "npc_map_spawner_"


local function createCVAR( name, value, flags, helptext )
    local cvar = CreateConVar(cvarPrefix..name, value, flags or bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY), helptext )
    NPCMS["cvar_"..name] = cvar
end


createCVAR("enable", "0")
createCVAR("show_time", "0")
createCVAR("cooldown", "3")
createCVAR("poscount", "3")
createCVAR("mindist", "2000")
createCVAR("maxdist", "6000")
createCVAR("visibility", "0")