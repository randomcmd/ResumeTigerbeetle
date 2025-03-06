const std = @import("std");
const builtin = @import("builtin");
const pdapi = @import("playdate_api_definitions.zig");
const panic_handler = @import("panic_handler.zig");
const Allocator = @import("Allocator.zig");

pub const panic = panic_handler.panic;

const ExampleGlobalState = struct {
    playdate: *pdapi.PlaydateAPI,
    zig_image: *pdapi.LCDBitmap,
    font: *pdapi.LCDFont,
    image_width: c_int,
    image_height: c_int,
    allocator: std.mem.Allocator,
    debugState: DebugState,
};

const imgui = if (builtin.os.tag != .freestanding) @import("zgui") else struct {
    pub fn begin(_: anytype, _: anytype) bool {
        return false;
    }
    pub fn end() void {}
    pub fn button(_: anytype, _: anytype) bool {
        return false;
    }
    pub fn text(_: anytype, _: anytype) void {}
};
const DebugState = switch (builtin.os.tag) {
    .windows, .macos, .linux => struct {
        const glfw = @import("zglfw");
        const opengl = @import("zopengl");

        window: *glfw.Window,
        allocator: std.mem.Allocator,

        pub fn new(allocator: std.mem.Allocator) DebugState {
            var this = DebugState{
                .window = undefined,
                .allocator = allocator,
            };
            this.init_window();
            return this;
        }
        pub fn init_window(this: *DebugState) void {
            // Set up ImGui and GLFW
            glfw.init() catch return;
            const gl_major = 4;
            const gl_minor = 0;
            glfw.windowHint(.context_version_major, gl_major);
            glfw.windowHint(.context_version_minor, gl_minor);
            glfw.windowHint(.opengl_profile, .opengl_core_profile);
            glfw.windowHint(.opengl_forward_compat, true);
            glfw.windowHint(.client_api, .opengl_api);
            glfw.windowHint(.doublebuffer, true);
            this.window = glfw.Window.create(600, 600, "zig-gamedev: minimal_glfw_gl", null) catch return;
            glfw.makeContextCurrent(this.window);
            opengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor) catch return;
            imgui.init(this.allocator);
            imgui.io.setConfigFlags(.{
                .dock_enable = true,
                .viewport_enable = false, // Viewports are available on my local fork, but requires change to imgui bindings
            });
            imgui.backend.init(this.window);
        }
        pub fn new_frame(this: *DebugState) void {
            glfw.pollEvents();
            const gl = opengl.bindings;
            gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 1, 1, 1, 1 });
            const size = this.window.getSize();
            imgui.backend.newFrame(@intCast(size[0]), @intCast(size[1]));
        }
        pub fn update_and_render(this: *DebugState) void {
            imgui.render();
            imgui.backend.draw();
            this.window.swapBuffers();
        }
    },
    .freestanding => struct {
        pub fn new(_: anytype) DebugState {
            return .{};
        }
        pub fn new_frame(_: *DebugState) void {}
        pub fn init_window(_: *DebugState) void {}
        pub fn update_and_render(_: *DebugState) void {}
    },
    else => unreachable,
};

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    _ = arg;
    switch (event) {
        .EventInit => {
            //NOTE: Initalizing the panic handler should be the first thing that is done.
            //      If a panic happens before calling this, the simulator or hardware will
            //      just crash with no message.
            panic_handler.init(playdate);

            const zig_image = playdate.graphics.loadBitmap("assets/images/zig-playdate", null).?;
            var image_width: c_int = 0;
            var image_height: c_int = 0;
            playdate.graphics.getBitmapData(
                zig_image,
                &image_width,
                &image_height,
                null,
                null,
                null,
            );
            const font = playdate.graphics.loadFont("/System/Fonts/Roobert-20-Medium.pft", null).?;
            playdate.graphics.setFont(font);

            const global_state: *ExampleGlobalState =
                @ptrCast(
                @alignCast(
                    playdate.system.realloc(
                        null,
                        @sizeOf(ExampleGlobalState),
                    ),
                ),
            );
            const allocator = Allocator.Allocator(playdate);
            global_state.* = .{
                .playdate = playdate,
                .font = font,
                .zig_image = zig_image,
                .image_width = image_width,
                .image_height = image_height,
                .allocator = allocator,
                .debugState = DebugState.new(allocator),
            };

            globalStateLua = global_state;

            playdate.system.setUpdateCallback(update_and_render, global_state);
        },
        .EventInitLua => {
            addLuaFunction(debug_start, "remi_debug_start");
            addLuaFunction(debug_update, "remi_debug_update");
            addLuaFunction(debug_new_frame, "remi_debug_new_frame");
            addLuaFunction(debug_delete, "remi_debug_delete");
            addLuaFunction(struct {
                pub fn function(luaState: ?*pdapi.LuaState) callconv(.C) c_int {
                    _ = luaState;
                    const lua = globalStateLua.?.playdate.lua;
                    const name = lua.getArgString(1);
                    const imgui_result = imgui.button(std.mem.span(name), .{});
                    lua.pushBool(@intFromBool(imgui_result));
                    return 1;
                }
            }.function, "imgui_button");
        },
        else => {},
    }
    return 0;
}

