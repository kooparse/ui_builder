/*

        @todo:

        - Should implement kerning.
        - Should store texture packer on heap.
        - texture_atlas is GFX_Texture, it should be backend agnostic.
*/

#scope_file;

font_catalog : Table(string, Font);

#scope_module;

DEFAULT_FT_SIZE :: 18;

Font_Atlas :: Texture_Packer(2024, 2024);

Font :: struct {
    ft_library    : FT_Library;
    ft_face       : FT_Face;
    ttf_file      : string;

    glyph_table   : Table(u32, Glyph_Info);

    font_atlas      : Font_Atlas;
    texture_atlas   : GFX_Texture;
}

Glyph_Info :: struct {
    advance, width, height, bearing_x, bearing_y: int;
    pos_in_atlas: Rect_Pos;
}

bake_font :: (font_name: string, ttf_filepath: string) -> *Font {
    content := read_entire_file(ttf_filepath);
    count32 := cast,trunc(s32) content.count;

    font := New (Font,, temp);
    using font;

    if FT_Init_FreeType(*ft_library) {
        log_error("Error while loading ft_library.");
    }

    if FT_New_Memory_Face(ft_library, content.data, count32, 0, *ft_face) {
        log_error("Error while loading ft_face.");
    }

    texture_name := tprint("Font Atlas %", font_name);
    texture_atlas = create_texture_2d_rgba8(texture_name, xx font_atlas.bitmap.data, xx font_atlas.total_width, xx font_atlas.total_height, mipmapped=false);

    new_font := table_add(*font_catalog, font_name, font.*);
    return new_font;
}

find_or_add_glyph :: (using font: *Font, char: u32, size: int) -> Glyph_Info {
    // @Speed Perhaps not very fast...
    key := sdbm_hash(*char, size_of(type_of(char)));
    key = sdbm_hash(*size, size_of(type_of(size)), key);

    glyph, newly_add := find_or_add(*glyph_table, key);

    if !newly_add {
        return glyph;
    }

    // @speed (stefan): This retrieves some info about the font metrics
    // each time it is called, so it may not be a good idea to call this per glyph
    FT_Set_Pixel_Sizes(ft_face, 0, xx size);

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

    replace_texture_region(
        *texture_atlas,
        .{0,0,0},
        .{xx font_atlas.total_width, xx font_atlas.total_height, 1},
        0, 0,
        *font_atlas.bitmap
    );

    return glyph.*;
}

get_font :: (font_name: string) -> *Font {
    font := table_find_pointer(*font_catalog, font_name);
    assert(font != null);

    return font;
}

Font_Metrics :: struct {
    pixel_size: u32;
    ascender: s32;
    descender: s32;
    line_height: s32; // ascender - descender
    max_advance: s32;
}

// @speed (stefan): we could cache this if we end up using many different
// sizes at once
get_font_metrics :: (using font : *Font, size : u32, apply_scale_factor := true) -> Font_Metrics {
    if apply_scale_factor {
        size = xx (size * scale_factor);
    }

    FT_Set_Pixel_Sizes(ft_face, 0, xx size);

    result := Font_Metrics.{
        pixel_size = size,
        ascender = xx (ft_face.size.metrics.ascender >> 6),
        descender = xx (ft_face.size.metrics.descender >> 6),
        max_advance = xx (ft_face.size.metrics.max_advance >> 6)
    };

    result.line_height = result.ascender - result.descender;

    return result;
}

get_font_metrics :: inline (font_name : string, size : u32, apply_scale_factor := true) -> Font_Metrics {
    font := get_font(font_name);
    assert (font != null);

    return get_font_metrics(font, size, apply_scale_factor);
}


