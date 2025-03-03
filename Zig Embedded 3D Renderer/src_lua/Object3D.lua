import "Vector3D"
local gfx <const> = playdate.graphics
local gtr <const> = playdate.geometry



---@class Point3D
---@field position Vector3D
---@overload fun(position: Vector3D): Point3D
Point3D = class("Point3D").extends() or Point3D

function Point3D:init(position)
    self.position = position
end

function Point3D:moveTo(position)
    self.position = position
end

function Point3D:translateBy(translate)
    self.position = self.position:add(translate)
end

---@class Object3D
---@field position Vector3D
---@overload fun(position: Vector3D): Object3D
Object3D = class("Object3D").extends() or Object3D

function Object3D:init(position)
    self.position = position
end

---Converts WorldSpace coordinates to CameraSpace coordinates
---Returns a new Point3D adjusted for CameraSpace
---@param camera Camera3D
---@return Point3D
function Point3D:WorldSpaceToCamSpace(camera)
    local x = (self.position.x - camera.position.x) * math.cos(math.rad(camera.rotation)) - (self.position.z - camera.position.z) * math.sin(math.rad(camera.rotation))
    local y = self.position.y - camera.position.y
    local z = (self.position.z - camera.position.z) * math.cos(math.rad(camera.rotation)) + (self.position.x - camera.position.x) * math.sin(math.rad(camera.rotation))
    return Point3D(Vector3D(x, y, z))
end


---@class Line3D
---@field pointA Point3D
---@field pointB Point3D
---@overload fun(a: Point3D, b: Point3D): Line3D
Line3D = class("Line3D").extends() or Line3D
---Constructor for a Line3D
---@param a Point3D
---@param b Point3D
function Line3D:init(a, b)
    self.pointA = a
    self.pointB = b
    self.vector = Vector3D.add_(a.position, b.position)
    self.length = self.vector.length
end

function Line3D:_recalculate()
    self.vector = Vector3D.add_(self.pointA.position, self.pointB.position)
    self.length = self.vector.length
end

---Translates this Line3D by a Vector3D
---@param vector Vector3D
---@return Line3D
function Line3D:translateBy(vector)
    self.pointA:translateBy(vector)
    self.pointB:translateBy(vector)
    self:_recalculate()
    return self
end


---Translates this Line3D to CameraSpace
---returns a new Line3D the translated vertex
---@param camera any
function Line3D:WorldSpaceToCamSpace(camera)
    local a = self.pointA:WorldSpaceToCamSpace(camera)
    local b = self.pointB:WorldSpaceToCamSpace(camera)
    return Line3D(a, b)
end

---@class Triangle3D
---@field pointA Point3D
---@field pointB Point3D
---@field pointC Point3D
---@field AB Line3D
---@field BC Line3D
---@field CA Line3D
---@overload fun(a: Point3D, b: Point3D, c: Point3D)
Triangle3D = class("Triangle3D").extends() or Triangle3D
---Constructor for Triangle3D
---@param a Point3D
---@param b Point3D
---@param c Point3D
function Triangle3D:init(a, b, c)
    self.pointA = a
    self.pointB = b
    self.pointC = c

    self:_recalculate()
end

---auto recalculates the triangle's lines
function Triangle3D:_recalculate()
    self.AB = Line3D(self.pointA, self.pointB)
    self.BC = Line3D(self.pointB, self.pointC)
    self.CA = Line3D(self.pointC, self.pointA)
end

---same as for every other fucking stuff
---@param vector Vector3D
function Triangle3D:translateBy(vector)
    self.pointA:translateBy(vector)
    self.pointB:translateBy(vector)
    self.pointC:translateBy(vector)
    self:_recalculate()
end

function Triangle3D:WorldSpaceToCamSpace(camera)
    self.pointA:WorldSpaceToCamSpace(camera)
    self.pointB:WorldSpaceToCamSpace(camera)
    self.pointC:WorldSpaceToCamSpace(camera)
    self:_recalculate()
end


---Returns a table containing unpacked vectors of each point
---@return table
function Triangle3D:unpack()
    return {self.pointA.position.x, self.pointA.position.y, self.pointA.position.z, self.pointB.position.x, self.pointB.position.y, self.pointB.position.z, self.pointC.position.x, self.pointC.position.y, self.pointC.position.z}
