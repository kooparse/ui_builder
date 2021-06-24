// TODO:
//
// - File per widget/logic.
// - Finishing scrolling.
// - Fix Layout code.
// - Better overlay system.
// - Input for numbers (proper value updates).
// - Less allocation.
// - Add user font API for creating vertices/indices.

const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const AutoHashMap = std.AutoHashMap;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const ArrayList = std.ArrayList;

usingnamespace @import("./drawer.zig");

const math = std.math;
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;
const unicode = std.unicode;
const print = std.debug.print;
const assert = std.debug.assert;
const Wyhash = std.hash.Wyhash;
const panic = std.debug.panic;

const Key = enum {
    Bspc,
    Esc,
    Cursor,
};

const KeyState = struct {
    /// If the key is held down (regardless of any frame).
    is_repeat: bool = false,
    /// Return true during the frame if the key is down.
    is_down: bool = false,
    /// Return true during the frame if the key is up.
    is_up: bool = false,
    /// Used to keep track of the previous frame state.
    was_down: bool = false,
};

/// Representing color with alpha channel.
/// The method `to_array` is used to convert the
/// rgba color to an array.
pub const Color = struct {
    rgb: [3]i32,
    a: f32,

    const Self = @This();

    /// 0-255 color per channel.
    pub fn new(r: i32, g: i32, b: i32, a: f32) Self {
        return .{
            .rgb = .{ r, g, b },
            .a = a,
        };
    }

    pub fn black() Self {
        return Self.new(0, 0, 0, 1);
    }

    pub fn white() Self {
        return Self.new(255, 255, 255, 1);
    }

    pub fn to_array(self: *const Self) [4]f32 {
        return [4]f32{
            @intToFloat(f32, self.rgb[0]) / 255,
            @intToFloat(f32, self.rgb[1]) / 255,
            @intToFloat(f32, self.rgb[2]) / 255,
            self.a,
        };
    }
};

/// All possible status.
pub const Status = enum {
    Normal,
    Hovered,
    Pressed,
    Dragged,
    Disabled,
};

/// TODO: Rename is_clicked/is_pressed...
pub const BoundState = struct {
    is_hover: bool = false,
    is_clicked: bool = false,
    is_pressed: bool = false,
    is_missed: bool = false,
    status: Status = .Disabled,
};

/// Text
pub const Text = struct {
    x: f32,
    y: f32,
    color: Color,
    content: []const u8,
};

const WidgetColor = struct {
    border_color: Color,
    base_color: Color,
    text_color: Color,
};

pub const Style = struct {
    background_color: Color = Color.new(0, 34, 43, 1),
    line_color: Color = Color.new(129, 192, 208, 1),

    normal: WidgetColor = .{
        .border_color = Color.new(47, 116, 134, 1),
        .base_color = Color.new(2, 70, 88, 1),
        .text_color = Color.new(81, 191, 211, 1),
    },

    hovered: WidgetColor = .{
        .border_color = Color.new(130, 205, 224, 1),
        .base_color = Color.new(50, 153, 180, 1),
        .text_color = Color.new(182, 225, 234, 1),
    },

    pressed: WidgetColor = .{
        .border_color = Color.new(235, 118, 48, 1),
        .base_color = Color.new(255, 188, 81, 1),
        .text_color = Color.new(216, 111, 54, 1),
    },

    disabled: WidgetColor = .{
        .border_color = Color.new(19, 75, 90, 1),
        .base_color = Color.new(2, 49, 61, 1),
        .text_color = Color.new(23, 80, 95, 1),
    },

    border_size: f32 = 3,
    widget_margin: f32 = 5,
    text_padding: f32 = 10,

    indent: f32 = 15,

    resizer_size: f32 = 10,
    closer_size: f32 = 10,

    /// TODO: Impl Dragged color.
    pub fn widget_color(self: *const @This(), status: Status) WidgetColor {
        return switch (status) {
            .Normal => self.normal,
            .Hovered => self.hovered,
            .Pressed => self.pressed,
            .Disabled => self.disabled,
            .Dragged => @panic("Not impl yet!\n"),
        };
    }
};

/// Config object, used to pass given allocator, given callback for
/// compute text sizes.
pub fn Config(comptime F: anytype) type {
    return struct {
        allocator: *Allocator,
        font: *F,
        font_size: f32,
        calc_text_size: fn (font: *F, size: f32, text: []const u8) f32,
    };
}

pub const TriangleDir = enum { Down, Right, DiagRight };
/// Simple triangle data + color.
pub const Triangle = struct {
    edges: [6]f32,
    color: Color,
    direction: TriangleDir = .Down,

    pub fn new(rect: Rect, color: Color, dir: TriangleDir) Triangle {
        return switch (dir) {
            .Down => down(rect, color),
            .Right => right(rect, color),
            .DiagRight => diag_right(rect, color),
        };
    }

    /// Only used for the resizer.
    fn diag_right(rect: Rect, color: Color) Triangle {
        const b_x = rect.x + rect.w;
        const b_y = rect.y;

        const c_x = rect.x;
        const c_y = rect.y + rect.h;

        const d_x = rect.x + rect.w;
        const d_y = rect.y + rect.h;

        return .{
            .edges = .{
                c_x, c_y,
                b_x, b_y,
                d_x, d_y,
            },
            .color = color,
        };
    }

    /// Triangle pointing to the bottom.
    fn down(rect: Rect, color: Color) Triangle {
        const a_x = rect.x;
        const a_y = rect.y;

        const b_x = rect.x + rect.w;
        const b_y = rect.y;

        const c_x = rect.x + rect.w / 2;
        const c_y = rect.y + rect.h;

        return .{
            .edges = .{
                a_x, a_y,
                b_x, b_y,
                c_x, c_y,
            },
            .color = color,
        };
    }

    /// Triangle pointing to the right.
    fn right(rect: Rect, color: Color) Triangle {
        const a_x = rect.x;
        const a_y = rect.y;

        const b_x = rect.x;
        const b_y = rect.y + rect.h;

        const c_x = rect.x + rect.w;
        const c_y = rect.y + rect.h / 2;

        return .{
            .edges = .{
                a_x, a_y,
                b_x, b_y,
                c_x, c_y,
            },
            .color = color,
        };
    }
};

