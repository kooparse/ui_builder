// 1) make SDL not required in Pixel_Maker (it's just the type window)
// 2) make load_shaders in its own module.
// 3) put everything in exemple.
// 4) do better for text... it's rather pretty messy.

quit   := false;
window : *SDL_Window;

scale_factor := 2.0;

Frame_Info :: struct {
    ortho : Matrix4;
};

vertex_buffer         : GFX_Buffer;
frame_info_buffer     : GFX_Buffer;

window_width    :: 800;
window_height   :: 600;

left_down : bool;

main :: () {
    window := SDL_CreateWindow("Demo", SDL_WINDOWPOS_UNDEFINED , SDL_WINDOWPOS_UNDEFINED,
                                       window_width, window_height, 0x0);

    assert(window != null);

    success := create_gfx_context(window);
    assert(success == true);

    load_all_shaders();
    init_gfx_buffers();


    while !quit {
        event: SDL_Event;

        while SDL_PollEvent(*event) {
            if event.type == {
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

        vertices := draw_ui();

        do_gpu_stuff(vertices);
    }

    if quit {
        SDL_DestroyWindow(window);
    }
}

draw_ui :: () -> [] UI_Vertex {
    ui_begin();

    mouse_x, mouse_y: s32;
    SDL_GetMouseState(*mouse_x, *mouse_y);

    ui_set_mouse_press(left_down);
    ui_set_mouse(xx mouse_x, xx mouse_y);

    r := Rect.{ 0, 0, window_width, window_height };

    r.x += 10;
    r.y += 10;

    ui_begin_panel(Rect.{ 600, r.y, 150, 400 }, "menu");

    ui_spread();

    if ui_button("button") {
        log("click! 0");
    }

    ui_end_panel();

    ui_begin_panel(Rect.{ r.x, r.y, 450, 400 }, "menu");

    if ui_button("button") {
        log("click! 1");
    }

    if ui_button("button") {
        log("click 2");
    }

    if ui_button("button") {
        log("click 3");
    }

    ui_set_layout(.INLINE);

    ui_spread();

    if ui_button("button") {
        log("click 4");
    }

    ui_set_layout(.COLUMNS, 3);

    if ui_button("button") {
        log("click 5");
    }

    if ui_button("button") {
        log("click 6");
    }

    if ui_button("button") {
        log("click 7");
    }

    if ui_button("button") {
        log("click 8");
    }

    if ui_button("button") {
        log("click 9");
    }

    if ui_button("button") {
        log("click 10");
    }

    ui_end_panel();

    ui_end();
    // Make UI.
    return get_vertices();
}















do_gpu_stuff:: (vertices: [] UI_Vertex) {
    begin_gfx_frame();

    command_buffer := create_gfx_command_buffer("Frame");
    screen_texture := get_swapchain_texture();

    update_gfx_buffers(vertices);

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

            set_vertex_buffer(*pass, 10, *vertex_buffer, 0, vertex_buffer.size, size_of(UI_Vertex));

            Shader_Params :: struct {
                frame_info : GFX_Pipeline_Binding;
            }

            params := get_binding(*loaded_shader.vertex_shader, Shader_Params.{});
            set_buffer(*pass, params.frame_info, *frame_info_buffer, 0, size_of(Matrix4));

            set_viewport(*pass, .{ width = window_width, height = window_height });

            // set_texture(*pass, pixel_params.immediate_2d_texture, *immediate_2d_resolve_texture);
            // set_sampler_state(*pass, pixel_params.default_sampler, *default_sampler);

            draw_primitives(*pass, xx vertices.count, 1);
        }
        end_gfx_render_pass(*pass);

    }

    execute_gfx_command_buffer(*command_buffer);
    submit_gfx_frame();
}


init_gfx_buffers :: () {
    stride       := size_of(UI_Vertex);
    capacity     := cast(u64, stride * 12000);
    vertex_buffer   = create_gfx_buffer("UI Vertices", capacity, xx stride, null, .CPU_WRITE, .VERTEX_BUFFER);

    frame_info_buffer = create_gfx_buffer("Frame Info", size_of(Frame_Info), size_of(Frame_Info), null, .CPU_WRITE, .CONSTANT_BUFFER);
}

update_gfx_buffers :: (vertices: [] UI_Vertex) {
    vertices_size  := size_of(UI_Vertex) * vertices.count;
    // Copy vertex data to GPU.
    {
        lock_buffer(*vertex_buffer, .WRITE_AND_FLUSH);
        memcpy(vertex_buffer.data_ptr, vertices.data, xx vertices_size);
        unlock_buffer(*vertex_buffer);
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
#import "Pixel_Maker";

using, except(NO) SDL :: #import "SDL";

#load "shader.jai";
#load "text.jai";
#load "src/module.jai";

// @incomplete: this is not correct for all cases, but works for most
round_pixel :: inline (x : float) -> float {
    if x < 0 {
        return cast(float) cast(int) (x - 0.5);
    }

    return cast(float) cast(int) (x + 0.5);
}
