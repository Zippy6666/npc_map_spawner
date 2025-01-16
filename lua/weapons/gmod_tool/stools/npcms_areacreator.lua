TOOL.AddToMenu = true
TOOL.Category = "NPC MAP SPAWNER"

local toolname = "NPC MAP SPAWNER: Spawn Area Creator"
TOOL.Name = toolname
TOOL.Description = "Create areas that determine where certain NPCs are allowed to spawn."



if CLIENT then
    local help = "Left-click: Create a point at the postition you are looking at. Right-click: Create a point on yourself. Reload: Remove the spawn area at your position."

    language.Add("tool.NPCMS_areacreator.name", TOOL.Name)
    language.Add("tool.NPCMS_areacreator.desc", TOOL.Description)
    language.Add("tool.NPCMS_areacreator.0", help)
end


function TOOL:Deploy()
    if SERVER then
        if !self:GetOwner():IsSuperAdmin() then return end
        NPCMS_RefreshClientAreas(self:GetOwner())
    end
end


if SERVER then
    util.AddNetworkString("NPCMS_AreaTagActions_Server")
    util.AddNetworkString("NPCMS_AreaAction_Server")
    util.AddNetworkString("NPCMS_AreaColor_Server")

    net.Receive("NPCMS_AreaTagActions_Server", function( _, ply )
        ply.NPCMSTool_AreaTagActions = net.ReadTable()
    end)

    net.Receive("NPCMS_AreaAction_Server", function( _, ply )
        ply.NPCMSTool_AreaAction = net.ReadString()
    end)

    net.Receive("NPCMS_AreaColor_Server", function( _, ply )
        ply.NPCMSTool_AreaColor = net.ReadColor()
    end)
end

function TOOL:BuildArea( new_point )
    sound.Play("buttons/button3.wav", new_point, 85, math.random(90, 110), 0.75)

    local own = self:GetOwner()
    local pos1 = own:GetNWVector("NPCMSTool_Position1")

    if pos1 == Vector(0,0,0) then own:SetNWVector("NPCMSTool_Position1", new_point)
    else
        NPCMS_CreateArea( pos1, new_point, own.NPCMSTool_AreaTagActions, own.NPCMSTool_AreaColor, own.NPCMSTool_AreaAction )
        own:SetNWVector("NPCMSTool_Position1", Vector(0,0,0))
    end
end


function TOOL:LeftClick( trace )
    if !self:GetOwner():IsSuperAdmin() then return end

    if SERVER then self:BuildArea( trace.HitPos ) end
    return true
end


function TOOL:RightClick( trace )
    local own = self:GetOwner()
    if !own:IsSuperAdmin() then return end

    if SERVER then self:BuildArea( own:GetPos() ) end
end


function TOOL:Reload( trace )
    if !SERVER then return end
    if !self:GetOwner():IsSuperAdmin() then return end

    local _, indexes = NPCMS_GetAreasAtPos( self:GetOwner():WorldSpaceCenter() )
    if !table.IsEmpty(indexes) then NPCMS_RemoveArea( table.Random(indexes) ) end
end


