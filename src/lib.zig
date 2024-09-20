// Lib.zig is the package interface where all modules are collected for export

pub const parser = @import("parser.zig");
pub const Parser = parser.Parser;

pub const zdotenv = @import("dotenv.zig");
pub const Zdotenv = zdotenv.Zdotenv;
