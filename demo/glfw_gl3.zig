const std = @import("std");
const Shader = @import("common/shader.zig").Shader;
const Font = @import("common/font.zig").Font;
usingnamespace @import("ui_builder");
usingnamespace @import("zalgebra");

const glfw = @import("common/c.zig").glfw;
usingnamespace @import("common/c.zig").gl;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const panic = std.debug.panic;
const print = std.debug.print;

const WINDOW_WIDTH: i32 = 1200;
const WINDOW_HEIGHT: i32 = 800;
const WINDOW_DPI: i32 = 2;
const WINDOW_NAME = "UI Builder";

// Render object identifier.
pub const RenderObject = struct {
    vao: u32,
    vbo: u32,
    ebo: ?u32,
    triangle_count: i32,
    indice_type: enum { u16, u32 },
    // textures: ArrayList(u32),
};

pub fn calc_text_size(font: *Font, size: f32, text: []const u8) f32 {
    const ratio_size = size / font.size;
    var text_cursor: f32 = 0;

    for (text) |letter, i| {
        const c = font.characters.get(&[_]u8{letter}).?;
        const x = text_cursor - (c.origin_x * ratio_size);
        text_cursor += c.advance * ratio_size;
    }

    return text_cursor;
}

pub fn main() !void {
    if (glfw.glfwInit() == glfw.GL_FALSE) {
        panic("Failed to intialize GLFW.\n", .{});
    }

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 2);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, glfw.GL_TRUE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw.glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_NAME, null, null) orelse {
        panic("Unable to create window.\n", .{});
    };

    glfw.glfwMakeContextCurrent(window);
    glfw.glEnable(glfw.GL_DEPTH_TEST);

    glfw.glfwSwapBuffers(window);
    glfw.glfwPollEvents();

    defer glfw.glfwDestroyWindow(window);
    defer glfw.glfwTerminate();

    var helvetica = try Font.init("helvetica");
    defer helvetica.deinit();


    var render_obj = blk: {
        var r: RenderObject = undefined;

        glGenVertexArrays(1, &r.vao);
        glGenBuffers(1, &r.vbo);

        r.ebo = 0;
        glGenBuffers(1, &r.ebo.?);

        glBindVertexArray(r.vao);
        glBindBuffer(GL_ARRAY_BUFFER, r.vbo);

        const stride = 8 * @sizeOf(f32);

        // Vertex.
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, null);
        glEnableVertexAttribArray(0);

        // UV.
        const uv_ptr = @intToPtr(*c_void, 2 * @sizeOf(f32));
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride, uv_ptr);
        glEnableVertexAttribArray(1);

        // Color.
        const color_ptr = @intToPtr(*c_void, 4 * @sizeOf(f32));
        glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, stride, color_ptr);
        glEnableVertexAttribArray(2);

        glBindVertexArray(0);

        break :blk r;
    };

    const quad_vert = @embedFile("assets/shaders/quad.vert");
    const quad_frag = @embedFile("assets/shaders/quad.fs");
    const text_vert = @embedFile("assets/shaders/text.vert");
    const text_frag = @embedFile("assets/shaders/text.fs");

    const quad_shader = try Shader.create("quad", quad_vert, quad_frag);
    const text_shader = try Shader.create("text", text_vert, text_frag);

    var font_size: f32 = 16;

    var ui = try Interface(Font).init(.{
        .allocator = &gpa.allocator,
        .font = &helvetica,
        .font_size = font_size,
        .calc_text_size = calc_text_size,
    }, .{});

    var should_close = false;
    var counter: i32 = 0;

    while (!should_close) {
        glfw.glfwPollEvents();
        glfw.glClear(glfw.GL_COLOR_BUFFER_BIT | glfw.GL_DEPTH_BUFFER_BIT);

        should_close = glfw.glfwWindowShouldClose(window) == glfw.GL_TRUE or
            glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) == glfw.GLFW_PRESS;

        // Build the interface.
        ui.reset();
        var cursor_x: f64 = undefined;
        var cursor_y: f64 = undefined;
        glfw.glfwGetCursorPos(window, &cursor_x, &cursor_y);
        ui.send_cursor_position(
            @floatCast(f32, cursor_x),
            @floatCast(f32, cursor_y),
        );
        const mouse_left_down = glfw.glfwGetMouseButton(window, 0) == 1;
        const mouse_right_down = glfw.glfwGetMouseButton(window, 1) == 1;
        try ui.send_input_key(.Cursor, mouse_left_down);

        if (ui.panel("Debug Panel", 25, 25, 400, 700)) {
            // try ui.label_alloc("counter: {}\n", .{counter}, .Left);
            if(ui.button("Kill this program!")) should_close = true;
            if(ui.button("Click to incremente the counter")) counter += 1;
        }

        // Send shapes to GPU.
        {
            const data = ui.process_ui();
            var vertices = data.vertices;
            var indices = data.indices;
            glBindVertexArray(render_obj.vao);
            glBindBuffer(GL_ARRAY_BUFFER, render_obj.vbo);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_obj.ebo.?);

            const vertex_size = @intCast(c_long, vertices.len * @sizeOf(f32));
            const element_size = @intCast(c_uint, indices.len * @sizeOf(u32));
            const max_vertex_size: c_long = 512 * 1024;
            const max_element_size: c_long = 256 * 1024;

            std.debug.assert(vertex_size <= max_vertex_size);

            glBufferData(GL_ARRAY_BUFFER, max_vertex_size, null, GL_STREAM_DRAW);
            glBufferData(GL_ARRAY_BUFFER, vertex_size, vertices.ptr, GL_STREAM_DRAW);

            glBufferData(GL_ELEMENT_ARRAY_BUFFER, max_element_size, null, GL_STREAM_DRAW);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, element_size, indices.ptr, GL_STREAM_DRAW);

            render_obj.triangle_count = @intCast(i32, indices.len);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindVertexArray(0);
        }

        // Draw
        {
            glDisable(GL_DEPTH_TEST);
            glEnable(GL_SCISSOR_TEST);
            defer glDisable(GL_SCISSOR_TEST);

            for (ui.draw()) |d, i| {

                // Draw shapes
                {
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                    glUseProgram(quad_shader.program_id);
                    const frame_width = @intToFloat(f32, WINDOW_WIDTH);
                    const frame_height = @intToFloat(f32, WINDOW_HEIGHT);
                    const proj = orthographic(0, frame_width, frame_height, 0, -1, 1);

                    quad_shader.setMat4("projection", &proj);

                    glBindVertexArray(render_obj.vao);

                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_obj.ebo.?);
                    glDrawElements(
                        GL_TRIANGLES,
                        @intCast(c_int, d.vertex_count),
                        GL_UNSIGNED_INT,
                        @intToPtr(*allowzero c_void, d.offset * @sizeOf(u32)),
                    );

                    glBindVertexArray(0);
                    glDisable(GL_BLEND);
                }


                for (d.texts) |text| {
                    // TODO: Should draw text...
                }
            }
        }

        glfw.glfwSwapBuffers(window);
    }
}
