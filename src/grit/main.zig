const std = @import("std");
const file = @import("file.zig");
const docs = @import("docs.zig");

const Calls = enum { Install, Update, Query, Remove };

// Return code based on invoke call
pub fn generate_call_code(call: []const u8) Calls {
    const call_name = call[0];
    if (call_name == 'i') {
        return Calls.Install;
    } else if (call_name == 'u') {
        return Calls.Update;
    } else if (call_name == 'r') {
        return Calls.Remove;
    } else if (call_name == 'q') {
        return Calls.Query;
    } else unreachable;
}

pub fn main() !void {
    const args = std.os.argv;
    if (args.len > 1) {
        const call: []const u8 = std.mem.span(args[1]);
        std.debug.print("Args used {s}\n", .{args[1..]});
        const call_code = generate_call_code(call);

        // Switch states for different invoke calls
        switch (call_code) {
            Calls.Install => {
                if (args.len > 2) {
                    try file.read_config(args[2]);
                } else {
                    docs.install_docs();
                }
            },
            Calls.Update => {
                docs.update_docs();
            },
            Calls.Query => {
                if (args.len > 2) {
                    try file.read_config(args[2]);
                } else {
                    docs.query_docs();
                }
            },
            Calls.Remove => {
                docs.remove_docs();
            },
        }
    } else {
        // Default message
        docs.print_ascii();
        std.debug.print(
            \\
            \\Grit: Speedy Cave Linux package manager
            \\--------------------------------------
            \\
            \\Usage: grit [option] [flags] [package]
            \\
            \\Options:
            \\
            \\i: Install a package
            \\u: Update a package
            \\q: Search for a package in repository
            \\r: Remove installed package
            \\
        , .{});
    }
}
