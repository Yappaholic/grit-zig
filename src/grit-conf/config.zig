const std = @import("std");
const check = @import("check.zig");
const fs = std.fs;

pub fn create_script(config_path: []const u8) !void {
    const pa = std.heap.page_allocator;
    // Get config inputs
    const config = try check.read_config(config_path);
    const script = try std.fmt.allocPrint(pa,
    \\function gfetch {{
    \\git clone {s} ~/hello
    \\}}
    \\
    \\{s}
    \\
    \\{s}
    \\
    \\{s}
    \\
    \\function all {{
    \\ gfetch
    \\ gprepare
    \\ gbuild
    \\ ginstall
    \\}}
    \\all
    \\
    , .{config.Specs.Source.?, config.Prepare.?, config.Build.?, config.Install.?});
    std.debug.print("{s}", .{script});

    const file = try fs.cwd().createFile("script", .{.read = true});
    defer file.close();

    try file.writeAll(script);
    try file.chmod(777);
}
