/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right


    - ability for user to disable interaction.
    - Fix font modified check we do in user code.
    - use some pool allocator
    - rename margin to gap.
    - fix input.

    TODO:
    - better understanding for scrollbar
    - better understanding for rounded corner.
    - Should makes radius samples relative to size.

    - Finish input text
    - Get proper color state.
    - we can do a better job with key delay/rate (the code is too complex/big for what it does).
    - design tab area. (another background too?).
    - text_codepoint in io struct... ?
    - clear memory of hashtable.

    Blog post:

    1) Explain our the UI backbones : layers, occluders, dragging.

    2) Explain "nice" tricks, like white pixel reserve in the font atlas, the
       double array we swap, the hovered_layer at begin...

*/


#load "theme.jai";
#load "font.jai";

// Context.
theme := DEFAULT_THEME;

UI_Font :: Font;
UI_Rect :: Rect;

operator * :: (rect: Rect, scaler: float) -> Rect {
    return .{ rect.x * scaler, rect.y * scaler, rect.w * scaler, rect.h * scaler };
}

operator == :: (a: Rect, b: Rect) -> bool {
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

io_frozen    := false;
#scope_file;

WHITE :: Vector4.{ 1, 1, 1, 1 };

// @todo: explain.
UV_DISCARD :: Vector2.{ 0, 0 };

UI_ID      :: int;
UI_Texture :: *void;

key_count       :: #run enum_names(UI_Key).count;
key_state       : [key_count] UI_Key_Info;

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

curr_window_scroll : *Scrollbar_State;
curr_expander      : *Expander_State;

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
font         : *Font;
font_texture : UI_Texture;


// @todo: rename.
current_depth := 0; // for layers

dt        := 0.;
prev_time := 0.;

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

Key_State :: enum_flags {
    START       :: 1 << 0;
    END         :: 1 << 1;
    DOWN        :: 1 << 2;
    REPEAT      :: 1 << 3;
};

UI_Key_Info :: struct {
    #as state       : Key_State;
    down_duration   : float;
    repeat_duration : float;
};


// @todo I don't like the name here...
Draw_Marker :: struct {
    clip_rect    : Rect;
    vertex_start : int;
    texture      : UI_Texture;
};

UI_Layout :: struct {
    rect         : Rect;

    cursor       : Vector2; // @todo: explain that.

    // When layout changed, we have to reset a couple of things, like the
    // "curr_column" or the cursor, and this variable is our way to notice it.
    changed    := false;

    columns    := 0;

    should_inline := false;

    // We compute after each space allocation the total space our widgets takes
    // within its layout rect. Used notably for the scrollbar.
    content_height : float;
    content_width  : float;

    scroll         : Vector2;

    // For auto layout.
    curr_column      := 0;
    prev_widget_size : Vector2;
};

Rect :: struct {
    x: float;
    y: float;
    w: float;
    h: float;

    #overlay (x) position   : Vector2;
    #overlay (w) size       : Vector2;
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


Widget_Status :: enum_flags {
    HOVERED     :: (1 << 0);
    DOWN        :: (1 << 1);
    PRESSED     :: (1 << 2);
    FOCUSED     :: (1 << 3);
};

Widget_State :: struct {
    widget_id : UI_ID;
    kind    : Type;
    rect    : Rect;
    status  : Widget_Status;

    pressed : bool; // pressed once.
};

Button_State :: struct {
    #as using base: Widget_State;

    press_duration  := 0.;
    hover_duration  := 0.;
}

Window_State :: struct {
    #as using state : Widget_State;

    open     := true;
    dragging : enum { NONE; MOVE_WINDOW; RESIZE_WINDOW; }
};

Dropdown_State :: struct {
    #as using state : Widget_State;
    open            : bool;
};

Text_Input_State :: struct {
    #as using base: Widget_State;

    text    : string;
    focused : bool;
    focused_start_time : float;

    cursor_start  := -1;
    cursor_end    := -1;
};

Scrollbar_State :: struct {
    #as using state : Widget_State;

    scroll          : Vector2;

    dragging_x : bool;
    dragging_y : bool;
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

UI_Vertex :: struct {
    position : Vector2; @TEXCOORD;
    uv       : Vector2; @TEXCOORD;
    color    : Vector4; @TEXCOORD;
};

push_id :: inline (id: int) {
    array_add(*context_ids, id);
}

pop_id :: inline () {
    if context_ids then pop(*context_ids);
}

set_theme :: (given_theme: Theme) {
    theme = given_theme;
}

set_font :: (font_to_set: *Font, font_texture_atlas: *void) {
    font            = font_to_set;
    font_texture    = font_texture_atlas;
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

freeze_io :: inline () {
    io_frozen = true;
}

unfreeze_io :: inline () {
    io_frozen = false;
}

io_captured :: () -> bool {
    return hovered_layer > 0 || active_widget > 0;
}

set_key_event :: (key: UI_Key, down: bool) {
    info := *key_state[key];

    if down {
        info.state |= (.DOWN | .START);
    } else {
        info.state |= .END;
    }
}

get_cursor_icon :: () -> Cursor_Icon {
    return prev_cursor_icon;
}

KEY_REPEAT_DELAY    :: 0.275;
KEY_REPEAT_RATE     :: 0.020;

update_io :: () {
    text_codepoint.count = 0;

    mask := ~(Key_State.START | .REPEAT);

    for * key_state {
        if (it.state & .END) {
            it.* = UI_Key_Info.{}; // Reset all.
        } else {
            it.state &= mask;
        }

        if it.state & .DOWN {
            it.down_duration += dt;
        } else {
            it.down_duration  = 0;
        }

        if it.down_duration >= KEY_REPEAT_DELAY {
            if it.repeat_duration >= KEY_REPEAT_RATE {
                it.state            |= .REPEAT;
                it.repeat_duration   = 0;
            }

            it.repeat_duration += dt;
        }
    }
}

ui_begin :: () {
    now      := cast(float) seconds_since_init();
    dt        = now - prev_time;
    prev_time = now;

    if io_frozen {
        hovered_layer = -1;

        for * key_state {
            it.* = UI_Key_Info.{};
        }
    }

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
    hovered_layer = -1;
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

    update_io();
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
    resizer_rect.x += state.rect.w - theme.content_padding * 4;
    resizer_rect.y += state.rect.h - theme.content_padding * 4;
    resizer_rect.w  = (theme.content_padding + theme.border_width) * 4;
    resizer_rect.h  = (theme.content_padding + theme.border_width) * 4;

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

    draw_rect(state.rect, theme.color.bg, .ROUND_ALL);

    border_color    := theme.color.border;
    border_color.w   = 0.6;

    // Draw title bar.
    if title {
        title_color := ifx is_topmost theme.color.fg else darken(theme.color.fg, 20);

        text_size := theme.window_title_bar_height * 0.5;
        title_width, title_height := get_text_size(font, title, xx text_size);

        x := title_rect.x + title_rect.w * 0.5 - title_width * 0.5;
        y := title_rect.y + title_rect.h * 0.5 - title_height * 0.5;

        flags := Rect_Flags.TOP | .LEFT | .RIGHT | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT;
        draw_rect(title_rect, title_color, flags);

        draw_outline(title_rect, border_color, theme.border_width, flags);
        draw_text(title, x, y, text_size, theme.color.text);
    }

    content_border := state.rect;
    content_border.y += theme.window_title_bar_height;
    content_border.h -= theme.window_title_bar_height;

    flags := Rect_Flags.BOTTOM | .LEFT | .RIGHT | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
    draw_outline(content_border, border_color, theme.border_width, flags);

    layer_rect   := state.rect;
    layer_rect.x += theme.content_padding;
    layer_rect.y += theme.window_title_bar_height + theme.content_padding;
    layer_rect.w -= theme.scrollbar_width + theme.content_padding * 2;
    layer_rect.h -= (theme.scrollbar_width + theme.window_title_bar_height + theme.content_padding * 2);

    layer_rect = pad_rect(layer_rect, theme.border_width, theme.border_width);

    set_layout(layer_rect);

    curr_window_scroll = begin_scroll(loc);

    push_clip(layer_rect);

    return state.open;
}

window_end :: (loc := #caller_location) {
    pop_clip();

    // Draw opacity gradiant at the bottom.
    if theme.alpha >= 1.0 {
        layout := current_layout();

        c1 := theme.color.bg;
        c1.w = 0;
        c2 := theme.color.bg;
        c2.w = 0;

        c3 := theme.color.bg;
        c4 := theme.color.bg;

        height  := 20.;

        rect    := layout.rect;
        rect.y   = rect.y + rect.h - height;
        rect.h   = height;

        internal_draw_gradiant(rect, c1, c2, c3, c4);
    }

    if curr_window_scroll then end_scroll(curr_window_scroll);
    pop_layer();
}




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
    text_width, text_height   := get_text_size(font, title, xx font_size);
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
        bg_region.h = state.computed_height + theme.margin_y;

        color   := theme.color.border;
        color.w  = 0.6;

        borders := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        draw_rect(bg_region, lighten(theme.color.bg, 2), 0x0);
        draw_outline(bg_region, color, theme.border_width, borders);

        layout_rect := Rect.{
            rect.x + theme.collapser_offset,
            rect.y + rect.h,
            rect.w - theme.collapser_offset * 2,
            layout.rect.h - rect.y,
        };


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
    modified := false;

    layout := current_layout();
    for tabs {
        push_id(it_index);
        defer pop_id();

        if it_index > 0 same_line();

        if tab(it, it_index == tab_index.*, .{ (layout.rect.w - theme.margin_x * tabs.count) / tabs.count, 50 }) {
            tab_index.* = it_index;
            modified = true;
        }
    }

    return modified;

}

flag_select :: (flag: *$T, size := Vector2.{ 100, 40 }, placeholder := "", max_items := 3, loc := #caller_location) -> modified: bool {
    id      := make_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    item_height := size.y * 0.8;

    ti := cast(*Type_Info_Enum) T;

    modified     := false;

    selected_count := 0;
    for enum_name: ti.names {
        if (flag.* & cast(T) ti.values[it_index]) {
            selected_count += 1;
        }
    }

    placeholder_text := ifx placeholder placeholder else "<Choose>";
    btn_label := sprint("% items selected", selected_count);
    defer free(btn_label);
    button_label := ifx selected_count >= 0 btn_label else placeholder_text;


    rect := alloc_space(size);
    mutate_state(state, rect);

    bg_color := get_color(state.status, theme.color.fg);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_size(font, button_label, xx font_size);
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

    {
        arrow_size  := rect.h * 0.3;
        offset      := arrow_size * 0.2;
        arrow_rect := Rect.{
            rect.x + rect.w - (arrow_size + theme.button_padding),
            rect.y + rect.h * 0.5 - arrow_size * 0.5 + offset,
            arrow_size, arrow_size,
        };

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



    if state.open {
        dropdown_height := cast(float, max_items) * (item_height + theme.content_padding * 2);
        dropdown_flags := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        dropdown_rect  := Rect.{ rect.x, rect.y + rect.h, rect.w, dropdown_height };

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


        selected_color := theme.color;
        selected_color.fg = theme.color.accent;

        scroll := begin_scroll(loc);

        for ti.names {
            push_id(it_index);
            defer pop_id();

            enum_val := cast(T) ti.values[it_index];
            selected := flag.* & enum_val;

            color := ifx selected selected_color else theme.color;

            if button(it, .{ layer_rect.w, item_height }, color = *color) {
                if selected then flag.* &= ~enum_val; else flag.* |= enum_val;
                modified    = true;
            }
        }

        end_scroll(scroll);

        draw_outline(dropdown_rect, theme.color.border, theme.border_width, dropdown_flags);

        // If click outside the dropdown, we close the dropdown.
        if is_pressed(.MOUSE_LEFT) && (state.status == 0x00) && !cursor_vs_rect(dropdown_rect) && active_widget == -1 {
            state.open = false;
        }

    }

    return modified;
}

select :: (selected: *int, items: [] string, size := Vector2.{ 100, 40 }, placeholder := "", max_items := 3, loc := #caller_location) -> bool {
    id      := make_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    placeholder_text := ifx placeholder placeholder else "<Choose>";

    modified     := false;
    button_label := ifx selected.* >= 0 items[selected.*] else placeholder_text;

    item_height := size.y * 0.8;

    rect := alloc_space(size);
    mutate_state(state, rect);

    bg_color := get_color(state.status, theme.color.fg);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_size(font, button_label, xx font_size);
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


    if state.open {
        dropdown_height := (item_height + theme.content_padding * 2) * (cast(float) max_items);
        dropdown_flags := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        dropdown_rect  := Rect.{ rect.x, rect.y + rect.h, rect.w, dropdown_height };

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

        scroll := begin_scroll(loc);

        for items {
            push_id(it_index);
            defer pop_id();

            if button(it, .{ layer_rect.w, item_height }) {
                selected.*  = it_index;
                modified    = true;
                state.open  = false;
            }
        }

        end_scroll(scroll);

        draw_outline(dropdown_rect, theme.color.border, theme.border_width, dropdown_flags);

        // If click outside the dropdown, we close the dropdown.
        if is_pressed(.MOUSE_LEFT) && (state.status == 0x00) && !cursor_vs_rect(dropdown_rect) && active_widget == -1 {
            state.open = false;
        }

    }

    return modified;
}

label :: (text: string, label_size := 0., loc := #caller_location) {
    text_size := ifx label_size <= 0 theme.text_size else label_size;
    text_width, text_height := get_text_size(font, text, xx text_size);

    height := text_height;
    center_on_previous_widget := false;

    layout := current_layout();
    if layout.should_inline {
        center_on_previous_widget = true;
        height = max(height, layout.prev_widget_size.y);
    }

    rect   := alloc_space(xy(text_width, height));
    y      := rect.y;

    if center_on_previous_widget {
        y += layout.prev_widget_size.y * 0.5 - text_height * 0.5;
    }

    draw_text(text, rect.x, y, text_size, theme.color.text);
}

separator :: (text := "") {
    layout := current_layout();

    if text {
        text_size := theme.text_size * 0.7;
        text_width, text_height := get_text_size(font, text, xx text_size);

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

hexa_input :: (color: *Vector4, size := Vector2.{ 200, 60 }) -> modified: bool {
    hexa := color_to_hexa(color.*);

    hexa_str := sprint("#%", formatInt(hexa, base = 16, minimum_digits = 6));
    defer free(hexa_str);

    modified, new_str := text_input(hexa_str, size);

    if modified && new_str.count >= 1 {
        advance(*new_str, 1);

        result, success := string_to_int(new_str, 16, u32);
        if success then color.* = hexa_to_color(result);
    }

    same_line();

    rect := alloc_space(Vector2.{ size.y, size.y }, true);
    draw_rect(rect, color.*, .ROUND_ALL);
    draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);

    return modified;
}

Color_Format :: enum {
    FLOAT;
    U8;
};

rgba_input :: (value : *Vector4, size := Vector2.{ 120, 60 }, format := Color_Format.FLOAT, loc := #caller_location) -> modified: bool {
    layout := current_layout();

    for * value.component {
        push_id(it_index);
        defer pop_id();

        if it_index > 0 same_line();

        rect := alloc_space(Vector2.{ size.y * 0.4, size.y }, false);

        mask := (Rect_Flags.ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        color   : Vector4;
        text    : string;

        if it_index == {
            case 0;
                color = theme.color.red;
                text  = "R";
            case 1;
                color = theme.color.green;
                text  = "G";
            case 2;
                color = theme.color.blue;
                text  = "B";
            case 3;
                color = theme.color.text_muted;
                text  = "A";
        }

        draw_rect(rect, color, mask);

        c := theme.color.border;
        c.w = 0.4;
        draw_outline(rect, c, theme.border_width, .TOP | .BOTTOM | .LEFT | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        text_size := (size.y * 0.3);
        text_width, text_height := get_text_size(font, text, text_size);

        draw_text(text, rect.x + rect.w * 0.5 - text_width * 0.5, rect.y + rect.h * 0.5 - text_height * 0.5, text_size, lighten(color, 90));

        flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;

        same_line();

        if format == {
            case .FLOAT;
                val := clamp(it.*, 0, 1);
                if number_input(*val, size = size, flags, loc) {
                    it.* = val;
                }

            case .U8;
                val := ifx it_index < 3 then clamp(it.* * 255, 0, 255) else clamp(it.*, 0, 1);

                if number_input(*val, size = size, flags, loc) {
                    if it_index < 3 {
                        it.* = val / 255;
                    } else {
                        it.* = val;
                    }
                }
        }

        layout.cursor.x += theme.margin_x;
    }

    same_line();

    rect := alloc_space(Vector2.{ size.y, size.y }, true);
    draw_rect(rect, value.*, .ROUND_ALL);
    draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);

    return false;
}

number_input :: (value: *$T, size := Vector2.{ 200, 60 }, flags := Rect_Flags.ALL_SIDES, loc := #caller_location) -> modified: bool
#modify {
    if T != float && T != int {
        return false, "Unsuported argument type, should be float or int.";
    }

    return true;
}
{
    str_value         := sprint("%", value.*);
    defer free(str_value);

    modified, new_str := text_input(str_value, size, flags, loc);

    if !modified return false;

    #if T == float {
        result, success        := parse_float(*new_str);
        if success then value.* = result;
    }

    #if T == int {
        result, success   := parse_int(*new_str, int);
        if success value.* = result;
    }

    return true;
}

text_input :: (user_str: string, size := Vector2.{ 200, 60 }, flags := Rect_Flags.ALL_SIDES, loc := #caller_location) -> modified: bool, new_string: string {
    id              := make_id(loc);
    state, is_new   := get_widget_state(Text_Input_State, id);

    using state;

    input_rect      := alloc_space(size, false);
    mutate_state(state, input_rect);

    // Sync string when we are typing.
    if !state.focused {
        if user_str != state.text then state.cursor_start = user_str.count;

        str_copied := copy_string(user_str);

        if state.text then free(state.text);
        state.text = str_copied;
    }


    if !state.focused && state.pressed {
        active_widget = id;
        state.focused = true;
        state.focused_start_time = xx seconds_since_init();
    }

    if state.status & .HOVERED then curr_cursor_icon = .TEXT_EDIT;

    modified := false;

    if state.focused {
        click_outside := !cursor_vs_rect(state.rect) && is_pressed(.MOUSE_LEFT);

        if is_pressed(.RETURN) {
            active_widget = -1;
            state.focused = false;
            modified = true;
        }

        if is_pressed(.ESCAPE) || click_outside {
            active_widget = -1;
            state.focused = false;
            modified = true;
        }

        if is_pressed(.BACKSPACE, repeat = true) && state.cursor_start > 0 {
            for state.cursor_start..state.text.count - 1 {
                state.text[it - 1] = state.text[it];
            }

            if state.cursor_start > 0 then state.cursor_start -= 1;
            if state.text.count   > 0 then state.text.count   -= 1;
        }

        if is_pressed(.RIGHT, repeat = true) && state.cursor_start <= state.text.count {
            state.cursor_start += 1;
        }

        if is_pressed(.LEFT, repeat = true) && state.cursor_start > 0 {
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


    bg_color := get_color(status, theme.color.fg);
    draw_rect(rect, bg_color, flags);
    draw_outline(rect, theme.color.border, theme.border_width, flags);

    font_size                 := input_rect.h * 0.5;
    text_width, text_height   := get_text_size(font, state.text, xx font_size);

    text_x := rect.x + theme.input_padding + theme.border_width;
    text_y := rect.y + state.rect.h * 0.5 - text_height * 0.5;

    should_clip  := text_x + text_width > state.rect.w - theme.border_width;

    clip_rect    := rect;

    if flags & .LEFT        clip_rect.x += theme.border_width;
    if flags & .TOP         clip_rect.y += theme.border_width;
    if flags & .RIGHT       clip_rect.w -= theme.border_width;
    if flags & .BOTTOM      clip_rect.h -= theme.border_width;

    if should_clip       then push_clip(clip_rect);
    defer if should_clip then pop_clip();

    if state.focused {
        cursor_text := state.text;

        if state.cursor_start < state.text.count {
            cursor_text = slice(state.text, 0, state.cursor_start);
        }

        cursor_height    := rect.h * 0.5;
        to_cursor_width  := get_text_size(font, cursor_text, xx font_size);

        input_width := state.rect.w - (theme.border_width * 2);
        cursor_size := theme.input_cursor_size;

        offset := (to_cursor_width + cursor_size + theme.input_padding) - input_width;
        if offset >= 0 then text_x -= offset;

        cursor_rect := Rect.{
            text_x + to_cursor_width, state.rect.y + state.rect.h * 0.5 - cursor_height * 0.5,
            cursor_size, cursor_height
        };

        now             := cast(float) seconds_since_init();
        elapsed         := state.focused_start_time - now;
        blink_speed     := 8.0;
        alpha           := cast(float) (sin(elapsed * blink_speed) + 1.0) * 0.5;

        cursor_color  := lighten(theme.color.text, 20);
        cursor_color.w = alpha;

        draw_text(text, text_x, text_y, size.y * 0.5, theme.color.text);
        draw_rect(cursor_rect, cursor_color);
    } else {
        draw_text(text, text_x, text_y, size.y * 0.5, theme.color.text);
    }

    return modified, text;
}

radio_buttons :: (items: [] string, index: *int, loc := #caller_location) -> bool {
    changed := false;

    for items {
        push_id(it_index);
        defer pop_id();

        checked := it_index == index.*;

        if checkbox(*checked, text_label = it) {
            changed = true;
        }

        if checked {
            index.* = it_index;
        }
    }

    return changed;
}

checkbox :: (checked: *bool, text_label := "", loc := #caller_location) -> bool {
    id      := make_id(loc, text_label);
    state   := get_widget_state(Widget_State, id);

    text_width, text_height : float;
    content_size            := xy(theme.checkbox_size);

    if text_label {
        text_width, text_height = get_text_size(font, text_label, theme.text_size);

        content_size.x += text_width + theme.content_padding;
        content_size.y  = max(theme.checkbox_size, text_height);
    }


    rect := alloc_space(content_size);
    mutate_state(state, rect);

    changed := false;

    if state.pressed {
        changed   = true;
        checked.* = !checked.*;
    }

    inner_color := get_color(state.status, ifx checked.* then theme.color.accent else theme.color.text_muted);

    radius  := theme.checkbox_size * 0.5;
    pos     := xy(rect.x + radius, rect.y + rect.h * 0.5);

    draw_circle(pos, radius, theme.color.bg);
    draw_circle_outline(pos, radius, theme.border_width, inner_color);

    if checked.* == true {
        inner_circle := radius * 0.5;
        draw_circle(pos, inner_circle, inner_color);
    }

    if text_label {
        pos.x += theme.checkbox_size - radius + theme.content_padding;
        pos.y  = rect.y + rect.h * 0.5 - text_height * 0.5;

        leftover    := (rect.x + rect.w - pos.x);
        text_index  := cursor_to_text_index(font, text_label, theme.text_size, leftover);

        if text_index < 0 {
            draw_text(text_label, pos.x, pos.y, theme.text_size, theme.color.text);
        } else {
            // @note: We want to make sure we can modify the string, so we copy
            // it. Yup, the underlying string could be in the read-only data
            // segment of the program.
            str_copied := copy_string(text_label);
            defer free(str_copied);

            str_copied = slice(str_copied, 0, str_copied.count - text_index);

            // Put ellipsis at the end of the string.
            for < * str_copied {
                index := str_copied.count - 1 - it_index;
                if index < 3 it.* = #char ".";
            }

            draw_text(str_copied, pos.x, pos.y, theme.text_size, theme.color.text);
        }

    }

    return changed;
}

tab :: (label: string, active: bool, size := Vector2.{ -1, 30 }, loc := #caller_location) -> bool {
    id          := make_id(loc, label);
    using state := get_widget_state(Widget_State, id);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_size(font, label, xx font_size);

    button_size := size;

    if size.x <= 0 {
        button_size.x = text_width + theme.button_padding;
    }

    mutate_state(state, alloc_space(button_size));

    clip := peek(current_layer.clip_stack);
    if !rect_vs_rect(state.rect, clip) return state.pressed;

    text_too_big := rect.w < button_size.x;

    is_activated := status & .FOCUSED || status & .PRESSED || active;

    bg_color     := get_color(status, ifx is_activated then theme.color.accent else theme.color.fg);
    border_color := theme.color.border;

    draw_rect(rect, bg_color, .TOP | .LEFT | .RIGHT | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT);

    text_rect := pad_rect(rect, theme.button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    if text_too_big push_clip(rect);
    draw_text(label, x, y, font_size, theme.color.text);
    if text_too_big pop_clip();

    return state.pressed;
}

button :: (label := "", size := Vector2.{ -1, 40 }, texture : UI_Texture = null, loc := #caller_location, color : *Color_Theme = null) -> bool {
    id          := make_id(loc, label);
    using state := get_widget_state(Button_State, id);

    font_size                 := size.y * 0.5;
    text_width, text_height   := get_text_size(font, label, xx font_size);

    button_size := size;

    if size.x <= 0 {
        button_size.x = text_width + theme.button_padding;
    }

    mutate_state(state, alloc_space(button_size));
    hover_strength, press_strength := update_times(state);

    clip := peek(current_layer.clip_stack);
    if !rect_vs_rect(state.rect, clip) return state.pressed;

    text_too_big := rect.w < button_size.x;


    is_activated := status == .FOCUSED || status == .PRESSED;

    colors := ifx color then color.* else theme.color;

    bg_color     := get_color(status, ifx is_activated then colors.accent else colors.fg);
    border_color := colors.border;


    bg_color = lerp(colors.fg, lighten(colors.fg, 10), hover_strength);
    bg_color = lerp(bg_color, lighten(colors.fg, 30), press_strength);

    if texture {
        draw_rect(rect, bg_color, .ROUND_ALL);
        draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);

        prev := set_texture(texture);
        draw_rect(rect, WHITE);
        set_texture(prev);
    } else {
        draw_rect(rect, bg_color, .ROUND_ALL);
    }

    if label {
        text_rect := pad_rect(rect, theme.button_padding, 0);

        // Center text in button rect.
        x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
        y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

        offset := 4.;

        x = lerp(x, x + offset, press_strength);
        y = lerp(y, y + offset, press_strength);

        if text_too_big push_clip(rect);
        draw_text(label, x, y, font_size, colors.text);
        if text_too_big pop_clip();
    }

    return state.pressed;
}

get_color :: (status: Widget_Status, color: Vector4) -> Vector4 {
    if status & .PRESSED || status & .DOWN || status & .FOCUSED return lighten(color, 25);
    if status & .HOVERED return lighten(color, 10);

    return color;
}

same_line :: () {
    layout := current_layout();
    layout.should_inline = true;
}

begin_column :: (col_count : int) {
    layout := current_layout();
    layout.columns = col_count;
}

end_column :: () {
    layout := current_layout();

    layout.columns      = 0;
    layout.cursor.x     = 0;
    layout.curr_column  = 0;
}











#scope_file;

get_widget_state :: ($T: Type, id: UI_ID, default_rect := Rect.{}) -> *T, bool {
    state, new := find_or_add(*widget_states, id);

    if new {
        ptr         := New(T, initialized = true);
        state.*      = cast(*Widget_State) ptr;
        state.*.kind = T;

        if default_rect.w > 0 || default_rect.h > 0 {
            state.*.rect = default_rect;
        }
    }

    state.*.widget_id = id;

    return cast(*T) state.*, new;
}

update_times :: (state: *Button_State) -> float, float {
    status := get_status(state.rect);

    HOVER_TIME    :: 0.6;
    PRESS_TIME    :: 0.4;

    now := cast(float) seconds_since_init();

    if state.status & .HOVERED {
        state.hover_duration += dt * 2;
        state.hover_duration = min(state.hover_duration, HOVER_TIME);
    } else {
        state.hover_duration -= dt;
        state.hover_duration = max(state.hover_duration, 0);
    }

    if state.status & .DOWN {
        state.press_duration += dt * 2;
        state.press_duration = min(state.press_duration, PRESS_TIME);
    } else {
        state.press_duration -= dt * 4;
        state.press_duration = max(state.press_duration, 0);
    }

    return (state.hover_duration / HOVER_TIME), (state.press_duration / PRESS_TIME);
}

mutate_state :: (state: *Widget_State, rect: Rect, check_layout := true) {
    state.status = ifx active_widget > -1 && active_widget != state.widget_id then 0 else get_status(rect, check_layout);

    if state.widget_id == active_widget {
        state.status |= .FOCUSED;
    }

    state.pressed = state.status & .PRESSED !=0;

    state.rect   = rect;
}

// @todo: Explain why check_layout or rename.
get_status :: (rect: Rect, check_layout := true) -> Widget_Status {
    status : Widget_Status;

    within_layer       := cursor_vs_rect(current_layer.rect);
    within_widget_rect := cursor_vs_rect(rect);
    within_layout_rect := ifx check_layout cursor_vs_rect(current_layout().rect) else true;

    if !is_occluded(rect) && within_widget_rect && within_layer && within_layout_rect {
        status |= .HOVERED;

        if is_down(.MOUSE_LEFT) {
            status |= .DOWN;

        }

        if is_pressed(.MOUSE_LEFT) {
            status |= .PRESSED;
        }
    }



    return status;
}

begin_scroll :: (loc := #caller_location) -> *Scrollbar_State {
    id      := make_id(loc, "scrollbar");
    state   := get_widget_state(Scrollbar_State, id);

    current_layout().scroll = state.scroll;

    return state;
}

end_scroll :: (state: *Scrollbar_State) {
    id := state.widget_id;

    layout := current_layout();

    scroll      := *state.scroll;
    prev_layout := current_layer.prev_layout;


    {
        // We compute the actual content size from the previous frame.
        content_h   := layout.content_height;
        visible_h   := layout.rect.h;

        // max_scroll offset?
        max_scroll  := max(0.0, content_h - visible_h);
        scroll.y     = clamp(scroll.y, 0.0, max_scroll);

        // @todo: Perhaps add again mouse wheel for scrolling content...
        // if point_vs_rect(mouse_x, mouse_y, layout.rect) && max_scroll > 0 && active_widget == -1 {
        //     scroll.y += xx wheel_y;
        //     scroll.y = clamp(scroll.y, 0.0, max_scroll);
        // }

        if max_scroll > 0 {
            track_h  := layout.rect.h;

            ratio    := clamp(visible_h / content_h, 0.0, 1.0);
            handle_h := max(20., track_h * ratio); // @todo, set the min size in theme.
            travel   := track_h - handle_h;
            scroll_t := ifx max_scroll > 0 scroll.y / max_scroll else 0.0;


            handle := Rect.{
                layout.rect.x + layout.rect.w + theme.content_padding * 0.5,
                layout.rect.y + scroll_t * travel,
                theme.scrollbar_width,
                handle_h,
            };

            status   := get_status(handle, check_layout = false);
            bg_color := get_color(status, ifx state.dragging_y then theme.color.accent else theme.color.text_muted);

            if !state.dragging_x && (active_widget == -1 || active_widget == id) {
                is_dragging := active_widget == id;
                hit         := cursor_vs_rect(handle) && is_down(.MOUSE_LEFT);

                if hit && !is_dragging && abs(delta_y) > 0 {
                    active_widget = id;
                    state.dragging_y = true;
                }

                if is_dragging && !is_down(.MOUSE_LEFT) {
                    active_widget = -1;
                    state.dragging_y = false;
                }

                if is_dragging && travel > 0 {
                    scroll.y += delta_y * (max_scroll / travel);
                    scroll.y  = clamp(scroll.y, 0.0, max_scroll);
                }
            }

            draw_rect(handle, bg_color, .ROUND_ALL);
        }

    }

    {
        // We compute the actual content size from the previous frame.
        content_w   := layout.content_width;
        visible_w   := layout.rect.w;

        max_scroll  := max(0.0, content_w - visible_w);
        scroll.x     = clamp(scroll.x, 0.0, max_scroll);

        if max_scroll > 6 {
            track_w  := layout.rect.w;

            ratio    := clamp(visible_w / content_w, 0.0, 1.0);
            handle_w := max(20., track_w * ratio); // @todo, set the min size in theme.
            travel   := track_w - handle_w;
            scroll_t := ifx max_scroll > 0 scroll.x / max_scroll else 0;


            handle := Rect.{
                layout.rect.x + scroll_t * travel,
                layout.rect.y + layout.rect.h + theme.content_padding * 0.5,
                handle_w,
                theme.scrollbar_width,
            };

            status := get_status(handle, check_layout = false);

            bg_color := get_color(status, ifx state.dragging_x then theme.color.accent else theme.color.text_muted);

            if !state.dragging_y && (active_widget == -1 || active_widget == id) {
                is_dragging := active_widget == id;
                hit         := cursor_vs_rect(handle) && is_down(.MOUSE_LEFT);

                if hit && !is_dragging && abs(delta_x) > 0 {
                    active_widget = id;
                    state.dragging_x = true;
                }

                if is_dragging && !is_down(.MOUSE_LEFT) {
                    active_widget = -1;
                    state.dragging_x = false;
                }

                if is_dragging && travel > 0 {
                    scroll.x += delta_x * (max_scroll / travel);
                    scroll.x  = clamp(scroll.x, 0.0, max_scroll);
                }
            }

            draw_rect(handle, bg_color, .ROUND_ALL);

        }

    }

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
set_texture :: (texture: UI_Texture) -> prev: UI_Texture {
    prev_texture    := current_texture;
    current_texture  = texture;

    last := peek(current_layer.draw_markers);
    record_draw_marker(last.clip_rect);

    return prev_texture;
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

alloc_space :: (widget_size: Vector2, margin := true) -> Rect {
    using layout := current_layout();

    size := widget_size;

    margin_x := theme.margin_x;
    margin_y := theme.margin_y;

    if !margin {
        margin_x = 0;
    }


    if prev_widget_size.x > 0 || prev_widget_size.y > 0 {
        if layout.columns > 0 {
            layout_width := layout.rect.w;

            col_width := layout.rect.w / max(1, columns);
            size.x     = col_width - margin_x;

            if curr_column == 0 {
                cursor.x     = 0;
                cursor.y    += prev_widget_size.y + margin_y;
                curr_column += 1;
            } else {
                cursor.x    += ifx curr_column > 0 col_width else 0;
                curr_column += 1;
            }

            if curr_column >= columns {
                curr_column = 0;
            }

        } else if layout.should_inline {
            cursor.x += prev_widget_size.x + margin_x;
            layout.should_inline = false;
        } else {
            cursor.x  = 0;
            cursor.y += prev_widget_size.y + margin_y;
            layout.should_inline = false;
        }

    } else {

        if layout.columns > 0 {
            col_width := (layout.rect.w) / max(1, columns);
            size.x     = col_width - margin_x;
            curr_column += 1;
        }
    }

    base_x := layout.rect.x - layout.scroll.x;
    base_y := layout.rect.y - layout.scroll.y;

    r := Rect.{ base_x + cursor.x, base_y + cursor.y, size.x, size.y };

    r.x = round_pixel(r.x);
    r.y = round_pixel(r.y);
    r.w = round_pixel(r.w);
    r.h = round_pixel(r.h);

    prev_widget_size = Vector2.{ size.x, size.y };

    layout.content_width  = max(layout.content_width, cursor.x + size.x);
    layout.content_height = max(layout.content_height, cursor.y + size.y);

    return r;
}

is_down :: (key: UI_Key) -> bool {
    info := key_state[key];

    if io_frozen return false;

    return info.state & .DOWN != 0;
}

// @note: For now, it's pressed on key release.
is_pressed :: (key: UI_Key, repeat := false) -> bool {
    using info := key_state[key];

    if io_frozen return false;

    if repeat {
        return state & (.REPEAT | .END) != 0;
    }

    return state & .END != 0;
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

draw_outline :: (r: Rect, color: Vector4, border_width: float, flags: Rect_Flags = .ALL_SIDES) {
    if border_width <= 0 return;

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

        if round_tl then x0 += radius;
        if round_tr then x1 -= radius;

        internal_draw_rect(Rect.{ x0, r.y, x1 - x0, border_width }, color);
    }

    if bottom {
        x0 := r.x;
        x1 := r.x + r.w;

        if round_bl then x0 += radius;
        if round_br then x1 -= radius;

        internal_draw_rect(Rect.{ x0, r.y + r.h - border_width, x1 - x0, border_width }, color);
    }

    if left {
        y0 := r.y;
        y1 := r.y + r.h;

        if round_tl then y0 += radius;
        if round_bl then y1 -= radius;

        internal_draw_rect(Rect.{ r.x, y0, border_width, y1 - y0 }, color);
    }

    if right {
        y0 := r.y;
        y1 := r.y + r.h;

        if round_tr then y0 += radius;
        if round_br then y1 -= radius;

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

get_uv :: (region: Rect, part: Rect) -> Rect {
    return Rect.{
        (part.x - region.x) / region.w,
        (part.y - region.y) / region.h,
        (part.x + part.w - region.x) / region.w,
        (part.y + part.h - region.y) / region.h,
    };
}

get_uv :: (region: Rect, point: Vector2) -> Vector2 {
    return .{
        (point.x - region.x) / region.w,
        (point.y - region.y) / region.h,
    };
}

draw_rect :: (r: Rect, color: Vector4, flags : Rect_Flags = .ALL_SIDES) {

    if flags == .ALL_SIDES {
        internal_draw_rect(r, color, get_uv(r, r));
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

            uv0 := get_uv(r, p0);
            uv1 := get_uv(r, p1);
            uv2 := get_uv(r, p2);

            push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_left, color, get_uv(r, top_left));
    }

    if flags & .ROUND_TOP_RIGHT {
        p0 := xy(top_right.x, top_right.y + top_right.h);

        prev := p0 + xy(0, -radius);
        for 1..theme.radius_sample {
            theta   := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1      := prev;
            p2      := p0 + xy(sin(theta) * radius, -cos(theta) * radius);

            uv0 := get_uv(r, p0);
            uv1 := get_uv(r, p1);
            uv2 := get_uv(r, p2);

            push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_right, color, get_uv(r, top_right));
    }

    if flags & .ROUND_BOTTOM_LEFT {
        p0 := xy(bottom_left.x + bottom_left.w, bottom_left.y);

        prev := p0 + xy(0, radius);
        for 1..theme.radius_sample {
            theta   := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1      := prev;
            p2      := p0 + xy(-sin(theta) * radius, cos(theta) * radius);

            uv0 := get_uv(r, p0);
            uv1 := get_uv(r, p1);
            uv2 := get_uv(r, p2);

            push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_left, color, get_uv(r, bottom_left));
    }

    if flags & .ROUND_BOTTOM_RIGHT {
        p0 := xy(bottom_right.x, bottom_right.y);

        prev := p0 + xy(0, radius);
        for 1..theme.radius_sample {
            theta   := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1      := prev;
            p2      := p0 + xy(sin(theta) * radius, cos(theta) * radius);

            uv0 := get_uv(r, p0);
            uv1 := get_uv(r, p1);
            uv2 := get_uv(r, p2);

            push_triangle(p0, p1, p2, color, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_right, color, get_uv(r, bottom_right));
    }

    // To fill up the rest of the belly of the rounded corner, we can do that
    // with only 3 rects.

    center_middle := Rect.{ r.x + radius, r.y, r.w - (2 * radius), r.h };
    internal_draw_rect(center_middle, color, get_uv(r, center_middle));

    right_middle := Rect.{ r.x, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(right_middle, color, get_uv(r, right_middle));

    left_middle := Rect.{ r.x + r.w - radius, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(left_middle, color, get_uv(r, left_middle));
}

draw_text :: (text: string, x: float, y: float, font_size := 16.0, color := Vector4.{ 1, 1, 1, 1 }) {
    if color.w <= 0 || text.count <= 0 return;

    assert(font != null, "Font is null, you must set a font.");

    using font;
    using metrics := get_font_metrics(font, xx font_size);

    space_glyph := find_or_add_glyph(font, #char " ", pixel_size);

    pen := Vector2.{ 0, xx ascender };

    line_start_index := 0;

    prev := set_texture(font_texture);
    defer set_texture(prev);

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

                u0 := pos_in_atlas.x / cast(float) font_atlas.WIDTH;
                v0 := pos_in_atlas.y / cast(float) font_atlas.HEIGHT;
                u1 := (pos_in_atlas.x + pos_in_atlas.w) / cast(float) font_atlas.WIDTH;
                v1 := (pos_in_atlas.y + pos_in_atlas.h) / cast(float) font_atlas.HEIGHT;

                uv_rect := Rect.{ u0, v0, u1, v1 };

                internal_draw_rect(rect, color, uv_rect);
            }
        }
    }
}

internal_draw_gradiant :: (r: Rect, _c0: Vector4, _c1: Vector4, _c2: Vector4, _c3: Vector4, uv := Rect.{}) {
    p0 := Vector2.{ r.x, r.y };
    p1 := Vector2.{ r.x + r.w, r.y };
    p2 := Vector2.{ r.x, r.y + r.h };
    p3 := Vector2.{ r.x + r.w, r.y + r.h };

    uv0 := Vector2.{ uv.x, uv.y };
    uv1 := Vector2.{ uv.w, uv.y };
    uv2 := Vector2.{ uv.x, uv.h };
    uv3 := Vector2.{ uv.w, uv.h };

    c0 := _c0;
    c0.w = _c0.w * theme.alpha;

    c1 := _c1;
    c1.w = _c1.w * theme.alpha;

    c2 := _c2;
    c2.w = _c2.w * theme.alpha;

    c3 := _c3;
    c3.w = _c3.w * theme.alpha;

    vertices := get_vertices();

    array_add(vertices, .{ position = p0, uv = uv0, color = c0 });
    array_add(vertices, .{ position = p1, uv = uv1, color = c1 });
    array_add(vertices, .{ position = p2, uv = uv2, color = c2 });

    array_add(vertices, .{ position = p2, uv = uv0, color = c2 });
    array_add(vertices, .{ position = p1, uv = uv1, color = c1 });
    array_add(vertices, .{ position = p3, uv = uv2, color = c3 });
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


#import "Basic";
#import "Hash_Table";
#import "Hash";
#import "Sort";
#import "String";
