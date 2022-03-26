local function GameRotationToQuaternion(rotation)
    local x,y,z = rotation.x,rotation.y,rotation.z
    local q1 = quat(y,vector3(0,1,0))
    local q2 = quat(x,vector3(1,0,0))
    local q3 = quat(z,vector3(0,0,1))
    local q = q1 * q2 * q3
    return q
end


local function GetMinMax(vertices)
    local min = {x=9999,y=9999,z=9999}
    local max = {x=-9999,y=-9999,z=-9999}
   
    local temp = {}
    for i=1, #vertices do
        local v = vertices[i]
        local x,y,z = v.x,v.y,v.z
        local v = vector3(x,y,z)
        if v.x < min.x then min.x = v.x end
        if v.y < min.y then min.y = v.y end
        if v.z < min.z then min.z = v.z end
        if v.x > max.x then max.x = v.x end
        if v.y > max.y then max.y = v.y end
        if v.z > max.z then max.z = v.z end
    end
    return vector3(min.x,min.y,min.z),vector3(max.x,max.y,max.z)
end

local DrawMinMax = function(min,max,r,g,b,a)
    DrawLine(min.x, min.y, min.z, max.x, min.y, min.z, r,g,b,a)
    DrawLine(max.x, min.y, min.z, max.x, max.y, min.z, r,g,b,a)
    DrawLine(max.x, max.y, min.z, min.x, max.y, min.z, r,g,b,a)
    DrawLine(min.x, max.y, min.z, min.x, min.y, min.z, r,g,b,a)
    DrawLine(min.x, min.y, max.z, max.x, min.y, max.z, r,g,b,a)
    DrawLine(max.x, min.y, max.z, max.x, max.y, max.z, r,g,b,a)
    DrawLine(max.x, max.y, max.z, min.x, max.y, max.z, r,g,b,a)
    DrawLine(min.x, max.y, max.z, min.x, min.y, max.z, r,g,b,a)
    DrawLine(min.x, min.y, min.z, min.x, min.y, max.z, r,g,b,a)
    DrawLine(max.x, min.y, min.z, max.x, min.y, max.z, r,g,b,a)
    DrawLine(max.x, max.y, min.z, max.x, max.y, max.z, r,g,b,a)
    DrawLine(min.x, max.y, min.z, min.x, max.y, max.z, r,g,b,a)
end


local GetHightedVertices = function(vertices, hight, isreturnincludedoriginalvertices)
    local result = {}
    local vertices_ = vertices
    for i=1,#vertices_ do
        table.insert(result,vector3(vertices_[i].x,vertices_[i].y,hight))
    end
    return result
end

local CreatePolygonPlane = function(...)
    local args = {...}
    local points = args
    local corners = {}
    for i=1,#points do
        local vec = vector3(points[i].x, points[i].y ,points[i].z)
        table.insert(corners,vec)
    end
    local center = vector3(0.0,0.0,0.0)
    for i=1,#corners do
        center = center + corners[i]
    end
    center = center / #corners
    local pos = center
    for i=1,#corners do
        corners[i] = vector3(corners[i].x-center.x, corners[i].y-center.y, 0)
    end
    center = vector3(0.0,0.0,0.0)
    return {
        vertices = corners
    }
end

