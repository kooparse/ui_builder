const std = @import("std");
usingnamespace @import("zalgebra");
usingnamespace @import("utils.zig");
usingnamespace @import("shader.zig");

usingnamespace @import("../glfw_gl3.zig");

const stb = @import("c.zig").stb;
usingnamespace @import("c.zig").gl;

const mem = std.mem;
const Allocator = mem.Allocator;
const json = std.json;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const panic = std.debug.panic;
const page_alloc = std.heap.page_allocator;
const StringHashMap = std.StringHashMap;
const ValueTree = json.ValueTree;

pub const Font = struct {
    name: []const u8,
    size: f32,
    is_bold: bool,
    // It's in pixel, but we're gonna cast them anyway.
    atlas_width: f32,
    atlas_height: f32,
    characters: StringBufSet(CharacterInfo),

    texture_id: u32,

    /// Also in pixels.
    const CharacterInfo = struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        origin_x: f32,
        origin_y: f32,
        advance: f32,
    };

    const Self = @This();

    pub fn init(font_name: []const u8) !Self {
        var font: Self = undefined;

        var tree = try parse_font_descriptor(font_name);
        defer tree.deinit();

        const root = tree.root.Object;

        const fonts_folder = "demo/assets/fonts";
        const atlas_path = try mem.join(
            page_alloc,
            "",
            &[_][]const u8{
                fonts_folder,
                "/",
                font_name,
                "/",
                font_name,
                "_atlas",
                ".png",
            },
        );
        defer page_alloc.free(atlas_path);

        font.texture_id = load_to_gpu(atlas_path);

        font.name = try Allocator.dupe(page_alloc, u8, root.get("name").?.String);
        font.size = @intToFloat(f32, root.get("size").?.Integer);
        font.is_bold = root.get("bold").?.Bool;
        font.atlas_width = @intToFloat(f32, root.get("width").?.Integer);
        font.atlas_height = @intToFloat(f32, root.get("height").?.Integer);

        font.characters = StringBufSet(CharacterInfo).init(page_alloc);
        var it = root.get("characters").?.Object.iterator();
        while (it.next()) |entry| {
            const char_name = entry.key_ptr.*;
            const char_value = entry.value_ptr.*.Object;

            try font.characters.put(char_name, .{
                .x = @intToFloat(f32, char_value.get("x").?.Integer),
                .y = @intToFloat(f32, char_value.get("y").?.Integer),
                .width = @intToFloat(f32, char_value.get("width").?.Integer),
                .height = @intToFloat(f32, char_value.get("height").?.Integer),
                .origin_x = @intToFloat(f32, char_value.get("originX").?.Integer),
                .origin_y = @intToFloat(f32, char_value.get("originY").?.Integer),
                .advance = @intToFloat(f32, char_value.get("advance").?.Integer),
            });
        }

        print("Font '{s}' successfuly loaded.\n", .{font.name});
        return font;
    }

    pub fn deinit(self: *Self) void {
        glDeleteTextures(1, &[_]u32{self.texture_id});
        page_alloc.free(self.name);
        self.characters.deinit();
    }
};

fn load_to_gpu(font_path: []const u8) u32 {
    var width: i32 = undefined;
    var height: i32 = undefined;
    var channels: i32 = undefined;

    const should_flip = @boolToInt(false);
    stb.stbi_set_flip_vertically_on_load(should_flip);

    const data = stb.stbi_load(font_path.ptr, &width, &height, &channels, 0);
    defer stb.stbi_image_free(data);

    if (data == 0) {
        panic("STB crashed while loading image '{s}'!\n", .{font_path});
    }

    var texture_id: u32 = undefined;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    // Should be always RGBA for SDF fonts.
    const format: c_int = switch (channels) {
        1 => GL_RED,
        3 => GL_RGB,
        4 => GL_RGBA,
        else => panic("Provided channels currently not supported!\n", .{}),
    };

    glTexImage2D(
        GL_TEXTURE_2D,
        0,
        format,
        width,
        height,
        0,
        @intCast(c_uint, format),
        GL_UNSIGNED_BYTE,
        data,
    );
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    return texture_id;
}

fn parse_font_descriptor(font_name: []const u8) !ValueTree {
    const fonts_folder = "demo/assets/fonts";
    const path = try mem.join(
        page_alloc,
        "",
        &[_][]const u8{ fonts_folder, "/", font_name, "/", font_name, ".json" },
    );
    defer page_alloc.free(path);

    const max_bytes: usize = 20480;
    const buf = try std.fs.cwd().readFileAlloc(page_alloc, path, max_bytes);
    defer page_alloc.free(buf);

    var parser = json.Parser.init(page_alloc, true);
    defer parser.deinit();

    return parser.parse(buf);
}

pub fn immediate_draw_text(
    args: struct {
        text: []const u8,
        size: f32 = 42,
        color: vec3 = vec3.new(1, 0, 1),
        pos_x: f32,
        pos_y: f32,
    },
    font: *const Font,
    render_obj: *RenderObject
) void {
    const ratio_size = args.size / font.size;

    // Color alpha value.
    const a: f32 = 1;

    var text_vertex_buffer = ArrayList(f32).init(page_alloc);
    defer text_vertex_buffer.deinit();

    var text_element_buffer = ArrayList(u32).init(page_alloc);
    defer text_element_buffer.deinit();

    const color = args.color;
    // Render each glyph.
    var text_cursor: f32 = 0;
    var count: u32 = 0;
    for (args.text) |letter, i| {
        if (!font.characters.contains(&[_]u8{letter})) continue;
        var c = font.characters.get(&[_]u8{letter}).?;

        const top_left_x = c.x / font.atlas_width;
        const top_left_y = c.y / font.atlas_height;

        const top_right_x = top_left_x + (c.width / font.atlas_width);
        const top_right_y = top_left_y;

        const bottom_left_x = top_left_x;
        const bottom_left_y = top_left_y + (c.height / font.atlas_height);

        const bottom_right_x = top_right_x;
        const bottom_right_y = bottom_left_y;

        const x = args.pos_x + text_cursor - (c.origin_x * ratio_size);
        const y = args.pos_y + 0 - (c.height - c.origin_y) * ratio_size;
        const w = c.width * ratio_size;
        const h = c.height * ratio_size;

        // Quad graph, you're welcome!
        //
        // A----B
        // |    |
        // |    |
        // C----D
        //
        //
        const glyph_data = [_]f32{
            x, y + h,       top_left_x, top_left_y, color.x, color.y, color.z, a,         // A
            x, y,           bottom_left_x, bottom_left_y, color.x, color.y, color.z, a,   // C
            x + w, y,       bottom_right_x, bottom_right_y, color.x, color.y, color.z, a, // D

            x + w, y + h,   top_right_x, top_right_y, color.x, color.y, color.z, a,      // B
        };

        text_vertex_buffer.appendSlice(&glyph_data) catch unreachable;

        text_element_buffer.appendSlice(&[_]u32{
            0 + count, 1 + count, 2 + count, 
            0 + count, 2 + count, 3 + count
        }) catch unreachable;

        text_cursor += c.advance * ratio_size;
        count += 4;
    }


    send_data_to_gpu(
        render_obj, 
        text_vertex_buffer.items, 
        text_element_buffer.items
    );

    {
        glBindVertexArray(render_obj.vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_obj.ebo.?);
        glDrawElements(
            GL_TRIANGLES,
            @intCast(c_int, text_element_buffer.items.len),
            GL_UNSIGNED_INT,
            @intToPtr(*allowzero c_void, 0),
        );

        glBindVertexArray(0);

    }

}
