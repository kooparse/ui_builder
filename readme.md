# UI Builder

_I'm not accepting pull requests, the code is designed with my own usage
and preferences in mind, and is available publicly as I think it is valuable
information for people who are looking to make their own GUI._

An immediate-mode GUI, with a simple layout system. This library currently
powers my own game editor, and my forthcoming projects. I explain the core
mechanisms and technical choices
[there](https://fomenko.fr/devlogs/gui-programming/).

<img width="2418" height="1674" alt="Screenshot" src="https://github.com/user-attachments/assets/e808bcf0-f700-4d83-ad9c-318a03731c0a" />

Here's a snippet to see the shape of the user code, for more complete example,
see `demo/demo.jai`:

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
            log("Clicked.");
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

    for drawlist.draw_calls {
        if it.texture {
            set_texture(*pass, it.texture);
        }

        set_scissor(true, it.clip);
        draw_primitives(*pass, it.vertex_count, 1, base_vertex = it.vertex_start);
    }
}


```

# License

MIT License

Copyright (c) 2026 Alexandre Chêne

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
