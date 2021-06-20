const std = @import("std");
const Shader = @import("common/shader.zig").Shader;
const Font = @import("common/font.zig").Font;

const c = @import("common/c.zig").glfw;

const panic = std.debug.panic;
const print = std.debug.print;

const WINDOW_WIDTH: i32 = 1200;
const WINDOW_HEIGHT: i32 = 800;
const WINDOW_DPI: i32 = 2;
const WINDOW_NAME = "UI Builder";

pub fn main() !void {
    if (c.glfwInit() == c.GL_FALSE) {
        panic("Failed to intialize GLFW.\n", .{});
    }

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 2);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_NAME, null, null) orelse {
        panic("Unable to create window.\n", .{});
    };

    c.glfwMakeContextCurrent(window);
    c.glEnable(c.GL_DEPTH_TEST);

    c.glfwSwapBuffers(window);
    c.glfwPollEvents();

    defer c.glfwDestroyWindow(window);
    defer c.glfwTerminate();

    const quad_vert = @embedFile("assets/shaders/quad.vert");
    const quad_frag = @embedFile("assets/shaders/quad.fs");
    const text_vert = @embedFile("assets/shaders/text.vert");
    const text_frag = @embedFile("assets/shaders/text.fs");

    const quad_shader = try Shader.create("quad", quad_vert, quad_frag);
    const text_shader = try Shader.create("text", text_vert, text_frag);

    var delta_time: f64 = 0.0;
    var last_frame: f64 = 0.0;

    var shouldClose = false;

    while (!shouldClose) {
        c.glfwPollEvents();
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        shouldClose = c.glfwWindowShouldClose(window) == c.GL_TRUE or
            c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS;

        // Compute times between frames (delta time).
        {
            var current_time = c.glfwGetTime();
            delta_time = current_time - last_frame;
            last_frame = current_time;
        }

        // c.glUseProgram(shader.program_id);
        // shader.setMat4("view", &view);

        c.glfwSwapBuffers(window);
    }
}
