


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

scale_factor := 2.0;

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

main :: () {
    window := SDL_CreateWindow("Demo", SDL_WINDOWPOS_UNDEFINED , SDL_WINDOWPOS_UNDEFINED,
                                       window_width, window_height, 0x0);

    assert(window != null);

    success := create_gfx_context(window);
    assert(success == true);

    load_all_shaders();
    init_gfx_buffers();


    _ := bake_font("cascadia_mono", "./cascadia_mono.ttf");

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

make_ui :: () -> UI_Draw_List {
    ui_begin();

    mouse_x, mouse_y: s32;
    SDL_GetMouseState(*mouse_x, *mouse_y);

    ui_set_mouse_press(left_down);
    ui_set_mouse(xx mouse_x, xx mouse_y);
    ui_set_wheel(wheel_delta.x, wheel_delta.y);

    r := Rect.{ 0, 0, window_width, window_height };

    r.x += 10;
    r.y += 10;

    begin_window(Rect.{ r.x, r.y, 450, 400 }, "menu 2");

    ui_select();

    if ui_button("OPEN") {
        should_open = !should_open;
    }

    for 0..15 {
        if ui_button(tprint("button %", it)) {
            log("click! %", it);
        }
    }

    end_window();


    if should_open {
        begin_window(Rect.{ 600, r.y, 150, 400 }, "menu 1");

        if ui_button("stack 1") {
            log("click! 3");
        }

        if ui_button("stack 2") {
            log("click! 4");
        }

        set_layout_order(.INLINE);

        if ui_button("inline") {
            log("click! 5");
        }

        set_layout_order(.COLUMNS, 3);

        if ui_button("col") {
            log("click! col 1");
        }

        if ui_button("col") {
            log("click! col 2");
        }

        if ui_button("col") {
            log("click! col 3");
        }

        if ui_button("col") {
            log("click! col 4");
        }

        if ui_button("col") {
            log("click! col 5");
        }

        end_window();

    }

    // if ui_button("button") {
    //     log("click! 1");
    // }
    //
    // if ui_button("button") {
    //     log("click 2");
    // }
    //
    // if ui_button("button") {
    //     log("click 3");
    // }
    //
    // ui_set_layout(.INLINE);
    //
    // ui_spread();
    //
    // if ui_button("button") {
    //     log("click 4");
    // }
    //
    // ui_set_layout(.COLUMNS, 3);
    //
    // if ui_button("button") {
    //     log("click 5");
    // }
    //
    // if ui_button("button") {
    //     log("click 6");
    // }
    //
    // if ui_button("button") {
    //     log("click 7");
    // }
    //
    // if ui_button("button") {
    //     log("click 8");
    // }
    //
    // if ui_button("button") {
    //     log("click 9");
    // }
    //
    // if ui_button("button") {
    //     log("click 10");
    // }
    //
    // ui_end_panel();

    ui_end();
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
            set_vertex_layout(UI_Vertex);

            set_cull_face(.NONE);

            vertex_buffer := *vertex_buffers[get_backbuffer_index()];
            set_vertex_buffer(*pass, 10, vertex_buffer, 0, vertex_buffer.size, size_of(UI_Vertex));

            Shader_Params :: struct {
                frame_info : GFX_Pipeline_Binding;
            }

            params := get_binding(*loaded_shader.vertex_shader, Shader_Params.{});
            set_buffer(*pass, params.frame_info, *frame_info_buffer, 0, size_of(Matrix4));

            set_viewport(*pass, .{ width = window_width, height = window_height });

            // set_texture(*pass, pixel_params.immediate_2d_texture, *immediate_2d_resolve_texture);
            // set_sampler_state(*pass, pixel_params.default_sampler, *default_sampler);

            for draw_list.draw_calls {
                set_scissor(true, .{ xx it.clip.x, xx it.clip.y, xx it.clip.w, xx it.clip.h });
                draw_primitives(*pass, xx it.vertex_count, 1, base_vertex = xx it.vertex_start);
            }

        }
        end_gfx_render_pass(*pass);

    }

    execute_gfx_command_buffer(*command_buffer);
    submit_gfx_frame();
}

init_gfx_buffers :: () {
    stride       := size_of(UI_Vertex);
    capacity     := cast(u64, stride * 24000);

    for 0..MAX_FRAME_IN_FLIGHT - 1 {
        vertex_buffers[it] = create_gfx_buffer("UI Vertices", capacity, xx stride, null, .CPU_WRITE, .VERTEX_BUFFER);
    }

    frame_info_buffer = create_gfx_buffer("Frame Info", size_of(Frame_Info), size_of(Frame_Info), null, .CPU_WRITE, .CONSTANT_BUFFER);
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
            ortho = orthographic_projection_matrix(0, window_width, window_height, 0, -1, 1, depth_range_01=true),
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
