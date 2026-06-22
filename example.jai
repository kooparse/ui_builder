


/*

    1) make SDL not required in Pixel_Maker (it's just the type window)
    2) make load_shaders in its own module.
    3) put everything in exemple.
    4) do better for text... it's rather pretty messy.
    5) should get max frame in gflight from Pixel_Maker.


    Advice that we want to capture mouse as far as possible.

*/

quit   := false;
window : *SDL_Window;

Frame_Info :: struct {
    ortho : Matrix4;
};

MAX_FRAME_IN_FLIGHT :: 2;

vertex_buffers        : [MAX_FRAME_IN_FLIGHT] GFX_Buffer;
frame_info_buffer     : GFX_Buffer;
quad_buffer           : GFX_Buffer;

window_width    := 1200.;
window_height   := 800.;

left_down   : bool;

our_font: *Font;

dpi_scale := 1.;

background_texture : GFX_Texture;

frame_start : float;
frame_count : int;
dt          : float;

cpu_time        : float;
gpu_time        : float;

font_atlas_texture      : GFX_Texture;


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

    success := create_gfx_context(window);
    assert(success == true);

    load_all_shaders();
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
        our_font = bake_font("./cascadia_mono.ttf", white_2x2_pixel = true);

        bitmap, width, height := get_raw_bitmap_texture(our_font);
        font_atlas_texture     = create_texture_2d_rgba8("cascadia_modo", xx bitmap, xx width, xx height, mipmapped=false);
    }

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
        }

        SDL_SetCursor(cursor);

        event: SDL_Event;
        while SDL_PollEvent(*event) {

            if event.type == {
                case .SDL_KEYUP;    #through;
                case .SDL_KEYDOWN;
                    down := event.key.state == SDL_PRESSED;

                    if event.key.keysym.sym == {
                        case .SDLK_ESCAPE;      set_key_event(.ESCAPE, down);
                        case .SDLK_BACKSPACE;   set_key_event(.BACKSPACE, down);
                        case .SDLK_RETURN;      set_key_event(.RETURN, down);
                        case .SDLK_LEFT;        set_key_event(.LEFT, down);
                        case .SDLK_RIGHT;       set_key_event(.RIGHT, down);
                        case .SDLK_UP;          set_key_event(.UP, down);
                        case .SDLK_DOWN;        set_key_event(.DOWN, down);
                    }

                case .SDL_TEXTINPUT;
                    str := to_string(cast(*u8) event.text.text.data);
                    send_text_codepoint(str);

                case SDL_WINDOWEVENT;
                    if event.window.event == .SDL_WINDOWEVENT_RESIZED {
                        window_width  = xx event.window.data1;
                        window_height = xx event.window.data2;
                    }

                case SDL_MOUSEWHEEL;
                    set_wheel(cast(float) event.wheel.x, cast(float) event.wheel.y);

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

        draw_list := make_ui();
        do_gpu_stuff(draw_list);
    }

    if quit {
        SDL_DestroyWindow(window);
    }
}

selected        := -1;
radio_selected  := 0;
items           := string.[ "Apple", "Peach", "Banana", "Chocolate", "Tea" ];

chosen_theme := 0;
Color_Themes :: enum {
    GRUVBOX_DARK;
    GRUVBOX_LIGHT;
    NORD;
    LIPKO;
};

mutate_text     : string = "I'm an input text!";

show_color_picker := false;
translucent       := false;
last_draw_calls   : int;
last_vertex_count : int;

WHITE   :: Vector4.{ 1, 1, 1, 1 };
BLACK   :: Vector4.{ 0, 0, 0, 1 };

TABS :: enum {
    TAB_1;
    TAB_2;
    TAB_3;
    TAB_4;
};
current_tab := TABS.TAB_1;

THEMES :: Color_Theme.[ GRUVBOX_DARK, GRUVBOX_LIGHT, NORD, LIPKO ];