if SERVER then
    util.AddNetworkString("NPCMS_UpdateToolTags")
    util.AddNetworkString("NPCMS_UpdateAreaClient")

    local areas_file_path = "npcms_areas/"..game.GetMap()..".json"
    NPCMS_AREAS = util.JSONToTable(file.Read(areas_file_path) or "[]" )
    
    function NPCMS_CreateArea( pos1, pos2, action_list, col, def_action )
        local area = { points = { pos1, pos2 }, Tag_actions = action_list, color = col, action = def_action }
        table.insert(NPCMS_AREAS, area )
        RunConsoleCommand("npc_map_spawner_reload_nodes")
        NPCMS_RefreshClientAreas_All()
    end
    
    util.AddNetworkString("NPCMS_RemoveAreaFromCL")
    
    net.Receive("NPCMS_RemoveAreaFromCL", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        NPCMS_RemoveArea( net.ReadInt(16) )
    end)
    
    function NPCMS_RemoveArea( idx )
        table.remove(NPCMS_AREAS, idx)
        NPCMS_RefreshClientAreas_All()
    end
    
    
    util.AddNetworkString("NPCMS_ModifyArea")
    
    net.Receive("NPCMS_ModifyArea", function( _, ply )
        if !ply:IsSuperAdmin() then return end

        local idx = net.ReadInt(16)
        local action = net.ReadString()
        local specific_actions = net.ReadTable()
        local color = net.ReadColor()
    
        NPCMS_AREAS[idx].action = action
        NPCMS_AREAS[idx].Tag_actions = specific_actions
        NPCMS_AREAS[idx].color = color
    
        NPCMS_RefreshClientAreas( ply )
    end)
    
    
    function NPCMS_IsInArea( area, pos )
        local p1 = area.points[1]
        local p2 = Vector( p1.x, p1.y, area.points[2].z )
        local p3 = Vector( p1.x, area.points[2].y, p1.z )
        local p4 = Vector( area.points[2].x, p1.y, p1.z )
    
        local dir1 = p1 - p2
        local dir2 = p1 - p3
        local dir3 = p1 - p4

        if dir1:Dot(pos) < dir1:Dot(p1) && dir1:Dot(pos) > dir1:Dot(p2) &&
        dir2:Dot(pos) < dir2:Dot(p1) && dir2:Dot(pos) > dir2:Dot(p3) &&
        dir3:Dot(pos) < dir3:Dot(p1) && dir3:Dot(pos) > dir3:Dot(p4) then
            return true
        end
    end
    
    
    function NPCMS_GetAreasAtPos( pos )
        local areas_at_pos = {}
        local indexes = {}
    
        for k,v in ipairs(NPCMS_AREAS) do
            if NPCMS_IsInArea( v, pos ) then
                table.insert(areas_at_pos, v)
                table.insert(indexes, k)
            end
        end
    
        return areas_at_pos, indexes
    end
    
    
    function NPCMS_RefreshClientAreas( cl )
        if !file.Exists(areas_file_path, "DATA") then
            file.CreateDir("npcms_areas")
        end
    
        if table.IsEmpty(NPCMS_AREAS) then
            file.Delete(areas_file_path)
        else
            file.Write( areas_file_path, util.TableToJSON(NPCMS_AREAS))
        end

        net.Start("NPCMS_UpdateAreaClient")
        if !game.SinglePlayer() then
            net.WriteString(util.TableToJSON(NPCMS_AREAS))
        end
        net.Send(cl)
    end
    
    
    function NPCMS_RefreshClientAreas_All()
        for _,ply in player.Iterator() do
            if IsValid( ply:GetActiveWeapon() ) && ply:GetActiveWeapon():GetClass() == "gmod_tool" && ply:GetTool().Name ==  toolname then
                NPCMS_RefreshClientAreas( ply )
            end
        end
    end
end

