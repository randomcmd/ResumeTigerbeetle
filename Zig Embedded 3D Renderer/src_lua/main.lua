import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/object"
import "CoreLibs/math"
import "CoreLibs/crank"

import "Vector3D"
import "Object3D"
import "model"



local gfx <const> = playdate.graphics

--- I N I T ---
playdate.display.setRefreshRate(50)
collectgarbage("collect")
---------------

--- T E S T I N G    P L A C E ---


local triangle = EfficientTriangle3D(Vector3D(0, 0, 0), Vector3D(0, 100, 0), Vector3D(100, 0, 0))
triangle:translateBy(Vector3D(-1, 0, 0))
-- printTable(triangle)
local triangle_rotated = Triangle3D(Point3D(Vector3D(0, 0, -100)), Point3D(Vector3D(0, 0, 0)), Point3D(Vector3D(0, 100, 0)))

printTable(playdate.file.listFiles('assets/models/'))

local models = {} 
local model = Model3D("assets/models/test.txt")

for i=0, 100 do
    local _model = Model3D("assets/models/test.txt")
    _model:translateBy(Vector3D(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10)))
    for _, tri in ipairs(_model.triangles) do
        ir_push_vertex(tri.pointA.x, tri.pointA.y, tri.pointA.z)
        ir_push_vertex(tri.pointB.x, tri.pointB.y, tri.pointB.z)
        ir_push_vertex(tri.pointC.x, tri.pointC.y, tri.pointC.z)
    end
    table.insert(models, _model)
end


local _hor = 0
local _ver = 0
local camX, camY, camZ = get_camera_position()
local _forward = Vector3D(0, 0, 1)
local _right = Vector3D(1, 0, 0)
local camUP = Vector3D(0, 0.15, 0)
local camDOWN = Vector3D(0, -0.15, 0)

function playdate.update()
    gfx.clear()
    gfx.drawText("tris : " .. camera_DEBUGSTATS(), 200, 10)
    -- hello()
    -- gfx.drawText("This is a text!", 100, 200)
    playdate.drawFPS(0, 0)
    _hor = 0
    _ver = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        _hor = -1
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        _hor = 1
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        _ver = 1
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        _ver = -1
    end
    set_camera_rotation(playdate.getCrankPosition())
    if _ver ~= 0 or _hor ~= 0 then
        local _rot = math.rad(get_camera_rotation())
        local forward = Vector3D.rotateByOnYAxis_(_forward, _rot)
        local right = Vector3D(forward.z, 0, -forward.x)
        forward:multiply(_ver * 0.15)
        right:multiply(_hor * 0.15)
        local mov = Vector3D.add(forward, right)
        move_camera_by(mov.x, mov.y, mov.z)
    end

    ir_draw_vertices()
    --model:draw()
    -- for _, model in ipairs(models) do
    --     model:draw()
    -- end
    -- if playdate.buttonIsPressed(playdate.kButtonA) then
    --     camera.position:add(camUP)
    -- end
    -- if playdate.buttonIsPressed(playdate.kButtonB) then
    --     camera.position:add(camDOWN)
    -- end
    
    -- local _rot = math.rad(camera.rotation)


    -- camera.position:add(forward:multiply(_ver * 0.15))
    -- camera.position:add(right:multiply(_hor * 0.15))

    -- triangle:translateBy(Vector3D(0, 0, 0.01))
    -- triangle_rotated:translateBy(Vector3D(0, 0, 0.01))
    -- camera.rotation = playdate.getCrankPosition()
    -- camera:DEBUG_draw_triangle(triangle)
    -- camera:DEBUG_draw_triangle(triangle_rotated)
    -- model:draw(camera)
    -- model2:draw(camera)

-- gfx.sprite.update()
    playdate.timer.updateTimers()
end
