const std = @import("std");
usingnamespace @import("zalgebra");

const gl = @import("c.zig").gl;
const c_allocator = std.heap.c_allocator;
const panic = std.debug.panic;

pub const Shader = struct {
    name: []const u8,
    program_id: u32,
    vertex_id: u32,
    fragment_id: u32,
    geometry_id: ?u32,

    pub fn create(
        name: []const u8,
        vert_content: []const u8,
        frag_content: []const u8,
    ) !Shader {
        var sp: Shader = undefined;
        sp.name = name;

        {
            sp.vertex_id = gl.glCreateShader(gl.GL_VERTEX_SHADER);
            const source_ptr: ?[*]const u8 = vert_content.ptr;
            const source_len = @intCast(gl.GLint, vert_content.len);
            gl.glShaderSource(sp.vertex_id, 1, &source_ptr, &source_len);
            gl.glCompileShader(sp.vertex_id);

            var ok: gl.GLint = undefined;
            gl.glGetShaderiv(sp.vertex_id, gl.GL_COMPILE_STATUS, &ok);

            if (ok == 0) {
                var error_size: gl.GLint = undefined;
                gl.glGetShaderiv(sp.vertex_id, gl.GL_INFO_LOG_LENGTH, &error_size);

                const message = try c_allocator.alloc(u8, @intCast(usize, error_size));
                gl.glGetShaderInfoLog(sp.vertex_id, error_size, &error_size, message.ptr);
                panic("Error compiling vertex shader:\n{s}\n", .{message});
            }
        }

        {
            sp.fragment_id = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
            const source_ptr: ?[*]const u8 = frag_content.ptr;
            const source_len = @intCast(gl.GLint, frag_content.len);
            gl.glShaderSource(sp.fragment_id, 1, &source_ptr, &source_len);
            gl.glCompileShader(sp.fragment_id);

            var ok: gl.GLint = undefined;
            gl.glGetShaderiv(sp.fragment_id, gl.GL_COMPILE_STATUS, &ok);

            if (ok == 0) {
                var error_size: gl.GLint = undefined;
                gl.glGetShaderiv(sp.fragment_id, gl.GL_INFO_LOG_LENGTH, &error_size);

                const message = try c_allocator.alloc(u8, @intCast(usize, error_size));
                gl.glGetShaderInfoLog(sp.fragment_id, error_size, &error_size, message.ptr);
                panic("Error compiling fragment shader:\n{s}\n", .{message});
            }
        }

        sp.program_id = gl.glCreateProgram();
        gl.glAttachShader(sp.program_id, sp.vertex_id);
        gl.glAttachShader(sp.program_id, sp.fragment_id);
        gl.glLinkProgram(sp.program_id);

        var ok: gl.GLint = undefined;
        gl.glGetProgramiv(sp.program_id, gl.GL_LINK_STATUS, &ok);

        if (ok == 0) {
            var error_size: gl.GLint = undefined;
            gl.glGetProgramiv(sp.program_id, gl.GL_INFO_LOG_LENGTH, &error_size);
            const message = try c_allocator.alloc(u8, @intCast(usize, error_size));
            gl.glGetProgramInfoLog(sp.program_id, error_size, &error_size, message.ptr);
            panic("Error linking shader program: {s}\n", .{message});
        }

        // Cleanup shaders (from gl doc).
        gl.glDeleteShader(sp.vertex_id);
        gl.glDeleteShader(sp.fragment_id);

        return sp;
    }

    pub fn setMat4(sp: Shader, name: [*c]const u8, value: *const mat4) void {
        const id = gl.glGetUniformLocation(sp.program_id, name);
        gl.glUniformMatrix4fv(id, 1, gl.GL_FALSE, value.get_data());
    }

    pub fn setInteger(sp: Shader, name: [*c]const u8, value: i32) void {
        const id = gl.glGetUniformLocation(sp.program_id, name);
        gl.glUniform1i(id, value);
    }

    // pub fn setBool(sp: Shader, name: [*gl]const u8, value: bool) void {
    //     const id = gl.glGetUniformLocation(sp.program_id, name);
    //     gl.glUniform1i(id, @boolToInt(value));
    // }

    // pub fn setFloat(sp: Shader, name: [*gl]const u8, value: f32) void {
    //     const id = gl.glGetUniformLocation(sp.program_id, name);
    //     gl.glUniform1f(id, value);
    // }

    // pub fn setRgb(sp: Shader, name: [*gl]const u8, value: *const vec3) void {
    //     const id = gl.glGetUniformLocation(sp.program_id, name);
    //     gl.glUniform3f(id, value.x / 255.0, value.y / 255.0, value.z / 255.0);
    // }

    // pub fn setRgba(sp: Shader, name: [*gl]const u8, value: *const vec4) void {
    //     const id = gl.glGetUniformLocation(sp.program_id, name);
    //     gl.glUniform4f(id, value.x / 255.0, value.y / 255.0, value.z / 255.0, value.w);
    // }
};
