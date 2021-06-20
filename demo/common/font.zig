const std = @import("std");
usingnamespace @import("../utils.zig");
usingnamespace @import("./renderer.zig");

const mem = std.mem;
const Allocator = mem.Allocator;
const json = std.json;
const print = std.debug.print;
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

    font_atlas: Image,

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

        font.font_atlas = Image.load_from_disk(
            "assets/fonts/helvetica/helvetica_atlas.png",
            false,
        );
        font.font_atlas.load_to_gpu(.Text);

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
        page_alloc.free(self.name);
        self.font_atlas.deinit();
        self.characters.deinit();
    }
};

fn parse_font_descriptor(font_name: []const u8) !ValueTree {
    const path = try mem.join(
        page_alloc,
        "",
        &[_][]const u8{ "assets/fonts", "/", font_name, "/", font_name, ".json" },
    );
    defer page_alloc.free(path);

    const max_bytes: usize = 20480;
    const buf = try std.fs.cwd().readFileAlloc(page_alloc, path, max_bytes);
    defer page_alloc.free(buf);

    var parser = json.Parser.init(page_alloc, true);
    defer parser.deinit();

    return parser.parse(buf);
}