local function GetPolygonVertices(hight,rotation,...)
    local polygon = CreatePolygonPlane(...)
    local temp_vertices_ground = polygon.vertices
    local temp_vertices_hight = GetHightedVertices(temp_vertices_ground,hight)
    local temp_vertices_all = {}
    local q = GameRotationToQuaternion(rotation)
    for i=1,#temp_vertices_ground do 
        temp_vertices_ground[i] = q * temp_vertices_ground[i]
        temp_vertices_all[#temp_vertices_all+1] = temp_vertices_ground[i]
    end
    for i=1,#temp_vertices_hight do
        temp_vertices_hight[i] = q * temp_vertices_hight[i]
        temp_vertices_all[#temp_vertices_all+1] = temp_vertices_hight[i]
    end
    return {
        ground = temp_vertices_ground,
        hight = temp_vertices_hight,
        all = temp_vertices_all
    }
end 

local function GetSphereVertices (size, rotation)
    local vertices = {}
    local sx,sy,sz = size.x/2, size.y/2, size.z/2
    local x,y,z = rotation.x,rotation.y,rotation.z
    local q = GameRotationToQuaternion(rotation)
    local i = 0
    for theta = 0, math.pi*2, math.pi/8 do
        for phi = 0, math.pi*2, math.pi/8 do
            for z = 0, math.pi*2, math.pi/8 do
                local x = sx * math.sin(theta) * math.cos(phi)
                local y = sy * math.sin(theta) * math.sin(phi)
                local z = sz * math.cos(theta)
                local v = vector3(x,y,z)
                vertices[i] =  q * v 
                i = i + 1
            end
        end 
    end
    return vertices
end

local function GetCylinderVertices(size,rotation,zoffset)
    local vertices = {}
    local sx,sy,sz = size.x/2, size.y/2, size.z/2
    local x,y,z = rotation.x,rotation.y,rotation.z
    local circlevertices = {}
    for theta = 0, math.pi*2, math.pi/8 do
        local x = sx * math.sin(theta)
        local y = sy * math.cos(theta)
        local z = 0.0 + (zoffset or 0)
        local v = vector3(x,y,z)
        circlevertices[#circlevertices+1] = v
    end
    
    return GetPolygonVertices(sz, rotation, table.unpack(circlevertices))
end


local function GetConeVertices(size, rotation)
    local vertices = {}
    local sx,sy,sz = size.x/2, size.y/2, size.z/2
    local q = GameRotationToQuaternion(rotation)
    local leftx = - sx
    local rightx =  sx
    local hight = sz + sz/2
    local pointbottom = vector3(0,0,-hight)
    local sizeX = sx
    local sizeY = sy
    for i = hight, -hight , -hight/8 do 
        local percent = (i+hight)/(2*hight)
        local sizeX = sx * percent
        local sizeY = sy * percent
        for theta = 0, math.pi*2, math.pi/8 do
            local x = sizeX * math.sin(theta)
            local y = sizeY * math.cos(theta)
            local v = vector3(x,y,i)
            vertices[#vertices+1] = q * v 
        end
    end
    return vertices
end

local function GetBoxVertices(size,rotation)
    local w,h,d = size.x, size.y, size.z
    local rx,ry,rz = rotation.x,rotation.y,rotation.z
    return GetPolygonVertices(d,rotation,vector3(0,0,0),vector3(w,0,0),vector3(w,h,0),vector3(0,h,0))
end

local DrawVertices = function(pos, vertices, r,g,b,a)
    for i=1, #vertices do
        if vertices[i] and vertices[i+1] then 
            DrawLine(vertices[i].x + pos.x, vertices[i].y + pos.y, vertices[i].z + pos.z, vertices[i+1].x + pos.x, vertices[i+1].y + pos.y, vertices[i+1].z + pos.z, r,g,b,a)
        end 
    end
    --DrawLine(pos.x, pos.y, pos.z, vertices[1].x + pos.x, vertices[1].y + pos.y, vertices[1].z + pos.z, r,g,b,a)
end

local DrawVertices2 = function(pos, verticestable, r,g,b,a)
    local ground = verticestable.ground
    local hight = verticestable.hight
    local vertices = ground 
    local hight_vertices = hight
    for i=1, #vertices do
        if vertices[i] and vertices[i+1] then 
            DrawLine(vertices[i].x + pos.x, vertices[i].y + pos.y, vertices[i].z + pos.z, vertices[i+1].x + pos.x, vertices[i+1].y + pos.y, vertices[i+1].z + pos.z, r,g,b,a)
            DrawLine(hight_vertices[i].x + pos.x, hight_vertices[i].y + pos.y, hight_vertices[i].z + pos.z, hight_vertices[i+1].x + pos.x, hight_vertices[i+1].y + pos.y, hight_vertices[i+1].z + pos.z, r,g,b,a)
        end 
    end
    --DrawLine(pos.x, pos.y, pos.z, vertices[1].x + pos.x, vertices[1].y + pos.y, vertices[1].z + pos.z, r,g,b,a)
end

DrawDebugBox = function(center, size, rotation, r, g, b, a, vertices_debug)
    if vertices_debug then 
        local pos = center
        local size = size
        local rotation = rotation
        local verticestable = GetBoxVertices(size, rotation)
        DrawVertices2(pos, verticestable, 255,0,0,100)
        local min,max = GetMinMax(verticestable.all)
        DrawMinMax(min + center, max + center, 255,255,255,255)
    end 
    DrawMarker(43, center.x,center.y,center.z, 0.0, 0.0, 0.0, rotation.x,rotation.y,rotation.z, size.x,size.y,size.z, r,g,b,100, false, false, 2, false, false, false, false)
end

DrawDebugCylinder = function(center, size, rotation, r,g,b,a, vertices_debug)
    if vertices_debug then 
        local pos = center
        local size = size
        local rotation = rotation
        local verticestable = GetCylinderVertices(size, rotation)
        DrawVertices2(pos, verticestable, 255,0,0,100)
        local min,max = GetMinMax(verticestable.all)
        DrawMinMax(min + center, max + center, 255,255,255,255)
     
    end 
    DrawMarker(1, center.x,center.y,center.z, 0.0, 0.0, 0.0, rotation.x,rotation.y,rotation.z, size.x, size.y, size.z/2 or 0.1, r,g,b,a, false, false, 2, false, false, false, false)
end

DrawDebugSphere = function(center, size, rotation, r,g,b,a, vertices_debug)
    if vertices_debug then 
        local pos = center
        local size = size
        local rotation = rotation
        local vertices = GetSphereVertices(size, rotation)
        DrawVertices(pos, vertices, 255,0,0,100)
        local min,max = GetMinMax(vertices)
        DrawMinMax(min + center, max + center, 255,255,255,255)
    
    end 
    DrawMarker(28, center.x,center.y,center.z, 0.0, 0.0, 0.0,rotation.x,rotation.y,rotation.z, size.x/2, size.y/2, size.z/2, r,g,b,a, false, false, 2, false, false, false, false)

end 

DrawDebugCone = function(center, size, rotation, r,g,b,a, vertices_debug)
    if vertices_debug then 
        local pos = center
        local size = size
        local rotation = rotation
        local vertices = GetConeVertices(size, rotation)
        DrawVertices(pos, vertices, 255,0,0,100)
        local min,max = GetMinMax(vertices)
        DrawMinMax(min + center, max + center, 255,255,255,255)
    end 
    DrawMarker(0, center.x,center.y,center.z, 0.0, 0.0, 0.0, rotation.x,rotation.y,rotation.z, size.x,size.y,size.z, r,g,b,100, false, false, 2, false, false, false, false)
end 

--[[
CreateThread(function()
    local pos = GetEntityCoords(PlayerPedId()) - vector3(0.0,0.0,1.0)
    local i = 0
    while true do Wait(0)
        local size = vector3(1,2,2)
        local rotation = vector3(i,i,i)
        i=i+0.1
        if i == 360 then i = 0 end
        --local rotation = vector3(0,0,0)
        DrawDebugCylinder(pos + vector3(5.0,5.0,1.0), size, rotation, 0,0,255,100, false)
        DrawDebugCone(pos+ vector3(10.0,10.0,1.0), size, rotation, 0,0,255,100, false)
        DrawDebugBox(pos+ vector3(15.0,15.0,1.0), size, rotation, 0,0,255,100, false)
        DrawDebugSphere(pos+ vector3(20.0,20.0,1.0), size, rotation, 0,0,255,100, false)
    end 
end)
--]]