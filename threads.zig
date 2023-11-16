const std = @import("std");

fn task(taskid: u32) void {
    var sequence: u32 = 0;
    while (true) {
        std.time.sleep(std.time.ns_per_ms * 200);
        std.debug.print("task{} running, suquence of thread is {}\n", .{ taskid, sequence });
        sequence += 1;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var pool: std.Thread.Pool = undefined;
    defer pool.deinit();

    _ = try pool.init(.{ .allocator = allocator });

    var taskid: u32 = 0;

    for (@as(u32, 0)..@as(u32, 10)) |i| {
        taskid = @as(u32, @intCast(i));
        _ = try pool.spawn(task, .{taskid});
    }
}
