


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

MAX_FRAME_IN_FLIGHT :: 2; // it's enough.

vertex_buffers        : [MAX_FRAME_IN_FLIGHT] GFX_Buffer;
frame_info_buffer     : GFX_Buffer;

window_width    :: 1200;
window_height   :: 800;

left_down   : bool;

wheel_delta : Vector2;

cascadia: *Font;

dpi_scale := 1.;

main :: () {
    window := SDL_CreateWindow("Demo", SDL_WINDOWPOS_UNDEFINED , SDL_WINDOWPOS_UNDEFINED,
                                       window_width, window_height, SDL_WINDOW_ALLOW_HIGHDPI);

    assert(window != null);

    dw, dh: s32;
    SDL_GL_GetDrawableSize(window, *dw, *dh);

    dpi_scale = xx (dw / window_width);
    log("dpi_scale: %", dpi_scale);

    success := create_gfx_context(window);
    assert(success == true);

    load_all_shaders();
    init_gfx_buffers();


    cascadia = bake_font("cascadia_mono", "./cascadia_mono.ttf");

    while !quit {
        event: SDL_Event;

        wheel_delta = .{};

        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_MOUSEWHEEL;
                    wheel_delta.x = xx event.wheel.x;
                    wheel_delta.y = xx event.wheel.y;
                case SDL_MOUSEBUTTONUP;
                    if event.button.button == SDL_BUTTON_LEFT {
                        left_down = false;
                    }
                case SDL_MOUSEBUTTONDOWN;
                    if event.button.button == SDL_BUTTON_LEFT {
                        left_down = true;
                    }

                case SDL_QUIT; quit = true;
            }
        }

        draw_list := make_ui();
        do_gpu_stuff(draw_list);

        // log("%", get_last_frame_gpu_time() * 1000);
    }

    if quit {
        SDL_DestroyWindow(window);
    }
}

should_open := false;

selected := -1;
items    := string.[ "Apple", "Peach", "Banana", "Chocolate", "Tea" ];

last_draw_calls   : int;
last_vertex_count : int;

make_ui :: () -> UI_Draw_List {
    ui_begin();

    mouse_x, mouse_y: s32;
    SDL_GetMouseState(*mouse_x, *mouse_y);

    ui_set_theme(Theme.{
        window_title_bar_height = DEFAULT_THEME.window_title_bar_height * dpi_scale,
        resize_size             = DEFAULT_THEME.resize_size             * dpi_scale,
        scrollbar_width         = DEFAULT_THEME.scrollbar_width         * dpi_scale,
        content_padding         = DEFAULT_THEME.content_padding         * dpi_scale,
        margin_x                = DEFAULT_THEME.margin_x                * dpi_scale,
        margin_y                = DEFAULT_THEME.margin_y                * dpi_scale,
        button_padding          = DEFAULT_THEME.button_padding          * dpi_scale,
        text_size               = DEFAULT_THEME.text_size               * dpi_scale,
    });

    ui_set_font(cascadia);
    ui_set_mouse_press(left_down);
    ui_set_mouse(xx mouse_x * dpi_scale, xx mouse_y * dpi_scale);
    ui_set_wheel(wheel_delta.x, wheel_delta.y);

    size := Vector2.{ -1, 30 } * dpi_scale;

    if begin_window(Rect.{ 10, 10, 450, 400 } * dpi_scale, "menu 1") {

        ui_label(tprint("Draw calls: %", last_draw_calls), Vector4.{0, 0, 0, 1});
        ui_label(tprint("Vertex count: %", last_vertex_count), Vector4.{0, 0, 0, 1});

        placeholder := "Choose...";
        selected = ui_select(selected, items, .{ 200, 30 } * dpi_scale, placeholder);

        if ui_button("Alex + Ola = ♥", size) {
            log("click!");
        }

        for 1..15 {
            if ui_button(tprint("button %", it), size) {
                log("click! %", it);
            }
        }

        end_window();
    }




    if begin_window(Rect.{ 600, 10, 150, 400 } * dpi_scale, "menu 2") {
        if ui_button("Button", size) {
            log("click!");
        }

        end_window();
    }


    // if should_open {
    //     begin_window(Rect.{ 600, r.y, 150, 400 }, "menu 1");
    //
    //     if ui_button("stack 1") {
    //         log("click! 3");
    //     }
    //
    //     if ui_button("stack 2") {
    //         log("click! 4");
    //     }
    //
    //     set_layout_order(.INLINE);
    //
    //     if ui_button("inline") {
    //         log("click! 5");
    //     }
    //
    //     set_layout_order(.COLUMNS, 3);
    //
    //     if ui_button("col") {
    //         log("click! col 1");
    //     }
    //
    //     if ui_button("col") {
    //         log("click! col 2");
    //     }
    //
    //     if ui_button("col") {
    //         log("click! col 3");
    //     }
    //
    //     if ui_button("col") {
    //         log("click! col 4");
    //     }
    //
    //     if ui_button("col") {
    //         log("click! col 5");
    //     }
    //
    //     end_window();
    //
    // }

    ui_end();

    last_draw_calls   = get_draw_list().draw_calls.count;
    last_vertex_count = get_draw_list().vertices.count;
    // Make UI.
    return get_draw_list();
}













do_gpu_stuff:: (draw_list: UI_Draw_List) {
    begin_gfx_frame();

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

            vertex_buffer := *vertex_buffers[get_backbuffer_index()];
            set_vertex_buffer(*pass, 10, vertex_buffer, 0, vertex_buffer.size, size_of(UI_Vertex));

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

            for draw_list.draw_calls {

                if it.texture {
                    set_texture(*pass, frag.immediate_texture, xx it.texture);
                }

                set_scissor(true, .{ xx it.clip.x, xx it.clip.y, xx it.clip.w, xx it.clip.h });
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
    capacity     := cast(u64, stride * 24000);

    for 0..MAX_FRAME_IN_FLIGHT - 1 {
        vertex_buffers[it] = create_gfx_buffer("UI Vertices", capacity, xx stride, null, .CPU_WRITE, .VERTEX_BUFFER);
    }

    frame_info_buffer = create_gfx_buffer("Frame Info", size_of(Frame_Info), size_of(Frame_Info), null, .CPU_WRITE, .CONSTANT_BUFFER);


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
}


#import "Basic";
#import "String";
#import "Math";
#import "Hash_Table";
#import "Hash";
#import "Pixel_Maker"(MAX_FRAME_IN_FLIGHT = MAX_FRAME_IN_FLIGHT);

using, except(NO) SDL :: #import "SDL";

#load "shader.jai";
#load "src/module.jai";

// @incomplete: this is not correct for all cases, but works for most
round_pixel :: inline (x : float) -> float {
    if x < 0 {
        return cast(float) cast(int) (x - 0.5);
    } else {
        return cast(float) cast(int) (x + 0.5);
    }
}
