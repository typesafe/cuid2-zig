const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cuid2Module = b.addModule("cuid2", .{
        .root_source_file = b.path("src/cuid2.zig"),
        .target = target,
        .optimize = optimize,
    });

    const compileUnitTests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const runUnitTests = b.addRunArtifact(compileUnitTests);

    const testStep = b.step("test", "Run unit tests");
    testStep.dependOn(&runUnitTests.step);

    // examples

    const compileExample = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("examples/default.zig"),
        .target = target,
        .optimize = optimize,
    });

    compileExample.root_module.addImport("cuid2", cuid2Module);

    const run = b.addRunArtifact(compileExample);

    const example = b.step("example", "Run default example");
    example.dependOn(&run.step);
}
