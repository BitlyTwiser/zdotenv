// Lib.zig is the package interface where all modules are collected for export

const parser = @import("parser.zig");
pub const Parser = parser.Parser;

const zdotenv = @import("dotenv.zig");
pub const Zdotenv = zdotenv.Zdotenv;
