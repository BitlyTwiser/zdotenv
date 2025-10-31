const std = @import("std");

pub fn build(b: *std.Build) void {
    // We build a binary for testing and the actual module for use
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const main_module =
        b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

    const exe = b.addExecutable(.{ .name = "zdotenv", .root_module = main_module });

    // For setting env vars using C
    exe.linkLibC();
    b.installArtifact(exe);

    // Module setup
    _ = b.addModule("zdotenv", .{ .root_source_file = b.path("src/main.zig") });
    var lib_tests = b.addTest(.{
        .root_module = main_module,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_tests.step);

    // Export the library module
    _ = b.addModule("zdotenv", .{
        .root_source_file = b.path("src/lib.zig"),
    });
}
