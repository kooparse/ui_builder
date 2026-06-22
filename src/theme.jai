#scope_export;

Color_Theme :: struct {
    bg            : Vector4;
    fg            : Vector4;
    border        : Vector4;
    text          : Vector4;
    accent        : Vector4;
    text_muted    : Vector4;
};

hex :: (hex: u32) -> Vector4 {
    r := (cast(float) (hex >> 16) & 0xFF) / 255.0;
    g := (cast(float) (hex >> 8) & 0xFF)  / 255.0;
    b := (cast(float) (hex >> 0) & 0xFF)  / 255.0;

    return xyzw(r, g, b, 1.0);
}

GRUVBOX_DARK :: Color_Theme.{
    bg          = #run hex(0x1d2021),
    fg          = #run hex(0x3c3836),
    text        = #run hex(0xebdbb2),
    text_muted  = #run hex(0x928374),
    border      = #run hex(0x504945),
    accent      = #run hex(0x7daea3),
};

LIPKO :: Color_Theme.{
    bg          = #run hex(0x427b58),
    fg          = #run hex(0x076678),

    text        = #run hex(0xebdbb2),
    text_muted  = #run hex(0x928374),
    border      = #run hex(0x076678),
    accent      = #run hex(0xd79921),
};

GRUVBOX_LIGHT :: Color_Theme.{
    bg          = #run hex(0xfbf1c7),
    fg          = #run hex(0xa89984),
    text        = #run hex(0x654735),
    text_muted  = #run hex(0xa89984),
    border      = #run hex(0xbdae93),
    accent      = #run hex(0x45707a),
};

NORD :: Color_Theme.{
    bg          = #run hex(0x2e3440),
    fg          = #run hex(0x3b4252),
    text        = #run hex(0xeceff4),
    text_muted  = #run hex(0x4c566a),
    border      = #run hex(0x4c566a),
    accent      = #run hex(0x88c0d0),
};

Theme :: struct {
    ui_scaler               := 1.0;
    alpha                   := 1.0;

    input_padding           := 4.;
    input_cursor_size       := 2.;

    separator_size          := 1.0;

    content_padding         := 4.;
    window_title_bar_height := 30.;
    scrollbar_width         := 12.;
    corner_radius           := 8.;
    radius_sample           := 20;
    circle_sample           := 20;
    border_width            := 4.;
    checkbox_size           := 40.;

    margin_x                := 3.;
    margin_y                := 6.;

    button_padding          := 16.;

    text_size               := 16.;

    collapser_offset        := 30.;

    color := LIPKO;

    button_color    := Vector4.{ 0.3, 0.3, 0.9, 1 };
    window_color    := Vector4.{ 0.2, 0.7, 0.3, 1 };
    win_title_color := Vector4.{ 0.7, 0.3, 0.3, 1 };
    scrollbar_color := Vector4.{ 0.5, 0.4, 0.6, 1 };
};

#scope_export;

DEFAULT_THEME :: Theme.{};
