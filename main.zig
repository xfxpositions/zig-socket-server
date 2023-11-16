const std = @import("std");
const math = std.math;
const Mutex = std.Thread.Mutex;
fn task(n: *Mutex, t_id: u8) void {
    n.lock();
    defer n.unlock();
    var guard = std.Thread
        .std.debug.print("n is {}\n", .{n.*});
    _ = guard;
    std.debug.print("thread_id is {}\n", .{t_id});
}

pub fn main() !void {
    var shared_value = Mutex{};

    var pool: std.Thread.Pool = undefined;
    _ = try pool.init(.{ .allocator = std.heap.page_allocator });
    defer pool.deinit();
    try pool.spawn(task, .{ &shared_value, @as(u8, 102) });
    try pool.spawn(task, .{ &shared_value, @as(u8, 103) });
}
