const std = @import("std");
const pdapi = @import("playdate_api_definitions.zig");

const This = @This();
const vtable: std.mem.Allocator.VTable = .{
    .alloc = alloc,
    .resize = resize,
    .free = free,
};
pub fn Allocator(playdate: *pdapi.PlaydateAPI) std.mem.Allocator {

    return .{
        .ptr = playdate,
        .vtable = &This.vtable
    };
}

fn alloc(ctx: *anyopaque, n: usize, log2_ptr_align: u8, ra: usize) ?[*]u8 {
    _ = log2_ptr_align;
    _ = ra;
    const playdate: *pdapi.PlaydateAPI = @alignCast(@ptrCast(ctx));
    return @alignCast(@ptrCast(playdate.system.realloc(null, n)));
}

fn resize(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, new_len: usize, ret_addr: usize) bool {
    _ = ctx;
    _ = buf;
    _ = log2_buf_align;
    _ = new_len;
    _ = ret_addr;
    return false;
}

fn free(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, ret_addr: usize) void {
    _ = log2_buf_align;
    _ = ret_addr;
    const playdate: *pdapi.PlaydateAPI = @alignCast(@ptrCast(ctx));
    _ = playdate.system.realloc(@alignCast(@ptrCast(buf)), 0);
}