/// Rectangle mainly used to describe a region lay down
/// on the screen.
pub const Rect = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    color: Color = Color.new(1, 1, 1, 0.3),

    pub fn new(x: f32, y: f32, w: f32, h: f32) Rect {
        return .{ .x = x, .y = y, .w = w, .h = h };
    }

    /// Create new sub region.
    pub fn add_padding(outer: Rect, padding_hori: f32, padding_vert: f32) Rect {
        return Rect.new(
            outer.x + padding_hori,
            outer.y + padding_vert,
            outer.w - padding_hori * 2,
            outer.h - padding_vert * 2,
        );
    }

    pub fn intersect(lhs: Rect, rhs: Rect) Rect {
        const x1 = math.max(lhs.x, rhs.x);
        const y1 = math.max(lhs.y, rhs.y);

        var x2 = math.min(lhs.x + lhs.w, rhs.x + rhs.w);
        var y2 = math.min(lhs.y + lhs.h, rhs.y + rhs.h);
        if (x2 < x1) x2 = x1;
        if (y2 < y1) y2 = y1;

        return Rect.new(x1, y1, x2 - x1, y2 - y1);
    }

    /// Align element of given width and height inside
    /// the given rectangle.
    pub fn xy_center(container: Rect, w: f32, h: f32) Rect {
        return Rect.new(
            container.x + ((container.w - w) / 2),
            container.y + ((container.h - h) / 2),
            w,
            h,
        );
    }

    pub fn y_center(container: Rect, w: f32, h: f32) Rect {
        return Rect.new(
            container.x,
            container.y + ((container.h - h) / 2),
            w,
            h,
        );
    }
};

pub const TextAlignment = enum { Left, Center, Right };

const Layout = @import("./layout.zig").Layout;
const LayoutOptions = @import("./layout.zig").LayoutOptions;

pub const OverlayType = enum { Panel, Popup, Select };

pub const OverlayOptions = struct {
    overlay_type: OverlayType = .Panel,
    resizable: bool = false,
    draggable: bool = false,
    bordered: bool = false,
    has_header: bool = false,
    closable: bool = false,
    // If overlay should be closed when initialized.
    closed: bool = false,
};

/// Main container.
pub const Overlay = struct {
    id: Id,
    title: []const u8,
    header: ?Rect = null,
    body: Rect,
    resizer: ?Rect = null,
    closer: ?Rect = null,

    parent: ?Id = null,

    is_closed: bool = false,
    is_resizing: bool = false,
    is_dragging: bool = false,

    scroll: ?Rect = null,

    options: OverlayOptions = .{},

    layout: Layout,

    /// Return overlay's total bounds.
    pub fn bounds(win: *const Overlay) Rect {
        if (win.header) |header| {
            return .{
                .x = header.x,
                .y = header.y,
                .w = header.w,
                .h = header.h + win.body.h,
            };
        } else {
            return win.body;
        }
    }
};

const Tree = struct { is_expanded: bool };

const Input = struct {
    buf: []u8,
    slice: [:0]u8,
};

const CachedValue = union(enum) {
    Overlay: Overlay,
    Tree: Tree,
    Input: Input,
};

pub const Id = u64;

