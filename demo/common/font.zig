const std = @import("std");
usingnamespace @import("utils.zig");

const stb = @import("c.zig").stb;
usingnamespace @import("c.zig").gl;

const mem = std.mem;
const Allocator = mem.Allocator;
const json = std.json;
const print = std.debug.print;
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
