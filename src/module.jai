/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right


    TODO:
    - rename many things, UI_Key...
    - no allocation for stack, clips etc? (not sure it's needed...).
    - not grear the dragging code, could be better.
    - check the perf... i found it a bit slow when dragging.


*/

#scope_file;

theme := Theme.{};

layout_stack    : [..] UI_Layout;
clip_stack      : [..] Rect;
parent_stack    : [..] UI_Parent;

hot_occluder    : UI_Key = -1;
active_occluder : UI_Key = -1;

hot_widget    : UI_Key = -1;
active_widget : UI_Key = -1;

occluder_stack           : [..] Occlusion;
occluder_currently_drawn : UI_Key;

Occlusion :: struct {
    depth       : int;
    rect        : Rect;
    widget_id   : UI_Key;
};

UI_Key :: int;

UI_Parent :: struct {
    index  := -1;
    rect   : Rect; // area ?
    layout : UI_Layout;

    spread : bool; // rename this.
    col_index := 0;
};

Persistent_State :: struct {
    id      : UI_Key = -1;
    pressed : bool;
    hovered : bool;
    once    : bool;

    // I don't like those things.
    dragging        : bool;
    dragging_start  : Vector2;
    start           : Vector2;

    using rect : Rect;
    // delta... etc...
};

persistent : Table(UI_Key, Persistent_State);
list       : [..] UI_Region;

mouse_x  : float;
mouse_y  : float;

left_pressed  : bool;
right_pressed : bool;

vertices      : [..] UI_Vertex;

#scope_export;

Layout_Order :: enum { STACK; INLINE; COLUMNS; };

Layout_Align :: enum {
    PIXEL_LEFT;
    PIXEL_CENTER;
    PIXEL_RIGHT;
};

UI_Layout :: struct {
    order           := Layout_Order.STACK;
    align           := Layout_Align.PIXEL_LEFT;
    column_count    := 0;
};

UI_Theme :: struct {
    text_size    := 16.0;
    text_color   := Vector4.{ 0, 0, 0, 1 };
    bg_color     := Vector4.{ 1, 1, 1, 1 };
    border_color := Vector4.{ 0, 0, 0, 1 };

    padding      := Vector2.{ 2.5, 2.5 };
};

Theme_State :: struct {
    normal   : UI_Theme;
    hovered  : UI_Theme;
    focused  : UI_Theme;
    disabled : UI_Theme;
};

Theme :: struct {
    button := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 1, 0, 0, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0, 0, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.7, 0, 0, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };

    panel_title := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };

    panel_content := Theme_State.{};

    resizer := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };
};

UI_Flags :: enum_flags {
    CLICKABLE           :: (1 << 0);
    SCROLLABLE          :: (1 << 1);
    DRAW_TEXT           :: (1 << 2);
    DRAW_BACKGROUND     :: (1 << 3);
    DRAW_BORDER         :: (1 << 4);

    MOVEABLE            :: (1 << 5);
    RESIZEABLE          :: (1 << 6);
    MINIMIZABLE         :: (1 << 7);
};

// Rename "UI_Element".
UI_Region :: struct {
    key     : UI_Key;
    flags   : UI_Flags;
    label   : string;
    rect    : Rect; // rename "computed_rect".

    size    : Vector2;

    occluder : UI_Key;
    parent  : UI_Parent;

    theme   : UI_Theme;
};

UI_State :: struct {
    pressed : bool;
    hovered : bool;
};

UI_Vertex :: struct {
    position : Vector2;
    uv       : Vector2;
    color    : Vector4;
};

Rect :: struct { x: float; y: float; w: float; h: float; };


ui_set_theme :: () {}

ui_set_mouse_press :: (left: bool, right := false) {
    left_pressed    = left;
    right_pressed   = right;
}

ui_set_mouse :: (x: float, y: float) {
    mouse_x = x;
    mouse_y = y;
}