end

---@class EfficientTriangle3D
---@field pointA Vector3D
---@field pointB Vector3D
---@field pointC Vector3D
---@overload fun(a: Vector3D, b: Vector3D, c: Vector3D) EfficientTriangle3D
EfficientTriangle3D = class("EfficientTriangle3D").extends() or EfficientTriangle3D

---Creates an "EfficientTriangle3D"
---@param a Vector3D
---@param b Vector3D
---@param c Vector3D
function EfficientTriangle3D:init(a, b, c)
    self.pointA = a
    self.pointB = b
    self.pointC = c
end

---comment
---@param vector Vector3D
function EfficientTriangle3D:translateBy(vector)
    self.pointA = Vector3D.add_(self.pointA, vector)
    self.pointB = Vector3D.add_(self.pointB, vector)
    self.pointC = Vector3D.add_(self.pointC, vector)
end


PERSPECTIVE_OFFSET = 0.007

---A 3D Camera (with associated renderer)
---NOTE : This camera only supports Y-Axis rotation for performance's sake
---@class Camera3D
---@field position Vector3D WorldSpace coordinates
---@field rotation number Rotation on the Y axis
---@field focal_length number Field of View in degrees
---@overload fun(position: Vector3D, rotation: number, focal_length: number): Camera3D
Camera3D = class("Camera3D").extends() or Camera3D

function Camera3D:init(position, rotation, focal_length)
    self.position = position
    self.rotation = rotation
    self.focal_length = focal_length
end

---DEBUGGING FUNCTION
---Draws a WorldSpace vertex on the screen with perspective
---@param line Line3D
function Camera3D:DEBUG_draw_line(line)
    -- first we convert the vertex to cameraspace
    local _line = line:WorldSpaceToCamSpace(self)
    if _line.pointA.position.z < 0.0001 then
        _line.pointA.position.z = 0.0001
    end
    if _line.pointB.position.z < 0.0001 then
        _line.pointB.position.z = 0.0001

    end
    -- then for the two points, we move them towards the center on the 2D axis according to how "deep" on the Z axis they are
    -- for that, we first have to calculate the offset towards the center (200;120 screen coordinates)
    local pointA = gtr.point.new(_line.pointA.position.x / _line.pointA.position.z * PERSPECTIVE_OFFSET, _line.pointA.position.y / _line.pointA.position.z)
    local pointB = gtr.point.new(_line.pointB.position.x / _line.pointB.position.z * PERSPECTIVE_OFFSET , _line.pointB.position.y / _line.pointB.position.z)

    local lineSegment = gtr.lineSegment.new(pointA.x + 200, -pointA.y + 120, pointB.x + 200, -pointB.y + 120)
    gfx.drawLine(lineSegment)
end

---Converts point to screenspace coordinates
---@param point Point3D
---@return
function Camera3D:point_to_screen(point)
    -- first we convert the vertex to cameraspace
    local _point = point:WorldSpaceToCamSpace(self)
    if _point.position.z < 0 then
        return nil
    end
    if _point.position.z <= 0.1 then
        _point.position.z = 0.1
    end
    local scale_factor = self.focal_length / _point.position.z
    -- then for the two points, we move them towards the center on the 2D axis according to how "deep" on the Z axis they are
    -- for that, we first have to calculate the offset towards the center (200;120 screen coordinates)
    return gtr.point.new((_point.position.x * scale_factor) + 200, (-_point.position.y * scale_factor) + 120)

end


---DEBUGGING FUNCTION
---Draws a WorldSpace Triangle on the screen with perspective
---@param triangle Triangle3D
function Camera3D:DEBUG_draw_triangle(triangle)
    local a, b, c = self:point_to_screen(triangle.pointA), self:point_to_screen(triangle.pointB), self:point_to_screen(triangle.pointC)
    if a == nil or b == nil or c == nil then
        return
    end
    gfx.pushContext()
        -- gfx.setColor(gfx.kColorWhite)
        -- gfx.fillTriangle(a.x, a.y, b.x, b.y, c.x, c.y)
        -- gfx.setColor(gfx.kColorBlack)
        gfx.drawTriangle(a.x, a.y, b.x, b.y, c.x, c.y)
    gfx.popContext()
end
