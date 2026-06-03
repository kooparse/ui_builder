/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right


    TODO:
    - rename many things, ui_id...
    - no allocation for stack, clips etc? (not sure it's needed...).

    - better understanding for scrollbar
    - better understanding for roudned corner.
*/

// @todo: should import.
#load "font.jai";

#scope_file;

#import "Sort";

UI_ID :: int;

// Context.
theme               := Theme.{};

prev_layer_list  : [..] Layer;
curr_layer_list  : [..] Layer;
layer_stack      : [..] int; // Index of item in the layer list.
current_layer    : *Layer;

dragging        : bool;
drag_offset     : Vector2;

widget_states   : Table(UI_ID, Widget_State);

active_widget   : *Widget_State;
hot_widget      : *Widget_State;
dragging_widget : UI_ID = -1;

draw_list       : UI_Draw_List;

mouse_x  : float;
mouse_y  : float;
delta_x  : float;
delta_y  : float;

wheel_x  : float;
wheel_y  : float;

z_index := 0;

// @todo: rename those vartiables.
left_pressed  : bool;
right_pressed : bool;

// @todo I don't like the name here...
Draw_Marker :: struct {
    clip_rect : Rect;
    vertex_start : int;
};

UI_Layout :: struct {
    content_rect : Rect;
    cursor       : Vector2; //@todo: explain that.

    order      := Layout_Order.STACK;
    align      := Layout_Align.PIXEL_LEFT;
    columns    := 0; //  0 = grow = true instead?

    scroll      : Vector2;
    max_scroll  : float;

    // For auto layout.
    curr_column      := 0;
    prev_widget_size : Vector2;

    prev_cursor  : Vector2;
};

/*
    The UI is made of a stack of layers.
    A Layer represent a rectangular surface where widgets are drawn on it.



*/

Layer :: struct {
    widget_id : UI_ID;

    // Depth is used to sort the layer stack,
    // biggest depth is on top.
    depth     : int;
    rect      : Rect;

    layout    : UI_Layout;

    vertices        : [..] UI_Vertex;
    draw_markers    : [..] Draw_Marker;
    clip_stack   : [..] Rect;
};

Widget_State :: struct {
    id      : UI_ID = -1;
    rect    : Rect;

    pressed : bool;
    hovered : bool;
    once    : bool;

    open    : bool;
};

#scope_export;



UI_Draw_Call :: struct {
    vertex_start   : int;
    vertex_count   : int;
    clip        : Rect; // rename clip?
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

    window_scroll_bar := Theme_State.{
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

    window_title_bar := Theme_State.{
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

    content_padding := 4.;
    window_title_bar_height := 70.;
    window_resizer_size     := 16.;

    scrollbar_width := 12.;

    window_content := Theme_State.{};

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

operator== :: (a: Rect, b: Rect) -> bool {
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
    assert(draw_list.vertices.count == 0, "WTF DUDE");

    quick_sort(curr_layer_list, (a, b) => a.depth - b.depth);


    global_index := 0;

    for curr_layer_list {
        for marker, index: it.draw_markers {
            vertex_end   := ifx index == it.draw_markers.count - 1 it.vertices.count else it.draw_markers[index + 1].vertex_start;
            vertex_count := vertex_end - marker.vertex_start;

            array_add(*draw_list.draw_calls, UI_Draw_Call.{
                vertex_start = global_index + marker.vertex_start,
                vertex_count = vertex_count,
                clip      = marker.clip_rect,
            });
        }

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

    ROUND_ALL :: ROUND_TOP_LEFT_CORNER | ROUND_TOP_RIGHT_CORNER | ROUND_BOTTOM_LEFT_CORNER | ROUND_BOTTOM_RIGHT_CORNER;
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


begin_window :: (region: Rect, title: string, loc := #caller_location) {
    id         := ui_id(loc, "_full_region");
    state, new := find_or_add(*widget_states, id);

    if new {
        state.rect = region;
    }

    full_rect := state.rect;

    title_id      := ui_id(loc, "_title");
    title_rect    := full_rect;
    title_rect.h   = theme.window_title_bar_height;
    handle_dragging(title_id, state.pressed, title_rect, *full_rect.x, *full_rect.y);

    resizer_id := ui_id(loc, "_resizer_id");
    size       := theme.window_resizer_size;
    handle_dragging(resizer_id, state.pressed, .{
        full_rect.x + full_rect.w - size,
        full_rect.y + full_rect.h - size,
        size, size
    }, *full_rect.w, *full_rect.h);

    state.rect = full_rect;

    content_rect   := full_rect;
    content_rect.x += theme.content_padding;
    content_rect.y += theme.window_title_bar_height + theme.content_padding;
    content_rect.w -= (theme.scrollbar_width - theme.content_padding);
    content_rect.h -= (theme.window_title_bar_height + theme.content_padding);

    {
        flags := UI_Flags.DRAW_TEXT | .DRAW_BACKGROUND | .DRAW_BORDER | .MOVEABLE;

        push_layer(id, full_rect, content_rect);
        push_clip(full_rect);

        ui_set_state(id, state, full_rect);

        is_active  := ifx prev_layer_list peek(prev_layer_list).widget_id == id;
        want_raise := !is_active && state.once && dragging_widget == -1;
        if want_raise then raise_window(id);

        window_theme := ifx is_active then theme.window_content.focused else theme.window_content.normal;
        draw_rect(full_rect, window_theme.bg_color, .ROUND_ALL);
    }


    flags := Rect_Flags.ROUND_TOP_LEFT_CORNER | .ROUND_TOP_RIGHT_CORNER;

    color := theme.window_title_bar.normal.bg_color;
    draw_rect(.{ full_rect.x, full_rect.y, full_rect.w, theme.window_title_bar_height }, color, flags);

    color  = theme.resizer.normal.bg_color;
    draw_rect(.{ full_rect.x + full_rect.w - size, full_rect.y + full_rect.h - size, size, size }, color, .ROUND_ALL);

    if current_layer.layout.max_scroll > 0 {
        handle_scroll(*current_layer.layout, loc);
        content_rect.w -= theme.scrollbar_width;
    }

    push_clip(content_rect);
}

// rename window_end().
end_window :: () {
    pop_clip(current_layer.layout.content_rect);
    pop_clip(current_layer.rect);

    pop_layer();
}

alloc_space :: (widget_size: Vector2, padding: Vector2) -> Rect {
    using layout  := *current_layer.layout;
    // cursor      := *layer.cursor;
    // layout      := *layer.layout;
    //
    // scroll       := current_layer.scroll;
    // content_rect := current_layer.content_rect;

    // If has a scrollbar.
    // @todo: remove this... there's a better way.
    if max_scroll > 0 {
        content_rect.w -= theme.scrollbar_width;
    }

    size := widget_size;

    if order != .COLUMNS then curr_column = 0;

    if prev_widget_size.x > 0 || prev_widget_size.y > 0 {
        if order == {
            case .STACK;
                // cursor.x  = theme.padding.x;
                cursor.y += prev_widget_size.y + padding.y;
            case .INLINE;
                cursor.x += prev_widget_size.x + padding.x;
            case .COLUMNS;
                col_width := (content_rect.w) / max(1, columns);
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
    }

    base_x := content_rect.x - scroll.x;
    base_y := content_rect.y - scroll.y;

    rect := Rect.{ base_x + cursor.x, base_y + cursor.y, size.x, size.y };

    rect.x = round_pixel(rect.x);
    rect.y = round_pixel(rect.y);
    rect.w = round_pixel(rect.w);
    rect.h = round_pixel(rect.h);

    prev_widget_size = Vector2.{ size.x, size.y };

    return rect;
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
    // id      := ui_id(loc);
    // state   := find_or_add(*widget_states, id);
    //
    // rect := alloc_space(size, theme.button.normal.padding);
    // ui_set_state(id, state, rect);
    //
    // color := ui_theme(state.*, theme.button).bg_color;
    // draw_rect(rect, color, .ROUND_ALL);

    // {
    //     dropdown_rect := Rect.{ rect.x, rect.y + rect.w, rect.w, 300 };
    //     push_layer(id, dropdown_rect, dropdown_rect);
    //
    //     draw_rect(rect, Vector4.{0.1, 0.4, 1, 1}, .ROUND_ALL);
    //
    //     pop_layer();
    // }
}

// @todo: remove "ui".
ui_button :: (label: string, size := Vector2.{ 100, 40 }, loc := #caller_location) -> bool {
    id      := ui_id(loc, label);
    state   := find_or_add(*widget_states, id);

    rect := alloc_space(size, theme.button.normal.padding);
    ui_set_state(id, state, rect);

    color := ui_theme(state.*, theme.button).bg_color;
    draw_rect(rect, color, .ROUND_ALL);

    return state.once;
}

ui_theme :: (state: Widget_State, theme_state: Theme_State) -> UI_Theme {
    if state.pressed return theme_state.focused;
    if state.hovered && !state.pressed return theme_state.hovered;

    return theme_state.normal;
}

ui_set_state :: (id: UI_ID, state: *Widget_State, rect: Rect) {
    if dragging_widget > -1 && dragging_widget != id {
        return;
    }

    if is_occluded(id, rect) {
        return;
    }

    // @todo: it's a fucking hack, we don't want to do this check for the layer itself,
    // cause the dragging won't work then, because it's above the content_rect....
    within_content := true;
    if current_layer.widget_id != id {
        within_content = point_vs_rect(mouse_x, mouse_y, current_layer.layout.content_rect);
    }

    was_pressed        := state.pressed;
    state.hovered       = point_vs_rect(mouse_x, mouse_y, rect) && within_content;
    state.pressed       = state.hovered && left_pressed;
    state.once          = !was_pressed && state.pressed;
}

handle_dragging :: (id: UI_ID, pressed: bool, rect: Rect, x: *float, y: *float) {
    if dragging_widget > -1 && dragging_widget != id return;

    hit := point_vs_rect(mouse_x, mouse_y, rect) && pressed;

    want_drag   := hit && (abs(delta_x) > 0 || abs(delta_y) > 0);
    is_dragging := dragging_widget > -1 && dragging_widget == id;

    if want_drag && !is_dragging {
        drag_offset       = xy(mouse_x, mouse_y) - xy(x.*, y.*);
        dragging_widget   = id;
        log("start drag!");
        return;
    }

    if is_dragging && !left_pressed {
        dragging_widget = -1;
        log("stop drag!");
        return;
    }

    if is_dragging {
        x.* = mouse_x - drag_offset.x;
        y.* = mouse_y - drag_offset.y;
    }
}

handle_scroll :: (using layout: *UI_Layout, loc := #caller_location) {
    scrollbar_id := ui_id(loc, "_scroll_bar");
    state        := find_or_add(*widget_states, scrollbar_id);

    content_h := prev_cursor.y;
    visible_h := content_rect.h;
    track_h   := content_rect.h;

    ratio    := clamp(visible_h / content_h, 0.0, 1.0);
    // @todo, set min size in theme.
    handle_h := max(20., track_h * ratio);
    travel   := track_h - handle_h;
    scroll_t := scroll.y / max_scroll;

    handle := Rect.{
        content_rect.x + content_rect.w - theme.scrollbar_width,
        content_rect.y + scroll_t * travel,
        theme.scrollbar_width,
        handle_h,
    };

    ui_set_state(scrollbar_id, state, handle);

    if dragging_widget == -1 || dragging_widget == scrollbar_id {

        is_dragging := dragging_widget == scrollbar_id;
        hit         := point_vs_rect(mouse_x, mouse_y, handle) && left_pressed;

        if hit && !is_dragging && abs(delta_y) > 0  dragging_widget = scrollbar_id;
        if is_dragging && !left_pressed             dragging_widget = -1;
        if is_dragging && travel > 0 {
            scroll.y += delta_y * (max_scroll / travel);
        }

    }

    scroll.y = clamp(scroll.y, 0.0, max_scroll);

    draw_rect(handle, theme.window_scroll_bar.normal.bg_color, .ROUND_ALL);
}

set_layout_order:: (order: Layout_Order, columns := 0) {
    current_layer.layout.order   = order;
    current_layer.layout.columns = columns;
}

#scope_file;

is_occluded :: (id: UI_ID, rect: Rect) -> bool {
    if dragging_widget == id {
        return false;
    }

    if current_layer {

        for prev_layer_list {
            // Don't test on itself.
            if it.widget_id == current_layer.widget_id continue;

            if current_layer.depth < it.depth {
                if point_vs_rect(mouse_x, mouse_y, it.rect) {
                    return true;
                }
            }
        }
    }

    return false;
}

push_layer :: (id: UI_ID, occlusion_rect: Rect, content_rect: Rect) {
    depth := -1;

    prev_cursor : Vector2;
    scroll      : Vector2;

    layout      : UI_Layout;

    // Find old z order.
    for prev_layer_list {
        if it.widget_id == id {
            depth     = it.depth;
            scroll      = it.layout.scroll;
            prev_cursor = it.layout.cursor + it.layout.prev_widget_size;
            break;
        }
    }

    content_h := prev_cursor.y;
    visible_h := content_rect.h;

    max_scroll := max(0.0, content_h - visible_h);

    if point_vs_rect(mouse_x, mouse_y, content_rect) && max_scroll > 0 && dragging_widget == -1 {
        scroll.y += xx wheel_y;
    }

    scroll.y = clamp(scroll.y, 0.0, max_scroll);

    // If old z not found, it's a new layer, let's init its z order.
    if depth == -1 {
        depth  = z_index;
        z_index += 1;
    }

    index := curr_layer_list.count;

    array_add(*curr_layer_list, .{
        widget_id    = id,
        rect         = occlusion_rect,
        depth      = depth,
        layout = .{
            scroll       = scroll,
            max_scroll   = max_scroll,
            content_rect = content_rect,
            prev_cursor  = prev_cursor,
        }
    });

    array_add(*layer_stack, index);
    current_layer = *curr_layer_list[index];
}

// todo: some asserts could be cool to put there.
pop_layer :: () {
    _ := pop(*layer_stack); // @todo: assert bunch of stuff.
    // Not correct, but somehow ok.
    // current_layer = ifx curr_layer_list then peek_pointer(curr_layer_list);
    current_layer = ifx layer_stack then *curr_layer_list[peek(layer_stack)];
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
    h = sdbm_hash(*loc.line_number, size_of(type_of(loc.line_number)), h);
    h = sdbm_hash(*loc.character_number, size_of(type_of(loc.character_number)), h);

    if extra != "" {
        h = sdbm_hash(extra.data, size_of(u8) * extra.count, h);
    }

    return h;
}

get_layout :: () -> UI_Layout {
    return current_layer.layout;
}

get_state :: (id: UI_ID) -> *Widget_State {
    return table_find_pointer(*widget_states, id);
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
pop_clip :: (rect: Rect) {
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

raise_window :: (id: UI_ID) {
    current_layer.depth = z_index;
    z_index += 1;

    assert(current_layer.widget_id == id);
    log("Want to raise window : % :: %", id, current_layer.depth);
}