ui_begin :: () {
    array_reset_keeping_memory(*vertices);

    array_reset_keeping_memory(*list);
    array_reset_keeping_memory(*parent_stack);
}

// Return old layout as well.
ui_set_layout :: (order: Layout_Order, column_count := 0) -> UI_Layout {
    parent := get_parent();

    old_layout := parent.layout;

    parent.layout = UI_Layout.{ order = order, column_count = column_count };
    return old_layout;
}

ui_set_align :: (align: Layout_Align) -> Layout_Align {
    parent := get_parent();

    old_align := parent.layout.align;

    parent.layout.align = align;
    return old_align;

}

ui_end :: () {
    layout_pass();


    {
        for occluder_stack {
            found, state := table_find(*persistent, it.widget_id);
            if !found continue;

            cursor := Vector2.{ mouse_x, mouse_y };
            // if point_vs_rect(cursor, state.rect) {
                // hot_occluder =
            // }
        }
    }

    // Add draw commands, but now it's just vertices.
    {

        for region: list {
            theme := region.theme;
            r     := region.rect;

            p0 := Vector2.{ r.x, r.y };
            p1 := Vector2.{ r.x + r.w, r.y };
            p2 := Vector2.{ r.x, r.y + r.h };
            p3 := Vector2.{ r.x + r.w, r.y + r.h };

            uv0 := Vector2.{ 0, 0 };
            uv1 := Vector2.{ 1, 0 };
            uv2 := Vector2.{ 0, 1 };
            uv3 := Vector2.{ 1, 1 };

            if region.flags & .DRAW_BACKGROUND {
                push_triangle(p0, p1, p2, theme.bg_color, uv0, uv1, uv2);
                push_triangle(p2, p1, p3, theme.bg_color, uv2, uv1, uv3);
            }

            if region.flags & .DRAW_BORDER {
                // draw border...
            }

            if region.flags & .DRAW_TEXT {
                // Draw text...
            }
        }

    }
}

ui_spread :: () {
    parent := get_parent();
    parent.spread = true;
}

layout_pass :: () {
    cursors := NewArray(list.count, Vector2);
    defer array_free(cursors);

    col_index := 0;

    // Phase 1: Compute all sizes.
    // for *region: list {
    //     if region.parent.index < 0 {
    //         continue;
    //     }
    //
    //     parent_width := region.parent.rect.w;
    //     layout       := region.parent.layout;
    //
    //     if layout.align == .GROW {
    //         if layout.order == .COLUMNS {
    //             region.size.x = parent_width / layout.column_count;
    //         } else {
    //             region.size.x = parent_width;
    //         }
    //
    //     }
    // }

    for *region: list {
        if region.parent.index < 0 {
            continue;
        }

        parent := region.parent;
        cursor := *cursors[region.parent.index];

        base_x := parent.rect.x + region.theme.padding.x;
        base_y := parent.rect.y + region.theme.padding.y;

        // Add padding...
        region.rect.x = base_x + cursor.x;
        region.rect.y = base_y + cursor.y;
        region.rect.w = region.size.x;
        region.rect.h = region.size.y;

        if parent.spread {
            if parent.layout.order == .COLUMNS {
                column_count   := parent.layout.column_count;
                col_width      := parent.rect.w / column_count;

                region.rect.w = col_width;
            } else {
                leftover := parent.rect.w - cursor.x;
                region.rect.w = leftover;
            }

        }

        // We base ourself on the coming up region because ui_set_layout
        // are set before the elements in the stack order.
        if it_index != list.count - 1 { // If not last.
            next_region := list[it_index + 1];

            if next_region.parent.layout.order == {
                case .INLINE;
                    cursor.x += region.size.x + region.theme.padding.x;
                case .STACK;
                    cursor.x  = 0;
                    cursor.y += region.size.y + region.theme.padding.y;

                case .COLUMNS;
                    column_count   := next_region.parent.layout.column_count;
                    col_width      := next_region.parent.rect.w / column_count;

                    // If previously the layout was set to INLINE, we want
                    // to reset the x axis before.
                    if region.parent.layout.order == .INLINE {
                        cursor.x  = 0;
                        cursor.y += region.size.y + region.theme.padding.y;
                    }

                    if col_index == column_count {
                        col_index = 0;
                        cursor.x = 0;
                        cursor.y += region.size.y + region.theme.padding.y;
                    } else {
                        cursor.x  += ifx col_index > 0 col_width else 0;
                        col_index += 1;
                    }
            }

            // We want to reset the column index if we get out of column layout.
            if next_region.parent.layout.order != .COLUMNS {
                col_index = 0;
            }
        }
    }

    // Update rect to persistent state.
    for list {
        persistent_region := table_find_pointer(*persistent, it.key);
        assert(persistent_region != null);
        persistent_region.id   = it.key;
        persistent_region.rect = it.rect;
    }
}

