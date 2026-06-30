#scope_export;

Color_Theme :: struct {
    bg            : Vector4;
    fg            : Vector4;
    border        : Vector4;
    text          : Vector4;
    accent        : Vector4;
    text_muted    : Vector4;

    blue          : Vector4;
    red           : Vector4;
    green         : Vector4;
};

hexa_to_color :: (hex: u32) -> Vector4 {
    r := (cast(float) (hex >> 16) & 0xFF)  / 255.0;
    g := (cast(float) (hex >> 8)  & 0xFF)  / 255.0;
    b := (cast(float) (hex >> 0)  & 0xFF)  / 255.0;

    return xyzw(r, g, b, 1.0);
}

color_to_hexa :: (vec: Vector4) -> u32 {
    r := cast(u8) (clamp(vec.x, 0, 1.) * 255);
    g := cast(u8) (clamp(vec.y, 0, 1.) * 255);
    b := cast(u8) (clamp(vec.z, 0, 1.) * 255);

    hex : u32;
    hex |= cast(u32, r) << 16;
    hex |= cast(u32, g) << 8;
    hex |= cast(u32, b) << 0;

    return hex;
}

LIPKO :: Color_Theme.{
    bg          = #run hexa_to_color(0x427b58),
    fg          = #run hexa_to_color(0x076678),

    text        = #run hexa_to_color(0xebdbb2),
    text_muted  = #run hexa_to_color(0x928374),
    border      = #run hexa_to_color(0x504945),
    accent      = #run hexa_to_color(0xd79921),

    red         = #run hexa_to_color(0xfb4934),
    green       = #run hexa_to_color(0xb8bb26),
    blue        = #run hexa_to_color(0x83a598),
};

GRUVBOX_DARK :: Color_Theme.{
    bg          = #run hexa_to_color(0x1d2021),
    fg          = #run hexa_to_color(0x3c3836),

    text        = #run hexa_to_color(0xebdbb2),
    text_muted  = #run hexa_to_color(0x928374),
    border      = #run hexa_to_color(0x504945),
    accent      = #run hexa_to_color(0x7daea3),

    red         = #run hexa_to_color(0xfb4934),
    green       = #run hexa_to_color(0xb8bb26),
    blue        = #run hexa_to_color(0x83a598),
};

GRUVBOX_LIGHT :: Color_Theme.{
    bg          = #run hexa_to_color(0xfbf1c7),
    fg          = #run hexa_to_color(0xbdae93),

    text        = #run hexa_to_color(0x654735),
    text_muted  = #run hexa_to_color(0x7c6f64),
    border      = #run hexa_to_color(0xbdae93),
    accent      = #run hexa_to_color(0x45707a),

    red         = #run hexa_to_color(0x9d0006),
    green       = #run hexa_to_color(0x79740e),
    blue        = #run hexa_to_color(0x076678),
};

NORD :: Color_Theme.{
    bg          = #run hexa_to_color(0x2e3440),
    fg          = #run hexa_to_color(0x3b4252),

    text        = #run hexa_to_color(0xeceff4),
    text_muted  = #run hexa_to_color(0xd8dee9),
    border      = #run hexa_to_color(0x4c566a),
    accent      = #run hexa_to_color(0x88c0d0),

    red         = #run hexa_to_color(0xbf616a),
    green       = #run hexa_to_color(0xa3be8c),
    blue        = #run hexa_to_color(0x5e81ac),
};

get_em :: (ratio: float) -> em: float {
    return theme.text_size * ratio;
}

content_padding     := 0.;
button_padding      := 0.;
scrollbar_width     := 0.;
input_padding       := 0.;
margin_x            := 0.;
margin_y            := 0.;

update_size :: () {
    content_padding  = get_em(0.25);
    button_padding   = get_em(1.);
    scrollbar_width  = get_em(0.8);
    input_padding    = get_em(0.25);
    margin_x         = get_em(0.25);
    margin_y         = get_em(0.20);
}

Theme :: struct {
    alpha                   := 1.0;
    input_cursor_size       := 2.;
    separator_size          := 1.0;
    corner_radius           := 8.;
    radius_sample           := 20;
    circle_sample           := 30;
    border_width            := 4.;
    text_size               := 18.;
    color := LIPKO;
};

#scope_export;

DEFAULT_THEME :: Theme.{};
