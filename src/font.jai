/*
        @todo:
        - Should implement kerning.
*/


#scope_module;

DEFAULT_FT_SIZE :: 18;

Font_Atlas :: Texture_Packer(2024, 2024);

Font :: struct {
    ft_library    : FT_Library;
    ft_face       : FT_Face;
    ttf_file      : string;

    glyph_table   : Table(u32, Glyph_Info);
    modified      : bool;

    font_atlas    : Font_Atlas;

    white_pixel_position : Vector2;
}

Glyph_Info :: struct {
    advance, width, height, bearing_x, bearing_y: int;
    pos_in_atlas: Rect_Pos;
}

#scope_export;

bake_font :: (ttf_filepath: string, white_2x2_pixel := false) -> *Font {
    content := read_entire_file(ttf_filepath);
    count32 := cast,trunc(s32) content.count;

    font := New(Font);

    using font;

    if FT_Init_FreeType(*ft_library) {
        log_error("Error while loading ft_library.");
    }

    if FT_New_Memory_Face(ft_library, content.data, count32, 0, *ft_face) {
        log_error("Error while loading ft_face.");
    }


    if white_2x2_pixel {
        WHITE_PIXELS :: u8.[255, 255, 255, 255];
        white_pos := push_white_bitmap_and_set_alpha_values(*font_atlas, 2, 2, xx *WHITE_PIXELS);

        font.white_pixel_position = Vector2.{
            (white_pos.x + 0.5) / cast(float) font_atlas.WIDTH,
            (white_pos.y + 0.5) / cast(float) font_atlas.HEIGHT,
        };
    }

    return font;
}

get_raw_bitmap_texture :: (font: *Font) -> *void, int, int {
    return font.font_atlas.bitmap.data, font.font_atlas.WIDTH, font.font_atlas.HEIGHT;
}

#scope_module;

find_or_add_glyph :: (using font: *Font, char: u32, font_size: int) -> Glyph_Info {
    // @Speed Perhaps not very fast...
    key := sdbm_hash(*char, size_of(type_of(char)));
    key  = sdbm_hash(*font_size, size_of(type_of(font_size)), key);

    glyph, newly_add := find_or_add(*glyph_table, key);

    if !newly_add {
        return glyph;
    }

    // @speed (stefan): This retrieves some info about the font metrics
    // each time it is called, so it may not be a good idea to call this per glyph
    FT_Set_Pixel_Sizes(ft_face, 0, xx font_size);

    glyph_index := FT_Get_Char_Index(ft_face, char);
    slot        := ft_face.glyph;

    FT_Load_Glyph(ft_face, glyph_index, FT_LOAD_RENDER);
    FT_Render_Glyph(slot, FT_Render_Mode.NORMAL);

    buffer    := ft_face.glyph.bitmap.buffer;
    width     := cast(int) ft_face.glyph.bitmap.width;
    height    := cast(int) ft_face.glyph.bitmap.rows; // rows of pixel
    bearing_x := cast(int) ft_face.glyph.bitmap_left;
    bearing_y := cast(int) ft_face.glyph.bitmap_top;
    advance   := cast(int) ft_face.glyph.advance.x >> 6;

    pos_in_atlas := push_white_bitmap_and_set_alpha_values(*font_atlas, width, height, buffer);

    glyph.* = .{
        pos_in_atlas = pos_in_atlas,
        bearing_x = bearing_x,
        bearing_y = bearing_y,
        width     = width,
        height    = height,
        advance = advance,
    };

    modified = true;

    return glyph.*;
}

Font_Metrics :: struct {
    pixel_size  : u32;
    ascender    : s32;
    descender   : s32;
    line_height : s32; // ascender - descender.
    max_advance : s32;
}

