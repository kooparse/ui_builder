# UI Builder

_I'm not accepting pull requests, but the code is designed with my own usage
and preferences in mind, and is available publicaly as I think it is valuable
informations for people who are looking to own the GUI part of their software._


An immediate-mode GUI, with a simple layout system. This library currently
powered my own game editor, and my forthcoming projects.

All widget position and size are computed from by a layout machinery, but you
can always escape it by passing youself a rect.

<img width="1196" height="827" alt="Screenshot" src="https://github.com/user-attachments/assets/4ce3830e-f068-4bde-ba2e-937370f6cb7f" />

---------------------

Here's a snippet of the shape of your program using this library, for a bigger
and complete example, see `example.jai`:

```jai

for program_loop {
    set_theme({
        color     = GRUVBOX_THEME,
        text_size = 16.,
    });

    ui_begin();

    if begin_window(*ed_widgets, UI_Rect.{ 25, 50, 450, 600 }, "Widgets") {

        select(*selected, plants, .{ 300, -1 }, "Pick a plant...", max_items = 4);
        flag_select(*my_enum_flag, .{ 300, -1 });

        if button("Hey") {
            log("You click on the button");
        }


        separator("Spread widgets on given columns");

        begin_column(2);
        checkbox(*checked, "Show Color Picker");
        checkbox(*checked, "Show Theme Picker");
        checkbox(*checked, "Show Undo/Redo");
        checkbox(*checked, "Translucent");
        end_column();

        separator();

        field("Hexa input:", 0.5);
        hexa_input(*hexa_value);
    }

    ui_end();


    drawlist := get_draw_list();

    memcpy(your_buffer.data, drawlist.vertices.data, drawlist.vertices.count * size_of(UI_Vertex));

    for draw_list.draw_calls {
        if it.texture {
            set_texture(*pass, it.texture);
        }

        set_scissor(true, it.clip);
        draw_primitives(*pass, it.vertex_count, 1, base_vertex = it.vertex_start);
    }
}


```

# License


