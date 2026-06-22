/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right


    TODO:
    - better understanding for scrollbar
    - better understanding for rounded corner.
    - Should makes radius samples relative to size.

    - Bug when we scroll then resize the area, the content is scrolled even tho we have the space.
    - Finish input text
    - Get proper color state.
    - we can do a better job with key delay/rate (the code is too complex/big for what it does).
    - design tab area. (another background too?).
    - have collapser area (with another background?)
    - text_codepoint in io struct... ?
    - remove font as dependency.

    Blog post:

    1) Explain our the UI backbones : layers, occluders, dragging.

    2) Explain "nice" tricks, like white pixel reserve in the font atlas, the
       double array we swap, the hovered_layer at begin...

*/


#load "theme.jai";
#load "font.jai";

// Context.
theme := DEFAULT_THEME;

UI_Key :: enum {
    ESCAPE;
    TAB;
    RETURN;
    BACKSPACE;

    LEFT;
    RIGHT;
    UP;
    DOWN;

    MOUSE_LEFT;
    MOUSE_RIGHT;
    MOUSE_MIDDLE;

    KEY_C;
    KEY_V;
    KEY_X;
    KEY_A;
    CTRL;
};

UI_Key_State :: struct {
    down         : bool;

    repeat_duration   : float;
    repeat_start_time : float;

    down_start_time : float;
    down_duration   : float;
};

#scope_file;

// @todo: explain.
UV_DISCARD :: Vector2.{ 0, 0 };

UI_ID      :: int;
UI_Texture :: *void;


key_count       :: #run enum_names(UI_Key).count;
key_state       : [key_count] UI_Key_State;

prev_layer_list  : [..] Layer;
curr_layer_list  : [..] Layer;
layer_stack      : [..] int; // Index of layers from our current layer list.
current_layer    : *Layer;

widget_states   : Table(UI_ID, *Widget_State);

active_widget   : UI_ID = -1; // I want a pointer to the state directly....
hovered_layer   : UI_ID = -1;

// @todo: explain that.
context_ids     : [..] UI_ID;

text_codepoint : string;

draw_list       : UI_Draw_List;
current_texture : UI_Texture;

mouse_x  : float;
mouse_y  : float;
delta_x  : float;
delta_y  : float;

Cursor_Icon :: enum {
    ARROW;
    RESIZE_ARROW;
    HAND;
    TEXT_EDIT;
}

prev_cursor_icon := Cursor_Icon.ARROW;
curr_cursor_icon := Cursor_Icon.ARROW;

wheel_x  : float;
wheel_y  : float;

// The current font.
font : *Font;

current_depth := 0; // for layers

// @todo I don't like the name here...
Draw_Marker :: struct {
    clip_rect    : Rect;
    vertex_start : int;
    texture      : UI_Texture;
};

