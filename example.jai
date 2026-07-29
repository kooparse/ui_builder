quit   := false;
window : *SDL_Window;

Frame_Info :: struct {
    ortho : Matrix4;
};

MAX_FRAME_IN_FLIGHT :: 2;

VERTEX_BIND_INDEX :: 10;

vertex_buffers        : [MAX_FRAME_IN_FLIGHT] GFX_Buffer;
frame_info_buffer     : GFX_Buffer;
quad_buffer           : GFX_Buffer;

window_width    := 1200.;
window_height   := 800.;

left_down   : bool;

our_font: *UI_Font;

dpi_scale := 1.;

background_texture : GFX_Texture;

frame_start : float;
frame_count : int;
dt          : float;

cpu_time        : float;
gpu_time        : float;

font_atlas_texture  : GFX_Texture;
white_texture       : GFX_Texture;
playstation_icon    : GFX_Texture;
xbox_icon           : GFX_Texture;

shader: *GFX_Loaded_Shader;

main :: () {
    window_flags := SDL_WindowFlags.SDL_WINDOW_RESIZABLE;

    #if OS == .WINDOWS {
        SDL_HINT_WINDOWS_DPI_SCALING    :: "SDL_WINDOWS_DPI_SCALING";
        SDL_HINT_WINDOWS_DPI_AWARENESS  :: "SDL_WINDOWS_DPI_AWARENESS";

        SDL_SetHint(SDL_HINT_WINDOWS_DPI_AWARENESS, "permonitorv2");
        SDL_SetHint(SDL_HINT_WINDOWS_DPI_SCALING, "1");
    } else {
        window_flags |= .SDL_WINDOW_ALLOW_HIGHDPI;
    }

    window := SDL_CreateWindow("Demo", SDL_WINDOWPOS_UNDEFINED , SDL_WINDOWPOS_UNDEFINED,
                                       xx window_width, xx window_height, window_flags);

    assert(window != null);

    dw, dh: s32;
    SDL_GL_GetDrawableSize(window, *dw, *dh);

    dpi_scale = xx (dw / window_width);
    log("dpi_scale: %", dpi_scale);

    platform_window: *void;

    winfo : SDL_SysWMinfo;
    SDL_GetWindowWMInfo(window, *winfo);

    #if OS == {
        case .MACOS;
            assert(winfo.subsystem == .SDL_SYSWM_COCOA);
            platform_window = winfo.info.cocoa.window;
        case .WINDOWS;
            assert(winfo.subsystem == .SDL_SYSWM_WINDOWS);
            platform_window = winfo.info.win.window;
    }

    success := create_gfx_context(platform_window);
    assert(success == true);

    shader = add_shader("shaders/ui.slang");

    init_gfx_buffers();


    {
        buffer := read_entire_file("./screenshot.png");
        defer free(buffer);

        width, height : s32;
        img := stbi_load_from_memory(buffer.data, xx buffer.count, *width, *height, null, 4);
        assert(img != null);

        background_texture = create_texture_2d_rgba8("bg_texture", img, width, height, mipmapped = false);
        assert(background_texture.handle != null);
    }

    {
        buffer := read_entire_file("./playstation_icon.png");
        defer free(buffer);

        width, height : s32;
        stbi_set_flip_vertically_on_load(0);
        img := stbi_load_from_memory(buffer.data, xx buffer.count, *width, *height, null, 4);
        assert(img != null);

        playstation_icon = create_texture_2d_rgba8("playstation_icon", img, width, height, mipmapped = false);
        assert(playstation_icon.handle != null);
    }

    {
        buffer := read_entire_file("./xbox_icon.png");
        defer free(buffer);

        width, height : s32;
        stbi_set_flip_vertically_on_load(0);
        img := stbi_load_from_memory(buffer.data, xx buffer.count, *width, *height, null, 4);
        assert(img != null);

        xbox_icon = create_texture_2d_rgba8("xbox_icon", img, width, height, mipmapped = false);
        assert(xbox_icon.handle != null);
    }

    {
        our_font = bake_font("./cascadia_mono.ttf", white_2x2_pixel = true);

        bitmap, width, height := get_raw_bitmap_texture(our_font);
        font_atlas_texture     = create_texture_2d_rgba8("cascadia_modo", xx bitmap, xx width, xx height, mipmapped=false);
    }

    {
        WHITE_PIXELS :: u32.[0xffffffff];
        white_texture = create_texture_2d_rgba8("white pixel", xx WHITE_PIXELS.data, 1, 1, mipmapped=false);
    }

    my_string = sprint("I'm an input text!");

    while !quit {
        reset_temporary_storage();

        {
            now     := cast(float) seconds_since_init();
            dt       = now - frame_start;

            frame_start  = now;
            frame_count += 1;

            // if dt * 1000 > 20 then log("SPIKE!");
        }

        begin_gfx_frame();

        ui_begin();


        cursor : *SDL_SystemCursor;

        if get_cursor_icon() == {
            case .ARROW;        cursor = SDL_CreateSystemCursor(SDL_SystemCursor.ARROW);
            case .RESIZE_ARROW; cursor = SDL_CreateSystemCursor(SDL_SystemCursor.SIZENWSE);
            case .HAND;         cursor = SDL_CreateSystemCursor(SDL_SystemCursor.HAND);
            case .TEXT_EDIT;    cursor = SDL_CreateSystemCursor(SDL_SystemCursor.IBEAM);
        }

        SDL_SetCursor(cursor);

        event: SDL_Event;
        while SDL_PollEvent(*event) {

            if event.type == {
                case .SDL_TEXTINPUT;
                    str := to_string(cast(*u8) event.text.text.data);
                    send_text_codepoint(str);

                case .SDL_KEYUP;    #through;
                case .SDL_KEYDOWN;
                    if event.key.repeat continue;

                    down := event.key.state == SDL_PRESSED;

                    // if event.key.keysym.sym == .SDLK_f {
                    //     if down freeze_io(); else unfreeze_io();
                    // }

                    if event.key.keysym.sym == {
                        case .SDLK_ESCAPE;      set_key_event(.ESCAPE, down);
                        case .SDLK_BACKSPACE;   set_key_event(.BACKSPACE, down);
                        case .SDLK_RETURN;      set_key_event(.RETURN, down);
                        case .SDLK_LEFT;        set_key_event(.LEFT, down);
                        case .SDLK_RIGHT;       set_key_event(.RIGHT, down);
                        case .SDLK_UP;          set_key_event(.UP, down);
                        case .SDLK_DOWN;        set_key_event(.DOWN, down);
                        case .SDLK_TAB;         set_key_event(.TAB, down);

                        case .SDLK_v;           set_key_event(.KEY_V, down);
                        case .SDLK_c;           set_key_event(.KEY_C, down);
                    }

                case SDL_WINDOWEVENT;
                    if event.window.event == .SDL_WINDOWEVENT_RESIZED {
                        window_width  = xx event.window.data1;
                        window_height = xx event.window.data2;
                    }

                case SDL_MOUSEWHEEL;
                    speed := 20.0;
                    reverse := -1; // macos.
                    set_wheel(cast(float) event.wheel.x * speed, cast(float) event.wheel.y * reverse * speed);

                case SDL_MOUSEBUTTONUP; #through;
                case SDL_MOUSEBUTTONDOWN;
                    down := event.button.state == SDL_PRESSED;

                    if event.button.button == {
                        case SDL_BUTTON_LEFT;   set_key_event(.MOUSE_LEFT, down);
                        case SDL_BUTTON_RIGHT;  set_key_event(.MOUSE_RIGHT, down);
                        case SDL_BUTTON_MIDDLE; set_key_event(.MOUSE_MIDDLE, down);
                    }

                case SDL_QUIT; quit = true;
            }
        }


        mouse_x, mouse_y: s32;
        SDL_GetMouseState(*mouse_x, *mouse_y);

        set_mouse_position(xx mouse_x * dpi_scale, xx mouse_y * dpi_scale);

        sdl_modifiers := SDL_GetModState();

        modifiers: UI_Modifiers;

        if sdl_modifiers & KMOD_SHIFT {
            modifiers |= .SHIFT;
        }

        if sdl_modifiers & KMOD_CTRL {
            modifiers |= .CTRL;
        }

        if sdl_modifiers & KMOD_ALT {
            modifiers |= .ALT;
        }

        if sdl_modifiers & KMOD_GUI {
            modifiers |= .OS;
        }

        set_modifiers(modifiers);

        draw_list := make_ui();
        do_gpu_stuff(draw_list);
    }

    if quit {
        ui_free();
        SDL_DestroyWindow(window);
    }
}

