UI_Theme :: struct {
    text_size    := 16.0;
    text_color   := Vector4.{ 0, 0, 0, 1 };
    bg_color     := Vector4.{ 1, 1, 1, 1 };
    border_color := Vector4.{ 0, 0, 0, 1 };

    padding      := Vector2.{ 2.5, 2.5 };
};

Theme_State :: struct {
    normal   : UI_Theme;
    hovered  : UI_Theme;
    focused  : UI_Theme;
    disabled : UI_Theme;
};

Theme :: struct {
    button := Theme_State.{
        normal = UI_Theme.{
            bg_color = Vector4.{ 1, 0, 0, 1 },
        },

        hovered = UI_Theme.{
            bg_color = Vector4.{ 0.8, 0, 0, 1 },
        },

        focused = UI_Theme.{
            bg_color = Vector4.{ 0.7, 0, 0, 1 },
        },

        disabled = UI_Theme.{
            bg_color = Vector4.{ 0.5, 0.5, 0.5, 1 },
        },
    };

    window_scroll_bar := Theme_State.{
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

    content_padding         := 4.;
    window_title_bar_height := 30.;
    resize_size             := 16.;

    scrollbar_width := 12.;

    window_content := Theme_State.{};

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