/// Immediate graphical interface.
/// You must provide your own Font.
pub fn Interface(comptime F: anytype) type {
    return struct {
        cfg: Config(F),

        cursor: struct {
            delta_x: f32 = 0,
            delta_y: f32 = 0,
            x: f32 = 0,
            y: f32 = 0,
            scroll_offset: f32 = 0,
        } = .{},

        disabled: bool = false,
        is_hot: bool = false,

        /// Visual styles is stored here, padding/margin included.
        style: Style = .{},

        // _draw_list: ArrayList(DrawSlice),
        layer: struct {
            /// The active item is always at the end of the stack.
            orders: ArrayList(Id),
            /// Next element to bring to front.
            bring_to_front: ?Id = null,
        },

        drawer: Drawer,

        /// The overlay currently process.
        current_overlay: Id,

        /// Last generated id, used for caching some
        /// values between frames.
        last_id: i32 = 0,

        /// If the value is set to `null`, nothing is currently drag,
        /// otherwise, the `id` of the dragging element is stored.
        dragging_id: ?i32 = null,

        focus_item: ?i32 = null,

        /// Used to keep track of key pressed.
        /// Reset between frame.
        key_status: AutoHashMap(Key, KeyState),

        /// Frame states.
        states: AutoHashMap(Id, CachedValue),

        /// Store user's unicode characters.
        //TODO: Should be a slice.
        string_buffer: ArrayList(u8),
        string_storage: ArrayList([]u8),

        /// Used to free all heap allocated data at once.
        _arena: *ArenaAllocator,

        const Self = @This();

        /// Initialize a new Interface from the given style and
        /// custom configuration object.
        pub fn init(cfg: Config(F), style: Style) !Self {
            var ui: Self = undefined;

            const allocator = cfg.allocator;
            ui._arena = try allocator.create(ArenaAllocator);
            ui._arena.* = ArenaAllocator.init(allocator);

            const arena = ui._arena.child_allocator;

            ui.cfg = cfg;
            ui.style = style;
            ui.layer.orders = ArrayList(Id).init(arena);
            ui.states = AutoHashMap(Id, CachedValue).init(arena);
            ui.string_buffer = ArrayList(u8).init(arena);
            ui.string_storage = ArrayList([]u8).init(arena);
            ui.key_status = AutoHashMap(Key, KeyState).init(arena);
            ui.drawer = Drawer.init(arena);

            return ui;
        }

        /// Generic method to construct any kind of overlay.
        /// They are all stored into the state manager.
        /// `title` will be used to create the id.
        fn _overlay(
            self: *Self,
            title: []const u8,
            bounds: Rect,
            layout_options: struct { hori: f32, vert: f32, space: f32 },
            options: OverlayOptions,
        ) !*Overlay {
            const style = self.style;
            const header_size = self.cfg.font_size + style.text_padding * 2;
            const seed = @intCast(u64, self.gen_id());
            const overlay_id = Wyhash.hash(seed, title);

            // Set drawer id.
            self.drawer.set_cmd_id(overlay_id);

            var overlay = blk: {
                const result = try self.states.getOrPut(overlay_id);

                // If overlay isn't found in frame states, we initialize a new one.
                if (!result.found_existing) {
                    if (options.overlay_type == .Select) {
                        try self.layer.orders.insert(0, overlay_id);
                    } else {
                        try self.layer.orders.append(overlay_id);
                    }

                    result.value_ptr.* = .{
                        .Overlay = Overlay{
                            .id = overlay_id,
                            .title = title,
                            .header = if (!options.has_header) null else Rect.new(
                                bounds.x,
                                bounds.y,
                                bounds.w,
                                header_size,
                            ),
                            .body = if (!options.has_header) bounds else Rect.new(
                                bounds.x,
                                bounds.y + header_size,
                                bounds.w,
                                bounds.h - header_size,
                            ),
                            .closer = if (!options.closable) null else Rect.new(
                                bounds.x + bounds.w - style.closer_size - 5,
                                bounds.y + 5,
                                style.closer_size,
                                style.closer_size,
                            ),
                            .resizer = if (!options.resizable) null else Rect.new(
                                bounds.x + bounds.w - style.resizer_size - 2,
                                bounds.y + bounds.h - style.resizer_size - 2,
                                style.resizer_size,
                                style.resizer_size,
                            ),
                            .options = options,
                            .is_closed = options.closed,
                            .layout = undefined,
                            // .draw_commands = DrawCommands.init(self._arena.child_allocator),
                        },
                    };
                }

                const entry = self.states.getEntry(overlay_id).?;
                break :blk &entry.value_ptr.Overlay;
            };

            // Display the scroll bar if the layout content is
            // larger than the parent dimension.
            if (overlay.layout.is_bigger_than_parent) {
                const space = 3;
                const width: f32 = 8;
                const height: f32 = 100;
                overlay.scroll = Rect.new(
                    (overlay.body.x + overlay.body.w) - width - space,
                    overlay.body.y + space,
                    width,
                    height,
                );

                if (self.cursor.scroll_offset != 0) {
                    const max_y = overlay.layout.cursor.y;
                    const with_offset = overlay.body.y + self.cursor.scroll_offset;
                    print("diff: {d}\n", .{(with_offset + overlay.body.h) - max_y});
                    overlay.body.y += self.cursor.scroll_offset;
                }
            } else {
                overlay.scroll = null;
            }

            // Used for parent Id on the select overlay type.
            const old_overlay = self.current_overlay;
            self.current_overlay = overlay_id;

            switch (overlay.options.overlay_type) {
                .Popup, .Panel => {
                    if (self.find_zindex(overlay_id)) |z_index| {
                        if (self.should_bring_to_front(overlay.bounds(), z_index)) {
                            self.layer.bring_to_front = overlay_id;
                        }

                        if (overlay.closer) |closer| {
                            if (self.bounds_state(closer, true).is_clicked) {
                                _ = self.layer.orders.orderedRemove(z_index);
                                overlay.is_closed = true;
                            }
                        }
                    }
                },
                .Select => {
                    overlay.body = bounds;
                    overlay.parent = old_overlay;
                    if (!self.is_on_front()) overlay.is_closed = true;
                },
            }

            const dx = self.cursor.delta_x;
            const dy = self.cursor.delta_y;

            if (overlay.header) |*header| {
                const is_draggable = overlay.options.draggable;
                overlay.is_dragging = false;

                if (is_draggable and self.dragging(header.*, self.gen_id())) {
                    header.x += dx;
                    header.y += dy;
                    overlay.body.x += dx;
                    overlay.body.y += dy;

                    if (overlay.resizer) |*resizer| {
                        resizer.x += dx;
                        resizer.y += dy;
                    }

                    if (overlay.closer) |*closer| {
                        closer.x += dx;
                        closer.y += dy;
                    }
                }
            }

            if (overlay.resizer) |*resizer| {
                const is_resizable = overlay.options.resizable;
                overlay.is_resizing = false;

                if (is_resizable and self.dragging(resizer.*, self.gen_id())) {
                    overlay.is_resizing = true;
                    overlay.body.w += dx;
                    overlay.body.h += dy;
                    resizer.x += dx;
                    resizer.y += dy;
                    if (overlay.header) |*header| header.w += dx;
                    if (overlay.closer) |*closer| closer.x += dx;
                }
            }

            if (!self.is_hot) {
                const state = self.bounds_state(overlay.bounds(), false);
                self.is_hot = state.is_hover;
            }

            // Reset layout data after overlay was resized or dragged.
            overlay.layout = Layout.new(
                overlay.body.add_padding(
                    layout_options.hori,
                    layout_options.vert,
                ),
                self.min_height(),
                layout_options.space,
            );

            return overlay;
        }

        /// New floating overlay.
        ///
        /// Created only once, thus data will be cached
        /// and retrieved every frame.
        pub fn panel(
            self: *Self,
            title: []const u8,
            x: f32,
            y: f32,
            w: f32,
            h: f32,
        ) bool {
            const bounds = Rect.new(x, y, w, h);
            const overlay = self._overlay(title, bounds, .{
                .hori = 10,
                .vert = 15,
                .space = 5,
            }, .{
                .has_header = true,
                .draggable = true,
                .resizable = true,
                .bordered = true,
                .closable = true,
            }) catch {
                @panic("Crashing while getting/creating Panel overlay.");
            };

            if (!overlay.is_closed) {
                self.draw_overlay(overlay.*);
                return true;
            }

            return false;
        }

        pub fn option_label(self: *Self, text: []const u8, is_checked: bool) bool {
            var checked = is_checked;
            self.checkbox_label(text, &checked);
            return checked;
        }

        pub fn checkbox_label(
            self: *Self,
            text: []const u8,
            is_checked: *bool,
        ) void {
            const size = self.cfg.font_size + 3;
            var rect = self.current_layout().allocate_space(null);
            const outer = Rect.y_center(rect, size, size);

            const state = self.bounds_state(outer, true);
            const color = self.style.widget_color(state.status);

            if (state.is_clicked) is_checked.* = !is_checked.*;

            // Draw instructions.
            {
                self.drawer.push_borders(outer, 2, color.border_color);
                if (is_checked.*) {
                    var inner = outer.xy_center(size - 6, size - 6);
                    inner.color = color.base_color;
                    self.drawer.push_rect(inner);
                }
                self.push_text(
                    rect.add_padding(outer.w + 5, 0),
                    text,
                    .Left,
                    color.text_color,
                );
            }
        }

        pub fn padding_space(self: *Self, padding: f32) void {
            self.current_layout().cursor.y += padding;
        }

        pub fn alloc_incr_value(
            self: *Self,
            comptime T: type,
            value: *T,
            step: T,
            min: ?T,
            max: ?T,
        ) !void {
            const layout = self.current_layout();
            const width = 70;

            var v = value.*;
            const rect = layout.allocate_space(null);

            var input = Rect.y_center(rect, width, rect.h);
            const add_btn = Rect.y_center(
                input.add_padding(width + 2, 0),
                rect.h,
                rect.h,
            );
            const min_btn = Rect.y_center(
                add_btn.add_padding(add_btn.w + 2, 0),
                rect.h,
                rect.h,
            );

            const allocator = self.cfg.allocator;
            const string = try fmt.allocPrint(allocator, "{d:.2}", .{value.*});
            try self.string_storage.append(string);

            // Draw instructions.
            {
                const style = self.style;
                const color = if (self.is_on_front()) style.normal else style.disabled;
                self.drawer.push_rect(input);
                self.drawer.push_borders(input, 2, color.border_color);
                self.push_text(input, string, .Center, color.text_color);
            }

            if (self._raw_button("+", true, true, add_btn)) v += step;
            if (self._raw_button("-", true, true, min_btn)) v -= step;

            if (min) |m| v = math.max(m, v);
            if (max) |m| v = math.min(m, v);

            value.* = v;
        }

        pub fn send_scroll_offset(self: *Self, offset: f32) void {
            self.cursor.scroll_offset = offset;
        }

        pub fn send_cursor_position(self: *Self, x: f32, y: f32) void {
            const old_cursor = self.cursor;
            self.cursor.x = x;
            self.cursor.y = y;
            self.cursor.delta_x = x - old_cursor.x;
            self.cursor.delta_y = y - old_cursor.y;
        }

        pub fn send_input_key(self: *Self, key: Key, is_down: bool) !void {
            const entry = try self.key_status.getOrPutValue(key, KeyState{});
            var key_state = entry.value_ptr;

            const old_state = key_state.*;
            key_state.was_down = is_down;
            key_state.is_down = !(old_state.was_down and is_down);
            key_state.is_repeat = old_state.was_down and is_down;
            key_state.is_up = old_state.was_down and !is_down;

            if (!is_down) {
                key_state.is_down = false;
                key_state.is_repeat = false;
            }
        }

        fn get_key(self: *const Self, key: Key) KeyState {
            const default = KeyState{};
            return if (self.key_status.get(key)) |state| state else default;
        }

        pub fn send_ascii_string(self: *Self, string: []const u8) void {
            self.string_buffer.appendSlice(string) catch unreachable;
        }

        /// Send unicode character.
        pub fn send_codepoint(self: *Self, codepoint: u21) !void {
            var tmp = [_]u8{0} ** 64;
            var len = try unicode.utf8Encode(codepoint, &tmp);
            try self.string_buffer.appendSlice(tmp[0..len]);
        }

        pub fn graph(self: *Self, data: []const f32, max: f32) void {
            const layout = self.current_layout();
            self.row_flex(100, 1);

            var row = layout.allocate_space(null);
            self.drawer.push_rect(row);

            const bounds = row.add_padding(10, 10);
            const count = @intToFloat(f32, data.len);

            const space = 1;
            const width = (bounds.w - space * count) * (1 / count);
            const height: f32 = bounds.h;
            const ref_max = height / max;

            var x = bounds.x;
            for (data) |d, i| {
                const min = max * 0.1;
                const value = math.clamp(d * ref_max, min, height);

                var bar = Rect.new(x, bounds.y, width, bounds.h);
                bar.h = value;
                bar.y += height - value;

                const state = self.bounds_state(bar, true);

                if (state.is_hover) {
                    bar.color = self.style.hovered.border_color;
                } else {
                    bar.color = self.style.normal.border_color;
                }

                self.drawer.push_rect(bar);
                x += width + space;
            }

            self.row_flex(0, 1);
        }

        pub fn edit_value(self: *Self, comptime T: type, value: *T) !void {
            const input_id = @intCast(u64, self.gen_id());
            const focus_id = self.gen_id();

            var is_valid = true;
            var is_focus = false;

            const rect = self.current_layout().allocate_space(null);
            const state = self.bounds_state(rect, true);

            var input = blk: {
                if (self.states.get(input_id)) |cached| {
                    break :blk cached.Input;
                } else {
                    // For now, we're using the arena allocator 
                    // because the input lifetime is equal to the UI.
                    const allocator = self._arena.child_allocator;
                    const buf = try allocator.alloc(u8, 128);
                    break :blk Input{
                        .buf = buf,
                        .slice = try fmt.bufPrintZ(buf, "{d}", .{value.*}),
                    };
                }
            };

            const to_append = self.string_buffer.items;

            // Bring the current input to focus if nothing is focused.
            if (self.focus_item == null and state.is_clicked) {
                self.focus_item = focus_id;
            }

            switch (@typeInfo(T)) {
                .Float => {
                    var has_decimal_point = false;

                    for (input.slice) |c| {
                        if (c == '.') has_decimal_point = true;
                    }

                    for (to_append) |c| {
                        const isPoint = c == '.';
                        const two_deci_point = has_decimal_point and isPoint;
                        const isNotDigit = !ascii.isDigit(c) and !isPoint;

                        if (two_deci_point or isNotDigit) {
                            is_valid = false;
                            break;
                        }

                        if (c == '.') has_decimal_point = true;
                    }
                },
                .Int => {
                    for (to_append) |c| {
                        if (!ascii.isDigit(c)) {
                            is_valid = false;
                            break;
                        }
                    }
                },
                else => {
                    @panic("Value type not impl.\n");
                },
            }

            if (is_valid) {
                if (self.focus_item) |item_id| {
                    is_focus = item_id == focus_id;
                    const is_delete = self.get_key(.Bspc).is_down;

                    if (is_focus) {
                        if (to_append.len > 0 and !is_delete) {
                            input.slice =
                                try fmt.bufPrintZ(input.buf, "{s}{s}", .{
                                input.slice,
                                to_append,
                            });
                        }

                        if (is_delete and input.slice.len > 0) {
                            input.slice[input.slice.len - 1] = '\x00';
                            input.slice.len = input.slice.len - 1;
                        }
                    }

                    if (is_focus and state.is_missed) {
                        self.focus_item = null;
                    }
                }

                if (input.slice.len > 0) {
                    value.* = switch (@typeInfo(T)) {
                        .Float => try fmt.parseFloat(T, input.slice),
                        .Int => try fmt.parseInt(T, input.slice, 0),
                        else => {},
                    };
                } else {
                    value.* = 0;
                }
            }

            // Draw instructions.
            {
                var color = if (self.is_on_front())
                    self.style.normal
                else
                    self.style.disabled;

                var bounds = if (state.is_hover)
                    rect.add_padding(-2, -2)
                else
                    rect;

                if (is_focus) {
                    bounds = rect.add_padding(-2, -2);
                    color = self.style.hovered;
                }

                self.drawer.push_rect(bounds);
                self.drawer.push_borders(bounds, 2, color.border_color);
                self.push_text(
                    bounds.add_padding(5, 0),
                    input.slice,
                    .Left,
                    color.text_color,
                );
            }

            self.states.put(input_id, .{ .Input = input }) catch unreachable;
        }

        pub fn edit_string(self: *Self, buf: [:0]u8) !void {
            const id = self.gen_id();
            var is_focus = false;
            var value = mem.spanZ(buf);

            const rect = self.current_layout().allocate_space(null);
            const state = self.bounds_state(rect, true);

            // Bring the current input to focus if nothing is focused.
            if (self.focus_item == null and state.is_clicked) {
                self.focus_item = id;
            }

            // Now, if the focus item is equal to our input item,
            // we start the editing.
            if (self.focus_item) |item_id| {
                is_focus = item_id == id;
                const is_delete = self.get_key(.Bspc).is_down;

                if (is_focus) {
                    const text_buf = self.string_buffer.items;
                    if (text_buf.len > 0 and !is_delete) {
                        _ = fmt.bufPrintZ(buf, "{s}{s}", .{
                            value,
                            text_buf,
                        }) catch |err| {
                            // If no space is left, we do nothing.
                        };
                    }

                    if (is_delete and value.len > 0) {
                        value[value.len - 1] = '\x00';
                    }
                }

                if (is_focus and state.is_missed) {
                    self.focus_item = null;
                }
            }

            // Draw instructions.
            {
                var color = if (self.is_on_front())
                    self.style.normal
                else
                    self.style.disabled;

                var bounds = if (state.is_hover)
                    rect.add_padding(-2, -2)
                else
                    rect;

                if (is_focus) {
                    bounds = rect.add_padding(-2, -2);
                    color = self.style.hovered;
                }

                self.drawer.push_rect(bounds);
                self.drawer.push_borders(bounds, 2, color.border_color);
                self.push_text(
                    bounds.add_padding(5, 0),
                    value,
                    .Left,
                    color.text_color,
                );
            }
        }

        pub fn label_alloc(
            self: *Self,
            comptime text: []const u8,
            args: anytype,
            aligment: TextAlignment,
        ) !void {
            const allocator = self.cfg.allocator;
            const string = try fmt.allocPrint(allocator, text, args);
            try self.string_storage.append(string);
            self.label(string, aligment);
        }

        pub fn label(
            self: *Self,
            text: []const u8,
            aligment: TextAlignment,
        ) void {
            const layout = self.current_layout();
            const min_width = self.get_text_size(text);
            const rect = layout.allocate_space(min_width);
            const color = if (self.is_on_front())
                self.style.normal.text_color
            else
                self.style.disabled.text_color;

            self.push_text(rect, text, aligment, color);
        }

        /// Get current overlay.
        /// TODO: Rename this function...
        fn get_current(self: *const Self) *Overlay {
            const entry = self.states.getEntry(self.current_overlay);
            return &entry.?.value_ptr.Overlay;
        }

        fn current_layout(self: *const Self) *Layout {
            const overlay = self.get_current();
            return &overlay.layout;
        }

        pub fn popup_begin(self: *Self, title: []const u8) bool {
            const padding = 10;

            return self.panel(
                title,
                self.cursor.x + padding,
                self.cursor.y + padding,
                300,
                500,
            );
        }

        pub fn select(
            self: *Self,
            items: [][]const u8,
            selected: anytype,
        ) @TypeOf(selected) {
            const T = @TypeOf(selected);

            var currently_selected = selected;
            var old_current = self.current_overlay;
            var input_bounds = self.current_layout().allocate_space(null);
            const state = self.bounds_state(input_bounds, true);

            // Draw instructions for selected input box.
            {
                var color = if (state.status != .Disabled)
                    self.style.normal
                else
                    self.style.disabled;

                self.drawer.push_rect(input_bounds);
                self.drawer.push_borders(input_bounds, 2, color.border_color);
                self.push_text(
                    input_bounds.add_padding(5, 0),
                    items[selected],
                    .Left,
                    color.text_color,
                );
            }

            const options_height = @intToFloat(f32, items.len) * input_bounds.h;

            const overlay = self._overlay(
                "select_id",
                Rect.new(
                    input_bounds.x,
                    input_bounds.y + input_bounds.h,
                    input_bounds.w,
                    options_height,
                ),
                .{ .hori = 0, .vert = 0, .space = 0 },
                .{ .overlay_type = .Select, .closed = true, .bordered = true },
            ) catch {
                @panic("Crash while creating/getting new overlay.\n");
            };

            if (!overlay.is_closed) {
                self.draw_overlay(overlay.*);

                for (items) |item_label, index| {
                    if (self._raw_button(item_label, false, false, null)) {
                        currently_selected = @intCast(T, index);
                        overlay.is_closed = true;
                        self.layer.bring_to_front = old_current;
                    }
                }

                self.drawer.push_borders(overlay.bounds(), 2, self.style.normal.border_color);
            }

            if (state.is_clicked) {
                overlay.is_closed = !overlay.is_closed;
                if (!overlay.is_closed) self.layer.bring_to_front = overlay.id;
            }

            self.current_overlay = old_current;
            self.drawer.set_cmd_id(old_current);
            return currently_selected;
        }

        pub fn tree_begin(
            self: *Self,
            title: []const u8,
            expanded: bool,
            mode: enum { Collapser, Tree },
        ) bool {
            self.row_flex(20, 1);

            const layout = self.current_layout();
            const current_win = self.get_current();

            const tree_id = blk: {
                var hash = Wyhash.init(@intCast(u64, self.gen_id()));
                hash.update(current_win.title);
                hash.update(title);
                break :blk hash.final();
            };

            var tree = if (self.states.get(tree_id)) |cached|
                cached.Tree
            else
                Tree{ .is_expanded = expanded };

            var rect = layout.allocate_space(null);
            const state = self.bounds_state(rect, true);
            const color = self.style.widget_color(state.status);

            if (state.is_clicked) tree.is_expanded = !tree.is_expanded;
            if (tree.is_expanded) layout.indent += self.style.indent;

            // Draw instructions.
            {
                rect.color = color.base_color;

                const size = self.cfg.font_size - 5;
                const icon_bounds = rect.add_padding(self.style.indent, 0);
                var icon = icon_bounds.y_center(size, size);

                switch (mode) {
                    .Collapser => {
                        self.drawer.push_rect(rect);
                        self.drawer.push_borders(rect, 1, color.border_color);
                        self.drawer.push_triangle(
                            icon,
                            size,
                            color.border_color,
                            if (tree.is_expanded) .Down else .Right,
                        );
                        self.push_text(rect, title, .Center, color.text_color);
                    },
                    .Tree => {
                        self.drawer.push_triangle(
                            icon,
                            size,
                            color.border_color,
                            if (tree.is_expanded) .Down else .Right,
                        );
                        const region = rect.add_padding(35, 0);
                        self.push_text(region, title, .Left, color.text_color);
                    },
                }
            }

            self.states.put(tree_id, .{ .Tree = tree }) catch unreachable;
            return tree.is_expanded;
        }

        pub fn tree_end(self: *Self) void {
            self.current_layout().indent -= self.style.indent;
            self.padding_space(10);
            self.row_flex(0, 1);
        }

        /// TODO: Should review...
        pub fn slider(self: *Self, min: f32, max: f32, value: f32, step: f32) f32 {
            var bounds = self.current_layout().allocate_space(null);
            const cursor_h = bounds.h - 5;
            const cursor_w = cursor_h * 0.5;

            const range = max - min;
            var slider_value = math.clamp(value, min, max);
            const slider_steps = range / step;
            const offset = (slider_value - min) / step;

            var logical_cursor: Rect = undefined;
            var visual_cursor: Rect = undefined;
            visual_cursor.color = self.style.normal.border_color;

            logical_cursor.h = bounds.h;
            logical_cursor.w = bounds.w / slider_steps;
            logical_cursor.x = bounds.x + (logical_cursor.w * offset);
            logical_cursor.y = bounds.y;

            visual_cursor.h = cursor_h;
            visual_cursor.w = cursor_w;
            visual_cursor.y = (bounds.y + bounds.h * 0.5) - visual_cursor.h * 0.5;
            visual_cursor.x = logical_cursor.x - visual_cursor.w * 0.5;

            const cursor_state = self.bounds_state(visual_cursor, true);
            const cursor_color = self.style.widget_color(cursor_state.status);

            var border_color = cursor_color.border_color;
            bounds.color = cursor_color.base_color;
            visual_cursor.color = cursor_color.text_color;

            if (self.dragging(visual_cursor, self.gen_id())) {
                var ratio: f32 = 0;
                const d = self.cursor.x - (visual_cursor.x + visual_cursor.w * 0.5);
                const pxstep = bounds.w / slider_steps;

                if (math.fabs(d) >= pxstep) {
                    const steps = @divTrunc(math.fabs(d), pxstep);
                    slider_value += if (d > 0) step * steps else -(step * steps);
                    slider_value = math.clamp(slider_value, min, max);
                    ratio = (slider_value - min) / step;
                    logical_cursor.x = bounds.x + (logical_cursor.w * ratio);
                }

                bounds.color = self.style.pressed.base_color;
                visual_cursor.color = self.style.pressed.text_color;
                border_color = self.style.pressed.border_color;
            }

            visual_cursor.x = logical_cursor.x - visual_cursor.w * 0.5;

            // Draw instructions.
            {
                self.drawer.push_rect(bounds);
                self.drawer.push_borders(bounds, 2, border_color);
                self.drawer.push_rect(visual_cursor);
            }

            return slider_value;
        }

        pub fn button(self: *Self, text: []const u8) bool {
            return self._raw_button(text, true, true, null);
        }

        fn _raw_button(
            self: *Self,
            text: []const u8,
            bordered: bool,
            text_centered: bool,
            region: ?Rect,
        ) bool {
            const layout = self.current_layout();
            var rect = if (region) |reg| reg else layout.allocate_space(null);

            const state = self.bounds_state(rect, true);
            const color = self.style.widget_color(state.status);

            // Draw instructions.
            {
                rect.color = color.base_color;
                self.drawer.push_rect(rect);
                if (bordered) self.drawer.push_borders(rect, 2, color.border_color);
                self.push_text(
                    rect.add_padding(5, 0),
                    text,
                    if (text_centered) .Center else .Left,
                    color.text_color,
                );
            }

            return state.is_clicked;
        }

        pub fn row_static(
            self: *Self,
            width: f32,
            height: f32,
            items: i32,
        ) void {
            assert(items > 0);

            const layout = self.current_layout();
            layout.reset();
            layout.column_threshold = items;
            layout.row_mode = .{ .RowFixed = width };
            layout.height = math.max(self.min_height(), height);
        }

        pub fn row_array_static(
            self: *Self,
            item_widths: []const f32,
            height: f32,
        ) void {
            assert(item_widths.len > 0);

            const layout = self.current_layout();
            layout.reset();
            layout.column_threshold = @intCast(i32, item_widths.len);
            layout.row_mode = .{ .RowFixedArray = item_widths };
            layout.height = math.max(self.min_height(), height);
        }

        /// Create new flex row.
        pub fn row_flex(self: *Self, height: f32, threshold: i32) void {
            assert(threshold > 0);

            const layout = self.current_layout();
            layout.reset();
            layout.column_threshold = threshold;
            layout.row_mode = .{ .RowFlex = {} };
            layout.height = math.max(self.min_height(), height);
        }

        // Push Text to the draw list.
        fn push_text(
            self: *Self,
            r: Rect,
            text: []const u8,
            alignment: TextAlignment,
            color: Color,
        ) void {
            const half_size = self.cfg.font_size / (2 + 2);

            var x = r.x;
            var y = r.y + (r.h / 2) + half_size;

            if (alignment == .Center) {
                const text_width = self.get_text_size(text);
                x = r.x + (r.w / 2) - (text_width / 2);
            }

            if (alignment == .Right) {
                const text_width = self.get_text_size(text);
                x = math.max(x, r.x + r.w - text_width);
            }

            self.drawer.push_text(.{
                .x = x,
                .y = y,
                .color = color,
                .content = text,
            });
        }

        /// Bring to front the registered overlay.
        fn sort_layers(self: *Self) void {
            if (self.layer.bring_to_front) |focus_id| {
                for (self.layer.orders.items) |id, index| {
                    if (id == focus_id) {
                        _ = self.layer.orders.orderedRemove(index);
                    }
                }

                self.layer.orders.append(focus_id) catch unreachable;
            }
        }

        pub fn process_ui(self: *Self) DrawerData {
            self.sort_layers();
            return self.drawer.process_ui(self.layer.orders.items);
        }

        pub fn draw(self: *Self) []DrawSlice {
            return self.drawer.draw_list.items;
        }

        fn gen_id(self: *Self) i32 {
            const current_id = self.last_id;

            self.last_id += 1;
            return current_id;
        }

        fn dragging(self: *Self, region: Rect, id: i32) bool {
            const cursor = self.get_key(.Cursor);
            const is_hover = self.cursor_vs_rect(region);

            if (self.dragging_id) |dragger_id| {
                if (dragger_id == id) {
                    if (!cursor.is_repeat) {
                        self.dragging_id = null;
                    }

                    return true;
                }
            } else {
                if (cursor.is_repeat and is_hover and self.is_on_front()) {
                    self.dragging_id = id;
                }
            }

            return false;
        }

        /// Z index is simply the position in the layer orders stack.
        /// It should always find it.
        fn find_zindex(self: *Self, id_to_find: Id) ?usize {
            for (self.layer.orders.items) |id, zindex| {
                if (id == id_to_find) return zindex;
            }

            return null;
        }

        /// Try to bring an overlay to front.
        fn should_bring_to_front(self: *Self, bounds: Rect, z_index: usize) bool {
            const state = self.bounds_state(bounds, false);

            if (!state.is_clicked or self.is_on_front()) {
                return false;
            }

            // At this point, we know two things:
            //  - Current overlay isn't already on top of the orders stack.
            //  - Mouse is pressed and hovered the overlay region.

            var activate = true;

            // Now, we iterate over all overlay that are in front
            // of the current one in order to check if the "clicked"
            // part was visible.
            for (self.layer.orders.items[z_index + 1 ..]) |id| {
                if (self.states.get(id)) |entry| {
                    switch (entry) {
                        .Overlay => |win| {
                            const intersection_region = Rect.intersect(bounds, win.bounds());

                            if (self.cursor_vs_rect(intersection_region)) {
                                activate = false;
                                break;
                            }
                        },
                        else => {},
                    }
                }
            }

            return activate;
        }

        /// Return if the given bounds is clicked, hovered, pressed.
        /// If the current overlay isn't hovered, return the default state.
        /// TODO: Rename to `get_bounds_state`?
        fn bounds_state(self: *const Self, rect: Rect, check_focus: bool) BoundState {
            if ((check_focus and !self.is_on_front()) or self.disabled) {
                return BoundState{};
            }

            const cursor = self.get_key(.Cursor);

            const is_hover = self.cursor_vs_rect(rect);
            const is_clicked = is_hover and cursor.is_down;
            const is_pressed = is_hover and cursor.is_repeat;
            const is_missed = cursor.is_down and !is_hover;

            const status: Status = blk: {
                if ((is_pressed or is_clicked) and is_hover) {
                    break :blk .Pressed;
                } else if (is_hover) {
                    break :blk .Hovered;
                }

                break :blk .Normal;
            };

            return .{
                .is_hover = is_hover,
                .is_clicked = is_clicked,
                .is_pressed = is_pressed,
                .is_missed = is_missed,
                .status = status,
            };
        }

        /// Return if the current overlay is the active one.
        fn is_on_front(self: *const Self) bool {
            const orders = &self.layer.orders;
            const len = orders.items.len;

            if (len == 0) return false;

            return orders.items[len - 1] == self.current_overlay;
        }

        /// Default height equal to the font size + text_padding.
        fn min_height(self: *const Self) f32 {
            return self.cfg.font_size + self.style.text_padding;
        }

        fn cursor_vs_rect(self: *const Self, rect: Rect) bool {
            return point_vs_rect(rect, self.cursor.x, self.cursor.y);
        }

        fn get_text_size(self: *const Self, text: []const u8) f32 {
            return self.cfg.calc_text_size(
                self.cfg.font,
                self.cfg.font_size,
                text,
            );
        }

        fn point_vs_rect(rect: Rect, x: f32, y: f32) bool {
            return x >= rect.x and
                x <= (rect.x + rect.w) and
                y >= rect.y and
                y <= (rect.y + rect.h);
        }

        fn draw_overlay(self: *Self, win: Overlay) void {
            const color = if (self.is_on_front())
                self.style.normal
            else
                self.style.disabled;

            const bounds = win.bounds();

            var mut_win = win;
            mut_win.body.color = self.style.background_color;

            self.drawer.push_clip(bounds.x, bounds.y, bounds.w, bounds.h);

            if (mut_win.header) |*header| {
                header.color = color.base_color;
                self.drawer.push_rect(header.*);
                self.push_text(header.*, win.title, .Center, color.text_color);
            }

            self.drawer.push_rect(mut_win.body);

            if (win.options.bordered) {
                self.drawer.push_borders(bounds, 1, color.border_color);
            }

            if (mut_win.closer) |*closer| {
                closer.color = color.base_color;
                self.drawer.push_rect(closer.*);
                self.push_text(closer.*, "-", .Center, color.text_color);
            }

            if (mut_win.resizer) |*resizer| {
                const size = self.cfg.font_size - 5;
                self.drawer.push_triangle(resizer.*, size, color.text_color, .DiagRight);
            }

            if (mut_win.scroll) |*scroll| {
                scroll.color = color.base_color;
                self.drawer.push_rect(scroll.*);
            }
        }

        /// Shrink allocated memory used in the last frame.
        pub fn reset(self: *Self) void {
            self.last_id = 0;
            self.is_hot = false;
            self.layer.bring_to_front = null;
            self.string_buffer.shrinkAndFree(0);
            self.drawer.reset();
            defer self.string_storage.shrinkAndFree(0);

            for (self.string_storage.items) |ptr| {
                self.cfg.allocator.free(ptr);
            }
        }

        pub fn deinit(self: *Self) void {
            const allocator = self._arena.child_allocator;
            self._arena.deinit();
            allocator.destroy(self._arena);
        }
    };
}

const TestFont = struct {};
fn calc_text_size(font: *TestFont, size: f32, text: []const u8) f32 {
    return 150;
}

test "interface.init" {
    var test_font = TestFont{};

    var ui = try Interface(TestFont).init(.{
        .allocator = test_allocator,
        .font = test_font,
        .font_size = 16,
        .calc_text_size = calc_text_size,
    }, .{});
    defer ui.deinit();
}