/// @Note: If text has more than one line, it returns the width of the longest one.
get_text_extents_v2 :: (font_name : string, text : string, size := DEFAULT_FT_SIZE, max_line_width := -1, apply_scale_factor := true) -> width: float, height: float {
    if text.count <= 0 return 0, 0;

    max_width, max_height: float;

    using font      := get_font(font_name);
    using metrics   := get_font_metrics(font, xx size, apply_scale_factor);

    if apply_scale_factor {
        size = cast (int) (size * scale_factor);
    }

    space_glyph := find_or_add_glyph(font, #char " ", pixel_size);

    pen := Vector2.{ 0, xx ascender };
    inv_scale_factor := 1. / scale_factor;

    line_start_index := 0;

    while line_start_index < text.count {
        line_end_index := find_index_from_left(text, #char "\n", line_start_index);

        if line_end_index == -1 {
            line_end_index = text.count;
        }

        line : string;
        line.data   = text.data + line_start_index;
        line.count  = line_end_index - line_start_index;

        line_start_index = line_end_index + 1;

        defer {
            pen.x  = 0;
            pen.y += line_height;
        }


        word_start_index := 0;

        prev_char: u32;
        while word_start_index < line.count {
            word_end_index := find_index_from_left(line, #char " ", word_start_index);

            defer {
                pen.x += space_glyph.advance;
                word_start_index = word_end_index + 1;
            }

            if word_start_index == word_end_index {
                pen.x += space_glyph.advance;
            }

            if word_end_index == -1 {
                word_end_index = line.count;
            }

            word: string;
            word.data   = line.data + word_start_index;
            word.count  = word_end_index - word_start_index;


            if check_if_should_wrap(font, xy(0), size, word, pen.x, max_line_width) {
                prev_char    = 0;
                pen.x        = 0;
                pen.y       += line_height;
            }

            while word.count > 0 {
                codepoint, _ := utf8_next_character(*word);
                defer prev_char = codepoint;

                glyph           := find_or_add_glyph(font, codepoint, pixel_size);
                pos_in_atlas    := glyph.pos_in_atlas;

                if prev_char > 0 {
                    delta: FT_Vector;

                    FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
                    pen.x += xx (delta.x >> 6);
                }

                defer pen.x += glyph.advance;

                glyph_pos := Vector2.{
                    pen.x + glyph.bearing_x,
                    pen.y - glyph.bearing_y
                };

                rect := Rect.{
                    glyph_pos.x * inv_scale_factor,
                    glyph_pos.y * inv_scale_factor,

                    pos_in_atlas.w * inv_scale_factor,
                    pos_in_atlas.h * inv_scale_factor,
                };

                rect.x = round_pixel(rect.x * scale_factor) / scale_factor;
                rect.y = round_pixel(rect.y * scale_factor) / scale_factor;

                max_width   = max(max_width, rect.x + rect.w);
                max_height  = max(max_height, rect.y + rect.h);
            }
        }
    }

    return max_width, max_height;
}

get_text_extents :: (font_name : string, text : string, size := DEFAULT_FT_SIZE, max_line_width := -1, apply_scale_factor := true) -> width: float, height: float {
    using font := get_font(font_name);

    metrics := get_font_metrics(font_name, xx size, apply_scale_factor);

    if apply_scale_factor {
        size = cast (int) (size * scale_factor);
    }

    width       := 0.0;
    height      := 0.0;

    line_start  := 0;

    while line_start < text.count {
        line_end := find_index_from_left(text, #char "\n", line_start);

        if line_end == -1 {
            line_end = text.count;
        }

        line := string.{line_end - line_start, text.data + line_start};
        line_start = line_end + 1;

        x := 0.;
        i := 0;

        while line.count > 0 {
            // @todo: We need to take care of wrong conversion here.
            codepoint, _ := utf8_next_character(*line);
            glyph := find_or_add_glyph(font, codepoint, size);

            x += glyph.advance;
        }

        width   = max(width, x);
        height += metrics.line_height;
    }

    return width, height;
}

free_font:: (using font: *Font) {
    FT_Done_Face(ft_face);
    FT_Done_FreeType(ft_library);

    deinit(*glyph_table);
    free(ttf_file);
}

#scope_file;

Rect_Pos :: struct {
    x, y, w, h : int;
}

Texture_Packer :: struct($WIDTH: s64, $HEIGHT: s64) {
    total_width   : int = WIDTH;
    total_height  : int = HEIGHT;
    bitmap        : [WIDTH][HEIGHT]u32;
    cursor        : struct { x, y: int; };

    largest_height_in_row: int;
}

push_white_bitmap_and_set_alpha_values :: (using texture_packer: *Texture_Packer,
width: int, height: int, data: *u8) -> Rect_Pos {

    if width > total_width || height > total_height {
        crash("Given bitmap is too large.");
    }

    if cursor.x + width > total_width {
        cursor.y += largest_height_in_row;
        cursor.x = 0;
        largest_height_in_row = 0;
    }

    if cursor.y + height >= total_height {
        crash("Texture Packer is full.");
    }

    largest_height_in_row = max(height, largest_height_in_row);

    rect_pos := Rect_Pos.{
        x = cursor.x,
        y = cursor.y,
        w = width,
        h = height,
    };

    cursor.x += width;

    i := 0;
    while i < width {
        j := 0;
        while j < height {
            a := data[j * width + i];
            value := cast(u32) 0x00ffffff;
            value |= (cast(u32) a) << 24;
            bitmap[rect_pos.y + j][rect_pos.x + i] = value;
            j += 1;
        }

        i += 1;
    }

    return rect_pos;
}

check_if_should_wrap :: (using font: *Font, position: Vector2, size: int, word: string, pen := 0., max_line_wrap : int) -> should_wrap: bool {
    if max_line_wrap <= 0 || word.count == 0 {
        return false;
    }

    using metrics := get_font_metrics(font, xx size);

    inv_scale_factor := 1 / scale_factor;

    prev_char: u32;
    while word.count > 0 {
        codepoint, _ := utf8_next_character(*word);
        defer prev_char = codepoint;

        glyph := find_or_add_glyph(font, codepoint, pixel_size);

        if prev_char > 0 {
            delta: FT_Vector;
            FT_Get_Kerning(ft_face, prev_char, codepoint, 0, *delta);
            pen += xx (delta.x >> 6);
        }

        defer pen += glyph.advance;

        glyph_pos := pen + glyph.bearing_x;

        rect_x := glyph_pos * inv_scale_factor;
        rect_x += position.x;
        rect_x  = round_pixel(rect_x * scale_factor) / scale_factor;

        rect_w := glyph.pos_in_atlas.w * inv_scale_factor;

        if rect_x + rect_w > position.x + max_line_wrap {
            return true;
        }
    }

    return false;
}

#import "freetype";
#import "Unicode";
