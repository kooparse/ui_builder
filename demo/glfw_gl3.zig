const std = @import("std");
usingnamespace @import("common/shader.zig");
usingnamespace @import("common/font.zig");
usingnamespace @import("ui_builder");
usingnamespace @import("zalgebra");

const glfw = @import("common/c.zig").glfw;
usingnamespace @import("common/c.zig").gl;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const panic = std.debug.panic;
const print = std.debug.print;

const WINDOW_WIDTH: i32 = 1200;
const WINDOW_HEIGHT: i32 = 800;
const WINDOW_NAME = "UI Builder";

var codepoint: ?u21 = null;

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

    _ = glfw.glfwSetCharCallback(window, char_callback);

    defer glfw.glfwDestroyWindow(window);
    defer glfw.glfwTerminate();

    var helvetica = try Font.init("helvetica");
    defer helvetica.deinit();

    var shape_render_obj = create_render_object();
    var text_render_obj = create_render_object();

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
    var checkbox_value = false;
    var value_to_incr: f32 = 0.5;
    var options = [_][]const u8{ "Option A", "Option B", "Option C" };
    var selected_opt: usize = 0;
    var slider_value: f32 = 50;
    var value_to_edit: f32 = 23.3214345345;

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
        // const mouse_right_down = glfw.glfwGetMouseButton(window, 1) == 1;
        try ui.send_input_key(.Cursor, mouse_left_down);
        try ui.send_input_key(.Bspc, glfw.glfwGetKey(window, 259) == 1);
        if (codepoint) |c| {
            try ui.send_codepoint(c);
            codepoint = null;
        }

        if (ui.panel("Graph Panel", 450, 50, 250, 400)) {
            ui.label("Beautiful graph:", .Left);

            var data = [_]f32{ 0.5, 10, 23, 35, 70, 10, 2.4, 34.5, 40.5 };
            ui.graph(&data, 70);
        }

        if (ui.panel("Debug Panel", 25, 25, 400, 700)) {
            try ui.label_alloc("counter: {}", .{counter}, .Left);
            try ui.alloc_incr_value(i32, &counter, 1, 0, 100);

            ui.row_array_static(&[_]f32{ 100, 150 }, 0);
            try ui.edit_value(f32, &value_to_edit, "{d:.3}");
            try ui.label_alloc("floating value: {d}", .{value_to_edit}, .Left);

            ui.padding_space(5);

            ui.label("Editing String: ", .Left);
            if (try ui.edit_string("test")) |str| {
                print("String updated: {s}\n", .{str});
            }

            ui.padding_space(25);

            if (ui.tree_begin("Widgets", true, .Collapser)) {
                ui.row_flex(0, 3);
                if (ui.button("btn_1")) {}
                if (ui.button("btn_2")) {}
                if (ui.button("btn_3")) {}
                ui.row_flex(0, 1);
                if (ui.button("btn_4")) {}

                ui.row_array_static(&[_]f32{ 50, 150 }, 0);
                ui.label("Select: ", .Left);
                selected_opt = ui.select(&options, selected_opt);
                ui.label("Slider: ", .Left);
                slider_value = ui.slider(0, 100, slider_value, 1);

                ui.row_flex(0, 1);
                ui.checkbox_label("Checkbox!", &checkbox_value);
                try ui.alloc_incr_value(f32, &value_to_incr, 2.5, 0, 50);

                ui.label("Left", .Left);
                ui.label("Center", .Center);
                ui.label("Right", .Right);

                ui.tree_end();
            }

            if (ui.button("Close")) should_close = true;
        }

        // Send shapes to GPU.
        const data = ui.process_ui();
        send_data_to_gpu(&shape_render_obj, data.vertices, data.indices);

        // Draw eveything
        {
            glDisable(GL_DEPTH_TEST);
            glEnable(GL_SCISSOR_TEST);
            defer glDisable(GL_SCISSOR_TEST);

            const size = blk: {
                var x: c_int = 0;
                var y: c_int = 0;
                var fx: c_int = 0;
                var fy: c_int = 0;
                glfw.glfwGetFramebufferSize(window, &fx, &fy);
                glfw.glfwGetWindowSize(window, &x, &y);

                break :blk .{
                    .width = @intToFloat(f32, x),
                    .height = @intToFloat(f32, y),
                    .frame_width = @intToFloat(f32, fx),
                    .frame_height = @intToFloat(f32, fy),
                };
            };

            for (ui.draw()) |d| {
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                const clip = d.clip;

                const fb_scale_x = size.frame_width / size.width;
                const fb_scale_y = size.frame_height / size.height;

                glScissor(
                    @floatToInt(c_int, clip.x * fb_scale_x),
                    @floatToInt(
                        c_int,
                        (size.height - (clip.y + clip.h)) * fb_scale_y,
                    ),
                    @floatToInt(c_int, clip.w * fb_scale_x),
                    @floatToInt(c_int, clip.h * fb_scale_y),
                );

                // Draw shapes
                {
                    const proj = orthographic(0, size.width, size.height, 0, -1, 1);
                    glUseProgram(quad_shader.program_id);
                    quad_shader.setMat4("projection", &proj);
                    glBindVertexArray(shape_render_obj.vao);

                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, shape_render_obj.ebo.?);
                    glDrawElements(
                        GL_TRIANGLES,
                        @intCast(c_int, d.vertex_count),
                        GL_UNSIGNED_INT,
                        @intToPtr(*allowzero c_void, d.offset * @sizeOf(u32)),
                    );

                    glBindVertexArray(0);
                }

                for (d.texts) |text| {
                    glUseProgram(text_shader.program_id);

                    const proj = orthographic(0, size.width, 0, size.height, -1, 1);
                    text_shader.setMat4("projection", &proj);

                    glActiveTexture(GL_TEXTURE1);
                    glBindTexture(GL_TEXTURE_2D, helvetica.texture_id);
                    text_shader.setInteger("glyph", @as(i32, 1));

                    immediate_draw_text(.{
                        .text = text.content,
                        .color = vec3.from_slice(&text.color.to_array()),
                        .pos_x = text.x,
                        .pos_y = size.height - text.y,
                        .size = ui.cfg.font_size,
                    }, &helvetica, &text_render_obj);

                    glBindVertexArray(0);
                }
            }

            glDisable(GL_BLEND);
        }

        glfw.glfwSwapBuffers(window);
        // TODO: Understand this shit. WTF?
        glfw.glFlush();
        glfw.glFinish();
    }
}

// Render object identifier.
pub const RenderObject = struct {
    vao: u32,
    vbo: u32,
    ebo: ?u32,
    triangle_count: i32,
    indice_type: enum { u16, u32 },
};

fn calc_text_size(font: *Font, size: f32, text: []const u8) f32 {
    const ratio_size = size / font.size;
    var text_cursor: f32 = 0;

    for (text) |letter| {
        if (font.characters.get(&[_]u8{letter})) |c| {
            text_cursor += c.advance * ratio_size;
        }
    }

    return text_cursor;
}

pub fn char_callback(_: ?*glfw.GLFWwindow, c: c_uint) callconv(.C) void {
    codepoint = @intCast(u21, c);
}

pub fn send_data_to_gpu(
    render_obj: *RenderObject,
    vertices: []const f32,
    indices: []const u32,
) void {
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

pub fn create_render_object() RenderObject {
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

    return r;
}
