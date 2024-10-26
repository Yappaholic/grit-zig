const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{ .default_target = .{ .cpu_model = .native, .abi = .gnu } });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const grit = b.addExecutable(.{
        .name = "grit",
        .root_source_file = b.path("src/grit/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .use_llvm = true,
        .single_threaded = false,
    });

    const grit_conf = b.addExecutable(.{
      	.name = "grit-conf",
      	.root_source_file = b.path("src/grit-conf/main.zig"),
      	.target = target,
      	.optimize = optimize,
      	.strip = false,
      	.use_llvm = true,
      	.single_threaded = false,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(grit);
    b.installArtifact(grit_conf);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const grit_cmd = b.addRunArtifact(grit);
    const grit_conf_cmd = b.addRunArtifact(grit_conf);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    grit_cmd.step.dependOn(b.getInstallStep());
    grit_conf_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        grit_cmd.addArgs(args);
        grit_conf_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const grit_step = b.step("grit", "Run package manager");
    const grit_conf_step = b.step("grit-conf", "Run config validation tool");
    grit_step.dependOn(&grit_cmd.step);
    grit_conf_step.dependOn(&grit_conf_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/grit/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
