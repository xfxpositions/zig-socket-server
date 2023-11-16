// A simple illustration of a stream server that handles each client with a thread pool, and
// if any worker returns an error then it prints out the errorReturnTrace.
//
// Untested.
//
// Written by Tetralux, 2023-11-15.

const std = @import("std");

const Data = struct {
    ally: std.mem.Allocator,
    conn: std.net.StreamServer.Connection,

    fn create(ally: std.mem.Allocator, client: std.net.StreamServer.Connection) !*Data {
        const data = try ally.create(Data);
        data.* = .{
            .ally = ally,
            .conn = client,
        };
        return data;
    }

    fn destroy(self: *Data) void {
        defer self.ally.destroy(self);
        self.* = undefined; // useful for debugging
    }
};

fn worker_proc(data: *Data) void {
    defer data.destroy();
    actual_worker_proc(data) catch |e| {
        // TODO: Do this printing and stack trace dumping under a lock that all workers have,
        // so that multiple workers that error do not stamp over each other's printouts.
        std.debug.print("Thread exited with error: {s}\n", .{@errorName(e)});
        if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
        return;
    };
}

fn actual_worker_proc(data: *Data) !void {
    // This arena can be used for temporary allocations in this worker proc.
    var arena_state = std.heap.ArenaAllocator.init(data.ally);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    _ = arena;
    // Do something useful here
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = ally, .n_jobs = null });
    defer pool.deinit();

    var socket = std.net.StreamServer.init(.{
        .reuse_address = true, // useful if you crash
    });
    const listen_address = try std.net.Address.parseIp("127.0.0.1", 9999);
    try socket.listen(listen_address);
    defer socket.deinit();

    while (true) {
        const client = try socket.accept();
        const data = try Data.create(ally, client);
        try pool.spawn(worker_proc, .{data});
    }
}
