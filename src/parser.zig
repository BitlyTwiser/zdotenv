const std = @import("std");

/// Parser is a simpel .env parser to extract the Key & Value from the given input (env) file.
pub const Parser = struct {
    env_values: std.StringHashMap([]const u8), // Store all Key Values in string hashmap for quick iteration and storage in local child process env
    allocator: std.mem.Allocator,
    file: std.fs.File,
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, file: std.fs.File) !Self {
        return Self{ .allocator = allocator, .file = file, .env_values = std.StringHashMap([]const u8).init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        var values = self.env_values;
        values.clearAndFree();
    }
    // parse is a simple parsing function. Its simple on purpose, this process should not be lofty or complex. No AST's or complex symbol resolution. Just take the Key and Value from the K=V from an .env and avoid comments (#)
    pub fn parse(self: *Self) !std.StringHashMap([]const u8) {
        var buf: [1024 * 2 * 2]u8 = undefined;
        while (try self.file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Skip comments (i.e. #)
            if (std.mem.startsWith(u8, line, "#")) continue;
            if (std.mem.eql(u8, line, "")) continue;

            var split_iter = std.mem.split(u8, line, "=");

            var key = split_iter.next() orelse "";
            var value = split_iter.next() orelse "";

            key = std.mem.trim(u8, key, "\"");
            value = std.mem.trim(u8, value, "\"");

            // One must dupe to avoid pointer issues in map
            const d_key = try self.allocator.dupe(u8, key);
            const d_val = try self.allocator.dupe(u8, value);

            try self.env_values.put(d_key, d_val);
        }

        return self.env_values;
    }
};
