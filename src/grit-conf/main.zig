const std = @import("std");
const file = @import("file.zig");
const print = std.debug.print;

pub fn main() !void {
  const args = std.os.argv;

  if (args.len == 1) {
    print(
      \\Grit-conf: check if package config is valid
      \\
      \\Usage: grit-conf [config path]
      \\Config path must be absolute path
      \\
    ,.{});
  }else if (args.len == 2) {
    const config_path = std.mem.span(args[1]);
    file.read_config(config_path) catch |err| {
        if (err == error.BadFormat) {
            std.debug.print("{any}: Missing parentheses, check your config\n", .{err});
        }else if (err == error.MissingInput) {
            std.debug.print("{any}: Missing build input, check your config\n", .{err});
        }
    };
  }
}