selected        := -1;
radio_selected  := 0;

plants := string.[ "Rose", "Tulip", "Daisy",
                  "Sunflower", "Lily", "Orchid",
                  "Fern", "Cactus", "Ivy",
                  "Bamboo", "Oak", "Maple",
                  "Pine", "Birch", "Willow",
                  "Lavender", "Basil", "Mint",
                  "Thyme", "Rosemary", "Sage",
                  "Clover", "Dandelion", "Fennel",
                  "Marigold", "Daffodil", "Iris",
                  "Peony", "Hibiscus", "Jasmine",
                  "Lotus", "Poppy", "Violet",
                  "Chrysanthemum", "Carnation", "Hydrangea",
                  "Magnolia", "Azalea", "Camellia",
                  "Aloe Vera", "Fig Tree", "Palm Tree",
                  "Eucalyptus", "Cedar", "Spruce",
                  "Bluebell", "Snowdrop", "Buttercup",
                  "Foxglove", "Bougainvillea" ];

chosen_theme := 0;

Color_Themes :: enum {
    GRUVBOX_DARK;
    GRUVBOX_LIGHT;
    NORD;
    LIPKO;
    CUSTOM;
};


translucent       := false;
last_draw_calls   : int;
last_vertex_count : int;

WHITE   :: Vector4.{ 1, 1, 1, 1 };
BLACK   :: Vector4.{ 0, 0, 0, 1 };

