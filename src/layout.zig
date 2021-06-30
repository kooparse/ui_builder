const std = @import("std");
const Rect = @import("./ui.zig").Rect;
const math = std.math;

const RowLayoutMode = enum { RowFlex, RowFixed, RowFixedArray };

const LayoutOptions = struct {
    spacing: f32,
    vert_pad: f32,
    hori_pad: f32,
};

/// Layout.
pub const Layout = struct {
    /// Parent region (egual to region's body).
    /// TODO Rename to just `space` or `region`
    /// or `area`.
    parent: Rect,
    /// Cursor region through the parent region available.
    cursor: struct { x: f32, y: f32 },

    indent: f32 = 0,

    is_first_on_row: bool = true,

    is_bigger_than_parent: bool = false,

    spacing: f32 = 5,
    height: f32,

    row_mode: union(RowLayoutMode) {
        RowFlex: void,
        RowFixed: f32,
        RowFixedArray: []const f32,
    } = .RowFlex,

    /// Maximum number of column allowed.
    column_threshold: i32 = 1,
    /// The number of column currently filled.
    /// Will never be bigger than the threshold.
    column_filled: i32 = 0,

    const Self = @This();

    pub fn new(parent: Rect, height: f32, spacing: f32) Self {
        return .{
            .parent = parent,
            .spacing = spacing,
            .cursor = .{ .x = parent.x, .y = parent.y },
            .height = height,
        };
    }

    /// Return the layout total width according to
    /// current indentation.
    fn layout_width(self: *const Self) f32 {
        const padded_parent = self.parent.add_padding(self.indent, 0);
        return padded_parent.w;
    }

    pub fn reset(self: *Self) void {
        self.column_filled = 0;
        if (!self.is_first_on_row) self.add_row();
    }

    fn add_row(self: *Self) void {
        self.column_filled = 0;
        self.cursor.x = self.parent.x;
        self.cursor.y += self.height + self.spacing;
        self.is_first_on_row = true;
    }

    /// TODO: Fix remaining_width...
    fn cast_width(self: *Self, w: f32) f32 {
        if (w >= 0 and w <= 1) {
            const percent = math.max(0, w);

            const total_width = self.layout_width();
            // const remaining_width = total_width - self.cursor.x;
            var width = total_width * percent;

            // const count = self.column_threshold - self.column_filled;
            // if (count == 1 and width >= remaining_width) width = remaining_width;

            return width;
        }

        return w;
    }

    /// Allocate new space for widget.
    pub fn allocate_space(self: *Self, min: ?f32) Rect {
        const available_count = self.column_threshold - self.column_filled;

        if (available_count == 0) self.add_row();

        var widget_width: f32 = undefined;
        switch (self.row_mode) {
            .RowFlex => {
                const column_threshold = @intToFloat(f32, self.column_threshold);
                widget_width =
                    (self.layout_width() - self.spacing) * (1 / column_threshold);
            },
            .RowFixed => |w| {
                widget_width = self.cast_width(w) - self.spacing;
            },
            .RowFixedArray => |widths| {
                const index = @intCast(usize, math.max(0, self.column_filled));
                widget_width = self.cast_width(widths[index]) - self.spacing;
            },
        }

        if (min) |min_width| {
            widget_width = math.max(min_width, widget_width);
        }

        defer {
            self.cursor.x += widget_width + self.spacing;
            self.column_filled += 1;
            self.is_first_on_row = false;
            self.is_bigger_than_parent = 
                self.cursor.y > (self.parent.y + self.parent.h);
        }

        return Rect{
            .x = self.cursor.x + self.indent,
            .y = self.cursor.y,
            .w = widget_width,
            .h = self.height,
        };
    }
};