Region_Status :: struct {
    hovered : bool;
    clicked : bool;
};

ui_begin_panel :: (region: Rect, title: string, loc := #caller_location) {
    x : float;
    y : float;
    w : float;

    {
        key     := ui_key(loc, "_full_region");
        p, new  := find_or_add(*persistent, key);

        if new {
            p.rect = region;
        }

        ui_set_state(p);

        x = p.rect.x;
        y = p.rect.y;
        w = p.rect.w;

        full_region := UI_Region.{
            key     = key,
            flags   = UI_Flags.MOVEABLE,
            rect    = p.rect,
            occluder = occluder_currently_drawn,
        };

        array_add(*list, full_region);

        push_occluder(key, p.rect);
    }


    title_height := region.h * 0.15;
    {
        key     := ui_key(loc, "_title");
        p, new  := find_or_add(*persistent, key);

        title_region := UI_Region.{
            key     = key,
            flags   = UI_Flags.DRAW_TEXT | .DRAW_BACKGROUND | .DRAW_BORDER,
            theme   = theme.panel_title.normal,
            rect    = Rect.{ x, y, w, title_height },
        };


        array_add(*list, title_region);
    }

    {
        key     := ui_key(loc, "_content");
        p       := find_or_add(*persistent, key);

        content_region := UI_Region.{
            key     = key,
            flags   = UI_Flags.DRAW_TEXT | .DRAW_BACKGROUND | .DRAW_BORDER | .MOVEABLE,
            theme   = theme.panel_content.normal,
            rect    = Rect.{ x, y + title_height, region.w, region.h - title_height },
            occluder = occluder_currently_drawn,
        };

        p.rect = content_region.rect;

        push_parent(list.count, content_region.rect);
        array_add(*list, content_region);
    }


    {
        size    := 8.0;

        key     := ui_key(loc, "_resize_btn");
        p       := find_or_add(*persistent, key);

        resize_region := UI_Region.{
            key     = key,
            flags   = UI_Flags.DRAW_TEXT | .DRAW_BACKGROUND,
            theme   = theme.resizer.normal,
            rect    = Rect.{ x + region.w - size, y + region.h - size, size, size },
            occluder = occluder_currently_drawn,
        };

        ui_set_state(p);

        array_add(*list, resize_region);
    }
}

ui_end_panel :: () {
    pop_parent();
    pop_occluder();
}

ui_button :: (label: string, size := Vector2.{ 100, 40 }, loc := #caller_location) -> bool {
    key     := ui_key(loc);
    p       := find_or_add(*persistent, key);

    ui_set_state(p);

    parent  := get_parent();

    array_add(*list, UI_Region.{
        key      = key,
        size     = size,
        theme    = ui_theme(p.*, theme.button),
        flags    = UI_Flags.CLICKABLE | .DRAW_TEXT | .DRAW_BACKGROUND | .DRAW_BORDER,
        label    = label,
        parent   = parent,
        occluder = occluder_currently_drawn,
    });

    return p.once;
}

