# UI Builder

An immediate-mode GUI, with a simple layout system. This library currently
powered my own game editor, and my forthcoming projects.

All widget position and size are computed from an  layout system, but you can
always escape it by passing youself a rect.

<img width="1196" height="827" alt="Screenshot 2026-07-13 at 14 52 19" src="https://github.com/user-attachments/assets/4ce3830e-f068-4bde-ba2e-937370f6cb7f" />

<br/>

And here's an example of the API, (but example.jai is way more complete):

```jai

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

    set_width(width);
    label("My label");
    same_line();
    hexa_input(*hexa_value);
}

ui_end();

```