if CLIENT then
    local function ply() return LocalPlayer() end

    hook.Add("InitPostEntity", "InitPostEntity_NPCMSTool_CL_InitVars", function()
        ply().NPCMSTool_cl_areas = {}
        ply().NPCMSTool_area_color = Color(255,255,255)
        ply().NPCMSTool_area_actions = {}
        ply().NPCMSTool_Tag_tbl = {}
    end)

    local ang_zero = Angle(0,0,0)
    local vec_zero = Vector(0,0,0)
    local cross_len = 18

    hook.Add("PostDrawTranslucentRenderables", "PostDrawTranslucentRenderables_NPCMS_Areas", function()
        if !( IsValid( LocalPlayer():GetActiveWeapon() ) && LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" && LocalPlayer():GetTool() && LocalPlayer():GetTool().Name == toolname ) then return end

        local pos1 = LocalPlayer():GetNWVector("NPCMSTool_Position1")

        if pos1 != vec_zero then
            render.DrawLine(pos1+Vector(0,0,cross_len), pos1-Vector(0,0,cross_len), ply().NPCMSTool_area_color, false)
            render.DrawLine(pos1+Vector(0,cross_len,0), pos1-Vector(0,cross_len,0), ply().NPCMSTool_area_color, false)
            render.DrawLine(pos1+Vector(cross_len,0,0), pos1-Vector(cross_len,0,0), ply().NPCMSTool_area_color, false)
        end

        if !table.IsEmpty(ply().NPCMSTool_cl_areas) then
            for _, v in ipairs( ply().NPCMSTool_cl_areas ) do
                render.DrawWireframeBox( v.points[1] , ang_zero, vec_zero, v.points[2] - v.points[1], v.color, false)
            end
        end
    end)

    net.Receive("NPCMS_UpdateAreaClient", function(bits)
        ply().NPCMSTool_cl_areas = ply().NPCMSTool_cl_areas or {}

        table.Empty(ply().NPCMSTool_cl_areas)

        -- surface.PlaySound("buttons/button14.wav")

        if ply().NPCMSTool_area_list then
            for k in ipairs(ply().NPCMSTool_area_list:GetLines()) do
                ply().NPCMSTool_area_list:RemoveLine(k)
            end
        end

        local file_read
        if !game.SinglePlayer() then
            file_read = net.ReadString()
        else
            file_read = file.Read("NPCMS_areas/"..game.GetMap()..".json")
        end

        if file_read then
            local areas = util.JSONToTable(file_read)

            for idx, area in ipairs(areas) do
                if ply().NPCMSTool_area_list then
                    local line = ply().NPCMSTool_area_list:AddLine("", "Area " .. idx, !table.IsEmpty( area.Tag_actions ) && "Advanced" or area.action or "Error" )
                    local col = vgui.Create("DColorButton", line)
                    col:SetColor(area.color)
                    col:Dock(LEFT)
                    col:SetWidth(12)
                    col:SetHeight(12)
                end

                ply().NPCMSTool_cl_areas[idx] = area
            end
        end
    end)

    local function update_Tags(Tags_file)
        if ply().NPCMSTool_Tag_list then
            for k in ipairs(ply().NPCMSTool_Tag_list:GetLines()) do
                ply().NPCMSTool_Tag_list:RemoveLine(k)
            end
        end

        table.Empty(ply().NPCMSTool_Tag_tbl)

        for _, Tag in ipairs(Tags_file) do
            if ply().NPCMSTool_Tag_list then
                ply().NPCMSTool_Tag_list:AddLine(Tag.Name, ply().NPCMSTool_area_actions[Tag.Name] or "Default")
            end
        
            table.insert(ply().NPCMSTool_Tag_tbl, Tag.Name)
        end
    end

    net.Receive("NPCMS_UpdateToolTags", function(bits)
        local Tags_file
        if !game.SinglePlayer() then
            Tags_file = util.JSONToTable(net.ReadString())
        else
            Tags_file = util.JSONToTable(file.Read("NPCMS_Tags.json"))
        end

        update_Tags(Tags_file)
    end)

    function TOOL.BuildCPanel(panel)
        if !LocalPlayer():IsSuperAdmin() then panel:Help("You don't have permission to to use this tool.") return end

        local vg

        panel:ControlHelp("NOTE: If the areas don't seem to be doing anything, it could be because you have \"Obey Spawn Areas\" disabled!")

        panel:Help("** BASIC **")

        panel:Help("Default area action:")

        local action_dropdown_choice = "Blacklist" 
        local action_dropdown = vgui.Create("DComboBox", panel)
        action_dropdown:Dock(TOP)
        action_dropdown:DockMargin(5, 5, 5, 5)
        action_dropdown.OnSelect = function( _, _, s )
            action_dropdown_choice = s

            net.Start("NPCMS_AreaAction_Server")
            net.WriteString(action_dropdown_choice)
            net.SendToServer()
        end
        action_dropdown:AddChoice("Whitelist", nil, false)
        action_dropdown:AddChoice("Blacklist", nil, true)
        action_dropdown:AddChoice("Force", nil, false)

        panel:ControlHelp("Blacklist = NPC spawning is not allowed in this area.")
        panel:ControlHelp("Whitelist = NPC spawning is allowed in this area.")
        panel:ControlHelp("Force = NPC spawning must occur in this area, or in another area with \"Force\".")

        panel:Help("Area color:")

        local color_disp = vgui.Create("DColorButton", panel)

        local function change_color( col )
            ply().NPCMSTool_area_color = Color(col.r, col.g, col.b)
            color_disp:SetColor(ply().NPCMSTool_area_color)

            net.Start("NPCMS_AreaColor_Server")
            net.WriteColor(ply().NPCMSTool_area_color)
            net.SendToServer()
        end

        vg = vgui.Create("DColorPalette", panel)
        vg:SetButtonSize(15)
        vg:Dock(TOP)
        vg:DockMargin(5, 5, 5, 5)
        vg.OnValueChanged = function( _, col )
            change_color( col )
        end

        color_disp:SetColor(ply().NPCMSTool_area_color)
        color_disp:Dock(TOP)
        color_disp:SetHeight(12)
        color_disp:DockMargin(5, 5, 5, 5)

        panel:Help("Areas:")

        ply().NPCMSTool_area_list = vgui.Create("DListView", panel)
        ply().NPCMSTool_area_list:SetMultiSelect(false)
        ply().NPCMSTool_area_list:Dock(TOP)
        ply().NPCMSTool_area_list:DockMargin(5, 5, 5, 0)
        local column = ply().NPCMSTool_area_list:AddColumn("")
        column:SetMinWidth(12)
        column:SetMaxWidth(12)
        column:SetWidth(12)
        ply().NPCMSTool_area_list:AddColumn("Area")
        ply().NPCMSTool_area_list:AddColumn("Action")
        ply().NPCMSTool_area_list:SetHeight(400)
        ply().NPCMSTool_area_list.OnRowRightClick = function( _, i )
            local options = DermaMenu()
            
            options:AddOption("Remove", function()
                net.Start("NPCMS_RemoveAreaFromCL")
                net.WriteInt(i, 16)
                net.SendToServer()
            end)

            options:AddOption("Apply Current Settings", function()
                net.Start("NPCMS_ModifyArea")
                net.WriteInt( i, 16 )
                net.WriteString( action_dropdown_choice )
                net.WriteTable( ply().NPCMSTool_area_actions )
                net.WriteColor( ply().NPCMSTool_area_color )
                net.SendToServer()
            end)

            options:AddOption("Get Settings", function()
                local area = ply().NPCMSTool_cl_areas[i]

                change_color( area.color )

                ply().NPCMSTool_area_actions = area.Tag_actions

                net.Start("NPCMS_AreaTagActions_Server")
                net.WriteTable(ply().NPCMSTool_area_actions)
                net.SendToServer()

                net.Start("NPCMS_GetServerTags")
                net.SendToServer()

                action_dropdown:ChooseOption(area.action)
            end)

            options:Open()
        end

        panel:Help("** ADVANCED **")

        panel:Help("Double click to change specific action for a Tag:")

        panel:ControlHelp("Default = The specific Tag uses the default area action.")

        ply().NPCMSTool_Tag_list = vgui.Create("DListView", panel)
        ply().NPCMSTool_Tag_list:SetMultiSelect(false)
        ply().NPCMSTool_Tag_list:Dock(TOP)
        ply().NPCMSTool_Tag_list:DockMargin(5, 5, 5, 0)
        ply().NPCMSTool_Tag_list:AddColumn("Tags")
        ply().NPCMSTool_Tag_list:AddColumn("Specific Action")
        ply().NPCMSTool_Tag_list:SetHeight(400)
        ply().NPCMSTool_Tag_list.DoDoubleClick = function( _, i )
            local gr = ply().NPCMSTool_Tag_tbl[i]

            if !ply().NPCMSTool_area_actions[ gr ] then
                ply().NPCMSTool_area_actions[ gr ] = "Blacklist"
            elseif ply().NPCMSTool_area_actions[ gr ] == "Blacklist" then
                ply().NPCMSTool_area_actions[ gr ] = "Force"
            elseif ply().NPCMSTool_area_actions[ gr ] == "Force" then
                ply().NPCMSTool_area_actions[ gr ] = "Whitelist"
            elseif ply().NPCMSTool_area_actions[ gr ] == "Whitelist" then
                ply().NPCMSTool_area_actions[ gr ] = nil
            end

            net.Start("NPCMS_GetServerTags")
            net.SendToServer()

            net.Start("NPCMS_AreaTagActions_Server")
            net.WriteTable(ply().NPCMSTool_area_actions)
            net.SendToServer()
        end

        local function change_all( action )
            for _,v in ipairs(ply().NPCMSTool_Tag_tbl) do
                ply().NPCMSTool_area_actions[ v ] = action
            end

            net.Start("NPCMS_GetServerTags")
            net.SendToServer()

            net.Start("NPCMS_AreaTagActions_Server")
            net.WriteTable(ply().NPCMSTool_area_actions)
            net.SendToServer()
        end

        local function make_button( label, action )
            vg = vgui.Create("DButton", panel)
            vg:SetText(label)
            vg:Dock(TOP)
            vg:DockMargin(5, 0, 5, 0)
            vg.DoClick = function()
                change_all(action)
            end
        end

        make_button("Blacklist All", "Blacklist")
        make_button("Force All", "Force")
        make_button("Whitelist All", "Whitelist")
        make_button("Set All to Default (make area not advanced)", nil)

        net.Start("NPCMS_AreaTagActions_Server")
        net.WriteTable(ply().NPCMSTool_area_actions)
        net.SendToServer()

        net.Start("NPCMS_AreaColor_Server")
        net.WriteColor(ply().NPCMSTool_area_color)
        net.SendToServer()
    end
end

