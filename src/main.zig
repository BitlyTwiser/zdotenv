const std = @import("std");
const zdotenv = @import("lib.zig").Zdotenv;
const assert = std.debug.assert;

///  The binary main is used for testing the package to showcase the API
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var dotenv = try zdotenv.init(allocator);
    try dotenv.load();

    const env_map = try std.process.getEnvMap(allocator);
    const pass = env_map.get("PASSWORD_ENV") orelse "foobar";

    std.debug.print("{s}", .{pass});

    assert(std.mem.eql(u8, pass, "I AM ALIVE!!"));
}