make_ui :: () -> UI_Draw_List {

    set_theme(Theme.{
        color                   = THEMES[chosen_theme],
        alpha                   = ifx translucent 0.4 else 1.0,

        window_title_bar_height = DEFAULT_THEME.window_title_bar_height * dpi_scale,
        scrollbar_width         = DEFAULT_THEME.scrollbar_width         * dpi_scale,
        content_padding         = DEFAULT_THEME.content_padding         * dpi_scale,
        margin_x                = DEFAULT_THEME.margin_x                * dpi_scale,
        margin_y                = DEFAULT_THEME.margin_y                * dpi_scale,
        button_padding          = DEFAULT_THEME.button_padding          * dpi_scale,
        text_size               = DEFAULT_THEME.text_size               * dpi_scale,
        input_padding           = DEFAULT_THEME.input_padding           * dpi_scale,
        input_cursor_size       = DEFAULT_THEME.input_cursor_size       * dpi_scale,
    });

    set_font(our_font, *font_atlas_texture);

    if our_font.modified {
        our_font.modified = false;

        bitmap, width, height := get_raw_bitmap_texture(our_font);
        replace_texture_region(*font_atlas_texture, .{ 0, 0, 0 }, .{ xx width, xx height, 1 }, 0, 0, bitmap);
    }

    size := Vector2.{ -1, 30 } * dpi_scale;

    if window_begin(Rect.{ 10, 10, 450, 400 } * dpi_scale, "menu 1") {

        if (frame_count % 8 == 0) {
            cpu_time = dt * 1000;
            gpu_time = get_last_frame_gpu_time() * 1000;
        }

        dt_fmt  := FormatFloat.{ value = cpu_time, trailing_width = 0 };
        gpu_fmt := FormatFloat.{ value = gpu_time, trailing_width = 1 };

        label(tprint("CPU % / GPU %", dt_fmt, gpu_fmt));
        label(tprint("Draw calls: %", last_draw_calls));
        label(tprint("Vertex count: %", last_vertex_count));


        if ui_tab(enum_names(TABS), xx *current_tab) {
            log("Select Tab: %", enum_names(TABS)[current_tab]);
        }

        if current_tab == .TAB_1 {
            placeholder := "Choose...";
            selected     = select(selected, items, .{ 200, 30 } * dpi_scale, placeholder);

            label("Input");
            set_layout_order(.INLINE);
            text_input(mutate_text);
            set_layout_order(.STACK);

            checkbox(*show_color_picker);
            set_layout_order(.INLINE);
            label("Show Color Picker");


            set_layout_order(.STACK);

            checkbox(*translucent);
            set_layout_order(.INLINE);
            label("Translucent");

            set_layout_order(.STACK);

            if button("Alex + Ola = ♥", size) {
                log("click!");
            }

            if begin_expander("Click to expand!") {
                if button("Ola ♥") {
                    log("click!");
                }

                set_layout_order(.COLUMNS, 2);

                for 1..4 {
                    if button(tprint("%", it)) then log("click! %", it);
                }
            }
            end_expander();

            for 1..15 {
                set_layout_order(.COLUMNS, 2);

                if button(tprint("button %", it), size) {
                    log("click! %", it);
                }
            }

        } else {
            label(tprint("YOU ARE ON TAB NUMBER %", current_tab));
        }

        window_end();
    }

    if window_begin(Rect.{ 600, 10, 250, 400 } * dpi_scale, "menu 2") {
        separator(1 * dpi_scale);

        if radio_buttons(enum_names(Color_Themes), *chosen_theme) {
            log("Theme choosen: %", enum_names(Color_Themes)[chosen_theme]);
        }

        separator(1 * dpi_scale);

        window_end();
    }


    if show_color_picker {
        if window_begin(Rect.{ 600, 450, 400, 300 } * dpi_scale, "Color Picker") {
            if button("OK!", size) {
                log("click!");
            }

            window_end();
        }
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
            set_vertex_shader(*loaded_shader.vertex_shader);
            set_pixel_shader(*loaded_shader.fragment_shader);
            set_color_format(get_swapchain_pixel_format());
            set_blend_mode(.ADDITIVE);
            set_vertex_layout(UI_Vertex);

            set_cull_face(.NONE);

            set_viewport(*pass, .{ width = window_width * dpi_scale, height = window_height * dpi_scale });


            Shader_Params :: struct {
                frame_info        : GFX_Pipeline_Binding;
                immediate_texture : GFX_Pipeline_Binding;
                default_sampler   : GFX_Pipeline_Binding;
            }

            vert := get_binding(*loaded_shader.vertex_shader, Shader_Params.{});
            frag := get_binding(*loaded_shader.fragment_shader, Shader_Params.{});


            set_buffer(*pass, vert.frame_info, *frame_info_buffer, 0, size_of(Matrix4));
            set_sampler_state(*pass, frag.default_sampler, *default_sampler);

            {
                set_vertex_buffer(*pass, 10, *quad_buffer, 0, quad_buffer.size, size_of(UI_Vertex));
                set_texture(*pass, frag.immediate_texture, xx *background_texture);
                draw_primitives(*pass, 6, 1, 0);
            }

            vertex_buffer := *vertex_buffers[get_backbuffer_index()];
            set_vertex_buffer(*pass, 10, vertex_buffer, 0, vertex_buffer.size, size_of(UI_Vertex));

            for draw_list.draw_calls {
                if it.texture {
                    set_texture(*pass, frag.immediate_texture, xx it.texture);
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
    capacity     := cast(u64, stride * 54000);

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
#import "Pixel_Maker"(MAX_FRAME_IN_FLIGHT = MAX_FRAME_IN_FLIGHT);

#import, file "./src/module.jai";

using, except(NO) SDL :: #import "SDL";

#load "shader.jai";
