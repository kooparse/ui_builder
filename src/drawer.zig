// zig fmt: off

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const Id = @import("./ui.zig").Id;
const Rect = @import("./ui.zig").Rect;
const Text = @import("./ui.zig").Text;
const TextAlignment = @import("./ui.zig").TextAlignment;
const Triangle = @import("./ui.zig").Triangle;
const TriangleDir = @import("./ui.zig").TriangleDir;
const Color = @import("./ui.zig").Color;

pub const Clip = struct { x: f32, y: f32, w: f32, h: f32 };

pub const DrawCommand = union(enum) {
    Text: Text,
    Triangle: Triangle,
    Rect: Rect,
    Clip: Clip,
};

pub const DrawerData = struct { vertices: []f32, indices: []u32 };

const CommandList = ArrayList(DrawCommand);
const DrawCommands = AutoHashMap(Id, CommandList);

pub const DrawSlice = struct {
    offset: usize,
    vertex_count: usize,
    texts: []Text,
    clip: Clip,
};

pub const Drawer = struct {
    command_id: Id = 0,

    commands: DrawCommands,
    draw_list: ArrayList(DrawSlice),

    _vertices: ArrayList(f32),
    _indices: ArrayList(u32),
    _texts: ArrayList(Text),

    allocator: *Allocator,

    const Self = @This();

    // TODO: USE THE ARENA ALLOCATOR FOR THE _TEXTS
    // ANS FIX THE BUG.
    pub fn init(arena_alloc: *Allocator) Self {
        return .{
            .commands       = DrawCommands.init(arena_alloc),
            .draw_list      = ArrayList(DrawSlice).init(arena_alloc),
            ._vertices      = ArrayList(f32).init(arena_alloc),
            ._indices       = ArrayList(u32).init(arena_alloc),
            // Temporary hack!
            ._texts         = ArrayList(Text).init(std.heap.page_allocator),
            .allocator      = arena_alloc,
        };
    }

    pub fn set_cmd_id(drawer: *Self, id: Id) void {
        drawer.command_id = id;
        _ = drawer.commands.getOrPutValue(
            id, 
            CommandList.init(drawer.allocator)
        ) catch unreachable;
    }

    /// We're trying to save some system call by retaining capacity.
    pub fn reset(drawer: *Self) void {
        var it = drawer.commands.iterator();
        while (it.next()) |*entry| entry.*.value_ptr.shrinkAndFree(0);

        drawer.draw_list.shrinkRetainingCapacity(0);
        drawer._vertices.shrinkRetainingCapacity(0);
        drawer._indices.shrinkRetainingCapacity(0);
        drawer._texts.shrinkRetainingCapacity(0);
    }

    /// Get vertex and indices from the UI.
    /// Here, user should send the data to the GPU. It's
    /// the step just before drawing it.
    pub fn process_ui(drawer: *Self, orders: []const Id) DrawerData {
        var i: u32 = 0;
        var offset: usize = 0;
        var text_offset: usize = 0;

        for (orders) |overlay_id| {
            if (drawer.commands.get(overlay_id)) |cmd_list| {
                var vertex_count: usize = 0;
                var clip: Clip = undefined;

                for (cmd_list.items) |cmd| {
                    switch (cmd) {
                        .Triangle => |triangle| {
                            const e = triangle.edges;
                            const c = triangle.color.to_array();

                            drawer._vertices.appendSlice(&[_]f32{
                                e[0], e[1], 0, 0, c[0], c[1], c[2], c[3],
                                e[2], e[3], 0, 0, c[0], c[1], c[2], c[3],
                                e[4], e[5], 0, 0, c[0], c[1], c[2], c[3],
                            }) catch unreachable;

                            drawer._indices.appendSlice(&[_]u32{
                                0 + i, 1 + i, 2 + i,
                            }) catch unreachable;

                            i += 3;
                            vertex_count += 3;
                        },
                        .Rect => |rect| {
                            const a_x = rect.x;
                            const a_y = rect.y;

                            const b_x = rect.x + rect.w;
                            const b_y = rect.y;

                            const c_x = rect.x + rect.w;
                            const c_y = rect.y + rect.h;

                            const d_x = rect.x;
                            const d_y = rect.y + rect.h;

                            const c = rect.color.to_array();

                            // POS, UV, COLOR
                            drawer._vertices.appendSlice(&[_]f32{
                                a_x, a_y, 0, 0, c[0], c[1], c[2], c[3],
                                b_x, b_y, 0, 0, c[0], c[1], c[2], c[3],
                                c_x, c_y, 0, 0, c[0], c[1], c[2], c[3],
                                d_x, d_y, 0, 0, c[0], c[1], c[2], c[3],
                            }) catch unreachable;

                            drawer._indices.appendSlice(&[_]u32{
                                0 + i, 1 + i, 2 + i,
                                0 + i, 2 + i, 3 + i,
                            }) catch unreachable;

                            i += 4;
                            vertex_count += 6;
                        },
                        .Clip => |clip_bounds| {
                            clip = clip_bounds;
                        },
                        .Text => |text| {
                            drawer._texts.append(text) catch unreachable;
                        },
                    }
                }

                drawer.draw_list.append(.{
                    .vertex_count = vertex_count,
                    .texts = drawer._texts.items[text_offset..],
                    .offset = offset,
                    .clip = clip,
                }) catch unreachable;


                if (drawer._texts.items.len > 0) {
                    text_offset = drawer._texts.items.len;
                }

                offset += vertex_count;
            }
        }

        return .{
            .vertices = drawer._vertices.items,
            .indices = drawer._indices.items,
        };
    }

    pub fn push_rect(drawer: *Self, r: Rect) void {
        const id = drawer.command_id;
        if (drawer.commands.getEntry(id)) |*entry| {
            entry.*.value_ptr.append(.{ .Rect = r }) catch unreachable;
        }
    }

    pub fn push_triangle(
        drawer: *Self, 
        region: Rect,
        size: f32,
        color: Color,
        direction: TriangleDir,
    ) void {
        const id = drawer.command_id;
        if (drawer.commands.getEntry(id)) |*entry| {
            const rect = region.y_center(size, size);
            const triangle = Triangle.new(region, color, direction);
            entry.value_ptr.append(.{ .Triangle = triangle }) catch unreachable;
        }
    }

    pub fn push_clip(drawer: *Self, x: f32, y: f32, w: f32, h: f32) void {
        const id = drawer.command_id;
        if (drawer.commands.getEntry(id)) |*entry| {
            entry.value_ptr.append(.{
                .Clip = .{
                    .x = x,
                    .y = y,
                    .w = w,
                    .h = h,
                },
            }) catch unreachable;
        } 
    }

    pub fn push_text(drawer: *Self, text: Text) void {
        const id = drawer.command_id;
        if (drawer.commands.getEntry(id)) |*entry| {
            entry.value_ptr.append(.{ .Text = text }) catch unreachable;
        }
    }

    pub fn push_borders(
        drawer: *Self, 
        r: Rect, 
        thickness: f32, 
        color: Color,
    ) void {
        const id = drawer.command_id;
        if (drawer.commands.getEntry(id)) |*entry| {
            entry.value_ptr.appendSlice(&[4]DrawCommand{
                .{
                    .Rect = .{
                        .x = r.x,
                        .y = r.y,
                        .w = thickness,
                        .h = r.h,
                        .color = color,
                    },
                    },
                // Right.
                .{
                    .Rect = .{
                        .x = r.x + r.w - thickness,
                        .y = r.y,
                        .w = thickness,
                        .h = r.h,
                        .color = color,
                    },
                    },
                // Top.
                .{
                    .Rect = .{
                        .x = r.x,
                        .y = r.y,
                        .w = r.w,
                        .h = thickness,
                        .color = color,
                    },
                    },
                // Bottom.
                .{
                    .Rect = .{
                        .x = r.x,
                        .y = r.y + r.h - thickness,
                        .w = r.w,
                        .h = thickness,
                        .color = color,
                    },
                    },
                }
            ) catch unreachable;
        }
    }
};

