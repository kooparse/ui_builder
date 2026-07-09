/*

    reminder: coord 0,0 is top left, max_width,max_height is bottom right

    - Move window when click between its widgets.
    - Scroll in tabs.
    - Ability to get the layout of a window.
    - Add wrap mode.
    - select, use u32 and autocast as "selected_index" could crash everything...
    - center vertically (undo/redo) and add vertical separator?
    - gradiant should vanish when content is at the bottom.
    - glitch in dropdown item list.
    - better design for inputs, radius...
    - Finish input text

    - use some pool allocator / clear memory.

    TODO:
    - Should makes radius samples relative to size.

    Blog post:

    1) Explain our the UI backbones : layers, occluders, dragging.

    2) Explain "nice" tricks, like white pixel reserve in the font atlas, the
       double array we swap, the hovered_layer at begin...

*/

#module_parameters(Texture_Type: Type = void);

#load "font.jai";

DEFAULT_THEME :: Theme.{};
theme         := DEFAULT_THEME;

UI_Font :: Font;
UI_Rect :: Rect;

operator * :: (rect: Rect, scaler: float) -> Rect {
    return .{ rect.x * scaler, rect.y * scaler, rect.w * scaler, rect.h * scaler };
}

operator / :: (rect: Rect, scaler: float) -> Rect {
    return .{ rect.x / scaler, rect.y / scaler, rect.w / scaler, rect.h / scaler };
}

operator == :: (a: Rect, b: Rect) -> bool {
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

get_longest_text_width :: (list: []string) -> max_width: float {
    max_width := 0.;

    for list {
        text_width := get_text_size(font, it, theme.text_size);
        max_width   = max(max_width, text_width);
    }

    return max_width;
}


#scope_file;

HOVER_TIME    :: 0.6;
PRESS_TIME    :: 0.4;


WHITE         :: Vector4.{ 1, 1, 1, 1 };

// @todo: explain.
UV_DISCARD :: Vector2.{ 0, 0 };

UI_ID       :: int;
BG_LAYER_ID :: S64_MAX;

key_count       :: #run enum_names(UI_Key).count;
key_state       : [key_count] UI_Key_Info;
modifiers       : UI_Modifiers;

prev_layer_list  : [..] Layer;
curr_layer_list  : [..] Layer;
layer_stack      : [..] int; // Index of layers from our current layer list.
current_layer    : *Layer;
background_layer :  Layer; // All widgets set outside windows will used this layer.

widget_states   : Table(UI_ID, *Widget_State);

active_widget   : UI_ID = -1; // I want a pointer to the state directly....
hovered_layer   : UI_ID = -1;

// @todo: explain that.
context_ids     : [..] UI_ID;

text_codepoint : string;

draw_list       : UI_Draw_List;
current_texture : *Texture_Type;

mouse_x  : float;
mouse_y  : float;
delta_x  : float;
delta_y  : float;

// @todo: Not great...
curr_window_scroll : *Scrollbar_State;
curr_expander      : *Expander_State;

// @todo: do a better job... here.
navigation_widget_index := 0;
curr_navigation_widget  := -1;

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
font_texture : *Texture_Type;


// @todo: rename.
current_depth := 0; // for layers

io_frozen    := false;

dt        := 0.;
prev_time := 0.;

prev_glyph_count := 0;
glyph_count      := 0;

wheel_scrolling_triggered := false;

all_widget_disabled := false;

// initialized  := false;
// ui_pool      : Flat_Pool;
// ui_allocator : Allocator;


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
    texture      : *Texture_Type;
};

UI_Layout :: struct {
    rect         : Rect;

    cursor     : Vector2;

    columns    := 0;

    row_max_height := 0.;

    should_inline      := false;
    should_fullwidth   := false;
    should_force_width := 0.0;

    // We compute after each alloc_space the total space our widgets takes
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

    press_duration  := 0.;
    hover_duration  := 0.;
};

Checkbox_State :: struct {
    #as using base: Widget_State;

    checked_duration := 0.;
};

Button_State :: struct {
    #as using base: Widget_State;
}

Dropdown_State :: struct {
    #as using state : Widget_State;
    open            : bool;
    want_search     : bool;
    search          : string;
};

Text_Input_State :: struct {
    #as using base: Widget_State;

    text               : string;
    editing         : bool;
    texting_start_time : float;

    cursor_start  := 0;
    cursor_end    := 0;
};