fn addLuaFunction(function: pdapi.LuaCFunction, name: [*c]const u8) void {
    var result: c_int = 0;
    var lua_err: [*c]const u8 = undefined;
    const playdate = globalStateLua.?.playdate;
    result = playdate.lua.addFunction(function, name, &lua_err);
    if (result != 1) {
        playdate.system.@"error"(lua_err);
    }
}

var globalStateLua: ?*ExampleGlobalState = null;

fn debug_start(luaState: ?*pdapi.LuaState) callconv(.C) c_int {
    _ = luaState;
    const state = globalStateLua orelse return 0;
    state.playdate.lua.pushNil();
    return 1;
}

fn debug_update(luaState: ?*pdapi.LuaState) callconv(.C) c_int {
    _ = luaState;
    const state = globalStateLua orelse return 0;
    state.debugState.update_and_render();
    state.playdate.lua.pushNil();
    return 1;
}

fn debug_new_frame(luaState: ?*pdapi.LuaState) callconv(.C) c_int {
    _ = luaState;
    const state = globalStateLua orelse return 0;
    state.debugState.new_frame();
    state.playdate.lua.pushNil();
    return 1;
}

fn debug_delete(luaState: ?*pdapi.LuaState) callconv(.C) c_int {
    _ = luaState;
    const state = globalStateLua orelse return 0;
    state.playdate.lua.pushNil();
    return 1;
}

fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    const global_state: *ExampleGlobalState = @ptrCast(@alignCast(userdata.?));
    global_state.debugState.new_frame();
    _ = imgui.begin("Crankxygen", .{});
    imgui.text("Hello Cranksters", .{});
    const playdate = global_state.playdate;
    const zig_image = global_state.zig_image;

    const to_draw = "Hold Ⓐ to invert screen";
    const text_width =
        playdate.graphics.getTextWidth(
        global_state.font,
        to_draw,
        to_draw.len,
        .UTF8Encoding,
        0,
    );

    var draw_mode: pdapi.LCDBitmapDrawMode = .DrawModeCopy;
    var clear_color: pdapi.LCDSolidColor = .ColorWhite;

    var buttons: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&buttons, null, null);

    const debug_state = struct {
        var toggle: bool = false;
    };
    if (imgui.button("Toggle Colors", .{})) {
        debug_state.toggle = !debug_state.toggle;
    }
    if (buttons & pdapi.BUTTON_A != 0) {
        debug_state.toggle = false;
    }
    //Yes, Zig fixed bitwise operator precedence so that this works!
    if (buttons & pdapi.BUTTON_A != 0 or debug_state.toggle) {
        draw_mode = .DrawModeInverted;
        clear_color = .ColorBlack;
    }

    playdate.graphics.setDrawMode(draw_mode);
    playdate.graphics.clear(@intCast(@intFromEnum(clear_color)));

    playdate.graphics.drawBitmap(zig_image, 0, 0, .BitmapUnflipped);
    const pixel_width = playdate.graphics.drawText(
        to_draw,
        to_draw.len,
        .UTF8Encoding,
        @divTrunc(pdapi.LCD_COLUMNS - text_width, 2),
        pdapi.LCD_ROWS - playdate.graphics.getFontHeight(global_state.font) - 20,
    );
    _ = pixel_width;

    _ = imgui.button("test", .{});
    imgui.end();

    global_state.debugState.update_and_render();

    //returning 1 signals to the OS to draw the frame.
    //we always want this frame drawn
    return 1;
}