TABS :: enum {
    TAB_1;
    TAB_2;
    LONG_TAB_NAME_TAB_3;
    TAB_4;
};
current_tab := TABS.TAB_1;

Entity_Flags :: enum_flags u64 {
    SOLID          :: 1 << 0;
    PICKABLE       :: 1 << 1;
    INTERACTIVE    :: 1 << 2;
    VIEWABLE       :: 1 << 3;
    READABLE       :: 1 << 4;
};

custom_theme := LIPKO;

THEMES :: Color_Theme.[ GRUVBOX_DARK, GRUVBOX_LIGHT, NORD, LIPKO ];


text_size    := 18.0;
my_string    :  string; // Alloc on the heap later on, dodging read-only data segment check.
my_float     := 12.4;
my_int       := 4;
my_color     := Vector4.{ 1, 0, 1, 1 };
my_hex       :  u32 = 0xffffee;
my_enum_flag := Entity_Flags.SOLID;
toggle       := false;

disable_all  := false;

position     := Vector3.{ 0.5, 12.3, 3.4 };
rotation     := Quaternion.{ 0.7, 0, 0, 1 };
scaler       := Vector3.{ 2, 2, 2 };

ed_widgets       :  Window_State;
ed_color_picker  := Window_State.{ open = true };
ed_undo_redo     := Window_State.{ open = true };
ed_theme         := Window_State.{ open = true };

