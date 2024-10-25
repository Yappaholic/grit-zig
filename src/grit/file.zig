const std = @import("std");
const fs = std.fs;
const ArrayList = std.ArrayList;

const Config = struct {
    Name: []const u8,
    Description: []const u8,
    Source: []const u8,
};

// Create db path in comptime
pub fn set_db_path(buffer: []const u8, list: anytype) ![]u8 {
    try list.appendSlice("/home/savvy/db/");
    try list.appendSlice(buffer);
    try list.appendSlice("/");
    const result = list.toOwnedSlice();
    return result;
}

// Create package file name in comptime
pub fn set_config_name(buffer: []const u8, list: anytype) ![]u8 {
    try list.appendSlice(buffer);
    try list.appendSlice(".grit");
    const result = list.toOwnedSlice();
    return result;
}

// Get info from package config
pub fn get_text(line: []const u8) []const u8 {
    var arr = std.mem.splitAny(u8, line, "\"");
    _ = arr.next();
    const res = arr.next().?;
    return res;
}

// Read package config
pub fn read_config(package: [*:0]u8) !void {
    // Turn package name into SANE string slice
    const package_name: []const u8 = std.mem.span(package);
    // Initiate allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // Initiate Array list
    var list = ArrayList(u8).init(allocator);
    const list_ptr = &list;
    // Get DataBase path and config name
    const db = try set_db_path(package_name, list_ptr);
    const config_name = try set_config_name(package_name, list_ptr);

    // Move to db directory
    var db_dir = try fs.openDirAbsolute(db, .{});
    defer db_dir.close();

    // Open config
    const config_file = try db_dir.openFile(config_name, .{ .mode = .read_only });
    defer config_file.close();

    // Allocate config text to buffer
    const config_buffer = try config_file.readToEndAlloc(allocator, 500);
    defer allocator.free(config_buffer);

    // Print config text
    var iter = std.mem.splitAny(u8, config_buffer, "\n");
    const stdout = std.io.getStdOut();
    defer stdout.close();

    // Generate config and print text
    var config = Config{ .Name = "", .Description = "", .Source = "" };
    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, line, "NAME")) {
            config.Name = get_text(line);
        } else if (std.mem.startsWith(u8, line, "DESCRIPTION")) {
            config.Description = get_text(line);
        } else if (std.mem.startsWith(u8, line, "SRC")) {
            config.Source = get_text(line);
        }
    }

    try stdout.writer().print(
        \\Name: {s}
        \\Description: {s}
        \\Source: {s}
        \\
    , .{ config.Name, config.Description, config.Source });
}
