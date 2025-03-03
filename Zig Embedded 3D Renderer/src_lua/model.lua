import "Object3D"
local fs <const> = playdate.file

---@class Model3D: Object3D
---@field triangles table<number, EfficientTriangle3D>
Model3D = class("Model3D").extends(Object3D) or Model3D

function Model3D:init(path)
    Model3D.super.init(Vector3D(0, 0, 0))
    local file, err = fs.open(path, fs.kFileRead)
    if err then
        assert(err == nil, "Cannot load " .. path .. " as 3D model. FSERR : " .. err)
    end
    if file then
        self.triangles = Model3D.parse(file)
    end
end

---Parses raw text data into a table of triangles
---@param data _File
function Model3D.parse(data)
    local parsed_triangles = {}
    local line=data:readline()
    --- We look for the PlaydateMeshRecord header
    if string.find(line, "#PMRv1") == nil then
        assert(false, "File provided to the 3D Model parser is invalid.")
    else
        line=data:readline()
    end
    while line ~= nil do
        local parsed_point = {}
        local current_point = {}
        local _cur = ""
        for i=1, line:len() do
        local c = line:sub(i, i)
        if c == ";" then
            table.insert(current_point, tonumber(_cur))
            _cur = ""
            goto continue
        elseif c == "_" then
            table.insert(current_point, tonumber(_cur))
            table.insert(parsed_point, Vector3D(current_point[1], current_point[2], current_point[3]))
            _cur = ""
            current_point = {}
            goto continue
        elseif c == "|" then
            table.insert(current_point, tonumber(_cur))
            table.insert(parsed_point, Vector3D(current_point[1], current_point[2], current_point[3]))
            if #parsed_point == 3 then
                -- assert(parsed_point[1] == nil or parsed_point[2] == nil or parsed_point[3] == nil, "ERR : Incomplete trianlge when trying to parse. Check your 3D model file!")
                table.insert(parsed_triangles, EfficientTriangle3D(parsed_point[1], parsed_point[2], parsed_point[3]))
                parsed_point = {}
            end
            goto continue
        end
        _cur = _cur.. c
        ::continue::
        end
    line=data:readline()
    end

    return parsed_triangles
end


---DEBUGGING draws each triangle
function Model3D:draw()
    local _triangles = self.triangles
    for i=1, #_triangles do
        local triangle = _triangles[i]
        draw_3d_triangle(triangle.pointA.x, triangle.pointA.y, triangle.pointA.z, triangle.pointB.x, triangle.pointB.y, triangle.pointB.z, triangle.pointC.x, triangle.pointC.y, triangle.pointC.z)
    end
    -- for _, triangle in ipairs(self.triangles) do
    --     draw_3d_triangle(triangle.pointA.x, triangle.pointA.y, triangle.pointA.z, triangle.pointB.x, triangle.pointB.y, triangle.pointB.z, triangle.pointC.x, triangle.pointC.y, triangle.pointC.z)
    -- end
end


function Model3D:translateBy(vector)
    for i=1, #self.triangles do
        self.triangles[i]:translateBy(vector)
    end

end