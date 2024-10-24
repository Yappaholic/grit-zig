const std = @import("std");
const fs = std.fs;
const ArrayList = std.ArrayList;

const Config = struct {
    db: []u8,
    config: []u8,
};

const ConfigError = error{StringError};
pub fn set_db_path(buffer: []const u8, list: anytype) ![]u8 {
    try list.appendSlice("/home/savvy/db/");
    try list.appendSlice(buffer);
    try list.appendSlice("/");
    const result = list.toOwnedSlice();
    return result;
}

pub fn set_config_name(buffer: []const u8, list: anytype) ![]u8 {
    try list.appendSlice(buffer);
    try list.appendSlice(".grit");
    const result = list.toOwnedSlice();
    return result;
}

pub fn read_config(package_name: [*:0]u8) !void {
    // Initiate allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // Initiate Array list
    var list = ArrayList(u8).init(allocator);
    const list_ptr = &list;
    // Get DataBase path and config name
    const package_name_slice: []const u8 = std.mem.span(package_name);
    const db = try set_db_path(package_name_slice, list_ptr);
    const config_name = try set_config_name(package_name_slice, list_ptr);

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

    while (iter.next()) |line| {
        try stdout.writeAll(line);
        _ = try stdout.write("\n");
    }
}
