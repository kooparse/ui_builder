const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    // Build step for the library
    {
        var tests = b.addTest("src/ui.zig");
        tests.setBuildMode(mode);

        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&tests.step);
    }

    // Build step for exemples.
    {
        var exe = b.addExecutable("glfw_opengl3", "demo/glfw_gl3.zig");
        exe.setBuildMode(mode);

        exe.addPackage(.{ .name = "ui_builder", .path = "src/ui.zig" });
        exe.addPackage(.{ .name = "zalgebra", .path = "demo/common/libs/zalgebra/src/main.zig" });

        switch (builtin.os.tag) {
            .macos => {
                exe.addFrameworkDir("/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks");
                exe.linkFramework("OpenGL");
            },
            else => {
                @panic("Don't know how to build on your system.");
            },
        }

        exe.addIncludeDir("demo/common/libs");
        exe.addCSourceFiles(
            &[_][]const u8{ "demo/common/libs/impl.c", }, 
            &[_][]const u8{ "-std=c99" },
        );

        exe.linkSystemLibrary("glfw");
        exe.linkSystemLibrary("epoxy");
        exe.install();

        const play = b.step("run", "Run demo");
        const run = exe.run();
        run.step.dependOn(b.getInstallStep());

        play.dependOn(&run.step);

    }
}
