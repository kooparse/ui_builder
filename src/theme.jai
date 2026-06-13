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

Theme :: struct {
    ui_scaler               := 1.0;
    alpha                   := 1.0;

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
    margin_y                := 3.;

    button_padding          := 16.;

    text_size               := 16.;

    window_content := Theme_State.{};

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
