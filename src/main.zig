const std = @import("std");
const file = @import("file.zig");
const fs = std.fs;
var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};

pub fn main() !void {
    const args = std.os.argv;
    if (args.len > 1) {
        const package_name = args[1];
        std.debug.print("Arg invoked {s}\n", .{package_name});
        try file.read_config(package_name);
    } else {
        std.debug.print(
            \\grit: Cave Linux package manager
            \\--------------------------------
            \\i: Install a package
            \\u: Update a package
            \\q: Search for a package in repository
            \\rm: Remove installed package\n
        , .{});
    }
}
