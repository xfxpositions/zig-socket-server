const std = @import("std");
const net = std.net;
const sleep = std.time.sleep;

var addr = net.Address.initIp4(.{ 127, 0, 0, 1 }, 5000);

const ClientData = struct {
    allocator: std.mem.Allocator,
    client: std.net.StreamServer.Connection,
    fn create(allocator: std.mem.Allocator, client: std.net.StreamServer.Connection) !*ClientData {
        const data = try allocator.create(ClientData);
        data.allocator = allocator;
        data.client = client;
        return data;
    }
    fn destroy(self: *ClientData) void {
        self.allocator.destroy(self);
        // self.* = undefined;
    }
};

fn handler_worker(client: *ClientData) void {
    defer client.destroy();
    var stream: std.net.Stream = client.client.stream;
    var address: std.net.Address = client.client.address;

    // handle_stream(stream, address) catch |e| {
    //     std.debug.print("Thread exited with error: {s}\n", .{@errorName(e)});
    //     if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
    // };
    handle_stream(stream, address);
}

fn handle_stream(stream: std.net.Stream, adress: std.net.Address) void {
    // Print client addr
    std.debug.print("Client addr is {any}\n", .{adress});

    var buffer: [256]u8 = undefined;

    _ = stream.read(&buffer) catch |err| blk: {
        std.debug.print("some error happened while reading the buffer {any}\n", .{err});
        break :blk;
    };

    // std.debug.print("request buffer is: {s}\n", .{buffer});

    const response = "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 11\n\nHello World";

    // Write response
    _ = stream.write(response) catch unreachable;
}

fn returns_no_error(stream: *net.Stream) void {
    _ = stream;
    std.debug.print("zigzog\n", .{});
}

fn print_pool(pool: *std.Thread.Pool) void {
    while (true) {
        sleep(2 * 100_000_000);
        std.debug.print("pool status: {any}\n", .{pool.threads.len});
    }
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    // Create thread pool for clients
    var pool: std.Thread.Pool = undefined;

    _ = try pool.init(.{ .allocator = allocator }); // Init pool with page_allocator.
    defer pool.deinit(); // Deinit threads after main func.

    // _ = try pool.spawn(print_pool, .{&pool});

    const options = net.StreamServer.Options{ .reuse_address = true };
    var server = net.StreamServer.init(options);

    // Listening
    _ = try server.listen(addr);
    defer server.deinit();

    std.debug.print("Server is listening on: {any}\n", .{addr});
    while (true) {
        const client = try server.accept();

        const clientData = try ClientData.create(allocator, client);

        _ = try pool.spawn(handler_worker, .{clientData}); // Execute stream handler
    }
}

// const client_addr = client.address;

// Handle stream
// var stream = client.stream;