ui_theme :: (state: Persistent_State, theme_state: Theme_State) -> UI_Theme {
    if state.pressed return theme_state.focused;
    if state.hovered && !state.pressed return theme_state.hovered;

    return theme_state.normal;
}

is_occluded :: (state: *Persistent_State) -> bool {
    return false;
    // if state.id < 0 return true; // no layout pass occured yet.
    //
    // if occluder_currently_drawn != state.occluder_currently_drawn return true;
    //
    // found, occluder := table_find(*persistent, occluder_currently_drawn);
    // if !found return false; // assert?

    // if
    // rect_vs_rect(occluder.rect, state.rect)
    //
    // p, new  := find(*persistent, occluder_currently_drawn);
    // if rect_vs_rect()
    // if occluder_currently_drawn
}

ui_set_state :: (state: *Persistent_State) {
    hovered := point_vs_rect(mouse_x, mouse_y, state.rect);

    if state.dragging {
        now             := Vector2.{ mouse_x, mouse_y };
        dragging_delta  := now - state.dragging_start;

        state.rect.x = state.start.x + dragging_delta.x;
        state.rect.y = state.start.y + dragging_delta.y;
    }

    if state.dragging && !left_pressed {
        state.dragging = false;
    }

    if !state.pressed && hovered && left_pressed {
        state.dragging       = true;
        state.dragging_start = Vector2.{ mouse_x, mouse_y };
        state.start          = Vector2.{ state.rect.x, state.rect.y };
    }

    state.hovered = hovered;

    was_pressed     := state.pressed;
    state.pressed    = hovered && left_pressed;
    state.once       = !was_pressed && state.pressed;
}

get_vertices :: () -> [] UI_Vertex {
    return vertices;
}

#scope_file;

push_occluder :: (id: UI_Key, rect: Rect) {
    occluder_currently_drawn = id;

    array_add(*occluder_stack, .{
        depth       = occluder_stack.count,
        widget_id   = id,
        rect        = rect,
    });
}

// todo: some asserts could be cool to put there.
pop_occluder :: () {
    pop(*occluder_stack);
    occluder_currently_drawn = ifx occluder_stack then peek(occluder_stack).widget_id;
}

get_parent :: () -> *UI_Parent {
    if parent_stack.count <= 0 {
        assert(false, "you must have a parent set...");
    }

    return *parent_stack[parent_stack.count - 1];
}

push_parent :: (parent_index: int, rect: Rect) {
    array_add(*parent_stack, .{ index = parent_index, rect = rect });
}

pop_parent :: () {
    if parent_stack.count <= 0 {
        assert(false, "pop but no parent in the fucking array....");
    }

    pop(*parent_stack);
}

point_vs_rect :: (x: float, y: float, rect: Rect) -> bool {
    return x > rect.x && x < (rect.x + rect.w) && y > rect.y && y < (rect.y + rect.h);
}

rect_vs_rect :: inline (rect: Rect, other: Rect) -> bool {
    return other.x < rect.x + rect.w && rect.x < other.x + other.w
    && other.y < rect.y + rect.h && rect.y < other.y + other.h;
}

push_triangle :: (p0: Vector2, p1: Vector2, p2: Vector2, color: Vector4, uv0: Vector2, uv1: Vector2, uv2: Vector2) {
    array_add(*vertices, .{ position = p0, uv = uv0, color = color });
    array_add(*vertices, .{ position = p1, uv = uv1, color = color });
    array_add(*vertices, .{ position = p2, uv = uv2, color = color });
}

ui_key :: (loc: Source_Code_Location, extra := "") -> u32 {
    h := sdbm_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
    h = sdbm_hash(*loc.line_number, size_of(type_of(loc.line_number)), h);
    h = sdbm_hash(*loc.character_number, size_of(type_of(loc.character_number)), h);

    if extra != "" {
        h = sdbm_hash(extra.data, size_of(u8) * extra.count, h);
    }

    return h;
}
