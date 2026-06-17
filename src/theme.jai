UI_Theme :: struct {
    text_color   := Vector4.{ 0, 0, 0, 1 };
    bg_color     := Vector4.{ 1, 1, 1, 1 };
    border_color := Vector4.{ 0, 0, 0, 1 };
};

Theme_State :: struct {
    normal   : UI_Theme;
    hovered  : UI_Theme;
    focused  : UI_Theme;
    disabled : UI_Theme;
};

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

Theme :: struct {
    ui_scaler               := 1.0;
    alpha                   := 1.0;

    input_padding           := 4.;
    input_cursor_size       := 2.;

    content_padding         := 4.;
    window_title_bar_height := 30.;
    resize_size             := 16.;
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

    window_content := Theme_State.{};

    color := LIPKO;

    button_color    := Vector4.{ 0.3, 0.3, 0.9, 1 };
    window_color    := Vector4.{ 0.2, 0.7, 0.3, 1 };
    win_title_color := Vector4.{ 0.7, 0.3, 0.3, 1 };
    scrollbar_color := Vector4.{ 0.5, 0.4, 0.6, 1 };

    window_title_bar := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };

    resizer := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0.8, 0.8, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };
};


DEFAULT_THEME :: Theme.{};
