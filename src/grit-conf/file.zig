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
  MissingInput,
};

var config_specs = Config{.Name = null, .Description = null, .Source = null};
// Get resulting strings
var prepare = fifo.Queue([]const u8).init();
var build = fifo.Queue([]const u8).init();
var install = fifo.Queue([]const u8).init();
//Get parentheses queues
var prepare_q = fifo.Queue(u8).init();
var build_q = fifo.Queue(u8).init();
var install_q = fifo.Queue(u8).init();


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

pub fn build_input_function(config_line: []const u8, queue: []const u8) !void{
    // Parentheses to check
    const open = '{';
    const closed = '}';

    // Pointers to original queues
    var input_ptr: *fifo.Queue([]const u8)  = undefined;
    var queue_ptr: *fifo.Queue(u8)  = undefined;

    // Set queues to work with
    if (std.mem.eql(u8, queue, "prepare")) {
         input_ptr = &prepare;
         queue_ptr = &prepare_q;
    } else if(std.mem.eql(u8, queue, "build")) {
         input_ptr = &build;
         queue_ptr = &build_q;
    } else if (std.mem.eql(u8, queue, "install")) {
         input_ptr = &install;
         queue_ptr = &install_q;
    }

    // Edit parentheses queues
    for (config_line) |i| {
        if (i == open ) {
            queue_ptr.push(i);
        } else if (i == closed) {
            try queue_ptr.pop();
        }
    }

    // If input function is not closed, push slice to stack
    if (input_ptr.opened() == true) {
        input_ptr.push(config_line);
    }
}

pub fn check_config_inputs(config_line: []const u8) !void {
    // If start is known, move to another function
    if (prepare.stack[0] != null and prepare_q.empty() == false) {
        try build_input_function(config_line, "prepare");
        return;
    } else if (build.stack[0] != null and build_q.empty() == false) {
        try build_input_function(config_line, "build");
        return;
    } else if (install.stack[0] != null and install_q.empty() == false) {
        try build_input_function(config_line, "install");
        return;
    }

    // Check input start
    if (std.mem.startsWith(u8, config_line, "gprepare") and std.mem.endsWith(u8, config_line, "{" )){
        prepare.push(config_line);
        prepare_q.push('{');
        return;
    } else if (std.mem.startsWith(u8, config_line, "gbuild") and std.mem.endsWith(u8, config_line, "{")){
        build.push(config_line);
        build_q.push('{');
        return;
    } else if (std.mem.startsWith(u8, config_line, "ginstall") and std.mem.endsWith(u8, config_line, "{")){
        install.push(config_line);
        install_q.push('{');
        return;
    }
}

pub fn test_inputs() !void {
    // If some input functions are not closed, return BadFormat error
    if (prepare_q.empty() == false
    	or build_q.empty() == false
    	or install_q.empty() == false) {
        return error.BadFormat;
    }
    const eql = std.mem.eql;
    if (eql(u8,try prepare.concat_result(), "")) {
        return error.MissingInput;
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
      try check_config_inputs(line);
    }

    test_inputs() catch |err| return err;

    // Generate final input strings
    const prepare_config = try prepare.concat_result();
    const build_config = try build.concat_result();
    const install_config = try install.concat_result();

    std.debug.print(
        \\Prepare steps:
        \\{s}
        \\Build steps:
        \\{s}
        \\Install steps:
        \\{s}
        \\
    , .{prepare_config, build_config, install_config});
    // try stdout.writer().print(
    // \\ Name: {s}
    // \\ Description: {s}
    // \\ Source: {s}
    // \\
    // , .{config_specs.Name.?, config_specs.Description.?, config_specs.Source.?});

}
