-- Credit: Silverlan


local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 4096

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2



local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end


local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end


local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end


local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end


function HordeSilverlanParseFile(f)
	f = file.Open(f,"rb","GAME")
		if(!f) then return end
		local ainet_ver = ReadInt(f)
		local map_ver = ReadInt(f)
		local nodegraph = {
			ainet_version = ainet_ver,
			map_version = map_ver
		}
		if(ainet_ver != AINET_VERSION_NUMBER) then
			MsgN("Unknown graph file")
			return
		end
		local numNodes = ReadInt(f)
		if(numNodes > MAX_NODES || numNodes < 0) then
			MsgN("Graph file has an unexpected amount of nodes")
			return
		end
		local nodes = {}
		for i = 1,numNodes do
			local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
			local yaw = f:ReadFloat()
			local flOffsets = {}
			for i = 1,NUM_HULLS do
				flOffsets[i] = f:ReadFloat()
			end
			local nodetype = f:ReadByte()
			local nodeinfo = ReadUShort(f)
			local zone = f:ReadShort()
			
			local node = {
				pos = v,
				yaw = yaw,
				offset = flOffsets,
				type = nodetype,
				info = nodeinfo,
				zone = zone,
				neighbor = {},
				numneighbors = 0,
				link = {},
				numlinks = 0
			}
			table.insert(nodes,node)
		end
		local numLinks = ReadInt(f)
		local links = {}
		for i = 1,numLinks do
			local link = {}
			local srcID = f:ReadShort()
			local destID = f:ReadShort()
			local nodesrc = nodes[srcID +1]
			local nodedest = nodes[destID +1]
			if(nodesrc && nodedest) then
				table.insert(nodesrc.neighbor,nodedest)
				nodesrc.numneighbors = nodesrc.numneighbors +1
				
				table.insert(nodesrc.link,link)
				nodesrc.numlinks = nodesrc.numlinks +1
				link.src = nodesrc
				link.srcID = srcID +1
				
				table.insert(nodedest.neighbor,nodesrc)
				nodedest.numneighbors = nodedest.numneighbors +1
				
				table.insert(nodedest.link,link)
				nodedest.numlinks = nodedest.numlinks +1
				link.dest = nodedest
				link.destID = destID +1
			else MsgN("Unknown link source or destination " .. srcID .. " " .. destID) end
			local moves = {}
			for i = 1,NUM_HULLS do
				moves[i] = f:ReadByte()
			end
			link.move = moves
			table.insert(links,link)
		end
		local lookup = {}
		for i = 1,numNodes do
			table.insert(lookup,ReadInt(f))
		end
	f:Close()
	nodegraph.nodes = nodes
	nodegraph.links = links
	nodegraph.lookup = lookup
	return nodegraph
end


function NPCMS:GetNodePositions()
	local nodegraph = HordeSilverlanParseFile("maps/graphs/" .. game.GetMap() .. ".ain")

	if !nodegraph then
        -- No nodegraph, give an empty table
		MsgN("NPCMS did not detect any nodegraph.")
		return {}
	end

	if table.IsEmpty(nodegraph) then
		MsgN("NPCMS fetched an empty nodegraph...")
	end
	

    -- Nodes retrieved, return table of positions
	local node_positions = {}
	for _, node in pairs(nodegraph.nodes) do
		table.insert(node_positions, node.pos)
	end
	return node_positions

end



local ang0 = Angle()
local fromGndDist = 10
local trUpVec = Vector(0, 0, 30)
local trEnd_DownVec = Vector(0, 0, 30)
local fromGndVec = Vector(0, 0, fromGndDist)
local green = Color(0, 255, 0)
function NPCMS:GetAugmentedNodePositions()
	local nodepositions = {}
	local Areas = {}


	for _, pos in ipairs(self:GetNodePositions()) do

		-- Better node position
		pos = util.TraceLine({start=pos+trUpVec, endpos=pos-trEnd_DownVec, mask=MASK_NPCWORLDSTATIC}).HitPos + fromGndVec


		-- Water check, we dont want spawn positions in water
		if bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER then
			continue
		end


		-- Ground distance check
		local groundDistCheck = util.TraceLine({
			start = pos,
			endpos = pos-fromGndVec*1.5,
			mask = MASK_NPCWORLDSTATIC,
		})
		if !groundDistCheck.Hit then
			continue
		end

		local areas = NPCMS_GetAreasAtPos( pos )

		-- In blacklisted area
		local inBlacklistedArea = false
		for _, area in ipairs(areas) do
			if area.action == "Blacklist" then
				inBlacklistedArea = true
				break
			end
		end
		if inBlacklistedArea then
			continue
		end

		-- Good position, use this one
		table.insert(nodepositions, pos)

	end

	return nodepositions, Areas
end
concommand.Add("npc_map_spawner_reload_nodes", function()

	NPCMS.NodePositions = NPCMS:GetAugmentedNodePositions()

	if table.IsEmpty(NPCMS.NodePositions) then
		MsgN("No nodes...")
	end

	for _, v in ipairs(NPCMS.NodePositions) do
		local test = ents.Create("base_gmodentity")
		test:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		test:SetMaterial("models/wireframe")
		test:SetPos(v)
		test:SetColor(green)
		test:DrawShadow(false)
		test:Spawn()
		SafeRemoveEntityDelayed(test, 5)
	end

end)

