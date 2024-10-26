const std = @import("std");
const file = @import("check.zig");
const script = @import("config.zig");
const print = std.debug.print;
const eql = std.mem.eql;

pub fn options(args: [][*:0]const u8) !void {
	const call = std.mem.span(args[1]);
    if (eql(u8, call, "check") == true){
        const config_path = std.mem.span(args[2]);
        _ = file.read_config(config_path) catch |err| {
            if (err == error.BadFormat) {
                print("{any}: Missing parentheses, check your config\n", .{err});
            }else if (err == error.MissingInput) {
                print("{any}: Missing build input, check your config\n", .{err});
            }else {
                print("{any}", .{err});
            }
        };
    } else if (eql(u8, call, "build")) {
        const config_path = std.mem.span(args[2]);
        try script.create_script(config_path);
    }
}
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
  } else if (args.len == 2) {
      const call = std.mem.span(args[1]);
      if (eql(u8, call, "check")) {
          print(
              \\grit-conf check: [config path]
              \\
              \\Check if config is correct
              \\
              \\Exits with success if config is valid, error otherwise
              \\
          , .{});
      } else if (eql(u8, call, "build")) {
          print(
              \\grit-conf build: [config path]
              \\
              \\Build script to install package
              \\
          , .{});
      }
  } else if (args.len > 2) {
      try options(args);
  }
}