make_ui :: () -> UI_Draw_List {

    set_theme(Theme.{
        color                   = ifx chosen_theme >= THEMES.count then custom_theme else THEMES[chosen_theme],
        alpha                   = ifx translucent 0.4 else 1.0,

        text_size               = text_size                             * dpi_scale,
        input_cursor_size       = DEFAULT_THEME.input_cursor_size       * dpi_scale,
        separator_size          = DEFAULT_THEME.separator_size          * dpi_scale,
        corner_radius           = DEFAULT_THEME.corner_radius           * dpi_scale,
    });

    modified := set_font(our_font, *font_atlas_texture);

    if modified {
        bitmap, width, height := get_raw_bitmap_texture(our_font);
        replace_texture_region(*font_atlas_texture, .{ 0, 0, 0 }, .{ xx width, xx height, 1 }, 0, 0, bitmap);
    }

    {
        if button("Hey!", UI_Rect.{ 500, 10, 200, 60 } * dpi_scale) {
            log("click button!");
        }

        label("Label without window!");
    }

    if begin_window(*ed_widgets, UI_Rect.{ 25, 50, 450, 600 } * dpi_scale, "Widgets") {
        if (frame_count % 8 == 0) {
            cpu_time = dt * 1000;
            gpu_time = get_last_frame_gpu_time() * 1000;
        }

        dt_fmt  := FormatFloat.{ value = cpu_time, trailing_width = 0 };
        gpu_fmt := FormatFloat.{ value = gpu_time, trailing_width = 1 };


        labels := string.["CPU:", "GPU:", "Draw calls:", "Vertex count:", "IO Captured:", "Dark Theme:"];
        width  := get_longest_text_width(labels) + (text_size * 0.5);

        field(labels[0], width);
        label(tprint("%", dt_fmt));

        field(labels[1], width);
        label(tprint("%", gpu_fmt));

        field(labels[2], width);
        label(tprint("%", last_draw_calls));

        field(labels[3], width);
        label(tprint("%", last_vertex_count));

        field(labels[4], width);
        label(tprint("%", io_captured()));

        label("Text size:");
        same_line();
        number_input(*text_size);

        if button("Button Disabled", disabled = true) {
            log("You can't click me!");
        }

        checkbox(*disable_all, "Disable All");

        if disable_all begin_disable_all();
        defer if disable_all end_disable_all();

        if tab_menu(xx *current_tab, enum_names(TABS)) {
            log("Select Tab: %", enum_names(TABS)[current_tab]);
        }

        if current_tab == .TAB_1 {
            separator("Select inputs");

            placeholder := "Pick a plant...";
            select(*selected, plants, .{ 300, -1 } * dpi_scale, placeholder, max_items = 4);
            flag_select(*my_enum_flag, .{ 300, -1 } * dpi_scale, placeholder);

            separator("Button with img");

            ratio := cast(float, playstation_icon.width) / cast(float, playstation_icon.height);
            h := 40.0;
            if button(texture = xx *playstation_icon, size = .{ h * ratio * dpi_scale, h * dpi_scale }) {
                log("playstation!");
            }

            same_line();

            ratio = cast(float, xbox_icon.width) / cast(float, xbox_icon.height);
            if button(texture = xx *xbox_icon, size = .{ h * ratio * dpi_scale, h * dpi_scale }) {
                log("xbox!");
            }

            separator("Inputs");

            row_start := 140. * dpi_scale;

            field("Position", row_start);
            vec_input(*position);

            field("quaternion", row_start);
            vec_input(*rotation);

            field("Scale", row_start);
            vec_input(*scaler);

            set_width(row_start);
            label("text input:");
            same_line();
            modified, changed_str := text_input(my_string, .{ 320, -1 });
            if modified {
                free(my_string);
                my_string = copy_string(changed_str);
            }


            field("Float input", row_start);
            number_input(*my_float);

            field("Int input", row_start);
            number_input(*my_int);

            separator("Checkboxes");

            begin_column(2);
            checkbox(*ed_color_picker.open, "Show Color Picker");
            checkbox(*ed_theme.open, "Show Theme Picker");
            checkbox(*ed_undo_redo.open, "Show Undo/Redo");
            checkbox(*translucent, "Translucent");
            end_column();

            separator("Buttons");

            button("Toggle", toggle_value = *toggle);

            same_line();

            ratio = cast(float, playstation_icon.width) / cast(float, playstation_icon.height);
            if button(texture = *playstation_icon, size = .{ 20 * ratio * dpi_scale, 20 * dpi_scale }, toggle_value = *toggle) {
                log("playstation!");
            }

            if begin_section("Expand section to see buttons!") {
                begin_column(3);
                for 1..2000 {
                    if button(tprint("%", it)) then log("button %", it);
                }
                end_column();
            }
            end_section();

            begin_column(2);
            for 1..15 {
                if button(tprint("button %", it)) {
                    log("click! %", it);
                }
            }
            end_column();

        } else {
            label(tprint("YOU ARE ON TAB NUMBER %", current_tab));
        }

        end_window();
    }

    if begin_window(*ed_theme, UI_Rect.{ window_width - 350 - 25, 10, 350, 400 } * dpi_scale, "Themes") {

        begin_column(2);
        if radio_buttons(enum_names(Color_Themes), *chosen_theme) {
            log("Theme choosen: %", enum_names(Color_Themes)[chosen_theme]);
        }
        end_column();

        separator("Custom values");

        width := 0.3;

        set_width(width);
        label("bg");
        same_line();
        hexa_input(*custom_theme.bg);

        set_width(width);
        label("fg");
        same_line();
        hexa_input(*custom_theme.fg);

        set_width(width);
        label("border");
        same_line();
        hexa_input(*custom_theme.border);

        set_width(width);
        label("text");
        same_line();
        hexa_input(*custom_theme.text);

        set_width(width);
        label("accent");
        same_line();
        hexa_input(*custom_theme.accent);

        set_width(width);
        label("text_muted");
        same_line();
        hexa_input(*custom_theme.text_muted);

        set_width(width);
        label("red");
        same_line();
        hexa_input(*custom_theme.red);

        set_width(width);
        label("green");
        same_line();
        hexa_input(*custom_theme.green);

        set_width(width);
        label("blue");
        same_line();
        hexa_input(*custom_theme.blue);

        end_window();
    }


    if begin_window(*ed_color_picker, UI_Rect.{ window_width - 400 - 25, 450, 400, 300 } * dpi_scale, "Color Picker") {
        full_width();
        rgba_input(*my_color, format = .FLOAT);

        separator("Channels inputs, integer RGBA");
        full_width();
        rgba_input(*my_color, format = .U8);

        separator("Channels inputs, hexadecimal");
        hexa_input(*my_color);

        end_window();
    }

    if begin_window(*ed_undo_redo, UI_Rect.{ 25, window_height - 100 - 25, 300, 100 } * dpi_scale, "Undo/Redo") {
        rect := ed_undo_redo.layout_rect;

        btn_height := text_size * 4;
        btn_width  := btn_height;

        prev_btn  := rect;
        prev_btn.y = rect.y + rect.h * 0.5 - btn_height * 0.5;
        prev_btn.w = btn_height;
        prev_btn.h = btn_height;

        next_btn  := prev_btn;
        next_btn.x = rect.x + rect.w - btn_width;

        button("<", prev_btn);

        label_rect := UI_Rect.{
            x = prev_btn.x + prev_btn.w,
            y = rect.y,
            w = next_btn.x - (prev_btn.x + prev_btn.w),
            h = rect.h,
        };

        label("Entity moved", label_rect);

        button(">", next_btn);

        end_window();
    }


    ui_end();

    last_draw_calls   = get_draw_list().draw_calls.count;
    last_vertex_count = get_draw_list().vertices.count;

    // Make UI.
    return get_draw_list();
}













