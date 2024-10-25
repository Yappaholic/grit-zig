const std = @import("std");
const file = @import("file.zig");
const print = std.debug.print;

pub fn main() !void {
  const args = std.os.argv;

  if (args.len == 1) {
    print(
      \\Grit-conf: check if package config is valid
      \\
    ,.{});
  }else if (args.len == 2) {
    const config_path = std.mem.span(args[1]);
    try file.read_config(config_path);
  }
}
