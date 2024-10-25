const std = @import("std");
const fifo = @import("fifo.zig");
const fs = std.fs;
const ArrayList = std.ArrayList;

const Config = struct {
    Name: ?[]const u8,
    Description: ?[]const u8,
    Source: ?[]const u8,

    pub fn check_config(self: *Config) bool {
        if (self.Name != null and self.Description != null and self.Source != null){
            return true;
        } else return false;
    }
};

const BuildInputs = struct {
  	Prepare: [][]const u8,
  	Build: [][]const u8,
  	Install: [][]const u8,
};

const ConfigError = error{
  NotFound,
  BadFormat,
  RepeatingValues,
};

var config_specs = Config{.Name = null, .Description = null, .Source = null};

pub fn check_config_specs(config_line: []const u8) !void {
    // Get package Name
    if (std.mem.startsWith( u8, config_line, "NAME")) {
      var iter = std.mem.splitAny(u8, config_line, "\"");
      _ = iter.next();
      if (config_specs.Name == null) {
        config_specs.Name = iter.next();
      } else return error.RepeatingValues;
    // Get package Description
    } else if (std.mem.startsWith( u8, config_line, "DESCRIPTION")) {
      var iter = std.mem.splitAny(u8, config_line, "\"");
      _ = iter.next();
      if (config_specs.Description == null) {
        config_specs.Description = iter.next();
      } else return error.RepeatingValues;
    // Get package Source
    } else if (std.mem.startsWith( u8, config_line, "SRC")) {
      var iter = std.mem.splitAny(u8, config_line, "\"");
      _ = iter.next();
      if (config_specs.Source == null) {
        config_specs.Source = iter.next();
      } else return error.RepeatingValues;
    }
}

// Read package config
pub fn read_config(config_path: []const u8) !void {
    // Initiate allocator
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gp.allocator();
    defer {
      const defer_state = gp.deinit();
      if (defer_state == .leak) {
        @panic("The program is leaking memory!");
      }
    }
    // Get queue
    // const build_stack: [10]?[]const u8 = undefined;
    // const prepare_stack: [10]?[]const u8 = undefined;
    // const install_stack: [10]?[]const u8 = undefined;

	// Open config
	const config = try fs.openFileAbsolute( config_path, .{.mode =  .read_only});
    // Allocate config text to buffer
    const config_buffer = try config.readToEndAlloc(allocator, 500);
    defer allocator.free(config_buffer);

    // Print config text
    var iter = std.mem.splitAny(u8, config_buffer, "\n");
    const stdout = std.io.getStdOut();
    defer stdout.close();

    // Generate config and print text
    while (iter.next()) |line| {
      const trimmed_line = std.mem.trim(u8, line, " ");
      check_config_specs(trimmed_line) catch |err| {
        if (err == error.RepeatingValues) {
          std.debug.print("{}: there are repeating values in the config\n", .{error.RepeatingValues});
          return;
        }
      };
    }
    try stdout.writer().print(
    \\ Name: {s}
    \\ Description: {s}
    \\ Source: {s}
    \\
    , .{config_specs.Name.?, config_specs.Description.?, config_specs.Source.?});

}