UI_Layout :: struct {
    rect         : Rect;

    cursor       : Vector2; // @todo: explain that.
    prev_cursor  : Vector2;

    // When layout changed, we have to reset a couple of things, like the
    // "curr_column" or the cursor, and this variable is our way to notice it.
    changed    := false;

    order      := Layout_Order.STACK;
    align      := Layout_Align.PIXEL_LEFT;
    columns    := 0;

    // collapser_offset : float;

    scrollbar        : *Scrollbar_State;

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

Widget_Status :: enum {
    NONE;
    HOVERED;
    DOWN;
    PRESSED;
    FOCUSED;
    DISABLED;
};

Widget_State :: struct {
    widget_id : UI_ID;
    kind    : Type;
    rect    : Rect;
    status  : Widget_Status;

    pressed : bool; // pressed once.
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

Input_State :: struct {
    #as using state : Widget_State;

    text    : string;
    focused : bool;
    focused_start_time : float;

    offset        := 0;

    cursor_start  := -1;
    cursor_end    := -1;
}

Scrollbar_State :: struct {
    #as using state : Widget_State;

    scroll          : Vector2;
    has_scroll      : bool;
};

Expander_State :: struct {
    #as using state : Widget_State;

    open            : bool;
    prev_layout     : UI_Layout;
    computed_height : float;
};

#scope_export;

UI_Draw_Call :: struct {
    vertex_start : int;
    vertex_count : int;
    clip         : Rect;
    texture      : UI_Texture;
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
    position : Vector2; @TEXCOORD;
    uv       : Vector2; @TEXCOORD;
    color    : Vector4; @TEXCOORD;
};

Rect :: struct {
    x: float;
    y: float;
    w: float;
    h: float;

    #overlay (x) position   : Vector2;
    #overlay (w) size       : Vector2;
};

operator * :: (rect: Rect, scaler: float) -> Rect {
    return .{ rect.x * scaler, rect.y * scaler, rect.w * scaler, rect.h * scaler };
}

operator == :: (a: Rect, b: Rect) -> bool {
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

push_id :: inline (id: int) {
    array_add(*context_ids, id);
}

pop_id :: inline () {
    if context_ids then pop(*context_ids);
}



set_theme :: (given_theme: Theme) {
    theme = given_theme;
}

set_font :: (font_to_set: *Font, texture_atlas: *void) {
    font            = font_to_set;
    current_texture = texture_atlas;
}

set_mouse_position :: (x: float, y: float) {
    delta_x = x - mouse_x;
    delta_y = y - mouse_y;

    mouse_x = x;
    mouse_y = y;
}

set_wheel :: (x: float, y: float) {
    wheel_x = x;
    wheel_y = y;
}

is_down :: (key: UI_Key) -> bool {
    state := key_state[key];

    return state.down;
}

is_pressed :: (key: UI_Key, repeat := true) -> bool {
    state := key_state[key];

    if !repeat {
        return state.down && state.down_duration == 0;
    } else {
        return state.down && state.down_duration == 0 || state.down && state.repeat_duration == 0;
    }
}

set_key_event :: (key: UI_Key, down: bool) {
    state := *key_state[key];

    if !state.down && down {
        state.down_start_time = cast(float) seconds_since_init();
    }

    state.down = down;
}

get_cursor_icon :: () -> Cursor_Icon {
    return prev_cursor_icon;
}

KEY_REPEAT_DELAY    :: 0.275;
KEY_REPEAT_RATE     :: 0.020;

update_io :: () {
    text_codepoint.count = 0;

    now := cast(float) seconds_since_init();

    for * key_state {
        if !it.down {
            it.down_duration        = 0;
            it.repeat_duration      = -1;
            it.repeat_start_time    = -1;
        } else {
            it.down_duration    = now - it.down_start_time;

            if it.down_duration >= KEY_REPEAT_DELAY && it.repeat_start_time < 0 {
                it.repeat_start_time = now;
                it.repeat_duration   = 0;
            }

            if it.down_duration >= KEY_REPEAT_DELAY && it.repeat_start_time > 0 {
                it.repeat_duration  = now - it.repeat_start_time;

                if it.repeat_duration > KEY_REPEAT_RATE {
                    it.repeat_duration   = 0;
                    it.repeat_start_time = now;
                }
            }

        }


    }
}

ui_begin :: () {
    update_io();

    // Reset flat vertices.
    array_reset_keeping_memory(*draw_list.vertices);
    array_reset_keeping_memory(*draw_list.draw_calls);

    // Reset our stack of contextual ids.
    array_reset_keeping_memory(*context_ids);

    swap(*prev_cursor_icon, *curr_cursor_icon);
    curr_cursor_icon = Cursor_Icon.ARROW;

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


    // @todo: explain that.
    for < prev_layer_list  {
        if cursor_vs_rect(it.rect) {
            hovered_layer = it.widget_id;
            break;
        }
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
                texture      = marker.texture,
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

window_begin :: (region: Rect, title := "", loc := #caller_location) -> bool {
    id    := make_id(loc, "_full_region");
    state := get_widget_state(Window_State, id, default_rect = region);

    is_new := push_layer(id, state.rect);

    // If window's layer was the topmost one of the last frame, we consider it as
    // "active".
    is_topmost  := ifx prev_layer_list peek(prev_layer_list).widget_id == id;

    mutate_state(state, state.rect, check_layout = false);
    // If we click somewhere on the layer, we want to raise it to the top of
    // the stack.
    want_raise := !is_new && !is_topmost && state.pressed && active_widget == -1;
    if want_raise then raise_layer(id);


    title_rect     := state.rect;
    title_rect.h    = theme.window_title_bar_height;

    resizer_rect   := state.rect;
    resizer_rect.x += state.rect.w - theme.border_width;
    resizer_rect.y += state.rect.h - theme.border_width;
    resizer_rect.w  = theme.border_width * 6;
    resizer_rect.h  = theme.border_width * 6;

    dragging_allowed := active_widget == -1 && is_topmost && state.dragging == .NONE && is_down(.MOUSE_LEFT);

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
    if !is_occluded(resizer_rect) && cursor_vs_rect(resizer_rect) {
        curr_cursor_icon = .RESIZE_ARROW;

        // Prevent to mix clicking and dragging behavior.
        if dragging_allowed && (abs(delta_x) > 0 || abs(delta_y) > 0) {
            active_widget   = id;
            state.dragging  = .RESIZE_WINDOW;
            log("Start resizer!");
        }
    }

    if state.dragging != .NONE && !is_down(.MOUSE_LEFT) {
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
        curr_cursor_icon = .RESIZE_ARROW;
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

    bg_color     := ifx is_topmost then theme.color.bg else darken(theme.color.bg, 5);
    draw_rect(state.rect, bg_color, .ROUND_ALL);

    // Draw title bar.
    if title {
        title_color := theme.color.fg;

        text_size := theme.window_title_bar_height * 0.5;
        title_width, title_height := get_text_extents_v2(font, title, xx text_size);

        x := title_rect.x + title_rect.w * 0.5 - title_width * 0.5;
        y := title_rect.y + title_rect.h * 0.5 - title_height * 0.5;

        draw_rect(title_rect, title_color, .TOP | .LEFT | .RIGHT | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT);
        draw_text(title, x, y, text_size, theme.color.text);
    }

    layer_rect   := state.rect;
    layer_rect.x += theme.content_padding;
    layer_rect.y += theme.window_title_bar_height + theme.content_padding;
    layer_rect.w -= theme.scrollbar_width + theme.content_padding * 2;
    layer_rect.h -= (theme.window_title_bar_height + theme.content_padding);

    layer_rect = pad_rect(layer_rect, theme.border_width, theme.border_width);

    set_layout(layer_rect);

    internal_scrollbar(loc);

    push_clip(layer_rect);

    return state.open;
}

window_end :: () {
    pop_clip();
    pop_layer();
}


curr_expander : *Expander_State;

begin_expander :: (title : string, open_by_default := false, loc := #caller_location) -> bool {
    id          := make_id(loc);
    state, new  := get_widget_state(Expander_State, id);

    curr_expander = state;

    if new state.open = open_by_default;

    layout := current_layout();
    size := Vector2.{ layout.rect.w, 40. };

    rect := alloc_space(size);
    mutate_state(state, rect);

    bg_color := get_color(state.status, theme.color.fg);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_extents_v2(font, title, xx font_size);
    text_rect                 := pad_rect(rect, theme.button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;


    if state.pressed  {
        state.open = !state.open;
    }



    flags := Rect_Flags.ROUND_ALL;
    if state.open then flags = .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT | .TOP | .LEFT | .RIGHT;

    draw_rect(rect, bg_color, flags);
    draw_outline(rect, theme.color.border, theme.border_width, flags);
    draw_text(title, x, y, font_size, theme.color.text);

    if state.open {
        bg_region  := rect;
        bg_region.y = rect.y + rect.h;
        bg_region.h = state.computed_height + theme.margin_y;;

        color   := theme.color.border;
        color.w  = 0.6;

        borders := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        draw_outline(bg_region, color, theme.border_width, borders);

        layout_rect := Rect.{
            rect.x + theme.collapser_offset,
            rect.y + rect.h,
            rect.w - theme.collapser_offset * 2,
            layout.rect.h - rect.y,
        };

        // draw_outline(layout_rect, color, theme.border_width, borders);

        prev_layout      := set_layout(layout_rect);
        state.prev_layout = prev_layout;

        current_layout().cursor.y += theme.margin_y;
    }


    // Draw arrow.
    {
        arrow_size  := rect.h * 0.3;
        offset      := arrow_size * 0.2;
        arrow_rect := Rect.{
            rect.x + rect.w - (arrow_size + theme.button_padding),
            rect.y + rect.h * 0.5 - arrow_size * 0.5 + offset,
            arrow_size, arrow_size,
        };

        // draw_rect(arrow_rect, Vector4.{1, 1, 1, 1});

        p0 := Vector2.{ arrow_rect.x, arrow_rect.y };
        p1 := Vector2.{ arrow_rect.x + arrow_rect.w, arrow_rect.y };
        p2 := Vector2.{ arrow_rect.x + arrow_rect.w * 0.5, arrow_rect.y + arrow_rect.h - offset };

        if state.open {
            p0 = Vector2.{ arrow_rect.x, p2.y };
            p1 = Vector2.{ arrow_rect.x + arrow_rect.w, p2.y };
            p2 = Vector2.{ arrow_rect.x + arrow_rect.w * 0.5, arrow_rect.y };
        }

        push_triangle(p0, p1, p2, theme.color.border);
    }

    return state.open;
}

end_expander :: () {
    assert(curr_expander != null);

    if curr_expander.open {
        collapser_layout := current_layout().*;
        content_height   := collapser_layout.cursor.y + collapser_layout.prev_widget_size.y;

        curr_expander.computed_height = content_height;

        restore_layout(curr_expander.prev_layout);

        current_layer.layout.cursor.y += content_height + theme.margin_y;
    }

    curr_expander = null;
}

ui_tab :: (tabs: [] string, tab_index: *int) -> modified: bool {
    set_layout_order(.COLUMNS, tabs.count);
    defer set_layout_order(.STACK);

    modified := false;

    active_tab_color := theme.color;
    active_tab_color.fg = theme.color.accent;

    for tabs {
        push_id(it_index);
        defer pop_id();

        color := ifx it_index == tab_index.* active_tab_color else theme.color;

        if button(it, .{ -1, 50 }, color = *color) {
            tab_index.* = it_index;
            modified = true;
        }
    }

    return modified;

}

select :: (selected: int, items: [] string, size := Vector2.{ 100, 40 }, placeholder := "", loc := #caller_location) -> int {
    id      := make_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    placeholder_text := ifx placeholder placeholder else "<Choose>";

    button_label := ifx selected >= 0 items[selected] else placeholder_text;

    rect := alloc_space(size);
    mutate_state(state, rect);

    bg_color := get_color(state.status, theme.color.fg);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_extents_v2(font, button_label, xx font_size);
    text_rect                 := pad_rect(rect, theme.button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;



    if state.pressed {
        state.open = !state.open;
    }

    flags := Rect_Flags.ROUND_ALL;
    if state.open flags = .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT | .TOP | .LEFT | .RIGHT;

    draw_rect(rect, bg_color, flags);
    draw_outline(rect, theme.color.border, theme.border_width, flags);
    draw_text(button_label, x, y, font_size, theme.color.text);

    value := selected;

    if state.open {
        dropdown_flags := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        dropdown_rect  := Rect.{ rect.x, rect.y + rect.h, rect.w, 300 };

        is_new := push_layer(id, dropdown_rect);
        defer pop_layer();

        push_clip(dropdown_rect);
        defer pop_clip();

        is_topmost  := ifx prev_layer_list peek(prev_layer_list).widget_id == id;
        want_raise := !is_new && !is_topmost && active_widget == -1;

        if want_raise {
            raise_layer(id);
        }

        draw_rect(dropdown_rect, theme.color.bg, dropdown_flags);

        layer_rect   := dropdown_rect;
        layer_rect.x += theme.content_padding + theme.border_width;
        layer_rect.y += theme.content_padding + theme.border_width;
        layer_rect.w -= theme.content_padding + theme.scrollbar_width + theme.border_width * 2;
        layer_rect.h -= theme.content_padding + theme.border_width * 2;

        set_layout(layer_rect);

        internal_scrollbar(loc);

        size := Vector2.{ layer_rect.w , 60 };

        for items {
            push_id(it_index);
            defer pop_id();

            if button(it, size) {
                value       = it_index;
                state.open  = false;
            }
        }

        draw_outline(dropdown_rect, theme.color.border, theme.border_width, dropdown_flags);

        // If click outside the dropdown, we close the dropdown.
        if is_pressed(.MOUSE_LEFT) && (state.status == .NONE) && !cursor_vs_rect(dropdown_rect) && active_widget == -1 {
            state.open = false;
        }

    }

    return value;
}

label :: (text: string, label_size := 0., loc := #caller_location) {
    text_size := ifx label_size <= 0 theme.text_size else label_size;

    width, height := get_text_extents_v2(font, text, xx text_size);
    rect := alloc_space(xy(width, height));

    draw_text(text, rect.x, rect.y, text_size, theme.color.text);
}

separator :: (text := "") {
    layout := current_layout();

    if text {
        text_size := theme.text_size * 0.7;
        text_width, text_height := get_text_extents_v2(font, text, xx text_size);

        rect := alloc_space(.{ layout.rect.w, text_height  });

        // draw_rect(rect, theme.color.fg);

        x := rect.x + theme.content_padding;

        line_height := min(text_size * 0.5, theme.separator_size);

        first_line := Rect.{
            x,
            rect.y + (rect.h * 0.5) - (line_height * 0.5),
            rect.w * 0.05,
            line_height,
        };

        x += first_line.w + theme.margin_x;

        draw_rect(first_line, theme.color.text_muted);
        draw_text(text, x, rect.y + rect.h * 0.5 - text_height * 0.5, xx text_size, theme.color.text);

        x += text_width + theme.margin_x;

        second_line := Rect.{
            x, first_line.y,
            (rect.x + rect.w) - x, // leftover.
            line_height
        };

        draw_rect(second_line, theme.color.text_muted);
    } else {
        rect     := alloc_space(.{ layout.rect.w, theme.separator_size + theme.content_padding * 2 });
        sep_rect := Rect.{ rect.x + theme.content_padding, rect.y + theme.content_padding, rect.w - theme.content_padding * 2, theme.separator_size };
        draw_rect(sep_rect, theme.color.text_muted);
    }
}

send_text_codepoint :: (codepoint: string) {
    if !codepoint return;

    if text_codepoint then free(text_codepoint);
    text_codepoint = copy_string(codepoint);
}

text_input :: (value: string, size := Vector2.{ 200, 60 }, loc := #caller_location) -> modified: bool, new_string: string {
    id              := make_id(loc);
    state, is_new   := get_widget_state(Input_State, id);

    if is_new {
        state.text         = copy_string(value);
        state.cursor_start = state.text.count;
    }

    mutate_state(state, alloc_space(size));


    if !state.focused && state.pressed {
        active_widget = id;
        state.focused = true;
        state.focused_start_time = xx seconds_since_init();
    }

    if state.status & .HOVERED || state.focused then curr_cursor_icon = .TEXT_EDIT;

    if state.focused {
        click_outside := !cursor_vs_rect(state.rect) && is_pressed(.MOUSE_LEFT);

        if is_pressed(.RETURN) {
            active_widget = -1;
            state.focused = false;
        }

        if is_pressed(.ESCAPE) || click_outside {
            active_widget = -1;
            state.focused = false;
        }

        if is_pressed(.BACKSPACE, true) && state.cursor_start > 0 {
            for state.cursor_start..state.text.count - 1 {
                state.text[it - 1] = state.text[it];
            }

            if state.cursor_start > 0 then state.cursor_start -= 1;
            if state.text.count   > 0 then state.text.count   -= 1;
        }

        if is_pressed(.RIGHT) && state.cursor_start <= state.text.count {
            state.cursor_start += 1;
        }

        if is_pressed(.LEFT) && state.cursor_start > 0 {
            state.cursor_start -= 1;
        }

        if text_codepoint && text_codepoint != state.text {
            begin := slice(state.text, 0, state.cursor_start);
            end   := slice(state.text, state.cursor_start, state.text.count);

            new_value := join(begin, text_codepoint, end);
            state.cursor_start += 1;

            if state.text {
                free(state.text);
            }

            state.text = new_value;
        }
    }

    bg_color := get_color(state.status, theme.color.fg);

    draw_rect(state.rect, bg_color);
    draw_outline(state.rect, theme.color.border, theme.border_width);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_extents_v2(font, state.text, xx font_size);


    x := state.rect.x + theme.input_padding + theme.border_width;
    y := state.rect.y + state.rect.h * 0.5 - text_height * 0.5;


    should_clip := x + text_width > state.rect.w - theme.border_width;

    clip_rect   := state.rect;
    clip_rect.w -= theme.border_width;

    if should_clip       then push_clip(clip_rect);
    defer if should_clip then pop_clip();

    if state.focused {
        cursor_text := state.text;

        if state.cursor_start < state.text.count {
            cursor_text = slice(state.text, 0, state.cursor_start);
        }

        cursor_height    := size.y * 0.5;
        to_cursor_width  := get_text_extents_v2(font, cursor_text, xx font_size);

        input_width := state.rect.w - (theme.border_width * 2);
        cursor_size := theme.input_cursor_size;

        offset := (to_cursor_width + cursor_size + theme.input_padding) - input_width;
        if offset >= 0 x -= offset;

        cursor_rect := Rect.{ x + to_cursor_width, state.rect.y + state.rect.h * 0.5 - cursor_height * 0.5, cursor_size, cursor_height };

        now             := cast(float) seconds_since_init();
        elapsed         := state.focused_start_time - now;
        blink_speed     := 8.0;
        alpha           := cast(float) (sin(elapsed * blink_speed) + 1.0) * 0.5;

        cursor_color  := lighten(theme.color.text, 20);
        cursor_color.w = alpha;


        draw_text(state.text, x, y, font_size, theme.color.text);
        draw_rect(cursor_rect, cursor_color);
    } else {
        draw_text(state.text, x, y, font_size);
    }

    return false, state.text;
}

radio_buttons :: (items: [] string, index: *int, loc := #caller_location) -> bool {
    changed := false;

    for items {
        push_id(it_index);
        defer pop_id();

        checked := it_index == index.*;

        if checkbox(*checked) {
            changed = true;
        }

        set_layout_order(.INLINE);
        label(it);
        set_layout_order(.STACK);

        if checked {
            index.* = it_index;
        }
    }

    return changed;
}

// @todo: we don't need state for that...
checkbox :: (checked: *bool, size := 0., loc := #caller_location) -> bool {
    id      := make_id(loc);
    state   := get_widget_state(Widget_State, id);

    checkbox_size := ifx size <= 0 xy(theme.checkbox_size) else xy(size);

    rect := alloc_space(checkbox_size);
    mutate_state(state, rect);

    changed := false;

    if state.pressed {
        changed   = true;
        checked.* = !checked.*;
    }

    inner_color := get_color(state.status, ifx checked.* then theme.color.accent else theme.color.text_muted);

    pos     := xy(rect.x + rect.w * 0.5, rect.y + rect.h * 0.5);
    radius  := checkbox_size.x * 0.5;

    draw_circle(pos, radius, theme.color.bg);
    draw_circle_outline(pos, radius, theme.border_width, inner_color);

    if checked.* == true {
        radius = radius * 0.5;
        draw_circle(pos, radius, inner_color);
    }

    return changed;
}

button :: (label: string, size := Vector2.{ -1, 30 }, loc := #caller_location, color : *Color_Theme = null) -> bool {
    id          := make_id(loc, label);
    using state := get_widget_state(Widget_State, id);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_extents_v2(font, label, xx font_size);

    button_size := size;

    if size.x <= 0 {
        button_size.x = text_width + theme.button_padding;
    }

    mutate_state(state, alloc_space(button_size));

    text_too_big := rect.w < button_size.x;

    colors := ifx color then color.* else theme.color;

    is_activated := status == .FOCUSED || status == .PRESSED;

    bg_color     := get_color(status, ifx is_activated then colors.accent else colors.fg);
    border_color := colors.border;

    draw_rect(rect, bg_color, .ROUND_ALL);

    text_rect := pad_rect(rect, theme.button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    if text_too_big push_clip(rect);
    draw_text(label, x, y, font_size, colors.text);
    if text_too_big pop_clip();

    return state.pressed;
}

get_color :: (status: Widget_Status, color: Vector4) -> Vector4 {
    if status == {
        case .HOVERED; return lighten(color, 10);
        case .FOCUSED; return lighten(color, 25);
        case .DOWN;    #through;
        case .PRESSED; return lighten(color, 25);
    }

    return color;
}

set_layout_order:: (order: Layout_Order, columns := 0) {
    layout := current_layout();
    if layout.order != order {
        layout.changed = true;
    }

    layout.order   = order;
    layout.columns = columns;
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

    state.*.widget_id = id;

    return cast(*T) state.*, new;
}

mutate_state :: (state: *Widget_State, rect: Rect, check_layout := true) {
    state.status = ifx active_widget > -1 && active_widget != state.widget_id then 0 else get_status(rect, check_layout);

    if state.widget_id == active_widget {
        state.status = .FOCUSED;
    }

    state.pressed = state.status == .PRESSED;

    state.rect   = rect;
}

// @todo: Explain why check_layout or rename.
get_status :: (rect: Rect, check_layout := true) -> Widget_Status {
    status : Widget_Status;

    within_layer       := cursor_vs_rect(current_layer.rect);
    within_widget_rect := cursor_vs_rect(rect);
    within_layout_rect := ifx check_layout cursor_vs_rect(current_layout().rect) else true;

    if !is_occluded(rect) && within_widget_rect && within_layer && within_layout_rect {
        status = .HOVERED;
    }

    if status == .HOVERED && is_down(.MOUSE_LEFT) {
        status = .DOWN;
    }

    if status == .DOWN && is_pressed(.MOUSE_LEFT, repeat = false) {
        status = .PRESSED;
    }

    return status;
}

internal_scrollbar :: (loc := #caller_location) -> *Scrollbar_State {
    id      := make_id(loc, "_scrollbar");
    state   := get_widget_state(Scrollbar_State, id);

    layout := current_layout();
    layout.scrollbar = state;

    scroll      := *state.scroll;
    prev_layout := current_layer.prev_layout;

    // We compute the actual content size from the previous frame.
    content_h   := prev_layout.cursor.y + prev_layout.prev_widget_size.y;
    visible_h   := layout.rect.h;
    max_scroll  := max(0.0, content_h - visible_h);

    // @todo: Perhaps add again mouse wheel for scrolling content...
    // if point_vs_rect(mouse_x, mouse_y, layout.rect) && max_scroll > 0 && active_widget == -1 {
    //     scroll.y += xx wheel_y;
    //     scroll.y = clamp(scroll.y, 0.0, max_scroll);
    // }



    track_h  := layout.rect.h;

    ratio    := clamp(visible_h / content_h, 0.0, 1.0);
    handle_h := max(20., track_h * ratio); // @todo, set the min size in theme.
    travel   := track_h - handle_h;
    scroll_t := scroll.y / max_scroll;


    handle := Rect.{
        layout.rect.x + layout.rect.w + theme.content_padding * 0.5,
        layout.rect.y + scroll_t * travel,
        theme.scrollbar_width,
        handle_h,
    };

    mutate_state(state, handle, check_layout = false);

    bg_color := get_color(state.status, ifx state.status != 0 theme.color.accent else theme.color.text_muted);

    if active_widget == -1 || active_widget == id {
        is_dragging := active_widget == id;
        hit         := cursor_vs_rect(handle) && is_down(.MOUSE_LEFT);

        if hit && !is_dragging && abs(delta_y) > 0 {
            active_widget = id;
        }

        if is_dragging && !is_down(.MOUSE_LEFT) {
            active_widget = -1;
        }

        if is_dragging && travel > 0 {
            scroll.y += delta_y * (max_scroll / travel);
            scroll.y  = clamp(scroll.y, 0.0, max_scroll);
        }
    }

    draw_rect(handle, bg_color, .ROUND_ALL);

    return state;
}

// @todo: inline this func.
is_occluded :: (rect: Rect) -> bool {
    return !point_vs_rect(mouse_x, mouse_y, rect) || current_layer.widget_id != hovered_layer;
}

push_layer :: (id: UI_ID, rect: Rect) -> is_new: bool {
    is_new      := false;
    depth       := -1;

    prev_layout : UI_Layout;

    // Find old z order.
    for prev_layer_list {
        if it.widget_id == id {
            depth        = it.depth;
            prev_layout  = it.layout;
            break;
        }
    }

    // If it's a new layout, we simply initialize it on the top of the stack.
    if depth == -1 {
        is_new         = true;
        depth          = current_depth;
        current_depth += 1;
    }

    index := curr_layer_list.count;

    array_add(*curr_layer_list, .{
        widget_id   = id,
        rect        = rect,
        depth       = depth,
        prev_layout = prev_layout,
    });

    array_add(*layer_stack, index);
    current_layer = *curr_layer_list[index];

    return is_new;
}

// todo: some asserts could be cool to put there.
pop_layer :: () {
    _ := pop(*layer_stack); // @todo: assert bunch of stuff.
    current_layer = ifx layer_stack then *curr_layer_list[peek(layer_stack)] else null;
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

push_triangle :: (p0: Vector2, p1: Vector2, p2: Vector2, color: Vector4, uv0 := UV_DISCARD, uv1 := UV_DISCARD, uv2 := UV_DISCARD) {
    vertices := get_vertices();

    c  := color;
    c.w = color.w * theme.alpha;

    array_add(vertices, .{ position = p0, uv = uv0, color = c });
    array_add(vertices, .{ position = p1, uv = uv1, color = c });
    array_add(vertices, .{ position = p2, uv = uv2, color = c });
}

make_id :: (loc: Source_Code_Location, extra := "") -> u32 {
    h := sdbm_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
    h  = sdbm_hash(*loc.line_number, size_of(type_of(loc.line_number)), h);
    h  = sdbm_hash(*loc.character_number, size_of(type_of(loc.character_number)), h);

    if context_ids {
        id := peek(context_ids);
        h  = sdbm_hash(*id, size_of(type_of(UI_ID)), h);
    }

    if extra {
        h = sdbm_hash(extra.data, size_of(u8) * extra.count, h);
    }

    return h;
}

current_layout :: () -> *UI_Layout {
    return *current_layer.layout;
}

set_layout :: (layout_rect: Rect) -> prev: UI_Layout {
    prev_layout          := current_layer.layout;
    current_layer.layout = .{ rect = layout_rect };

    return prev_layout;
}

restore_layout :: (layout: UI_Layout) {
    current_layer.layout = layout;
}

get_vertices :: () -> *[..] UI_Vertex {
    assert(current_layer != null);
    return *current_layer.vertices;
}

// @todo: let's review this func at some point, when we add real texture(not just font).
set_texture :: (texture: UI_Texture) -> old: UI_Texture {
    old_texture := current_texture;
    current_texture = texture;

    return old_texture;
}

push_clip :: (rect: Rect) {
    safe_rect := rect;

    if current_layer.clip_stack {
        clip := peek(current_layer.clip_stack);

        x0 := max(rect.x, clip.x);
        y0 := max(rect.y, clip.y);
        x1 := min(rect.x + rect.w, clip.x + clip.w);
        y1 := min(rect.y + rect.h, clip.y + clip.h);

        safe_rect.x = x0;
        safe_rect.y = y0;
        safe_rect.w = max(0.0, x1 - x0);
        safe_rect.h = max(0.0, y1 - y0);
    }

    array_add(*current_layer.clip_stack, safe_rect);
    record_draw_marker(safe_rect);
}

pop_clip :: () {
    old_rect := pop(*current_layer.clip_stack);

    if current_layer.clip_stack {
        record_draw_marker(peek(current_layer.clip_stack));
    }
}

// change the name.
record_draw_marker :: (rect: Rect) {
    draw_markers := *current_layer.draw_markers;

    if draw_markers.count > 0 {
        last := peek(draw_markers.*);
        if last.clip_rect == rect && last.texture == current_texture return;
    }

    array_add(*current_layer.draw_markers, .{
        clip_rect    = rect,
        vertex_start = current_layer.vertices.count,
        texture      = current_texture,
    });
}

raise_layer :: (id: UI_ID) {
    current_layer.depth = current_depth;
    current_depth += 1;

    log("Want to raise window : % :: %", id, current_layer.depth);
}

alloc_space :: (widget_size: Vector2) -> Rect {
    using layout := current_layout();

    size := widget_size;

    if layout.changed {
        curr_column    = 0;
        cursor.x       = 0;

        layout.changed = false;
    }

    if prev_widget_size.x > 0 || prev_widget_size.y > 0 {
        if order == {
            case .STACK;
                cursor.y += prev_widget_size.y + theme.margin_y;
            case .INLINE;
                cursor.x += prev_widget_size.x + theme.margin_x;
            case .COLUMNS;
                layout_width := layout.rect.w;

                col_width := layout.rect.w / max(1, columns);
                size.x     = col_width - theme.margin_x;

                if curr_column == 0 {
                    cursor.x     = 0;
                    cursor.y    += prev_widget_size.y + theme.margin_y;
                    curr_column += 1;
                } else {
                    cursor.x    += ifx curr_column > 0 col_width else 0;
                    curr_column += 1;
                }

                if curr_column >= columns {
                    curr_column = 0;
                }
        }
    } else {

        if order == .COLUMNS {
            col_width := (layout.rect.w) / max(1, columns);
            size.x     = col_width - theme.margin_x;
        }
    }

    scroll : Vector2;

    if layout.scrollbar then scroll = layout.scrollbar.scroll;

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



/*
        Some useful helpers.

*/

darken :: (color: Vector4, percent : float) -> Vector4 {
    darker := color;

    t := clamp(percent / 100, 0, 1);
    darker.xyz *= 1 - t;

    return darker;
}

lighten :: (color: Vector4, percent : float) -> Vector4 {
    lighter := color;

    t := clamp(percent / 100, 0, 1);

    lighter.x = lerp(lighter.x, 1.0, t);
    lighter.y = lerp(lighter.y, 1.0, t);
    lighter.z = lerp(lighter.z, 1.0, t);

    return lighter;
}

pad_rect :: (rect: Rect, pad_x : float, pad_y : float) -> Rect {
    return .{
        x = rect.x + pad_x,
        y = rect.y + pad_y,
        w = rect.w - pad_x * 2,
        h = rect.h - pad_y * 2,
    };
}

// @incomplete: this is not correct for all cases, but works for most
round_pixel :: inline (x : float) -> float {
    if x < 0 {
        return cast(float) cast(int) (x - 0.5);
    } else {
        return cast(float) cast(int) (x + 0.5);
    }
}





/*


        Draw functions


*/

Rect_Flags :: enum_flags u32 {
    NONE   :: 0x00;
    TOP    :: (1 << 0);
    LEFT   :: (1 << 1);
    RIGHT  :: (1 << 2);
    BOTTOM :: (1 << 3);

    ROUND_TOP_LEFT     :: (1 << 4);
    ROUND_TOP_RIGHT    :: (1 << 5);
    ROUND_BOTTOM_LEFT  :: (1 << 6);
    ROUND_BOTTOM_RIGHT :: (1 << 7);

    ALL_SIDES :: TOP | LEFT | RIGHT | BOTTOM;
    ROUND_ALL :: ROUND_TOP_LEFT | ROUND_TOP_RIGHT | ROUND_BOTTOM_LEFT | ROUND_BOTTOM_RIGHT | ALL_SIDES;
};

draw_outline :: (r: Rect, color: Vector4, border_width: float, flags: Rect_Flags = 0x00) {
    if border_width <= 0 return;

    if flags == .NONE {
        top_line    := Rect.{ r.x, r.y, r.w, border_width };
        bottom_line := Rect.{ r.x, r.y + r.h - border_width, r.w, border_width };
        left_line   := Rect.{ r.x, r.y + border_width, border_width, r.h - border_width };
        right_line  := Rect.{ r.x + r.w - border_width, r.y + border_width, border_width, r.h - border_width };

        internal_draw_rect(top_line, color);
        internal_draw_rect(bottom_line, color);
        internal_draw_rect(left_line, color);
        internal_draw_rect(right_line, color);

        return;
    }


    top    := (flags & .TOP);
    left   := (flags & .LEFT);
    right  := (flags & .RIGHT);
    bottom := (flags & .BOTTOM);

    // For rounded corners:
    radius := theme.corner_radius;
    radius  = min(radius, r.w * 0.5);
    radius  = min(radius, r.h * 0.5);

    top_left     := Rect.{ r.x, r.y, radius, radius };
    top_right    := Rect.{ r.x + r.w - radius, r.y, radius, radius };
    bottom_left  := Rect.{ r.x, r.y + r.h - radius, radius, radius };
    bottom_right := Rect.{ r.x + r.w - radius, r.y + r.h - radius, radius, radius };

    // We want to round the corner only if its adjacent side are present.
    round_tl := (flags & .ROUND_TOP_LEFT)     && top    && left;
    round_tr := (flags & .ROUND_TOP_RIGHT)    && top    && right;
    round_bl := (flags & .ROUND_BOTTOM_LEFT)  && bottom && left;
    round_br := (flags & .ROUND_BOTTOM_RIGHT) && bottom && right;


    if round_tl {
        p0 := xy(top_left.x + top_left.w, top_left.y + top_left.h);

        prev := p0 + xy(0, -radius);                 // angle 0, top

        for 1..theme.radius_sample {
            theta  := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1     := prev;
            p2     := p0 + xy(-sin(theta) * radius, -cos(theta) * radius);

            a := p1 + normalize(p0 - p1) * border_width;
            b := p1;
            c := p2;
            d := p2 + normalize(p0 - p2) * border_width;

            push_triangle(a, b, c, color);
            push_triangle(a, c, d, color);

            prev = p2;
        }

    }

    if round_tr {
        p0 := xy(top_right.x, top_right.y + top_right.h);

        prev := p0 + xy(0, -radius);
        for 1..theme.radius_sample {
            theta  := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1     := prev;
            p2     := p0 + xy(sin(theta) * radius, -cos(theta) * radius);

            a := p1 + normalize(p0 - p1) * border_width;
            b := p1;
            c := p2;
            d := p2 + normalize(p0 - p2) * border_width;

            push_triangle(a, b, c, color);
            push_triangle(a, c, d, color);

            prev = p2;
        }
    }

    if round_bl {
        p0 := xy(bottom_left.x + bottom_left.w, bottom_left.y);

        prev := p0 + xy(0, radius);
        for 1..theme.radius_sample {
            theta := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1 := prev;
            p2 := p0 + xy(-sin(theta) * radius, cos(theta) * radius);

            a := p1 + normalize(p0 - p1) * border_width;
            b := p1;
            c := p2;
            d := p2 + normalize(p0 - p2) * border_width;

            push_triangle(a, b, c, color);
            push_triangle(a, c, d, color);

            prev = p2;
        }
    }

    if round_br {
        p0   := xy(bottom_right.x, bottom_right.y);
        prev := p0 + xy(0, radius);

        for 1..theme.radius_sample {
            theta  := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1 := prev;
            p2 := p0 + xy(sin(theta) * radius, cos(theta) * radius);

            a := p1 + normalize(p0 - p1) * border_width;
            b := p1;
            c := p2;
            d := p2 + normalize(p0 - p2) * border_width;

            push_triangle(a, b, c, color);
            push_triangle(a, c, d, color);

            prev = p2;
        }
    }

    if top {
        x0 := r.x;
        x1 := r.x + r.w;

        if round_tl       x0 += radius; else if left  x0 += border_width;
        if round_tr       x1 -= radius; else if right x1 -= border_width;

        internal_draw_rect(Rect.{ x0, r.y, x1 - x0, border_width }, color);
    }

    if bottom {
        x0 := r.x;
        x1 := r.x + r.w;

        if round_bl       x0 += radius; else if left  x0 += border_width;
        if round_br       x1 -= radius; else if right x1 -= border_width;

        internal_draw_rect(Rect.{ x0, r.y + r.h - border_width, x1 - x0, border_width }, color);
    }

    if left {
        y0 := r.y;
        y1 := r.y + r.h;

        if round_tl       y0 += radius; else if top    y0 += border_width;
        if round_bl       y1 -= radius; else if bottom y1 -= border_width;

        internal_draw_rect(Rect.{ r.x, y0, border_width, y1 - y0 }, color);
    }

    if right {
        y0 := r.y;
        y1 := r.y + r.h;

        if round_tr       y0 += radius; else if top    y0 += border_width;
        if round_br       y1 -= radius; else if bottom y1 -= border_width;

        internal_draw_rect(Rect.{ r.x + r.w - border_width, y0, border_width, y1 - y0 }, color);
    }
}

draw_circle :: (pos: Vector2, radius: float, color: Vector4) {
    p0   := pos;
    prev := pos - xy(-1, 0) * radius;

    for 1..theme.circle_sample {
        theta  := 2 * PI * (it / cast(float) theme.circle_sample);

        p1 := prev;
        p2 := p0 + xy(cos(theta), sin(theta)) * radius;

        push_triangle(p0, p1, p2, color);

        prev = p2;
    }
}

draw_circle_outline :: (pos: Vector2, radius: float, border_size: float, color: Vector4) {
    p0   := pos;
    prev := pos - xy(-1, 0) * radius;

    for 1..theme.circle_sample {
        theta  := 2 * PI * (it / cast(float) theme.circle_sample);

        p1 := prev;
        p2 := p0 + xy(cos(theta), sin(theta)) * radius;

        a := p1;
        b := p2;
        c := p2 + normalize(p0 - p2) * border_size;
        d := p1 + normalize(p0 - p1) * border_size;

        push_triangle(a, b, c, color);
        push_triangle(a, c, d, color);

        prev = p2;
    }
}

draw_rect :: (r: Rect, color: Vector4, flags : Rect_Flags = 0x00) {
    if flags == .NONE {
        internal_draw_rect(r, color);
        return;
    }

    // For rounded corners:
    radius := theme.corner_radius;
    radius = min(radius, r.w * 0.5);
    radius = min(radius, r.h * 0.5);

    // For that, it means that each corner is a rect of radius dimension.

    top_left     := Rect.{ r.x, r.y, radius, radius };
    top_right    := Rect.{ r.x + r.w - radius, r.y, radius, radius };
    bottom_left  := Rect.{ r.x, r.y + r.h - radius, radius, radius };
    bottom_right := Rect.{ r.x + r.w - radius, r.y + r.h - radius, radius, radius };

    if flags & .ROUND_TOP_LEFT {

        p0 := xy(top_left.x + top_left.w, top_left.y + top_left.h);

        prev := p0 + xy(0, -radius);                 // angle 0, top

        for 1..theme.radius_sample {
            theta  := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1     := prev;
            p2     := p0 + xy(-sin(theta) * radius, -cos(theta) * radius);

            push_triangle(p0, p1, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_left, color);
    }

    if flags & .ROUND_TOP_RIGHT {
        p0 := xy(top_right.x, top_right.y + top_right.h);

        prev := p0 + xy(0, -radius);
        for 1..theme.radius_sample {
            a  := (PI * 0.5) * (it / cast(float) theme.radius_sample);
            p2 := p0 + xy(sin(a) * radius, -cos(a) * radius);
            push_triangle(p0, prev, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_right, color);
    }

    if flags & .ROUND_BOTTOM_LEFT {
        p0 := xy(bottom_left.x + bottom_left.w, bottom_left.y);

        prev := p0 + xy(0, radius);
        for 1..theme.radius_sample {
            a  := (PI * 0.5) * (it / cast(float) theme.radius_sample);
            p2 := p0 + xy(-sin(a) * radius, cos(a) * radius);
            push_triangle(p0, prev, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_left, color);
    }

    if flags & .ROUND_BOTTOM_RIGHT {
        p0 := xy(bottom_right.x, bottom_right.y);

        prev := p0 + xy(0, radius);
        for 1..theme.radius_sample {
            a  := (PI * 0.5) * (it / cast(float) theme.radius_sample);
            p2 := p0 + xy(sin(a) * radius, cos(a) * radius);
            push_triangle(p0, prev, p2, color);
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

draw_text :: (text: string, x: float, y: float, font_size := 16.0, color := Vector4.{ 1, 1, 1, 1 }) {
    if color.w <= 0 || text.count <= 0 return;

    assert(font != null, "Font is null, you must set a font.");

    using font;
    using metrics := get_font_metrics(font, xx font_size);

    space_glyph := find_or_add_glyph(font, #char " ", pixel_size);

    pen := Vector2.{ 0, xx ascender };

    line_start_index := 0;

    while line_start_index < text.count {
        line_end_index := find_index_from_left(text, #char "\n", line_start_index);

        if line_end_index == -1 {
            line_end_index = text.count;
        }

        line : string;
        line.data   = text.data + line_start_index;
        line.count  = line_end_index - line_start_index;

        line_start_index = line_end_index + 1;

        defer {
            pen.x = 0;
            pen.y += line_height;
        }

        word_start_index := 0;

        prev_char: u32;
        while word_start_index < line.count {
            word_end_index := find_index_from_left(line, #char " ", word_start_index);

            defer {
                pen.x += space_glyph.advance;
                word_start_index = word_end_index + 1;
            }

            // Treat if there is more than one space character.
            if word_start_index == word_end_index {
                pen.x += space_glyph.advance;
            }

            if word_end_index == -1 {
                word_end_index = line.count;
            }

            word: string;
            word.data   = line.data + word_start_index;
            word.count  = word_end_index - word_start_index;

            while word.count > 0 {
                codepoint, _ := utf8_next_character(*word);
                defer prev_char = codepoint;

                glyph           := find_or_add_glyph(font, codepoint, pixel_size);
                pos_in_atlas    := glyph.pos_in_atlas;

                if prev_char > 0 {
                    delta: FT_Vector;

                    FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
                    pen.x += xx (delta.x >> 6);
                }

                defer pen.x += glyph.advance;

                glyph_pos := Vector2.{
                    pen.x + glyph.bearing_x,
                    pen.y - glyph.bearing_y
                };

                rect := Rect.{
                    glyph_pos.x,
                    glyph_pos.y,

                    xx pos_in_atlas.w,
                    xx pos_in_atlas.h,
                };

                rect.position += xy(x, y);

                rect.x = round_pixel(rect.x);
                rect.y = round_pixel(rect.y);

                // uv_rect := Rect.{
                //     pos_in_atlas.x / cast(float) font_atlas.total_width,
                //     pos_in_atlas.y / cast(float) font_atlas.total_height,
                //     pos_in_atlas.w / cast(float) font_atlas.total_width,
                //     pos_in_atlas.h / cast(float) font_atlas.total_height,
                // };

                u0 := pos_in_atlas.x / cast(float) font_atlas.total_width;
                v0 := pos_in_atlas.y / cast(float) font_atlas.total_height;
                u1 := (pos_in_atlas.x + pos_in_atlas.w) / cast(float) font_atlas.total_width;
                v1 := (pos_in_atlas.y + pos_in_atlas.h) / cast(float) font_atlas.total_height;

                uv_rect := Rect.{ u0, v0, u1, v1 };

                internal_draw_rect(rect, color, uv_rect);
            }
        }
    }
}


internal_draw_rect :: (r: Rect, color: Vector4, uv := Rect.{ 0, 0, 0, 0 }) {
    p0 := Vector2.{ r.x, r.y };
    p1 := Vector2.{ r.x + r.w, r.y };
    p2 := Vector2.{ r.x, r.y + r.h };
    p3 := Vector2.{ r.x + r.w, r.y + r.h };

    uv0 := Vector2.{ uv.x, uv.y };
    uv1 := Vector2.{ uv.w, uv.y };
    uv2 := Vector2.{ uv.x, uv.h };
    uv3 := Vector2.{ uv.w, uv.h };

    push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
    push_triangle(p2, p1, p3, color, uv2, uv1, uv3);
}



#scope_file;

#import "Basic";
#import "Hash_Table";
#import "Hash";
#import "Sort";
#import "String";