Scrollbar_State :: struct {
    #as using state : Widget_State;

    scroll          : Vector2;

    has_scrollbar_x : bool;
    has_scrollbar_y : bool;

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

Window_State :: struct {
    #as using state : Widget_State;

    open     := true;
    dragging : enum { NONE; MOVE_WINDOW; RESIZE_WINDOW; }

    init     := false;
};

UI_Modifiers :: enum_flags {
    CTRL    :: 1 << 0;
    SHIFT   :: 1 << 1;
    ALT     :: 1 << 2;
    OS      :: 1 << 3;
};

UI_Draw_Call :: struct {
    vertex_start : int;
    vertex_count : int;
    clip         : Rect;
    texture      : *Texture_Type;
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

push_id :: inline (str: string) {
    array_add(*context_ids, get_hash(str));
}

pop_id :: inline () {
    if context_ids then pop(*context_ids);
}

set_theme :: (given_theme: Theme) {
    theme = given_theme;
}

set_font :: (font_to_set: *Font, font_texture_atlas: *Texture_Type) -> bool {
    font            = font_to_set;
    font_texture    = font_texture_atlas;

    return prev_glyph_count != glyph_count;
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
    return hovered_layer != BG_LAYER_ID && (hovered_layer > 0 || active_widget > 0);
}

set_modifiers :: (mod: UI_Modifiers) {
    modifiers |= mod;
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

    if is_pressed(.TAB) {
        if modifiers & .CTRL {
            curr_navigation_widget -= 1;
            if curr_navigation_widget < 0 curr_navigation_widget = 0;
        } else {
            curr_navigation_widget += 1;
        }
    }

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

    modifiers = 0x00;

    wheel_x = 0;
    wheel_y = 0;
}

ui_begin :: () {

    // if !initialized {
    //     ui_allocator.proc = flat_pool_allocator_proc;
    //     ui_allocator.data = *ui_pool;
    //     initialized       = true;
    // }


    now      := cast(float) seconds_since_init();
    dt        = now - prev_time;
    prev_time = now;


    sync_theme_sizes();

    wheel_scrolling_triggered = false;


    if font != null {
        prev_glyph_count = glyph_count;
        glyph_count      = font.glyph_table.count;
    }

    if io_frozen {
        hovered_layer = -1;

        for * key_state {
            it.* = UI_Key_Info.{};
        }
    }

    navigation_widget_index = 0;

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

    // Reset and set background layer.
    {
        array_reset(*background_layer.vertices);
        array_reset(*background_layer.draw_markers);
        array_reset(*background_layer.clip_stack);

        rect := UI_Rect.{ 0, 0, FLOAT32_MAX, FLOAT32_MAX };
        push_layer(BG_LAYER_ID, rect);
        set_layout(rect);
        push_clip(rect);
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

Window_Flags :: enum_flags {
    CLOSABLE;
    MOVEABLE;
    RESIZABLE;
    TITLE_BAR;

    ALL :: TITLE_BAR | CLOSABLE | MOVEABLE | RESIZABLE;
};


// Make moveable ok when clicking IN the window (not just the title bar).

// @todo: rename begin_window.
window_begin :: (state: *Window_State, default_rect: Rect, title := "", flags := Window_Flags.ALL, loc := #caller_location) -> bool {
    if !state.init {
        state.rect = default_rect;
        state.init = true;
    }

    id := make_id(loc, "window_widget");
    state.widget_id = id;


    if !state.open return false;


    is_new := push_layer(id, state.rect);
    // If window's layer was the topmost one of the last frame, we consider it as
    // "active".
    is_topmost  := ifx prev_layer_list peek(prev_layer_list).widget_id == id;

    mutate_state(state, state.rect, check_layout = false);
    // If we click somewhere on the layer, we want to raise it to the top of
    // the stack.
    want_raise := !is_new && !is_topmost && state.status & .PRESSED != 0 && active_widget == -1;
    if want_raise then raise_layer(id);

    window_title_bar_height := ifx flags & .TITLE_BAR then get_row_height() * 1.2 else 0;

    title_rect     := state.rect;
    title_rect.h    = window_title_bar_height;

    resizer_rect   := state.rect;
    resizer_rect.x += state.rect.w - content_padding * 4;
    resizer_rect.y += state.rect.h - content_padding * 4;
    resizer_rect.w  = (content_padding + theme.border_width) * 4;
    resizer_rect.h  = (content_padding + theme.border_width) * 4;

    dragging_allowed := active_widget == -1 && state.dragging == .NONE && is_down(.MOUSE_LEFT);

    // Start title bar dragging.
    if flags & .MOVEABLE && dragging_allowed && !is_occluded(title_rect) && cursor_vs_rect(title_rect) {
        // Prevent to mix clicking and dragging behavior.
        if (abs(delta_x) > 0 || abs(delta_y) > 0) {
            raise_layer(id);
            active_widget   = id;
            state.dragging  = .MOVE_WINDOW;
        }
    }


    // Start resizer dragging.
    if flags & .RESIZABLE && !is_occluded(resizer_rect) && cursor_vs_rect(resizer_rect) {
        curr_cursor_icon = .RESIZE_ARROW;

        // Prevent to mix clicking and dragging behavior.
        if dragging_allowed && (abs(delta_x) > 0 || abs(delta_y) > 0) {
            raise_layer(id);
            active_widget   = id;
            state.dragging  = .RESIZE_WINDOW;
        }
    }

    if state.dragging != .NONE && !is_down(.MOUSE_LEFT) {
        active_widget   = -1;
        state.dragging  = .NONE;
    }

    if state.dragging == .MOVE_WINDOW {
        state.rect.x += delta_x;
        state.rect.y += delta_y;
    }

    if state.dragging == .RESIZE_WINDOW {
        curr_cursor_icon = .RESIZE_ARROW;
        state.rect.w += delta_x;
        state.rect.h += delta_y;
    }

    // Once dragging is done, and we updated the window rect state, we make our
    // layer clip area.
    push_clip(state.rect);

    // Now, we recompute the title and resizer region, to get the latest
    // position/size.

    title_rect   = state.rect;
    title_rect.h = window_title_bar_height;

    draw_rect(state.rect, theme.color.bg, .ROUND_ALL);

    border_color    := theme.color.border;
    border_color.w   = 0.6;


    // Draw title bar.
    if flags & .TITLE_BAR {
        title_color := ifx is_topmost theme.color.fg else darken(theme.color.fg, 20);
        rect_flags  := Rect_Flags.TOP | .LEFT | .RIGHT | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT;

        draw_rect(title_rect, title_color, rect_flags);
        draw_outline(title_rect, border_color, theme.border_width, rect_flags);

        if title {
            title_width, title_height := get_text_size(font, title, theme.text_size);

            x := title_rect.x + title_rect.w * 0.5 - title_width * 0.5;
            y := title_rect.y + title_rect.h * 0.5 - title_height * 0.5;

            draw_text(title, x, y, theme.text_size, theme.color.text);
        }
    }


    if flags & .CLOSABLE && flags & .TITLE_BAR {
        btn_height := title_rect.h * 0.7;
        close_rect := Rect.{
            title_rect.x + content_padding,
            title_rect.y + title_rect.h * 0.5 - btn_height * 0.5,
            btn_height, btn_height
        };

        btn_id    := make_id(loc, "window_close_btn");
        btn_state := get_widget_state(Button_State, btn_id);

        mutate_state(btn_state, close_rect, check_layout = false);

        if btn_state.status & .PRESSED {
            state.open = false;
        }

        clear_bg := interact_color(btn_state, theme.color.fg);
        draw_rect(close_rect, clear_bg, .ROUND_ALL);

        cross_pad := max(theme.border_width, close_rect.h * 0.3);
        draw_cross(pad_rect(close_rect, cross_pad, cross_pad), lighten(clear_bg, 60), 2);

        draw_outline(close_rect, border_color, theme.border_width, .ROUND_ALL);
    }

    content_border := state.rect;
    content_border.y += window_title_bar_height;
    content_border.h -= window_title_bar_height;

    rect_flags := Rect_Flags.BOTTOM | .LEFT | .RIGHT | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
    if flags & .TITLE_BAR == 0 rect_flags = .ROUND_ALL;
    draw_outline(content_border, border_color, theme.border_width, rect_flags);

    layer_rect   := state.rect;
    layer_rect.x += content_padding;
    layer_rect.y += window_title_bar_height + content_padding;
    layer_rect.w -= content_padding * 2;
    layer_rect.h -= (window_title_bar_height + content_padding * 2);

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

    if curr_window_scroll then end_scroll(curr_window_scroll, loc);
    pop_layer();
}


begin_disable_all :: () {
    all_widget_disabled = true;
}

end_disable_all :: () {
    all_widget_disabled = false;
}

begin_expander :: (title : string, open_by_default := false, loc := #caller_location) -> bool {
    id          := make_id(loc);
    state, new  := get_widget_state(Expander_State, id);

    curr_expander = state;

    if new state.open = open_by_default;

    layout := current_layout();
    size := Vector2.{ layout.rect.w, get_row_height() };

    rect := alloc_space(size);
    mutate_state(state, rect);

    bg_color := interact_color(state, theme.color.fg);

    text_width, text_height   := get_text_size(font, title, theme.text_size);
    text_rect                 := pad_rect(rect, button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;


    if state.status & .PRESSED {
        state.open = !state.open;
    }




    {
        left_flags := Rect_Flags.TOP | .LEFT | .BOTTOM | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT;
        if state.open {
            left_flags &= ~(.BOTTOM | .ROUND_BOTTOM_LEFT);
        }

        caret_rect := rect;
        caret_rect.w  = rect.h;

        caret_bg := lighten(theme.color.border, 20);
        draw_rect(caret_rect, caret_bg, left_flags);

        border_color := theme.color.border;
        border_color.w = 0.4;

        draw_outline(caret_rect, border_color, theme.border_width, left_flags);

        caret_pad := max(theme.border_width, caret_rect.h * 0.3);
        draw_caret(pad_rect(caret_rect, caret_pad, caret_pad), theme.color.text, up = state.open, 2);
    }

    flags := Rect_Flags.ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT | .TOP | .BOTTOM | .RIGHT;
    if state.open then flags &= ~(.BOTTOM | .ROUND_BOTTOM_RIGHT);

    input_rect      := rect;
    input_rect.x    += rect.h;
    input_rect.w    -= rect.h;

    draw_rect(input_rect, bg_color, flags);
    draw_outline(input_rect, theme.color.border, theme.border_width, flags);
    draw_text(title, x, y, theme.text_size, theme.color.text);

    if state.open {
        bg_region  := rect;
        bg_region.y = rect.y + rect.h;
        bg_region.h = state.computed_height + (gap_y * 4);

        color   := theme.color.border;
        color.w  = 0.6;

        borders := Rect_Flags.LEFT | .RIGHT | .BOTTOM | .ROUND_BOTTOM_LEFT | .ROUND_BOTTOM_RIGHT;
        draw_rect(bg_region, lighten(theme.color.bg, 2), 0x0);
        draw_outline(bg_region, color, theme.border_width, borders);

        collapser_offset := get_em(1.);

        layout_rect := Rect.{
            rect.x + collapser_offset,
            rect.y + rect.h,
            rect.w - collapser_offset * 2,
            layout.rect.h - rect.y,
        };


        prev_layout      := set_layout(layout_rect);
        state.prev_layout = prev_layout;

        current_layout().cursor.y += (gap_y * 4);
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

        current_layer.layout.cursor.y += content_height + (gap_y * 4);
    }

    curr_expander = null;
}

tab_menu :: (tab_index : *int, tabs: []string) -> modified: bool {
    modified := false;

    layout := current_layout();

    tab_width := max(get_em(3), (layout.rect.w - gap_x * tabs.count) / tabs.count);

    for tabs {
        push_id(it_index);
        defer pop_id();

        if it_index > 0 same_line();

        if tab(it, it_index == tab_index.*, .{ tab_width, -1 }) {
            tab_index.* = it_index;
            modified = true;
        }
    }

    return modified;

}

dropdown_item :: (label: string, item_rect := Rect.{}, selected := false, loc := #caller_location) -> bool {
    id          := make_id(loc, label);
    using state := get_widget_state(Widget_State, id);

    text_width, text_height := get_text_size(font, label, theme.text_size);

    mutate_state(state, item_rect);

    clip := peek(current_layer.clip_stack);
    if !rect_vs_rect(rect, clip) return status & .PRESSED != 0;

    text_too_big := rect.w < text_width + button_padding;

    fg_color := ifx selected theme.color.accent else xyzw(theme.color.fg.xyz, 0.4);
    bg_color := interact_color(state, fg_color);

    btn_rect := rect;
    draw_rect(btn_rect, bg_color);

    text_rect := pad_rect(btn_rect, button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width  * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    offset := text_height * 0.15;
    x = interact_lerp(state, x, x + offset);
    y = interact_lerp(state, y, y + offset);

    if text_too_big push_clip(btn_rect);
    draw_text(label, x, y, theme.text_size, theme.color.text);
    if text_too_big pop_clip();

    if curr_navigation_widget == navigation_widget_index {
        draw_outline(btn_rect, theme.color.blue, theme.border_width);
    }

    return status & .PRESSED != 0;
}

flag_select :: (flag: *$T, size := Vector2.{ 100, -1 }, placeholder := "", max_items := 6, loc := #caller_location) -> modified: bool {
    ti := cast(*Type_Info_Enum) T;
    return flag_select(flag, ti, size, placeholder, max_items, loc);
}

flag_select :: (flag: *$T, ti: *Type_Info_Enum, size := Vector2.{ 100, -1 }, placeholder := "", max_items := 6, loc := #caller_location) -> modified: bool {
    id      := make_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    item_height := get_row_height() * 0.8;

    modified     := false;

    selected_count     := 0;
    selection_builder  : String_Builder;

    for enum_name: ti.names {
        if (flag.* & cast(T) ti.values[it_index]) {

            if selected_count > 0 {
                append(*selection_builder, ", ");
            }

            append(*selection_builder, slice(enum_name, 0, 4));
            selected_count += 1;
        }
    }

    placeholder_text := ifx placeholder then placeholder else "<Choose>";


    selected_names := builder_to_string(*selection_builder, do_reset = true);
    defer free(selected_names);

    btn_label := ifx selected_count > 0 sprint("(%) %", selected_count, selected_names) else sprint("Nothing selected");
    defer free(btn_label);

    button_label := ifx selected_count >= 0 btn_label else placeholder_text;

    input_size := size;
    if size.x <= 0 {
        input_size.x = get_text_size(font, placeholder_text, theme.text_size) + get_em(2) * 2;
    }

    rect := alloc_space(input_size);
    mutate_state(state, rect);

    if all_widget_disabled then state.status &= ~(.PRESSED | .DOWN);

    input_rect      := rect;
    input_rect.w    -= rect.h; // because of the right side (clear/caret).

    bg_color     := interact_color(state, theme.color.fg);
    border_color := interact_color(state, theme.color.border);
    text_color   := theme.color.text;

    font_size                 := theme.text_size;
    text_width, text_height   := get_text_size(font, button_label, xx font_size);
    text_rect                 := pad_rect(rect, button_padding, 0);


    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    if state.status & .PRESSED {
        state.open = !state.open;
    }

    if is_pressed(.ESCAPE) {
        state.open = false;
    }

    flags := Rect_Flags.TOP | .LEFT | .BOTTOM | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT;
    if state.open then flags &= ~(.BOTTOM | .ROUND_BOTTOM_LEFT);

    draw_rect(input_rect, bg_color, flags);
    draw_outline(input_rect, border_color, theme.border_width, flags);



    should_clip := text_width > input_rect.w;

    if selected_count <= 0 then text_color.w = 0.4;

    if should_clip push_clip(input_rect);
    draw_text(button_label, x, y, font_size, text_color);
    if should_clip pop_clip();

    {
        right_flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;
        if state.open {
            right_flags &= ~(.BOTTOM | .ROUND_BOTTOM_RIGHT);
        }

        caret_rect := rect;
        caret_rect.x += (rect.w - rect.h);
        caret_rect.w  = rect.h;

        caret_bg := lighten(theme.color.border, 20);
        draw_rect(caret_rect, caret_bg, right_flags);

        border_color := theme.color.border;
        border_color.w = 0.4;

        draw_outline(caret_rect, border_color, theme.border_width, right_flags);

        caret_pad := max(theme.border_width, caret_rect.h * 0.3);
        draw_caret(pad_rect(caret_rect, caret_pad, caret_pad), theme.color.text, up = state.open, 2);
    }



    if state.open {
        dropdown_height := cast(float, max_items) * (item_height + content_padding * 2);
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
        layer_rect.x += theme.border_width;
        layer_rect.w -= theme.border_width * 2;
        layer_rect.h -= theme.border_width;

        set_layout(layer_rect);

        layout := current_layout();

        scroll := begin_scroll(loc);

        items_region := alloc_space(.{ layout.rect.w, item_height * ti.names.count });

        item_rect  := items_region;
        item_rect.h = item_height;

        for ti.names {
            push_id(it_index);
            defer pop_id();

            enum_val := cast(T) ti.values[it_index];
            selected := flag.* & enum_val != 0;

            if dropdown_item(it, item_rect, selected = selected) {
                if selected then flag.* &= ~enum_val; else flag.* |= enum_val;
                modified    = true;
            }

            item_rect.y += item_height;
        }

        end_scroll(scroll, loc);

        draw_outline(dropdown_rect, theme.color.border, theme.border_width, dropdown_flags);

        // If click outside the dropdown, we close the dropdown.
        if is_pressed(.MOUSE_LEFT) && (state.status == 0x00) && !cursor_vs_rect(dropdown_rect) && active_widget == -1 {
            state.open = false;
        }

    }

    return modified;
}

Select_Flags :: enum_flags {
    CLEARABLE;
    FILTER;

    ALL  :: CLEARABLE | FILTER;
    NONE :: 0;
};

select :: (selected: *$T, items: [] string, size := Vector2.{ -1, -1 }, placeholder := "", max_items := 6, flags := Select_Flags.ALL, loc := #caller_location) -> bool
#modify {
    ti := cast(*Type_Info) T;
    return ti.type == .INTEGER || ti.type == .ENUM;
} {
    id      := make_id(loc);
    state   := get_widget_state(Dropdown_State, id);

    placeholder_text := ifx placeholder placeholder else "<Choose>";

    // If T is not signed, we remove the clearable flag because the "null"
    // value is signed, -1.
    ti := cast(*Type_Info_Integer) T;
    if !ti.signed flags &= ~.CLEARABLE;

    select_size := size;
    if size.x <= 0 {
        select_size.x = get_text_size(font, placeholder_text, theme.text_size) + get_em(2) * 2;
    }

    modified     := false;
    button_label := ifx selected.* >= 0 items[selected.*] else placeholder_text;

    select_label_color := theme.color.text;
    if selected.* < 0 then select_label_color.w = 0.4;

    item_height := get_row_height() * 0.8;

    rect := alloc_space(select_size);
    mutate_state(state, rect);

    if all_widget_disabled then state.status &= ~(.PRESSED | .DOWN);

    input_rect      := rect;
    input_rect.w    -= rect.h; // because of the right side (clear/caret).

    text_width, text_height   := get_text_size(font, button_label, theme.text_size);
    text_rect                 := pad_rect(rect, button_padding, 0);

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    if state.status & .PRESSED {
        state.open        = !state.open;
        state.want_search = state.open;
    }

    if is_pressed(.ESCAPE) {
        state.open        = false;
        state.want_search = false;
        state.search.count = 0;
    }


    rect_flags := Rect_Flags.TOP | .LEFT | .BOTTOM | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT;
    if state.open then rect_flags &= ~(.BOTTOM | .ROUND_BOTTOM_LEFT);

    bg_color     := interact_color(state, theme.color.fg);
    border_color := interact_color(state, theme.color.border);

    if state.want_search && flags & .FILTER {
        push_id("select_filter_input");
        defer pop_id();

        _, updated_str := text_input(state.search, rect = input_rect, flags = rect_flags, loc = loc);

        copied := copy_string(updated_str);
        if state.search free(state.search);
        state.search = copied;

        if !state.search {
            placeholder_color   := theme.color.text;
            placeholder_color.w  = 0.4;
            draw_text(button_label, x, y, theme.text_size, placeholder_color);
        }

    } else {
        should_clip := text_width > input_rect.w;

        draw_rect(input_rect, bg_color, rect_flags);
        draw_outline(input_rect, theme.color.border, theme.border_width, rect_flags);
        if should_clip push_clip(input_rect);
        draw_text(button_label, x, y, theme.text_size, select_label_color);
        if should_clip pop_clip();
    }




    right_flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;
    if state.open {
        right_flags &= ~(.BOTTOM | .ROUND_BOTTOM_RIGHT);
    }


    // The right side of our select input.
    {
        if flags & .CLEARABLE {
            clear_rect   := rect;
            clear_rect.x += input_rect.w;
            clear_rect.w  = rect.h;

            border_color := theme.color.border;
            border_color.w = 0.4;

            btn_id    := make_id(loc, "select_clear_btn");
            btn_state := get_widget_state(Button_State, btn_id);

            mutate_state(btn_state, clear_rect);

            if btn_state.status & .PRESSED {
                selected.*        = cast, no_check(T) -1;
                modified          = true;
                state.open        = false;
                state.want_search = false;
                state.search.count = 0;
            }

            clear_bg := interact_color(btn_state, theme.color.border);

            draw_rect(clear_rect, clear_bg, right_flags);

            cross_pad := max(theme.border_width, clear_rect.h * 0.3);
            draw_cross(pad_rect(clear_rect, cross_pad, cross_pad), theme.color.text, 2);

            draw_outline(clear_rect, border_color, theme.border_width, right_flags);
        } else {
            caret_rect := rect;
            caret_rect.x += (rect.w - rect.h);
            caret_rect.w  = rect.h;

            caret_bg := lighten(theme.color.border, 20);
            draw_rect(caret_rect, caret_bg, right_flags);

            border_color := theme.color.border;
            border_color.w = 0.4;

            draw_outline(caret_rect, border_color, theme.border_width, right_flags);

            caret_pad := max(theme.border_width, caret_rect.h * 0.3);
            draw_caret(pad_rect(caret_rect, caret_pad, caret_pad), theme.color.text, up = state.open, 2);
        }
    }

    if state.open {
        dropdown_height := (item_height + content_padding * 2) * (cast(float) max_items);
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
        layer_rect.x += theme.border_width;
        layer_rect.w -= theme.border_width * 2;
        layer_rect.h -= theme.border_width;

        set_layout(layer_rect);

        layout := current_layout();

        scroll := begin_scroll(loc);

        items_region := alloc_space(.{ layout.rect.w, item_height * items.count });

        item_rect  := items_region;
        item_rect.h = item_height;

        for items {

            if state.search && !contains_nocase(it, state.search) {
                continue;
            }

            push_id(it_index);
            defer pop_id();

            if dropdown_item(it, item_rect) {
                selected.*        = cast(T) it_index;
                modified          = true;
                state.open        = false;
                state.want_search = false;
                state.search.count = 0;
            }

            item_rect.y += item_height;
        }

        end_scroll(scroll);

        draw_outline(dropdown_rect, theme.color.border, theme.border_width, dropdown_flags);

        // If click outside the dropdown, we close the dropdown.
        if is_pressed(.MOUSE_LEFT) && (state.status == 0x00) && !cursor_vs_rect(dropdown_rect) && active_widget == -1 {
            state.open        = false;
            state.want_search = false;
            state.search.count = 0;
        }
    }

    return modified;
}

label :: (text: string, label_size := 0., loc := #caller_location) {
    text_size := ifx label_size <= 0 theme.text_size else label_size;
    text_width, text_height := get_text_size(font, text, xx text_size);

    rect   := alloc_space(xy(text_width, text_height));
    y      := rect.y;
    y      += get_row_height() * 0.5 - text_height * 0.5;

    if text_width > rect.w {
        text_index  := cursor_to_text_index(font, text, text_size, rect.w);

        str_copied := copy_string(text);
        defer free(str_copied);

        str_copied = slice(str_copied, 0, str_copied.count - text_index);

        // Put ellipsis at the end of the string.
        for < * str_copied {
            index := str_copied.count - 1 - it_index;
            if index < 3 it.* = #char ".";
        }

        draw_text(str_copied, rect.x, y, text_size, theme.color.text);
    } else {
        draw_text(text, rect.x, y, text_size, theme.color.text);
    }

}

separator :: (text := "") {
    layout := current_layout();

    if text {
        text_size := theme.text_size * 0.7;
        text_width, text_height := get_text_size(font, text, xx text_size);

        rect := alloc_space(.{ layout.rect.w, text_height  });

        // draw_rect(rect, theme.color.fg);

        x := rect.x;

        line_height := min(text_size * 0.5, theme.separator_size);

        first_line := Rect.{
            x,
            rect.y + (rect.h * 0.5) - (line_height * 0.5),
            rect.w * 0.05,
            line_height,
        };

        x += first_line.w + gap_x;

        draw_rect(first_line, theme.color.text_muted);
        draw_text(text, x, rect.y + rect.h * 0.5 - text_height * 0.5, xx text_size, theme.color.text);

        x += text_width + gap_x;

        second_line := Rect.{
            x, first_line.y,
            (rect.x + rect.w) - x, // leftover.
            line_height
        };

        draw_rect(second_line, theme.color.text_muted);
    } else {
        rect     := alloc_space(.{ layout.rect.w, get_row_height() });
        sep_rect := Rect.{ rect.x + content_padding, rect.y + rect.h * 0.5 - theme.separator_size * 0.5, rect.w - content_padding * 2, theme.separator_size };
        draw_rect(sep_rect, theme.color.text_muted);
    }
}

// perhaps we need two verrsion of the function, one when user send utf-8, and another when it's u32 codepoint.
send_text_codepoint :: (codepoint: string) {
    if !codepoint return;

    if text_codepoint then free(text_codepoint);
    text_codepoint = copy_string(codepoint);
}

hexa_input :: (color: *Vector4, loc := #caller_location) -> modified: bool {
    modified     := false;

    height       := get_row_height();
    prefix_width := height;
    input_width  := get_text_size(font, "#FFFFFFFF", theme.text_size);
    result_width := height;

    widget_width := Vector2.{ prefix_width + input_width + gap_x + result_width, height };
    widget_rect  := alloc_space(widget_width);

    input_width = (widget_rect.w - result_width - (prefix_width + gap_x));

    x := widget_rect.x;
    y := widget_rect.y;

    {
        rect := Rect.{ x, y, prefix_width, height };
        x    += rect.w;

        draw_rect(rect, theme.color.blue, .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        border_color := theme.color.border;
        border_color.w = 0.4;

        draw_outline(rect, border_color, theme.border_width, .TOP | .BOTTOM | .LEFT | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        text_width, text_height := get_text_size(font, "#", theme.text_size);
        draw_text("#", rect.x + rect.w * 0.5 - text_width * 0.5, rect.y + rect.h * 0.5 - text_height * 0.5, theme.text_size, lighten(color, 90));
    }


    {
        rect := Rect.{ x, y, input_width, height };
        x    += rect.w + gap_x;


        hexa := color_to_hexa(color.*);

        hexa_str := sprint("%", formatInt(hexa, base = 16, minimum_digits = 6));
        defer free(hexa_str);

        flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;
        modified=, new_str := text_input(hexa_str, rect = rect, loc = loc, flags = flags, validate = hexa_validation);

        if modified && new_str.count >= 1 {
            result, success := string_to_int(new_str, 16, u32);
            if success then color.* = hexa_to_color(result);
        }
    }


    rect := Rect.{ x, y, result_width, height };
    draw_rect(rect, color.*, .ROUND_ALL);
    draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);

    return modified;
}

vec_input :: (value : *$T/.[Vector2, Vector3, Vector4, Quaternion], loc := #caller_location) -> modified: bool {
    height            := get_row_height();

    min_input_width   := get_text_size(font, "9999", theme.text_size);
    input_width       := min_input_width;
    prefix_width      := height * 0.6;

    widget_size := Vector2.{ (prefix_width + input_width + gap_x) * value.component.count, height };
    widget_rect := alloc_space(widget_size);

    // Takes available space.
    input_width = (widget_rect.w - (prefix_width + gap_x) * value.component.count) / value.component.count;
    input_width = max(min_input_width, input_width);

    // internal_draw_rect(widget_rect, Vector4.{1, 1, 1, 0.6});

    x := widget_rect.x;
    y := widget_rect.y;

    modified := false;

    for * value.component {
        push_id(it_index);
        defer pop_id();

        rect := Rect.{ x, y, prefix_width, height };
        x    += rect.w;

        mask := (Rect_Flags.ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        color   : Vector4;
        text    : string;

        if it_index == {
            case 0;
                color = theme.color.red;
                text  = "X";
            case 1;
                color = theme.color.green;
                text  = "Y";
            case 2;
                color = theme.color.blue;
                text  = "Z";
            case 3;
                color = theme.color.blue;
                text  = "W";
        }

        draw_rect(rect, color, mask);

        c := theme.color.border;
        c.w = 0.4;
        draw_outline(rect, c, theme.border_width, .TOP | .BOTTOM | .LEFT | .ROUND_TOP_LEFT | .ROUND_BOTTOM_LEFT);

        text_size := theme.text_size * 0.6;
        text_width, text_height := get_text_size(font, text, text_size);

        draw_text(text, rect.x + rect.w * 0.5 - text_width * 0.5, rect.y + rect.h * 0.5 - text_height * 0.5, text_size, lighten(color, 90));

        flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;

        input_rect := Rect.{ x, y, input_width, height };
        x += input_rect.w + gap_x;

        if number_input(it, rect = input_rect, flags = flags, loc) {
            modified = true;
        }
    }

    return modified;
}

// @todo: not great "u8" to define the color format...
Color_Format :: enum {
    FLOAT;
    U8;
};

rgba_input :: (value : *$T/.[Vector3, Vector4], format := Color_Format.FLOAT, loc := #caller_location) -> modified: bool {
    height            := get_row_height();

    min_input_width   := get_text_size(font, "9999", theme.text_size);
    input_width       := min_input_width;
    prefix_width      := height * 0.6;
    result_rect_width := height;

    widget_size := Vector2.{ (prefix_width + input_width + gap_x) * value.component.count + result_rect_width, height };
    widget_rect := alloc_space(widget_size);

    // Takes available space.
    input_width = (widget_rect.w - result_rect_width - (prefix_width + gap_x) * value.component.count) / value.component.count;
    input_width = max(input_width, min_input_width);

    // internal_draw_rect(widget_rect, Vector4.{1, 1, 1, 0.6});

    x := widget_rect.x;
    y := widget_rect.y;

    modified := false;

    for * value.component {
        push_id(it_index);
        defer pop_id();

        rect := Rect.{ x, y, prefix_width, height };
        x    += rect.w;

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

        text_size := theme.text_size * 0.6;
        text_width, text_height := get_text_size(font, text, text_size);

        draw_text(text, rect.x + rect.w * 0.5 - text_width * 0.5, rect.y + rect.h * 0.5 - text_height * 0.5, text_size, lighten(color, 90));

        flags := Rect_Flags.TOP | .RIGHT | .BOTTOM | .ROUND_TOP_RIGHT | .ROUND_BOTTOM_RIGHT;

        input_rect := Rect.{ x, y, input_width, height };
        x += input_rect.w + gap_x;

        if format == {
            case .FLOAT;
                val := clamp(it.*, 0, 1);
                if number_input(*val, rect = input_rect, flags = flags, loc) {
                    it.* = val;
                    modified = true;
                }

            case .U8;
                val := ifx it_index < 3 then clamp(it.* * 255, 0, 255) else clamp(it.*, 0, 1);

                if number_input(*val, rect = input_rect, flags = flags, loc) {
                    if it_index < 3 {
                        it.* = val / 255;
                    } else {
                        it.* = val;
                    }

                    modified = true;
                }
        }

    }

    rect := Rect.{ x, y, height, height };
    draw_rect(rect, value.*, .ROUND_ALL);
    draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);

    return modified;
}

// @todo: Ability to use all integers... and then we clamp to their min/max.
number_input :: (value: *$T, size := Vector2.{ -1, -1 }, rect := Rect.{}, flags := (Rect_Flags.ROUND_ALL | .HALF_RADIUS), loc := #caller_location) -> modified: bool
#modify {
    if T != float && T != int {
        return false, "Unsuported argument type, should be float or int.";
    }

    return true;
}
{
    str_value := sprint("%", value.*);
    defer free(str_value);

    modified, updated_str := text_input(str_value, size, rect = rect, flags, number_validation, loc);

    if !modified return false;

    #if T == float {
        result, success        := parse_float(*updated_str);
        if success then value.* = result;
    }

    #if T == int {
        result, success   := parse_int(*updated_str, int);
        if success value.* = result;
    }

    return true;
}

default_validation :: (codepoint : string) -> bool {
    return true;
}

hexa_validation :: (codepoint : string) -> bool {
    valid := true;
    for char: codepoint {

        if !is_digit(char) && !(char >= #char "a" && char <= #char "f") && !(char >= #char "A" && char <= #char "F") {
            valid = false;
            break;
        }
    }

    return valid;
}

number_validation :: (codepoint : string) -> bool {
    valid := true;
    for char: codepoint {
        if !is_digit(char) && char != #char "." {
            valid = false;
            break;
        }
    }

    return valid;
}

Validation_Proc :: #type (codepoint: string) -> bool;

text_input :: (user_str: string, size := Vector2.{ -1, -1 }, rect := Rect.{}, flags := (Rect_Flags.ROUND_ALL | .HALF_RADIUS),
               validate := default_validation, loc := #caller_location) -> modified: bool, edited_str: string, editing: bool {

    id    := make_id(loc, "text_input");
    state := get_widget_state(Text_Input_State, id);

    input_rect := rect;

    if rect.w <= 0 || rect.h <= 0 {
        input_rect = alloc_space(size);
    }

    mutate_state(state, input_rect);




    using, only(text, status) state;


    // When user is not editing, we simply copy the passing string. It's this
    // copy that will be modify.
    if !state.editing {
        if user_str != state.text then state.cursor_start = user_str.count;

        str_copied := copy_string(user_str);

        if state.text then free(state.text);
        state.text = str_copied;
    }


    // We start the edit process if user click on the input.
    if !state.editing && (status & .PRESSED) {
        state.editing = true;
        state.texting_start_time = cast(float, seconds_since_init());
    }

    if state.status & .HOVERED && !(state.status & .DISABLED) {
        set_cursor_icon(.TEXT_EDIT);
    }

    modified := false;

    if state.editing {
        click_outside := !cursor_vs_rect(state.rect) && is_pressed(.MOUSE_LEFT);

        if is_pressed(.RETURN) {
            state.editing = false;
            modified      = state.text != user_str;
        }

        #if OS == .MACOS {
            want_clipboard_past := modifiers & .OS && is_pressed(.KEY_V);
        } else {
            want_clipboard_past := modifiers & .CTRL && is_pressed(.KEY_V);
        }

        if want_clipboard_past {
            clipboard_str := os_clipboard_get_text();
            defer free(clipboard_str);

            if validate(clipboard_str) {
                begin := slice(state.text, 0, state.cursor_start);
                end   := slice(state.text, state.cursor_start, state.text.count);

                new_value := join(begin, clipboard_str, end);
                state.cursor_start += clipboard_str.count;

                if state.text {
                    free(state.text);
                }

                state.text = new_value;
            }

        }

        if is_pressed(.ESCAPE) || click_outside {
            state.editing    = false;
            modified         = state.text != user_str;
        }

        if is_pressed(.BACKSPACE, repeat = true) {
            substr     := slice(state.text, 0, state.cursor_start);
            lead_index := find_lead_from_left(substr);
            char_size  := state.cursor_start - lead_index;

            for state.cursor_start..state.text.count - 1 {
                state.text[it - char_size] = state.text[it];
            }

            if state.cursor_start > 0 then state.cursor_start -= char_size;
            if state.text.count   > 0 then state.text.count   -= char_size;
        }

        if is_pressed(.RIGHT, repeat = true) && state.cursor_start < state.text.count {
            char := state.text[state.cursor_start];
            state.cursor_start += utf8_char_size(char);
        }

        if is_pressed(.LEFT, repeat = true) && state.cursor_start > 0 {
            substr     := slice(state.text, 0, state.cursor_start);
            lead_index := find_lead_from_left(substr);
            char_size  := state.cursor_start - lead_index;

            state.cursor_start -= char_size;
        }

        if text_codepoint && validate(text_codepoint) {
            begin := slice(state.text, 0, state.cursor_start);
            end   := slice(state.text, state.cursor_start, state.text.count);

            new_value := join(begin, text_codepoint, end);
            state.cursor_start += text_codepoint.count;

            if state.text {
                free(state.text);
            }

            state.text = new_value;
        }
    }

    bg_color      := interact_color(state, theme.color.fg);
    outline_color := interact_color(state, theme.color.border);
    text_color    := theme.color.text;

    draw_rect(input_rect, bg_color, flags);
    draw_outline(input_rect, outline_color, theme.border_width, flags);

    text_width, text_height := get_text_size(font, state.text, theme.text_size);

    text_x := input_rect.x + input_padding + theme.border_width;
    text_y := input_rect.y + input_rect.h * 0.5 - text_height * 0.5;

    should_clip  := text_x + text_width > input_rect.w - theme.border_width;

    clip_rect := input_rect;
    if flags & .LEFT        clip_rect.x += theme.border_width;
    if flags & .TOP         clip_rect.y += theme.border_width;
    if flags & .RIGHT       clip_rect.w -= theme.border_width;
    if flags & .BOTTOM      clip_rect.h -= theme.border_width;

    if should_clip       then push_clip(clip_rect);
    defer if should_clip then pop_clip();

    if state.editing {
        cursor_text := state.text;

        if state.cursor_start < state.text.count {
            cursor_text = slice(state.text, 0, state.cursor_start);
        }

        cursor_height    := get_em(0.95);
        to_cursor_width  := get_text_size(font, cursor_text, theme.text_size);

        input_width := input_rect.w - (theme.border_width * 2);
        cursor_size := get_em(0.08);

        offset := (to_cursor_width + cursor_size + input_padding) - input_width;
        if offset >= 0 then text_x -= offset;

        cursor_rect := Rect.{
            text_x + to_cursor_width, input_rect.y + input_rect.h * 0.5 - cursor_height * 0.5,
            cursor_size, cursor_height
        };

        now             := cast(float) seconds_since_init();
        elapsed         := state.texting_start_time - now;
        blink_speed     := 8.0;
        alpha           := cast(float) (sin(elapsed * blink_speed) + 1.0) * 0.5;

        cursor_color  := lighten(text_color, 20);
        cursor_color.w = alpha;

        draw_text(text, text_x, text_y, theme.text_size, text_color);
        draw_rect(cursor_rect, cursor_color);
    } else {
        draw_text(text, text_x, text_y, theme.text_size, text_color);
    }

    return modified, text, state.editing;
}

radio_buttons :: (items: [] string, index: *int, loc := #caller_location) -> bool {
    modified := false;

    for items {
        push_id(it_index);
        defer pop_id();

        checked := it_index == index.*;

        if checkbox(*checked, text_label = it) {
            modified = true;
        }

        if checked {
            index.* = it_index;
        }
    }

    return modified;
}

checkbox :: (checked: *bool, text_label := "", loc := #caller_location) -> modified: bool {
    id      := make_id(loc, text_label);
    state   := get_widget_state(Checkbox_State, id);

    checkbox_size := get_row_height();

    text_width, text_height : float;

    // Content size is the full space allocation of the checkbox + following
    // label.
    content_size := xy(checkbox_size);

    if text_label {
        text_width, text_height = get_text_size(font, text_label, theme.text_size);

        content_size.x += text_width + content_padding;
        content_size.y  = max(checkbox_size, text_height);
    }


    layout := current_layout();

    rect := alloc_space(content_size, strict = false);
    mutate_state(state, rect);

    modified := false;

    if state.status & .PRESSED {
        modified  = true;
        checked.* = !checked.*;
    }

    CHECKED_TIME  :: 0.2;

    if checked.* {
        state.checked_duration += dt * 2;
        state.checked_duration = min(state.checked_duration, CHECKED_TIME);
    } else {
        state.checked_duration -= dt * 2;
        state.checked_duration = max(state.checked_duration, 0);
    }

    base_color := ifx checked.* then theme.color.accent else theme.color.text_muted;

    inner_color := interact_color(state, base_color);
    bg_color    := interact_color(state, theme.color.bg);

    row_height := max(layout.row_max_height, rect.h);

    radius  := checkbox_size * 0.5;
    pos     := xy(rect.x + radius, rect.y + row_height * 0.5);

    draw_circle(pos, radius, bg_color);
    draw_circle_outline(pos, radius, theme.border_width, inner_color);

    {
        inner_circle   := radius * 0.5;
        current_radius := lerp(0, inner_circle, state.checked_duration / CHECKED_TIME);
        draw_circle(pos, current_radius, inner_color);
    }

    if text_label {
        pos.x += checkbox_size - radius + content_padding;
        pos.y  = rect.y + row_height * 0.5 - text_height * 0.5;

        // @note: If the layout currently has columns, we set want to computed
        //        the leftover against the cell width. If not, we currently do it
        //        against the layout rect width, but in some cases it's not correct
        //        like, if same_line or set_width is set just after this widget.
        leftover := ifx layout.columns > 0 then (rect.x + rect.w - pos.x) else layout.rect.x + layout.rect.w - pos.x;

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

    return modified;
}

tab :: (label: string, active: bool, size := Vector2.{ -1, -1 }, loc := #caller_location) -> bool {
    id          := make_id(loc, label);
    using state := get_widget_state(Button_State, id);

    text_width, text_height   := get_text_size(font, label, theme.text_size);

    button_size := size;

    if size.x <= 0 {
        button_size.x = text_width + button_padding;
    }

    mutate_state(state, alloc_space(button_size));

    clip := peek(current_layer.clip_stack);
    if !rect_vs_rect(state.rect, clip) return status & .PRESSED != 0;

    text_too_big := rect.w < text_width;

    is_activated := status & .FOCUSED || status & .PRESSED || active;

    color        := theme.color.fg;

    bg_color     := interact_color(state, theme.color.fg);
    border_color := interact_color(state, theme.color.border);

    draw_rect(rect, bg_color, .TOP | .LEFT | .RIGHT | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT);

    if active {
        draw_outline(rect, theme.color.accent, theme.border_width, .LEFT | .RIGHT | .TOP | .ROUND_TOP_LEFT | .ROUND_TOP_RIGHT);
    }
    text_rect := pad_rect(rect, button_padding, 0);

    label_color := ifx is_activated then theme.color.accent else theme.color.text;

    // Center text in button rect.
    x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
    y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

    offset := text_height * 0.15;

    x = interact_lerp(state, x, x + offset);
    y = interact_lerp(state, y, y + offset);

    if text_too_big push_clip(rect);
    draw_text(label, x, y, theme.text_size, label_color);
    if text_too_big pop_clip();

    return status & .PRESSED != 0;
}

image :: (texture: *Texture_Type, size := Vector2.{ -1, -1 }, rect_flags:= Rect_Flags.ROUND_ALL) {
    rect := alloc_space(size);

    prev := set_texture(texture);
    defer set_texture(prev);

    draw_img(rect, rect_flags);
}

field :: (text_label : string, width := 0.5) {
    set_width(width);
    label(text_label);
    same_line();
    full_width();
}

button :: (label := "", size := Vector2.{ -1, -1 }, texture : *Texture_Type = null, toggle_value : *bool = null, disabled := false, loc := #caller_location) -> bool {
    text_width, text_height   := get_text_size(font, label, theme.text_size);

    button_size := size;
    if size.x <= 0 then button_size.x = text_width + button_padding;

    btn_rect := alloc_space(button_size);

    return button(label, btn_rect, texture, toggle_value, disabled, loc);
}

button :: (label := "", rect : UI_Rect, texture : *Texture_Type = null, toggle_value : *bool = null, disabled := false, loc := #caller_location) -> bool {
    defer navigation_widget_index += 1;

    id          := make_id(loc, label);
    state := get_widget_state(Button_State, id);

    using, except(rect) state;

    mutate_state(state, rect, disabled = disabled);

    if toggle_value != null && status & .PRESSED {
        toggle_value.* = !toggle_value.*;
    }

    clip := peek(current_layer.clip_stack);
    if !rect_vs_rect(rect, clip) return status & .PRESSED != 0;

    is_activated := status == .FOCUSED || status == .PRESSED;

    color := theme.color;

    fg_color := ifx toggle_value != null && toggle_value.* color.accent else color.fg;
    bg_color := interact_color(state, fg_color);

    if texture {
        draw_rect(rect, bg_color, .ROUND_ALL);

        prev := set_texture(texture);
        draw_img(rect, .ROUND_ALL);
        set_texture(prev);
    } else {
        draw_rect(rect, bg_color, .ROUND_ALL);
    }

    if toggle_value != null  {
        if toggle_value.* {
            draw_outline(rect, darken(theme.color.accent, 20), theme.border_width, .ROUND_ALL);
        } else {
            draw_outline(rect, theme.color.border, theme.border_width, .ROUND_ALL);
        }
    }

    if label {
        text_width, text_height   := get_text_size(font, label, theme.text_size);
        text_rect                 := pad_rect(rect, button_padding, 0);

        // Center text in button rect.
        x := text_rect.x + text_rect.w * 0.5 - text_width * 0.5;
        y := text_rect.y + text_rect.h * 0.5 - text_height * 0.5;

        offset := text_height * 0.15;

        x = interact_lerp(state, x, x + offset);
        y = interact_lerp(state, y, y + offset);

        text_too_big := rect.w < text_width;
        if text_too_big push_clip(rect);
        draw_text(label, x, y, theme.text_size, color.text);
        if text_too_big pop_clip();
    }

    if curr_navigation_widget == navigation_widget_index {
        draw_outline(rect, theme.color.blue, theme.border_width, .ROUND_ALL);
    }

    return status & .PRESSED != 0;
}


full_width :: () {
    layout := current_layout();
    layout.should_fullwidth = true;
}

set_width :: (number := 0.5) {
    layout := current_layout();

    if number <= 1.0 {
        layout.should_force_width = layout.rect.w * number;
    } else {
        layout.should_force_width = number;
    }

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

set_cursor_icon :: (icon: Cursor_Icon) {
    curr_cursor_icon = icon;
}

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

// @todo: rename this proc.
update_interaction_time :: (state: *Widget_State) {
    if state.status & .HOVERED {
        state.hover_duration += dt * 2;
        state.hover_duration = min(state.hover_duration, HOVER_TIME);
    } else {
        state.hover_duration -= dt;
        state.hover_duration = max(state.hover_duration, 0);
    }

    if (state.status & (.DOWN | .FOCUSED)) {
        state.press_duration += dt * 2;
        state.press_duration = min(state.press_duration, PRESS_TIME);
    } else {
        state.press_duration -= dt * 4;
        state.press_duration = max(state.press_duration, 0);
    }
}

mutate_state :: (state: *Widget_State, rect: Rect, check_layout := true, disabled := false) {
    // Always update rect value.
    state.rect = rect;

    if active_widget > -1 && state.widget_id != active_widget {
        state.status &= ~(.FOCUSED | .HOVERED | .DOWN);
        return;
    }

    state.status = get_status(rect, check_layout);

    if state.widget_id == active_widget {
        state.status |= .FOCUSED;
    }

    if all_widget_disabled || disabled {
        state.status &= ~(.FOCUSED | .DOWN | .PRESSED);
        state.status |= .DISABLED;
    }

    update_interaction_time(state);
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

    layout := current_layout();

    layout.scroll = state.scroll;

    if state.has_scrollbar_y {
        layout.rect.w -= scrollbar_width;
    }

    if state.has_scrollbar_x {
        layout.rect.h -= scrollbar_width;
    }

    return state;
}

end_scroll :: (state: *Scrollbar_State, loc := #caller_location) {
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

        if !wheel_scrolling_triggered && point_vs_rect(mouse_x, mouse_y, layout.rect) && max_scroll > 0 {
            wheel_scrolling_triggered = true;

            scroll.y += xx wheel_y;
            scroll.y = clamp(scroll.y, 0.0, max_scroll);
        }

        state.has_scrollbar_y = max_scroll > 0;

        if max_scroll > 0 {
            track_h  := layout.rect.h;

            ratio    := clamp(visible_h / content_h, 0.0, 1.0);
            handle_h := max(scrollbar_width * 2, track_h * ratio);
            travel   := track_h - handle_h;
            scroll_t := ifx max_scroll > 0 scroll.y / max_scroll else 0.0;

            handle := Rect.{
                layout.rect.x + layout.rect.w + content_padding * 0.5,
                layout.rect.y + scroll_t * travel,
                scrollbar_width,
                handle_h,
            };

            handle_id    := make_id(loc, "vertical_scrollbar");
            handle_state := get_widget_state(Widget_State, handle_id);
            mutate_state(handle_state, handle, check_layout = false);

            handle_state.status &= ~.DISABLED;

            hit      := cursor_vs_rect(handle) && is_down(.MOUSE_LEFT);
            bg_color := interact_color(handle_state, ifx (hit || state.dragging_y) theme.color.accent else theme.color.text_muted);


            if !state.dragging_x {
                is_dragging := active_widget == id;

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

            draw_rect(handle, bg_color, (.ROUND_ALL | .HALF_RADIUS));
        }

    }

    {
        // We compute the actual content size from the previous frame.
        content_w   := layout.content_width;
        visible_w   := layout.rect.w;

        max_scroll  := max(0.0, content_w - visible_w);
        scroll.x     = clamp(scroll.x, 0.0, max_scroll);

        state.has_scrollbar_x = max_scroll > 6;

        if max_scroll > 6 {
            track_w  := layout.rect.w;

            ratio    := clamp(visible_w / content_w, 0.0, 1.0);
            handle_w := max(scrollbar_width * 2, track_w * ratio);
            travel   := track_w - handle_w;
            scroll_t := ifx max_scroll > 0 scroll.x / max_scroll else 0;

            handle := Rect.{
                layout.rect.x + scroll_t * travel,
                layout.rect.y + layout.rect.h + content_padding * 0.5,
                handle_w,
                scrollbar_width,
            };


            handle_id    := make_id(loc, "horizontal_scrollbar");
            handle_state := get_widget_state(Widget_State, handle_id);
            mutate_state(handle_state, handle, check_layout = false);

            handle_state.status &= ~.DISABLED;

            hit      := cursor_vs_rect(handle) && is_down(.MOUSE_LEFT);
            bg_color := interact_color(handle_state, ifx (hit || state.dragging_x) theme.color.accent else theme.color.text_muted);

            if !state.dragging_y {
                is_dragging := active_widget == id;

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

            draw_rect(handle, bg_color, (.ROUND_ALL | .HALF_RADIUS));

        }

    }

}

is_occluded :: inline (rect: Rect) -> bool {
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

    for ctx_id: context_ids {
        h = sdbm_hash(*ctx_id, size_of(type_of(UI_ID)), h);
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
    current_layer.layout  = .{ rect = layout_rect };

    return prev_layout;
}

restore_layout :: (layout: UI_Layout) {
    current_layer.layout = layout;
}

get_vertices :: () -> *[..] UI_Vertex {
    if current_layer == null {
        return *background_layer.vertices;
    }

    return *current_layer.vertices;
}

set_texture :: (texture: *Texture_Type) -> prev: *Texture_Type {
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

// @todo: change the name.
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
    // log("Want to raise window : % :: %", id, current_layer.depth);
}

alloc_space :: (widget_size: Vector2, strict := true) -> Rect {
    using layout := current_layout();

    min_size    := widget_size;
    min_size.x   = ifx min_size.x <= 0 get_em(2) * 2 else min_size.x;
    min_size.y   = max(get_row_height(), min_size.y);

    size := min_size;

    is_first     := prev_widget_size.x <= 0 && prev_widget_size.y <= 0;
    was_inline   := layout.should_inline;

    // Use the biggest widget height as row height.
    row_height   := max(row_max_height, get_row_height());

    if !is_first {
        if layout.columns > 0 {
            layout_width := layout.rect.w;

            col_width := layout.rect.w / max(1, columns);
            size.x     = col_width - gap_x;

            if curr_column == 0 {
                cursor.x     = 0;
                cursor.y    += row_height + gap_y;
                curr_column += 1;
            } else {
                cursor.x    += ifx curr_column > 0 col_width else 0;
                curr_column += 1;
            }

            if curr_column >= columns {
                curr_column = 0;
            }

        } else if layout.should_inline {
            cursor.x += prev_widget_size.x + gap_x;
            layout.should_inline = false;
        } else {
            cursor.x  = 0;
            cursor.y += row_height + gap_y;
            layout.should_inline = false;
        }

    } else {

        if layout.columns > 0 {
            col_width := (layout.rect.w) / max(1, columns);
            size.x     = col_width - gap_x;
            curr_column += 1;
        }
    }

    base_x := layout.rect.x - layout.scroll.x;
    base_y := layout.rect.y - layout.scroll.y;

    if should_fullwidth {
        leftover := (layout.rect.x + layout.rect.w) - (layout.rect.x + cursor.x);

        if leftover > 0 {
            size.x = leftover;
        }

        should_fullwidth = false;
    }

    if should_force_width > 0 {
        size.x             = should_force_width;
        should_force_width = 0;
    }

    r := Rect.{ base_x + cursor.x, base_y + cursor.y, size.x, size.y };

    r.x = round_pixel(r.x);
    r.y = round_pixel(r.y);
    r.w = round_pixel(r.w);
    r.h = round_pixel(r.h);

    start_new_row := is_first || (!was_inline && curr_column <= 1);

    if start_new_row {
        layout.row_max_height = size.y;
    } else {
        layout.row_max_height = max(layout.row_max_height, size.y);
    }

    prev_widget_size = Vector2.{ size.x, size.y };

    if !strict {
        min_size = size;
    }

    layout.content_width  = max(layout.content_width, cursor.x + min_size.x);
    layout.content_height = max(layout.content_height, cursor.y + min_size.y);

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

get_row_height :: () -> float {
    layout := current_layout();
    return theme.text_size * 1.4;
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

hexa_to_color :: (hex: u32) -> Vector4 {
    r := (cast(float) (hex >> 16) & 0xFF)  / 255.0;
    g := (cast(float) (hex >> 8)  & 0xFF)  / 255.0;
    b := (cast(float) (hex >> 0)  & 0xFF)  / 255.0;

    return xyzw(r, g, b, 1.0);
}

color_to_hexa :: (vec: Vector4) -> u32 {
    r := cast(u8) (clamp(vec.x, 0, 1.) * 255);
    g := cast(u8) (clamp(vec.y, 0, 1.) * 255);
    b := cast(u8) (clamp(vec.z, 0, 1.) * 255);

    hex : u32;
    hex |= cast(u32, r) << 16;
    hex |= cast(u32, g) << 8;
    hex |= cast(u32, b) << 0;

    return hex;
}

get_em :: (ratio: float) -> em: float {
    return theme.text_size * ratio;
}

disable :: (color: Vector4, amount : float) -> Vector4 {
    c    := color;
    grey := xyzw(0.5, 0.5, 0.5, 1.0);

    c.x = c.x + (grey.x - c.x) * amount;
    c.y = c.y + (grey.y - c.y) * amount;
    c.z = c.z + (grey.z - c.z) * amount;
    c.w = 0.6;

    return c;
}

// @todo: rename this.
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

utf8_char_size :: (lead: u8) -> int {
    assert((lead & 0xC0) != 0x80, "Given char is not a lead unicode character.");
    return 1 + trailingBytesForUTF8[lead];
}

// @todo: rename
find_lead_from_left :: (str: string) -> int {
    lead_index := str.count - 1;

    while lead_index > 0 && (str[lead_index] & 0xC0) == 0x80 {
        lead_index -= 1;
    }

    return lead_index;
}

find_lead_from_right :: (str: string) -> int {
    lead_index := 0;

    while lead_index > 0 && (str[lead_index] & 0xC0) == 0x80 {
        lead_index += 1;
    }

    return lead_index;
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

    HALF_RADIUS        :: (1 << 8);

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
    radius := ifx flags & .HALF_RADIUS theme.corner_radius * 0.5 else theme.corner_radius;
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

draw_img :: (r: Rect, flags : Rect_Flags = .ALL_SIDES) {
    if flags == .ALL_SIDES {
        internal_draw_rect(r, WHITE, get_uv(r, r));
        return;
    }

    // For rounded corners:
    radius := ifx flags & .HALF_RADIUS theme.corner_radius * 0.5 else theme.corner_radius;
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

            push_triangle(p0, p1, p2, WHITE, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_left, WHITE, get_uv(r, top_left));
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

            push_triangle(p0, p1, p2, WHITE, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_right, WHITE, get_uv(r, top_right));
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

            push_triangle(p0, p1, p2, WHITE, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_left, WHITE, get_uv(r, bottom_left));
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

            push_triangle(p0, p1, p2, WHITE, uv0, uv1, uv2);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_right, WHITE, get_uv(r, bottom_right));
    }

    // To fill up the rest of the belly of the rounded corner, we can do that
    // with only 3 rects.

    center_middle := Rect.{ r.x + radius, r.y, r.w - (2 * radius), r.h };
    internal_draw_rect(center_middle, WHITE, get_uv(r, center_middle));

    right_middle := Rect.{ r.x, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(right_middle, WHITE, get_uv(r, right_middle));

    left_middle := Rect.{ r.x + r.w - radius, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(left_middle, WHITE, get_uv(r, left_middle));
}

draw_rect :: (r: Rect, color: Vector4, flags : Rect_Flags = .ALL_SIDES) {
    if flags == .ALL_SIDES {
        internal_draw_rect(r, color);
        return;
    }

    // For rounded corners:
    radius := ifx flags & .HALF_RADIUS theme.corner_radius * 0.5 else theme.corner_radius;
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
            theta   := (PI * 0.5) * (it / cast(float) theme.radius_sample);

            p1      := prev;
            p2      := p0 + xy(sin(theta) * radius, -cos(theta) * radius);

            push_triangle(p0, p1, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(top_right, color);
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

            push_triangle(p0, p1, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_left, color);
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

            push_triangle(p0, p1, p2, color);
            prev = p2;
        }
    } else {
        internal_draw_rect(bottom_right, color);
    }

    // To fill up the rest of the belly of the rounded corner, we can do that
    // with only 3 rects.

    center_middle := Rect.{ r.x + radius, r.y, r.w - (2 * radius), r.h };
    internal_draw_rect(center_middle, color);

    right_middle := Rect.{ r.x, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(right_middle, color);

    left_middle := Rect.{ r.x + r.w - radius, r.y + radius, radius, r.h - (2 * radius) };
    internal_draw_rect(left_middle, color);
}

draw_text :: (text: string, x: float, y: float, font_size := 16.0, color := WHITE) {
    if color.w <= 0 || text.count <= 0 return;

    assert(font != null, "Font is null, you must set a font.");

    using font;
    using metrics := get_font_metrics(font, xx font_size);

    set_texture(font_texture);

    prev_char   : u32;
    pen         := Vector2.{ 0, xx ascender };

    while text.count > 0 {
        codepoint, _ := utf8_next_character(*text);
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

draw_cross :: (rect: Rect, color : Vector4, thickness := 3.0) {
    {
        p0 := Vector2.{ rect.x, rect.y + thickness };
        p1 := Vector2.{ rect.x + thickness, rect.y };
        p2 := Vector2.{ rect.x + rect.w, rect.y + rect.h - thickness };
        p3 := Vector2.{ rect.x + rect.w - thickness, rect.y + rect.h };

        push_triangle(p0, p1, p3, color);
        push_triangle(p1, p2, p3, color);
    }

    {
        p0 := Vector2.{ rect.x + rect.w - thickness, rect.y };
        p1 := Vector2.{ rect.x + rect.w, rect.y + thickness };
        p2 := Vector2.{ rect.x + thickness, rect.y + rect.h };
        p3 := Vector2.{ rect.x, rect.y + rect.h - thickness };

        push_triangle(p0, p1, p3, color);
        push_triangle(p1, p2, p3, color);
    }
}

draw_caret :: (rect: Rect, color : Vector4, up: bool, thickness := 3.0) {
    p0, p1, p2: Vector2;

    if up {
        p0 = Vector2.{ rect.x, rect.y + rect.h };
        p1 = Vector2.{ rect.x + rect.w, rect.y + rect.h };
        p2 = Vector2.{ rect.x + rect.w * 0.5, rect.y };
    } else {
        p0 = Vector2.{ rect.x, rect.y };
        p1 = Vector2.{ rect.x + rect.w, rect.y };
        p2 = Vector2.{ rect.x + rect.w * 0.5, rect.y + rect.h };
    }

    push_triangle(p0, p1, p2, theme.color.text);
}





#scope_export;

interact_lerp :: (using state: *Widget_State, from: float, to: float) -> float {
    press_strength := press_duration / PRESS_TIME;
    return lerp(from, to, press_strength);
}

interact_color :: (using state: Widget_State, base_color: Vector4) -> Vector4 {
    theme_bg := theme.color.bg;
    luminance := 0.2126 * theme_bg.x + 0.7152 * theme_bg.y + 0.0722 * theme_bg.z;
    is_dark := luminance < 0.5;

    hover_strength := hover_duration / HOVER_TIME;
    press_strength := press_duration / PRESS_TIME;

    color := lerp(base_color, ifx is_dark then lighten(base_color, 20) else darken(base_color, 20), hover_strength);
    color  = lerp(color, ifx is_dark then lighten(base_color, 30) else darken(base_color, 30), press_strength);

    if status & .DISABLED {
        color = disable(color, 1.0);
    }

    return color;
}

Color_Theme :: struct {
    bg            : Vector4;
    fg            : Vector4;
    border        : Vector4;
    text          : Vector4;
    accent        : Vector4;
    text_muted    : Vector4;

    blue          : Vector4;
    red           : Vector4;
    green         : Vector4;
};

LIPKO :: Color_Theme.{
    bg          = #run hexa_to_color(0x427b58),
    fg          = #run hexa_to_color(0x2f6247),
    text        = #run hexa_to_color(0xebdbb2),
    text_muted  = #run hexa_to_color(0xbdb291),
    border      = #run hexa_to_color(0x638a5e),
    accent      = #run hexa_to_color(0xd79921),
    red         = #run hexa_to_color(0xa62a1e),
    green       = #run hexa_to_color(0x6b8e3d),
    blue        = #run hexa_to_color(0x7ba0c8),
};

GRUVBOX_DARK :: Color_Theme.{
    bg          = #run hexa_to_color(0x1d2021),
    fg          = #run hexa_to_color(0x3c3836),

    text        = #run hexa_to_color(0xebdbb2),
    text_muted  = #run hexa_to_color(0x928374),
    border      = #run hexa_to_color(0x504945),
    accent      = #run hexa_to_color(0x7daea3),

    red         = #run hexa_to_color(0xfb4934),
    green       = #run hexa_to_color(0xb8bb26),
    blue        = #run hexa_to_color(0x83a598),
};

GRUVBOX_LIGHT :: Color_Theme.{
    bg          = #run hexa_to_color(0xfbf1c7),
    fg          = #run hexa_to_color(0xbdae93),
    text        = #run hexa_to_color(0x654735),
    text_muted  = #run hexa_to_color(0x7c6f64),
    border      = #run hexa_to_color(0x877461),
    accent      = #run hexa_to_color(0x45707a),
    red         = #run hexa_to_color(0x9d0006),
    green       = #run hexa_to_color(0x79740e),
    blue        = #run hexa_to_color(0x076678),
};

NORD :: Color_Theme.{
    bg          = #run hexa_to_color(0x2e3440),
    fg          = #run hexa_to_color(0x3b4252),

    text        = #run hexa_to_color(0xeceff4),
    text_muted  = #run hexa_to_color(0xd8dee9),
    border      = #run hexa_to_color(0x4c566a),
    accent      = #run hexa_to_color(0x88c0d0),

    red         = #run hexa_to_color(0xbf616a),
    green       = #run hexa_to_color(0xa3be8c),
    blue        = #run hexa_to_color(0x5e81ac),
};

content_padding     := 0.;
button_padding      := 0.;
scrollbar_width     := 0.;
input_padding       := 0.;
gap_x               := 0.;
gap_y               := 0.;

sync_theme_sizes :: () {
    content_padding  = get_em(0.25);
    button_padding   = get_em(1.);
    scrollbar_width  = get_em(0.8);
    input_padding    = get_em(0.25);
    gap_x            = get_em(0.25);
    gap_y            = get_em(0.20);
}

Theme :: struct {
    color                   := GRUVBOX_DARK;
    alpha                   := 1.0;
    input_cursor_size       := 2.;
    separator_size          := 1.0;
    corner_radius           := 8.;
    radius_sample           := 20;
    circle_sample           := 30;
    border_width            := 4.;
    text_size               := 18.;
};


#import "Basic";
#import "Hash_Table";
#import "Hash";
#import "Flat_Pool";
#import "Sort";
#import "String";
#import "Clipboard";
