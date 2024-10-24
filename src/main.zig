const std = @import("std");
const file = @import("file.zig");
const docs = @import("docs.zig");
const fs = std.fs;
var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};

const Calls = enum { Install, Update, Query, Remove };
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
        std.debug.print("Call invoked {s}\n", .{call});
        const call_code = generate_call_code(call);
        switch (call_code) {
            Calls.Install => {
                docs.install_docs();
            },
            Calls.Update => {
                docs.update_docs();
            },
            Calls.Query => {
                docs.query_docs();
            },
            Calls.Remove => {
                docs.remove_docs();
            },
        }
    } else {
        std.debug.print(
            \\grit: Cave Linux package manager
            \\--------------------------------
            \\i: Install a package
            \\u: Update a package
            \\q: Search for a package in repository
            \\r: Remove installed package
            \\
        , .{});
    }
}
