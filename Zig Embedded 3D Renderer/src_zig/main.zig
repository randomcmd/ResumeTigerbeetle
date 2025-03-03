const std = @import("std");
const play = @import("playdate_api_definitions.zig");
const panic_handler = @import("panic_handler.zig");

const idea_renderer = @import("3dutils/idea_renderer.zig");
const Vector3 = idea_renderer.Vector3;

pub var playdate: *play.PlaydateAPI = undefined;
pub const panic = panic_handler.panic;

pub var camera: idea_renderer.Camera = idea_renderer.Camera.create(Vector3{ 0, 0, -25 }, 0, 110);

pub export fn eventHandler(playdate_local: *play.PlaydateAPI, event: play.PDSystemEvent, arg: u32) callconv(.C) c_int {
    //TODO: replace with your own code!

    _ = arg;
    switch (event) {
        .EventInit => {
            //NOTE: Initalizing the panic handler should be the first thing that is done.
            //      If a panic happens before calling this, the simulator or hardware will
            //      just crash with no message.
            panic_handler.init(playdate);
            playdate = playdate_local;
            playdate.system.logToConsole("Hello from Zig!");
            idea_renderer.initVertices();
            //playdate.system.setUpdateCallback(empty_update, null);
        },
        .EventInitLua => {
            var lua_error: [*c]const u8 = null;
            var lua_error_code = playdate.lua.addFunction(lua_function, "hello", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_draw_3d_triangle, "draw_3d_triangle", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_move_camera, "move_camera_by", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_get_camera_rotation, "get_camera_rotation", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_set_camera_rotation, "set_camera_rotation", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_get_camera_position, "get_camera_position", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(lua_camera_DEBUGSTATS, "camera_DEBUGSTATS", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(idea_renderer.pushVertex, "ir_push_vertex", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
            lua_error_code = playdate.lua.addFunction(idea_renderer.drawVertices, "ir_draw_vertices", &lua_error);
            if (lua_error_code == 0) {
                playdate.system.@"error"(lua_error);
            }
        },
        else => {},
    }
    return 1;
}

pub fn empty_update(userdata: ?*anyopaque) callconv(.C) c_int {
    _ = userdata;
    return 1;
}

pub fn lua_function(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    const triangle = idea_renderer.Triangle.create(Vector3{ 0, 0, 0 }, Vector3{ 0, 100, 0 }, Vector3{ 100, 0, 0 });
    triangle.drawTriangle();
    playdate.lua.pushInt(1);
    return 1;
}

pub fn lua_draw_3d_triangle(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    //const cam = camera;
    //const pA = r.Vector3{ playdate.lua.getArgFloat(1), playdate.lua.getArgFloat(2), playdate.lua.getArgFloat(3) };
    //const pB = r.Vector3{ playdate.lua.getArgFloat(4), playdate.lua.getArgFloat(5), playdate.lua.getArgFloat(6) };
    //const pC = r.Vector3{ playdate.lua.getArgFloat(7), playdate.lua.getArgFloat(8), playdate.lua.getArgFloat(9) };
    //const tri = r.Triangle.create(pA, pB, pC);
    //cam.drawTriangle(tri);
    return 0;
}

pub fn lua_move_camera(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    camera.update();
    const moveVec = Vector3{ playdate.lua.getArgFloat(1), playdate.lua.getArgFloat(2), playdate.lua.getArgFloat(3) };
    camera.position += moveVec;
    return 0;
}

pub fn lua_get_camera_rotation(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    playdate.lua.pushFloat(camera.rotation);
    return 1;
}

pub fn lua_set_camera_rotation(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    camera.update();
    camera.rotation = playdate.lua.getArgFloat(1);
    return 0;
}

pub fn lua_get_camera_position(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    playdate.lua.pushFloat(camera.position[0]);
    playdate.lua.pushFloat(camera.position[1]);
    playdate.lua.pushFloat(camera.position[2]);
    return 3;
}

pub fn lua_camera_DEBUGSTATS(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    playdate.lua.pushInt(idea_renderer.ir_trianglesCounter);
    idea_renderer.ir_trianglesCounter = 0;
    return 1;
}
