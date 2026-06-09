/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right


    TODO:
    - rename many things, ui_id...
    - no allocation for stack, clips etc? (not sure it's needed...).

    - better understanding for scrollbar
    - better understanding for roudned corner.
*/

// @todo: should import font.
#load "font.jai";
#load "theme.jai";

#scope_file;

#import "Sort";

UI_ID :: int;

// Context.
theme            := Theme.{};

prev_layer_list  : [..] Layer;
curr_layer_list  : [..] Layer;
layer_stack      : [..] int; // Index of layers from our current layer list.
current_layer    : *Layer;

widget_states   : Table(UI_ID, *Widget_State);

active_widget   : UI_ID = -1; // I want a pointer to the state directly....
hot_widget      : UI_ID = -1;

draw_list       : UI_Draw_List;

mouse_x  : float;
mouse_y  : float;
delta_x  : float;
delta_y  : float;

wheel_x  : float;
wheel_y  : float;

current_depth := 0;

// @todo: rename those variables.
left_pressed  : bool;
right_pressed : bool;

// @todo I don't like the name here...
Draw_Marker :: struct {
    clip_rect    : Rect;
    vertex_start : int;
};

UI_Layout :: struct {
    rect         : Rect;

    cursor       : Vector2; // @todo: explain that.
    prev_cursor  : Vector2;

    order      := Layout_Order.STACK;
    align      := Layout_Align.PIXEL_LEFT;
    columns    := 0;

    scroll     : Vector2;

    // For auto layout.
    curr_column      := 0;
    prev_widget_size : Vector2;
};


/*

    A Layer represent a surface where widgets are drawn on top of it.

*/

Layer :: struct {
    rect         : Rect;

    widget_id    : UI_ID;
    depth        : int; // Used to sort the layer list.

    layout       : UI_Layout;
    prev_layout  : UI_Layout;

    vertices     : [..] UI_Vertex;
    draw_markers : [..] Draw_Marker;
    clip_stack   : [..] Rect;
};

Widget_State :: struct {
    id      : UI_ID = -1;
    kind    : Type;
    rect    : Rect;

    pressed : bool;
    hovered : bool;
    once    : bool;
};

Window_State :: struct {
    #as using state : Widget_State;

    open     := true;
    dragging : enum { NONE; MOVE_WINDOW; RESIZE_WINDOW; }
};

Dropdown_State :: struct {
    #as using state : Widget_State;
    open            : bool;
};

#scope_export;

UI_Draw_Call :: struct {
    vertex_start : int;
    vertex_count : int;
    clip         : Rect; // rename clip?
};

UI_Draw_List  :: struct {
    vertices    : [..] UI_Vertex;
    draw_calls  : [..] UI_Draw_Call;
};

Layout_Order :: enum { STACK; INLINE; COLUMNS; };

Layout_Align :: enum {
    PIXEL_LEFT;
    PIXEL_CENTER;
    PIXEL_RIGHT;
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

Rect :: struct {
    x: float;
    y: float;
    w: float;
    h: float;

    #overlay (x) position   : Vector2;
    #overlay (w) size       : Vector2;
};

operator == :: (a: Rect, b: Rect) -> bool {
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

ui_set_theme :: () {}

ui_set_mouse_press :: (left: bool, right := false) {
    left_pressed    = left;
    right_pressed   = right;
}

ui_set_mouse :: (x: float, y: float) {
    delta_x = x - mouse_x;
    delta_y = y - mouse_y;

    mouse_x = x;
    mouse_y = y;
}

ui_set_wheel :: (x: float, y: float) {
    wheel_x = x;
    wheel_y = y;
}

ui_begin :: () {
    // Reset flat vertices.
    array_reset_keeping_memory(*draw_list.vertices);
    array_reset_keeping_memory(*draw_list.draw_calls);

    {
        swap(*prev_layer_list, *curr_layer_list);

        // Reset occlusion and widget list.
        for * curr_layer_list {
            array_reset(*it.vertices);
            array_reset(*it.draw_markers);
            array_reset(*it.clip_stack);
        }

        array_reset_keeping_memory(*curr_layer_list);
        array_reset_keeping_memory(*layer_stack);

        current_layer = null;
    }

}

ui_end :: () {
    // @todo: Add comment.
    quick_sort(curr_layer_list, (a, b) => a.depth - b.depth);

    /*

        We want an easy way to send the data on the GPU, so we construct a flat
        array with all vertices of the current frame.

        And each draw call is a slice of this big buffer, with specific clip
        region and texture pointer.

    */

    global_index := 0; // Base index on the flat vertices buffer.

    for curr_layer_list {

        for marker, index: it.draw_markers {
            vertex_end   := ifx  index == it.draw_markers.count - 1 it.vertices.count
                            else it.draw_markers[index + 1].vertex_start;

            vertex_count := vertex_end - marker.vertex_start;

            array_add(*draw_list.draw_calls, UI_Draw_Call.{
                vertex_start = global_index + marker.vertex_start,
                vertex_count = vertex_count,
                clip         = marker.clip_rect,
            });
        }

        // Append the local layer vertices to the flat one.
        array_add(*draw_list.vertices, ..it.vertices);

        global_index += it.vertices.count;
    }
}

get_draw_list :: () -> UI_Draw_List {
    return draw_list;
}

Rect_Flags :: enum_flags u32 {
    NONE                        :: 0x00;
    ROUND_TOP_LEFT_CORNER       :: (1 << 0);
    ROUND_TOP_RIGHT_CORNER      :: (1 << 1);
    ROUND_BOTTOM_LEFT_CORNER    :: (1 << 2);
    ROUND_BOTTOM_RIGHT_CORNER   :: (1 << 3);

    ROUND_ALL :: ROUND_TOP_LEFT_CORNER      |
                 ROUND_TOP_RIGHT_CORNER     |
                 ROUND_BOTTOM_LEFT_CORNER   |
                 ROUND_BOTTOM_RIGHT_CORNER;
};

draw_rect :: (r: Rect, color: Vector4, flags : Rect_Flags = 0x00) {
    if flags == .NONE {
        internal_draw_rect(r, color);
        return;
    }

    // For rounded corners:
    radius := 4.0;
    radius = min(radius, r.w * 0.5);
    radius = min(radius, r.h * 0.5);

    // For that, it means that each corner is a rect of radius dimension.

    top_left     := Rect.{ r.x, r.y, radius, radius };
    top_right    := Rect.{ r.x + r.w - radius, r.y, radius, radius };
    bottom_left  := Rect.{ r.x, r.y + r.h - radius, radius, radius };
    bottom_right := Rect.{ r.x + r.w - radius, r.y + r.h - radius, radius, radius };

    uv0 := xy(0, 0);
    uv1 := xy(0, 0);
    uv2 := xy(0, 0);

    SAMPLE  :: 16;

    if flags & .ROUND_TOP_LEFT_CORNER {

        p0 := xy(top_left.x + top_left.w, top_left.y + top_left.h);

        prev := p0 + xy(0, -radius);                 // angle 0, top

        for 1..SAMPLE {
            theta  := (PI * 0.5) * (it / cast(float) SAMPLE);

            p1     := prev;
            p2     := p0 + xy(-sin(theta) * radius, -cos(theta) * radius);

            push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_left, color);
    }

    if flags & .ROUND_TOP_RIGHT_CORNER {
        p0 := xy(top_right.x, top_right.y + top_right.h);

        prev := p0 + xy(0, -radius);
        for 1..SAMPLE {
            a  := (PI * 0.5) * (it / cast(float) SAMPLE);
            p2 := p0 + xy(sin(a) * radius, -cos(a) * radius);
            push_triangle(p0, prev, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_right, color);
    }

    if flags & .ROUND_BOTTOM_LEFT_CORNER {
        p0 := xy(bottom_left.x + bottom_left.w, bottom_left.y);

        prev := p0 + xy(0, radius);
        for 1..SAMPLE {
            a  := (PI * 0.5) * (it / cast(float) SAMPLE);
            p2 := p0 + xy(-sin(a) * radius, cos(a) * radius);
            push_triangle(p0, prev, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_left, color);
    }

    if flags & .ROUND_BOTTOM_RIGHT_CORNER {
        p0 := xy(bottom_right.x, bottom_right.y);

        prev := p0 + xy(0, radius);
        for 1..SAMPLE {
            a  := (PI * 0.5) * (it / cast(float) SAMPLE);
            p2 := p0 + xy(sin(a) * radius, cos(a) * radius);
            push_triangle(p0, prev, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_right, color);
    }

    // To fill up the rest of the belly of the rounded corner, we can do that with only
    // 3 rects.

    center_middle := Rect.{ r.x + radius, r.y, r.w - (2 * radius), r.h };
    internal_draw_rect(center_middle, color);

    right_middle := Rect.{ r.x, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(right_middle, color);
    left_middle := Rect.{ r.x + r.w - radius, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(left_middle, color);
}

internal_draw_rect :: (r: Rect, color: Vector4) {
    p0 := Vector2.{ r.x, r.y };
    p1 := Vector2.{ r.x + r.w, r.y };
    p2 := Vector2.{ r.x, r.y + r.h };
    p3 := Vector2.{ r.x + r.w, r.y + r.h };

    uv0 := Vector2.{ 0, 0 };
    uv1 := Vector2.{ 1, 0 };
    uv2 := Vector2.{ 0, 1 };
    uv3 := Vector2.{ 1, 1 };

    push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
    push_triangle(p2, p1, p3, color, uv2, uv1, uv3);
}


Region_Status :: struct {
    hovered : bool;
    clicked : bool;
};

begin_window :: (region: Rect, title: string, loc := #caller_location) -> bool {
    id    := ui_id(loc, "_full_region");
    state := get_widget_state(Window_State, id, default_rect = region);

    push_layer(id, state.rect);

    // If its layer was the topmost one of the last frame, we consider it as
    // "active".
    is_topmost  := ifx prev_layer_list peek(prev_layer_list).widget_id == id;

    update_rect_state(id, state, state.rect);
    // If we click somewhere on the layer, we want to raise it to the top of
    // the stack.
    want_raise := !is_topmost && state.once && active_widget == -1;
    if want_raise then raise_layer(id);


    title_rect     := state.rect;
    title_rect.h    = theme.window_title_bar_height;

    resizer_rect   := state.rect;
    resizer_rect.x += state.rect.w - theme.resize_size;
    resizer_rect.y += state.rect.h - theme.resize_size;
    resizer_rect.w  = theme.resize_size;
    resizer_rect.h  = theme.resize_size;

    dragging_allowed := active_widget == -1 && is_topmost && state.dragging == .NONE && left_pressed;

    // Start title bar dragging.
    if dragging_allowed && !is_occluded(title_rect) && cursor_vs_rect(title_rect) {
        // Prevent to mix clicking and dragging behavior.
        if (abs(delta_x) > 0 || abs(delta_y) > 0) {
            active_widget   = id;
            state.dragging  = .MOVE_WINDOW;
            log("Start moving!");
        }
    }

    // Start resizer dragging.
    if dragging_allowed && !is_occluded(resizer_rect) && cursor_vs_rect(resizer_rect) {
        // Prevent to mix clicking and dragging behavior.
        if (abs(delta_x) > 0 || abs(delta_y) > 0) {
            active_widget   = id;
            state.dragging  = .RESIZE_WINDOW;
            log("Start resizer!");
        }
    }

    if state.dragging != .NONE && !left_pressed {
        active_widget   = -1;
        state.dragging  = .NONE;
        log("Stop moving/resizer!");
    }

    if state.dragging == .MOVE_WINDOW {
        log("moving!");
        state.rect.x += delta_x;
        state.rect.y += delta_y;
    }

    if state.dragging == .RESIZE_WINDOW {
        log("resizing !");
        state.rect.w += delta_x;
        state.rect.h += delta_y;
    }

    // Once dragging is done, and we updated the window rect state, we make our
    // layer clip area.
    push_clip(state.rect);

    // Now, we recompute the title and resizer region, to get the latest
    // position/size.

    title_rect     = state.rect;
    title_rect.h    = theme.window_title_bar_height;

    resizer_rect    = state.rect;
    resizer_rect.x += state.rect.w - theme.resize_size;
    resizer_rect.y += state.rect.h - theme.resize_size;
    resizer_rect.w  = theme.resize_size;
    resizer_rect.h  = theme.resize_size;

    // Draw window background.
    window_theme := ifx is_topmost then theme.window_content.focused else theme.window_content.normal;
    draw_rect(state.rect, window_theme.bg_color, .ROUND_ALL);

    // Draw title bar.
    color := theme.window_title_bar.normal.bg_color;
    draw_rect(title_rect, color, .ROUND_TOP_LEFT_CORNER | .ROUND_TOP_RIGHT_CORNER);

    // Draw resizer.
    color  = theme.resizer.normal.bg_color;
    draw_rect(resizer_rect, theme.resizer.normal.bg_color, .ROUND_ALL);


    layer_rect   := state.rect;
    layer_rect.x += theme.content_padding;
    layer_rect.y += theme.window_title_bar_height + theme.content_padding;
    layer_rect.w -= (theme.scrollbar_width - theme.content_padding);
    layer_rect.h -= (theme.window_title_bar_height + theme.content_padding);

    current_layer.layout.rect = layer_rect;
    update_scrollbar(loc);

    push_clip(layer_rect);

    return state.open;
}

// rename window_end().
end_window :: () {
    pop_clip();
    pop_layer();
}

alloc_space :: (widget_size: Vector2, padding: Vector2) -> Rect {
    using layout  := *current_layer.layout;

    // If has a scrollbar.
    // @todo: remove this... there's a better way.
    // if max_scroll > 0 {
    //     content_rect.w -= theme.scrollbar_width;
    // }

    size := widget_size;

    if order != .COLUMNS then curr_column = 0;

    if prev_widget_size.x > 0 || prev_widget_size.y > 0 {
        if order == {
            case .STACK;
                cursor.y += prev_widget_size.y + padding.y;
            case .INLINE;
                cursor.x += prev_widget_size.x + padding.x;
            case .COLUMNS;
                col_width := (layout.rect.w) / max(1, columns);
                size.x     = col_width - padding.x;

                // @todo: Here we have to take into account the padding.

                if curr_column == 0 {
                    cursor.x  = 0;
                    cursor.y += prev_widget_size.y + padding.y;
                    curr_column += 1;
                } else {
                    cursor.x  += ifx curr_column > 0 col_width else 0;
                    curr_column += 1;
                }

                if curr_column >= columns {
                    curr_column = 0;
                }
        }
    } else {
        // I don't like this tho....
        if order == .COLUMNS {
            col_width := (layout.rect.w) / max(1, columns);
            size.x     = col_width - padding.x;
        }
    }

    base_x := layout.rect.x - scroll.x;
    base_y := layout.rect.y - scroll.y;

    r := Rect.{ base_x + cursor.x, base_y + cursor.y, size.x, size.y };

    r.x = round_pixel(r.x);
    r.y = round_pixel(r.y);
    r.w = round_pixel(r.w);
    r.h = round_pixel(r.h);

    prev_widget_size = Vector2.{ size.x, size.y };

    return r;
}

// draw_text :: (
//     text        : string,
//     font_name   : string,
//     position    : Vector2,
//     color       : Vector4,
//     size        := 16,
//     apply_scale_factor  := true
// ) {
//     if color.w <= 0 || text.count <= 0 return;
//
//     using font      := get_font(font_name);
//     using metrics   := get_font_metrics(font, xx size, apply_scale_factor);
//
//     if apply_scale_factor {
//         size = cast (int) (size * scale_factor);
//     }
//
//     space_glyph := find_or_add_glyph(font, #char " ", pixel_size);
//
//     prev_tex := set_texture(list, *texture_atlas);
//     defer set_texture(list, prev_tex);
//
//     pen := Vector2.{ 0, xx ascender };
//     inv_scale_factor := 1 / scale_factor;
//
//     line_start_index := 0;
//
//     while line_start_index < text.count {
//         line_end_index := find_index_from_left(text, #char "\n", line_start_index);
//
//         if line_end_index == -1 {
//             line_end_index = text.count;
//         }
//
//         line : string;
//         line.data   = text.data + line_start_index;
//         line.count  = line_end_index - line_start_index;
//
//         line_start_index = line_end_index + 1;
//
//         defer {
//             pen.x = 0;
//             pen.y += line_height;
//         }
//
//         word_start_index := 0;
//
//         prev_char: u32;
//         while word_start_index < line.count {
//             word_end_index := find_index_from_left(line, #char " ", word_start_index);
//
//             defer {
//                 pen.x += space_glyph.advance;
//                 word_start_index = word_end_index + 1;
//             }
//
//             // Treat if there is more than one space character.
//             if word_start_index == word_end_index {
//                 pen.x += space_glyph.advance;
//             }
//
//             if word_end_index == -1 {
//                 word_end_index = line.count;
//             }
//
//             word: string;
//             word.data   = line.data + word_start_index;
//             word.count  = word_end_index - word_start_index;
//
//             // if check_if_should_wrap(font, position, size, word, pen.x, max_line_width) {
//             //     prev_char    = 0;
//             //     pen.x        = 0;
//             //     pen.y       += line_height;
//             // }
//
//             while word.count > 0 {
//                 codepoint, _ := utf8_next_character(*word);
//                 defer prev_char = codepoint;
//
//                 glyph           := find_or_add_glyph(font, codepoint, pixel_size);
//                 pos_in_atlas    := glyph.pos_in_atlas;
//
//                 if prev_char > 0 {
//                     delta: FT_Vector;
//
//                     FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
//                     pen.x += xx (delta.x >> 6);
//                 }
//
//                 defer pen.x += glyph.advance;
//
//                 glyph_pos := Vector2.{
//                     pen.x + glyph.bearing_x,
//                     pen.y - glyph.bearing_y
//                 };
//
//                 rect := Rect.{
//                     glyph_pos.x * inv_scale_factor,
//                     glyph_pos.y * inv_scale_factor,
//
//                     pos_in_atlas.w * inv_scale_factor,
//                     pos_in_atlas.h * inv_scale_factor,
//                 };
//
//                 rect.position += position;
//
//                 rect.x = round_pixel(rect.x * scale_factor) / scale_factor;
//                 rect.y = round_pixel(rect.y * scale_factor) / scale_factor;
//
//                 uv_rect := Rect.{
//                     pos_in_atlas.x / cast(float) font_atlas.total_width,
//                     pos_in_atlas.y / cast(float) font_atlas.total_height,
//                     pos_in_atlas.w / cast(float) font_atlas.total_width,
//                     pos_in_atlas.h / cast(float) font_atlas.total_height,
//                 };
//
//                 push_rect(list, rect, color, uv_rect);
//             }
//         }
//     }
// }

ui_select :: (size := Vector2.{ 100, 40 }, placeholder := "", loc := #caller_location) {
    id      := ui_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    rect := alloc_space(size, theme.button.normal.padding);
    update_rect_state(id, state, rect);

    color := Vector4.{ 0.2, 0.4, 1, 1 };
    draw_rect(rect, color, .ROUND_ALL);

    if state.once {
        state.open = !state.open;
    }

    if state.open {
        dropdown_rect := Rect.{ rect.x, rect.y + rect.h, rect.w, 100 };
        content := dropdown_rect;

        content.x += theme.content_padding;
        content.y += theme.content_padding;
        content.w -= theme.content_padding;
        content.h -= theme.content_padding;

        push_layer(id, dropdown_rect);
        defer pop_layer();

        push_clip(dropdown_rect);
        defer pop_clip();

        draw_rect(dropdown_rect, Vector4.{ 0.1, 0.4, 1, 1 });

        size := Vector2.{ 80, 20 };

        set_layout_order(.COLUMNS, 1);

        ui_button("asjkhd", size);
        ui_button("asjkhd", size);
        ui_button("asjkhd", size);

        // handle_scroll(*current_layer.layout, loc);
    }
}

// @todo: remove "ui".
ui_button :: (label: string, size := Vector2.{ 100, 40 }, loc := #caller_location) -> bool {
    id      := ui_id(loc, label);
    state   := get_widget_state(Widget_State, id);

    rect := alloc_space(size, theme.button.normal.padding);
    update_rect_state(id, state, rect);

    color := ui_theme(state.*, theme.button).bg_color;
    draw_rect(rect, color, .ROUND_ALL);

    return state.once;
}

ui_theme :: (state: Widget_State, theme_state: Theme_State) -> UI_Theme {
    if state.pressed return theme_state.focused;
    if state.hovered && !state.pressed return theme_state.hovered;

    return theme_state.normal;
}


set_layout_order:: (order: Layout_Order, columns := 0) {
    current_layer.layout.order   = order;
    current_layer.layout.columns = columns;
}

#scope_file;

get_widget_state :: ($T: Type, id: UI_ID, default_rect := Rect.{}) -> *T, bool {
    state, new := find_or_add(*widget_states, id);

    if new {
        ptr     := New(T);
        state.*  = cast(*Window_State) ptr;

        if default_rect.w > 0 || default_rect.h > 0 {
            state.*.rect = default_rect;
        }
    }

    return cast(*T) state.*, new;
}

// Not really, only if not active.
update_rect_state :: (id: UI_ID, state: *Widget_State, rect: Rect) {
    if active_widget > -1 && active_widget != id {
        return;
    }

    if is_occluded(rect) {
        return;
    }

    // @todo: it's a fucking hack, we don't want to do this check for the layer itself,
    // cause the dragging won't work then, because it's above the content_rect....
    // within_content := true;
    // if current_layer.widget_id != id {
    //     within_content = point_vs_rect(mouse_x, mouse_y, current_layer.layout.content_rect);
    // }

    was_pressed        := state.pressed;
    state.hovered       = point_vs_rect(mouse_x, mouse_y, rect);
    state.pressed       = state.hovered && left_pressed;
    state.once          = !was_pressed && state.pressed;
}

update_scrollbar :: (loc := #caller_location) {
    id      := ui_id(loc, "_scrollbar");
    state   := get_widget_state(Widget_State, id);

    prev_layout := current_layer.prev_layout;
    layout      := current_layer.layout;

    scroll      := *current_layer.layout.scroll;


    // We compute the actual content size from the previous frame.
    content_h   := prev_layout.cursor.y + prev_layout.prev_widget_size.y;
    visible_h   := layout.rect.h;
    max_scroll  := max(0.0, content_h - visible_h);

    if point_vs_rect(mouse_x, mouse_y, layout.rect) && max_scroll > 0 && active_widget == -1 {
        scroll.y += xx wheel_y;
        scroll.y = clamp(scroll.y, 0.0, max_scroll);
    }



    track_h  := layout.rect.h;

    ratio    := clamp(visible_h / content_h, 0.0, 1.0);
    handle_h := max(20., track_h * ratio); // @todo, set the min size in theme.
    travel   := track_h - handle_h;
    scroll_t := scroll.y / max_scroll;


    handle := Rect.{
        layout.rect.x + layout.rect.w - theme.scrollbar_width,
        layout.rect.y + scroll_t * travel,
        theme.scrollbar_width,
        handle_h,
    };

    update_rect_state(id, state, handle);

    if active_widget == -1 || active_widget == id {
        is_dragging := active_widget == id;
        hit         := point_vs_rect(mouse_x, mouse_y, handle) && left_pressed;

        if hit && !is_dragging && abs(delta_y) > 0 {
            active_widget = id;
        }

        if is_dragging && !left_pressed {
            active_widget = -1;
        }

        if is_dragging && travel > 0 {
            scroll.y += delta_y * (max_scroll / travel);
            scroll.y  = clamp(scroll.y, 0.0, max_scroll);
        }
    }

    draw_rect(handle, theme.window_scroll_bar.normal.bg_color, .ROUND_ALL);
}

is_occluded :: (rect: Rect) -> bool {
    if current_layer {
        for prev_layer_list {
            // Don't test on itself.
            if it.widget_id == current_layer.widget_id continue;

            if current_layer.depth < it.depth {
                widget_found, widget_state := table_find(*widget_states, it.widget_id);

                if widget_found && point_vs_rect(mouse_x, mouse_y, widget_state.rect) {
                    return true;
                }
            }
        }
    }

    return false;
}

push_layer :: (id: UI_ID, rect: Rect) {
    depth       := -1;
    prev_layout : UI_Layout;

    // Find old z order.
    for prev_layer_list {
        if it.widget_id == id {
            depth       = it.depth;
            prev_layout = it.layout;
            // scroll      = it.layout.scroll;
            // prev_cursor = it.layout.cursor + it.layout.prev_widget_size;
            break;
        }
    }

    // If it's a new layout, we simply initialize it on the top of the stack.
    if depth == -1 {
        depth          = current_depth;
        current_depth += 1;
    }

    index := curr_layer_list.count;

    array_add(*curr_layer_list, .{
        widget_id   = id,
        rect        = rect,
        depth       = depth,
        prev_layout = prev_layout,
        layout      = .{ scroll = prev_layout.scroll }, // Restore previous scroll.
    });
    array_add(*layer_stack, index);
    current_layer = *curr_layer_list[index];
}

// todo: some asserts could be cool to put there.
pop_layer :: () {
    _ := pop(*layer_stack); // @todo: assert bunch of stuff.
    // Not correct, but somehow ok.
    current_layer = ifx layer_stack then *curr_layer_list[peek(layer_stack)];
}

cursor_vs_rect :: (rect: Rect) -> bool {
    return point_vs_rect(mouse_x, mouse_y, rect);
}

point_vs_rect :: (x: float, y: float, rect: Rect) -> bool {
    return x > rect.x && x < (rect.x + rect.w) && y > rect.y && y < (rect.y + rect.h);
}

rect_vs_rect :: inline (rect: Rect, other: Rect) -> bool {
    return other.x < rect.x + rect.w && rect.x < other.x + other.w
    && other.y < rect.y + rect.h && rect.y < other.y + other.h;
}

push_triangle :: (p0: Vector2, p1: Vector2, p2: Vector2, color: Vector4, uv0: Vector2, uv1: Vector2, uv2: Vector2) {
    vertices := get_vertices();

    array_add(vertices, .{ position = p0, uv = uv0, color = color });
    array_add(vertices, .{ position = p1, uv = uv1, color = color });
    array_add(vertices, .{ position = p2, uv = uv2, color = color });
}

ui_id :: (loc: Source_Code_Location, extra := "") -> u32 {
    h := sdbm_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
    h  = sdbm_hash(*loc.line_number, size_of(type_of(loc.line_number)), h);
    h  = sdbm_hash(*loc.character_number, size_of(type_of(loc.character_number)), h);

    if extra != "" {
        h = sdbm_hash(extra.data, size_of(u8) * extra.count, h);
    }

    return h;
}

get_layout :: () -> UI_Layout {
    return current_layer.layout;
}

get_vertices :: () -> *[..] UI_Vertex {
    assert(current_layer != null);
    return *current_layer.vertices;
}

push_clip :: (rect: Rect) {
    safe_rect := rect;

    // @todo: Let's the user declare some viewport, and make sure our rects are viewport bounds.
    safe_rect.x = max(0.0, rect.x);
    safe_rect.y = max(0.0, rect.y);
    safe_rect.w = max(0.0, rect.w);
    safe_rect.h = max(0.0, rect.h);

    array_add(*current_layer.clip_stack, safe_rect);
    record_draw_marker(safe_rect);
}

// @todo: make proper assert.
pop_clip :: () {
    old_rect := pop(*current_layer.clip_stack);
    record_draw_marker(old_rect);
}

// change the name.
record_draw_marker :: (rect: Rect) {
    draw_markers := *current_layer.draw_markers;

    if draw_markers.count > 0 {
        last := peek(draw_markers.*);
        if last.clip_rect == rect return;
    }

    array_add(*current_layer.draw_markers, .{ clip_rect = rect, vertex_start = current_layer.vertices.count });
}

raise_layer :: (id: UI_ID) {
    current_layer.depth = current_depth;
    current_depth += 1;

    log("Want to raise window : % :: %", id, current_layer.depth);
}

