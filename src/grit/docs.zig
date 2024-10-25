const std = @import("std");
const print = std.debug.print;

pub fn install_docs() void {
    print(
        \\grit i: [flags] [package]
        \\--------------------------------------
        \\Install specified package
        \\
        \\If package is not found in the repository, returns error
        \\
    , .{});
}

pub fn update_docs() void {
    print(
        \\grit u: [flags] [package]
        \\--------------------------------------
        \\Check for package updates
        \\
    , .{});
}

pub fn query_docs() void {
    print(
        \\grit q: [flags] [package]
        \\--------------------------------------
        \\Search for a package in the repository
        \\
        \\Flags:
        \\
        \\-i: Search already installed package
        \\
    , .{});
}

pub fn remove_docs() void {
    print(
        \\grit rm: [flags] [package]
        \\--------------------------------------
        \\Remove installed package
        \\
    , .{});
}
pub fn print_ascii() void {
    print(
        \\_________________ ________________       
        \\__  ____/___  __ \____  _/___  __/       
        \\_  / __  __  /_/ / __  /  __  /          
        \\/ /_/ /  _  _, _/ __/ /   _  /           
        \\\____/   /_/ |_|  /___/   /_/            
        \\
    , .{});
}