do_gpu_stuff :: (draw_list: UI_Draw_List) {
    command_buffer := create_gfx_command_buffer("Frame");
    screen_texture := get_swapchain_texture();

    update_gfx_buffers(draw_list.vertices);

    // pass...
    {
        pass_desc: GFX_Render_Pass_Desc;
        set_color_attachment(*pass_desc, 0, screen_texture);
        clear_color(*pass_desc, 0, xyzw(0, 0, 0, 1));

        pass: GFX_Render_Pass;
        begin_gfx_render_pass(*pass, "UI_Builder", *command_buffer, pass_desc);
        {
            reset_render_state();

            set_pso_name("UI_Builder");
            set_vertex_shader(*shader.vertex_shader);
            set_pixel_shader(*shader.fragment_shader);
            set_color_format(get_swapchain_pixel_format());
            set_blend_mode(.ADDITIVE);
            set_vertex_layout(UI_Vertex, VERTEX_BIND_INDEX);

            set_cull_face(.NONE);

            set_viewport(*pass, .{ width = window_width * dpi_scale, height = window_height * dpi_scale });


            Shader_Params :: struct {
                frame_info        : GFX_Pipeline_Binding;
                immediate_texture : GFX_Pipeline_Binding;
                default_sampler   : GFX_Pipeline_Binding;
            }

            vert := get_binding(*shader.vertex_shader, Shader_Params);
            frag := get_binding(*shader.fragment_shader, Shader_Params);


            set_buffer(*pass, vert.frame_info, *frame_info_buffer, 0, size_of(Matrix4));
            set_sampler_state(*pass, frag.default_sampler, *default_sampler);

            {
                set_vertex_buffer(*pass, 10, *quad_buffer, 0, quad_buffer.size, size_of(UI_Vertex));
                set_texture(*pass, frag.immediate_texture, xx *background_texture);
                draw_primitives(*pass, 6, 1, 0);
            }

            vertex_buffer := *vertex_buffers[get_backbuffer_index()];
            set_vertex_buffer(*pass, VERTEX_BIND_INDEX, vertex_buffer, 0, vertex_buffer.size, size_of(UI_Vertex));

            for draw_list.draw_calls {
                if it.texture {
                    set_texture(*pass, frag.immediate_texture, xx it.texture);
                } else {
                    set_texture(*pass, frag.immediate_texture, *white_texture);
                }

                clip := Recti.{
                    xx max(0., it.clip.x),
                    xx max(0., it.clip.y),
                    xx max(0., it.clip.w),
                    xx max(0., it.clip.h),
                };

                set_scissor(true, clip);
                draw_primitives(*pass, xx it.vertex_count, 1, base_vertex = xx it.vertex_start);
            }

        }
        end_gfx_render_pass(*pass);

    }

    execute_gfx_command_buffer(*command_buffer);
    submit_gfx_frame();
}


