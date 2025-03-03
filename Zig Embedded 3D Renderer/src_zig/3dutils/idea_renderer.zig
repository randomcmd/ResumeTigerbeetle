const std = @import("std");
const play = @import("../playdate_api_definitions.zig");
const main = @import("../main.zig");
const mem = @import("../zig_memory.zig");

pub var ir_trianglesCounter: i32 = 0;

pub const Vector3 = @Vector(3, f32);

pub const Vector2_i32 = @Vector(2, i32);

pub fn vec3_dot_product(v1: Vector3, v2: Vector3) f32 {
    return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

pub fn vec3_normalize(v: Vector3) Vector3 {
    const _length = @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    return Vector3{ v[0] / _length, v[1] / _length, v[2] / _length };
}

pub const Vector2 = @Vector(2, f32);

pub fn vec2_dot_product(v1: Vector2, v2: Vector2) f32 {
    return v1[0] * v2[0] + v1[1] * v2[1];
}

pub const Triangle = struct {
    vertices: [3]Vector3,
    pub fn create(a: Vector3, b: Vector3, c: Vector3) Triangle {
        return .{
            .vertices = .{ a, b, c },
        };
    }

    pub fn drawTriangle(this: Triangle) void {
        main.playdate.graphics.drawLine(@intFromFloat(this.vertices[0][0]), @intFromFloat(this.vertices[0][1]), @intFromFloat(this.vertices[1][0]), @intFromFloat(this.vertices[1][1]), 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
        main.playdate.graphics.drawLine(@intFromFloat(this.vertices[1][0]), @intFromFloat(this.vertices[1][1]), @intFromFloat(this.vertices[2][0]), @intFromFloat(this.vertices[2][1]), 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
        main.playdate.graphics.drawLine(@intFromFloat(this.vertices[0][0]), @intFromFloat(this.vertices[0][1]), @intFromFloat(this.vertices[2][0]), @intFromFloat(this.vertices[2][1]), 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
    }
};

pub const Camera = struct {
    position: Vector3,
    rotation: f32,
    focal_length: f32,

    pub fn create(position: Vector3, rotation: f32, focal_length: f32) Camera {
        return .{
            .position = position,
            .rotation = rotation,
            .focal_length = focal_length,
        };
    }

    pub fn update(this: *Camera) void {
        _ = this;
    }

    pub fn controls(this: *Camera) void {
        var pushed: play.PDButtons = undefined;
        main.playdate.system.getButtonState(&pushed, null, null);
        var move = Vector3{ 0, 0, 0 };
        if (pushed & play.BUTTON_UP != 0) {
            move[2] += 1;
        }
        if (pushed & play.BUTTON_DOWN != 0) {
            move[2] -= 1;
        }
        if (pushed & play.BUTTON_LEFT != 0) {
            move[0] -= 1;
        }
        if (pushed & play.BUTTON_RIGHT != 0) {
            move[0] += 1;
        }
        this.position += move;
        this.rotation = main.playdate.system.getCrankAngle();
    }

    fn worldSpaceToCamSpace(this: Camera, position: Vector3) ?Vector3 {
        const _camAngle = std.math.degreesToRadians(this.rotation);
        const _pos = position - this.position;
        return Vector3{ _pos[0] * @cos(_camAngle) - _pos[2] * @sin(_camAngle), _pos[1], _pos[2] * @cos(_camAngle) + _pos[0] * @sin(_camAngle) };
    }

    fn pointInCullArea(this: Camera, point: Vector3) bool {
        const _camAngle = std.math.degreesToRadians(this.rotation);
        // TODO: WHY IS THIS NOT COS SIN? FIX
        const cam2dDirection = Vector2{ @sin(_camAngle), @cos(_camAngle) };
        var relativePoint = point - this.position;
        relativePoint = vec3_normalize(relativePoint);
        const relativePoint2D = Vector2{ relativePoint[0], relativePoint[2] };

        return vec2_dot_product(cam2dDirection, relativePoint2D) >= 0.5;
    }

    pub fn projectPoint(this: Camera, point: Vector3) ?Vector2_i32 {
        var camSpacePoint = this.worldSpaceToCamSpace(point) orelse return null;

        // approximating lower values
        if (camSpacePoint[2] <= 0.01) {
            camSpacePoint[2] = 0.01;
        }

        const scale_factor = this.focal_length / camSpacePoint[2];

        return Vector2_i32{ @intFromFloat(camSpacePoint[0] * scale_factor + 200), @intFromFloat(-camSpacePoint[1] * scale_factor + 120) };
    }

    pub fn drawTriangle(this: Camera, triangle: Triangle) void {
        // We check for each projection to potentially skip some calculations
        const pA = this.projectPoint(triangle.vertices[0]);
        if (pA == null) {
            return;
        }
        const pB = this.projectPoint(triangle.vertices[1]);
        if (pB == null) {
            return;
        }
        const pC = this.projectPoint(triangle.vertices[2]);
        if (pC == null) {
            return;
        }
        var i: usize = 0;
        for(triangle.vertices) |vertex| {
            if(!this.pointInCullArea(vertex)) i += 1;
        }
        if(i == 3) return;
        ir_trianglesCounter += 1;
        main.playdate.graphics.drawLine(pA.?[0], pA.?[1], pB.?[0], pB.?[1], 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
        main.playdate.graphics.drawLine(pB.?[0], pB.?[1], pC.?[0], pC.?[1], 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
        main.playdate.graphics.drawLine(pA.?[0], pA.?[1], pC.?[0], pC.?[1], 1, @intFromEnum(play.LCDSolidColor.ColorBlack));
    }
};

var memory: std.mem.Allocator = undefined;
pub var vertices: std.ArrayList(Vector3) = undefined;

pub fn initVertices() void {
    memory = mem.playdate_allocator.Allocator(main.playdate);
    vertices = std.ArrayList(Vector3).init(memory);
}

pub fn pushVertex(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    const x = main.playdate.lua.getArgFloat(1);
    const y = main.playdate.lua.getArgFloat(2);
    const z = main.playdate.lua.getArgFloat(3);
    vertices.append(Vector3{ x, y, z }) catch return 0;
    return 0;
}

pub fn drawVertices(state: ?*play.LuaState) callconv(.C) c_int {
    _ = state;
    var i: usize = 0;
    while (i <= vertices.items.len - 3) : (i += 3) {
        main.camera.drawTriangle(Triangle.create(vertices.items[i], vertices.items[i + 1], vertices.items[i + 2]));
    }
    return 0;
}
