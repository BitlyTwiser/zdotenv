const std = @import("std");
const zdotenv = @import("lib.zig");
const assert = std.debug.assert;

const file_location_type = union(enum) {
    relative,
    absolute,
};

const FileError = error{ FileNotFound, FileNotAbsolute, GenericError };

// Zig fails to have a native way to do this, so we call the setenv C library
extern fn setenv(name: [*:0]const u8, value: [*:0]const u8, overwrite: i32) c_int;

/// Zdontenv is the primary interface for loading env values
pub const Zdotenv = struct {
    allocator: std.mem.Allocator,
    file: ?std.fs.File,

    const env_path_relative = ".env";
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .file = null,
        };
    }

    pub fn deinit(self: Self) void {
        if (self.file) |file| {
            file.close();
        }
    }

    /// Load from a specific file on disk. Must be absolute path to a location on disk
    pub fn loadFromFile(self: *Self, filename: []const u8) !void {
        const file = self.readFile(filename, .absolute) catch |e| {
            switch (e) {
                error.FileNotFound => {
                    std.debug.print("file {s} does not exist. Please ensure the file exists and try again\n", .{filename});
                },
                error.FileNotAbsolute => {
                    std.debug.print("given filepath {s} is not absolute. Filepath must start with / and be an absolute path on Postix systems\n", .{filename});
                },
                else => {
                    std.debug.print("error opening env file. Please check the file exists and try again\n", .{});
                },
            }

            return;
        };
        // defer file.close();

        // Set file
        self.file = file;

        // This will load the data into the environment of the calling program
        try self.parseAndLoadEnv();
    }

    // Load will just load the default .env at location of the calling binary (i.e. expects a .env to be located next to main func call)
    pub fn load(self: *Self) !void {
        const file = self.readFile(env_path_relative, .relative) catch |e| {
            switch (e) {
                error.FileNotFound => {
                    std.debug.print(".env file does not exist in current directory. Please ensure the file exists and try again\n", .{});
                },
                else => {
                    std.debug.print("error opening .env file. Please check the file exists and try again\n", .{});
                },
            }

            return;
        };
        // defer file.close();

        //Set file
        self.file = file;

        // This will load the data into the environment of the calling program
        try self.parseAndLoadEnv();
    }

    fn parseAndLoadEnv(self: *Self) !void {
        var parser = try zdotenv.Parser.init(self.allocator, self.file.?);
        defer parser.deinit();

        var env_map = try parser.parse();

        var iter = env_map.iterator();

        while (iter.next()) |entry| {
            // Dupe strings with terminating zero for C
            const key_z = try self.allocator.dupeZ(u8, entry.key_ptr.*);
            const value_z = try self.allocator.dupeZ(u8, entry.value_ptr.*);
            if (setenv(key_z, value_z, 1) != 0) {
                std.debug.print("Failed to set env var\n", .{});
                return;
            }
        }
    }

    // Simple wrapper for opening a file passing the memory allocation to the caller. Caller MUST dealloc memory!
    fn readFile(self: *Self, filename: []const u8, typ: file_location_type) FileError!std.fs.File {
        _ = self;

        switch (typ) {
            .relative => {
                return std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch |e| {
                    switch (e) {
                        error.FileNotFound => {
                            return FileError.FileNotFound;
                        },
                        else => {
                            return FileError.GenericError;
                        },
                    }
                    return;
                };
            },
            .absolute => {
                if (!std.fs.path.isAbsolute(filename)) return error.FileNotAbsolute;
                return std.fs.openFileAbsolute(filename, .{ .mode = .read_only }) catch |e| {
                    switch (e) {
                        error.FileNotFound => {
                            return FileError.FileNotFound;
                        },
                        else => {
                            return FileError.GenericError;
                        },
                    }

                    return;
                };
            },
        }
    }
};

test "loading env from absolute file location" {
    var z = try Zdotenv.init(std.heap.page_allocator);
    // Must be an absolute path!
    try z.loadFromFile("/home/butterz/Documents/gitclones/zdotenv/test-env.env");
}

test "loading generic .env" {
    var z = try Zdotenv.init(std.heap.page_allocator);
    try z.load();
}

// --library c
test "parse env 1" {
    // use better allocators than this when not testing
    const allocator = std.heap.page_allocator;
    var z = try Zdotenv.init(allocator);
    try z.load();

    var parser = try zdotenv.Parser.init(
        allocator,
        z.file.?,
    );
    defer parser.deinit();

    var env_map_global = try std.process.getEnvMap(allocator);
    const password = env_map_global.get("PASSWORD_ENV") orelse "bad";

    assert(std.mem.eql(u8, password, "I AM ALIVE!!"));
}

// --library c
test "parse env 2" {
    // use better allocators than this when not testing
    const allocator = std.heap.page_allocator;

    var z = try Zdotenv.init(allocator);
    try z.loadFromFile("/home/butterz/Documents/gitclones/zdotenv/test-env.env");
    var parser = try zdotenv.Parser.init(allocator, z.file.?);
    defer parser.deinit();

    var env_map_global = try std.process.getEnvMap(allocator);
    const password = env_map_global.get("PASSWORD") orelse "bad";
    assert(std.mem.eql(u8, password, "asdasd123123AS@#$"));
}