default_sampler : GFX_Sampler_State;

init_gfx_buffers :: () {
    stride       := size_of(UI_Vertex);
    capacity     := cast(u64, stride * 84000);

    for 0..MAX_FRAME_IN_FLIGHT - 1 {
        vertex_buffers[it] = create_gfx_buffer("UI Vertices", capacity, xx stride, null, .CPU_WRITE, .VERTEX_BUFFER);
    }

    frame_info_buffer = create_gfx_buffer("Frame Info", size_of(Frame_Info), size_of(Frame_Info), null, .CPU_WRITE, .CONSTANT_BUFFER);

    quad_buffer = create_gfx_buffer("QUAD", 6 * size_of(UI_Vertex), size_of(UI_Vertex), null, .CPU_WRITE, .VERTEX_BUFFER);

    sampler_desc : GFX_Sampler_State_Desc;
    sampler_desc.min_filter = .LINEAR;
    sampler_desc.mag_filter = .LINEAR;
    default_sampler = create_gfx_sampler_state("default_sampler", sampler_desc);
}

update_gfx_buffers :: (vertices: [] UI_Vertex) {
    vertices_size  := size_of(UI_Vertex) * vertices.count;

    index := get_backbuffer_index();

    vertex_buffer := *vertex_buffers[index];

    // Copy vertex data to GPU.
    {
        assert(xx vertices_size < vertex_buffer.size,
                "Overflow: \nVertex capacity: %, while vertex count is %.",
                vertex_buffer.size / size_of(UI_Vertex), vertices.count);

        lock_buffer(vertex_buffer, .WRITE_AND_FLUSH);
        memcpy(vertex_buffer.data_ptr, vertices.data, xx vertices_size);
        unlock_buffer(vertex_buffer);
    }

    // Copy frame data to GPU.
    {
        lock_buffer(*frame_info_buffer, .WRITE_AND_FLUSH);
        frame_info := Frame_Info.{
            ortho = orthographic_projection_matrix(0, window_width * dpi_scale, window_height * dpi_scale, 0, -1, 1, depth_range_01=true),
        };
        memcpy(frame_info_buffer.data_ptr, *frame_info, size_of(Frame_Info));
        unlock_buffer(*frame_info_buffer);
    }

    {
        lock_buffer(*quad_buffer, .WRITE_AND_FLUSH);

        p0 := UI_Vertex.{ position = xy(0, 0), color = WHITE, uv = xy(0, 0) };
        p1 := UI_Vertex.{ position = xy(window_width * dpi_scale, 0), color = WHITE, uv = xy(1, 0) };
        p2 := UI_Vertex.{ position = xy(window_width * dpi_scale, window_height * dpi_scale), color = WHITE, uv = xy(1, 1) };
        p3 := UI_Vertex.{ position = xy(0, window_height * dpi_scale), color = WHITE, uv = xy(0, 1)};

        quad_vertices := UI_Vertex.[ p0, p1, p2, p0, p2, p3 ];

        memcpy(quad_buffer.data_ptr, quad_vertices.data, size_of(UI_Vertex) * quad_vertices.count);

        unlock_buffer(*quad_buffer);
    }
}


#import "Basic";
#import "String";
#import "Math";
#import "stb_image";
#import "Hash_Table";
#import "Hash";
#import "File";
#import "Pixel_Maker"(MAX_FRAME_IN_FLIGHT = MAX_FRAME_IN_FLIGHT);

#import, file "./src/module.jai"(Texture_Type = GFX_Texture);

using, except(NO) SDL :: #import "SDL";
