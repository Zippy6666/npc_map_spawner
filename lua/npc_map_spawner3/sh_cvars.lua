-- Cvars
NPCMS.Cvars = {}
local cvarPrefix = "npc_map_spawner_"



local function createCVAR( name, value, flags, helptext )
    local cvar = CreateConVar(cvarPrefix..name, value, flags or bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY), helptext )
    NPCMS["cvar_"..name] = cvar
    table.insert(NPCMS.Cvars, cvar)
end



    -- Create cvars
createCVAR("enable", "0")
createCVAR("show_info", "0")
createCVAR("cooldown", "3")
createCVAR("poscount", "3")
createCVAR("maxnpcs", "50")
createCVAR("mindist", "2000")
createCVAR("maxdist", "6000")
createCVAR("visibility", "0")




    -- Reset all cvars
if SERVER then
    
    util.AddNetworkString("NPCMS_ResetSettings")


    net.Receive("NPCMS_ResetSettings", function(_, ply)

        if !ply:IsSuperAdmin() then return end

        for _, cvar in ipairs(NPCMS.Cvars) do
            cvar:Revert()
        end
    
    end)

end