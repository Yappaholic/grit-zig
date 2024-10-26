const std = @import("std");
const stack = @import("stack.zig");
const Queue = stack.Queue;
const fs = std.fs;
const ArrayList = std.ArrayList;

const Config = struct {
    Name: ?[]const u8 = null,
    Description: ?[]const u8 = null,
    Source: ?[]const u8 = null,
};

const BuildInputs = struct {
  	Prepare: ?[]const u8,
  	Build: ?[]const u8,
  	Install: ?[]const u8,
  	Specs: Config,
};

const ConfigError = error{
  NotFound,
  BadFormat,
  RepeatingValues,
  MissingInput,
};

// Get resulting strings
var prepare = Queue([]const u8).init();
var build = Queue([]const u8).init();
var install = Queue([]const u8).init();
//Get parentheses queues
var prepare_q = Queue(u8).init();
var build_q = Queue(u8).init();
var install_q = Queue(u8).init();
var result = BuildInputs{
	.Prepare = null,
	.Build = null,
	.Install = null,
	.Specs = Config{},
};

pub fn strip(string: []const u8, config_name: []const u8) ![]const u8 {
    const pa = std.heap.page_allocator;
    var new_string = ArrayList(u8).init(pa);
    var i = config_name.len + 1;
    while (i < string.len): (i += 1) {
        if (string[i] != '"') {
            try new_string.append(string[i]);
        }
    }
    return try new_string.toOwnedSlice();
}
pub fn check_config_specs(config_line: []const u8, config: *Config) !void {
    // Get package Name
    if (std.mem.startsWith( u8, config_line, "NAME") == true and config.Name == null) {
        result.Specs.Name = try strip(config_line, "NAME");
    // Get package Description
  	} else if (std.mem.startsWith( u8, config_line, "DESCRIPTION") == true and config.Description == null) {
          result.Specs.Description = try strip(config_line, "DESCRIPTION");
    // Get package Source
    } else if (std.mem.startsWith( u8, config_line, "SRC") == true and config.Source == null) {
        result.Specs.Source = try strip(config_line, "SRC");
  	}
    
}

pub fn build_input_function(config_line: []const u8, queue: []const u8) !void{
    // Parentheses to check
    const open = '{';
    const closed = '}';

    // Pointers to original queues
    var input_ptr: *Queue([]const u8)  = undefined;
    var queue_ptr: *Queue(u8)  = undefined;

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
    // If returned input is empty, return MissingInput error
    if (eql(u8,try prepare.concat_result(), "")) {
        return error.MissingInput;
    }
}

// Read package config
pub fn read_config(config_path: []const u8) !BuildInputs {
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

    // Split config text into lines
    var iter = std.mem.splitAny(u8, config_buffer, "\n");
    const stdout = std.io.getStdOut();
    defer stdout.close();

    // Generate config and print text
    while (iter.next()) |line| {
      const trimmed_line = std.mem.trim(u8, line, " ");
      check_config_specs(trimmed_line, &result.Specs) catch |err| {
        if (err == error.RepeatingValues) {
          std.debug.print("{}: there are repeating values in the config\n", .{error.RepeatingValues});
          break;
        }
      };
      try check_config_inputs(trimmed_line);
    }

    test_inputs() catch |err| return err;
    // Config
    result.Prepare = try prepare.concat_result();
    result.Build = try build.concat_result();
    result.Install = try install.concat_result();
    return result;
}