get_font_metrics :: (using font : *Font, font_size : u32) -> Font_Metrics {
    FT_Set_Pixel_Sizes(ft_face, 0, xx font_size);

    result := Font_Metrics.{
        pixel_size  = font_size,
        ascender    = xx (ft_face.size.metrics.ascender >> 6),
        descender   = xx (ft_face.size.metrics.descender >> 6),
        max_advance = xx (ft_face.size.metrics.max_advance >> 6)
    };

    result.line_height = result.ascender - result.descender;

    return result;
}

get_text_size :: (using font: *Font, text: string, text_size: float, width_allowed := -1) -> width: float, height: float {
    using metrics := get_font_metrics(font, xx text_size);

    pen := Vector2.{ 0, xx ascender };

    max_width   : float;
    prev_char   : u32;

    while text.count > 0 {
        codepoint, status := utf8_next_character(*text);
        defer prev_char = codepoint;

        glyph           := find_or_add_glyph(font, codepoint, pixel_size);
        pos_in_atlas    := glyph.pos_in_atlas;

        if prev_char > 0 {
            delta: FT_Vector;

            FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
            pen.x += xx (delta.x >> 6);
        }

        max_width = max(max_width, pen.x + glyph.advance);
        pen.x    += glyph.advance;
    }

    return max_width, xx line_height;
}

cursor_to_text_index :: (using font: *Font, text: string, text_size: float, cursor : float) -> text_index : int {
    using metrics := get_font_metrics(font, xx text_size);

    pen := Vector2.{ 0, xx ascender };

    words       := text;
    prev_char   : u32;

    max_width  : float;
    text_index := -1;

    while words.count > 0 {
        codepoint, status := utf8_next_character(*words);
        defer prev_char = codepoint;

        glyph           := find_or_add_glyph(font, codepoint, pixel_size);
        pos_in_atlas    := glyph.pos_in_atlas;

        if prev_char > 0 {
            delta: FT_Vector;

            FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
            pen.x += xx (delta.x >> 6);
        }

        max_width = max(max_width, pen.x + glyph.advance);
        pen.x    += glyph.advance;

        if max_width > cursor {
            text_index = words.count + 1;
            break;
        }
    }

    return text_index;

}

free_font:: (using font: *Font) {
    FT_Done_Face(ft_face);
    FT_Done_FreeType(ft_library);

    deinit(*glyph_table);
    free(ttf_file);
}

Rect_Pos :: struct {
    x, y, w, h : int;
}

Texture_Packer :: struct($WIDTH: s64, $HEIGHT: s64) {
    bitmap        : []u32;
    cursor        : struct { x, y: int; };

    largest_height_in_row: int;
}

push_white_bitmap_and_set_alpha_values :: (using packer: *Texture_Packer,
glyph_w: int, glyph_h: int, data: *u8) -> Rect_Pos {

    if bitmap.data == null {
        bitmap = NewArray(WIDTH * HEIGHT, u32, true);
    }

    if glyph_w > WIDTH || glyph_h > HEIGHT {
        assert(false, "Given bitmap is too large.");
    }

    if cursor.x + glyph_w > WIDTH {
        cursor.y += largest_height_in_row;
        cursor.x = 0;
        largest_height_in_row = 0;
    }

    if cursor.y + glyph_h >= HEIGHT {
        assert(false, "Texture Packer is full.");
    }

    largest_height_in_row = max(glyph_h, largest_height_in_row);

    rect_pos := Rect_Pos.{
        x = cursor.x,
        y = cursor.y,
        w = glyph_w,
        h = glyph_h,
    };

    cursor.x += glyph_w;

    i := 0;
    while i < glyph_w {
        j := 0;

        while j < glyph_h {
            a := data[j * glyph_w + i];

            value := cast(u32) 0x00ffffff;
            value |= (cast(u32) a) << 24;

            btmp_x := rect_pos.x + i;
            btmp_y := rect_pos.y + j;

            bitmap[btmp_y * WIDTH + btmp_x] = value;

            j += 1;
        }

        i += 1;
    }

    return rect_pos;
}

#import "File";
#import "freetype";
#import "Unicode";
#import "Math";
