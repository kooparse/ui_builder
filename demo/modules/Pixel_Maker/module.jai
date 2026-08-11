/*

    @todo:

    - Explain a bit more.
    - Fix visual glitch on resize.
*/

#module_parameters(DEBUG_LAYER := false, MAX_FRAME_IN_FLIGHT := 3);

gpu_frame_count : int;

Render_State :: struct {
    name                : string; // Nice for debugging.

    vertex_shader       : *GFX_Shader;
    pixel_shader        : *GFX_Shader;

    scissor_enabled     : bool;
    scissor_rect        : Recti;

    topology            := GFX_Topology_Primitive_Type.TRIANGLE;
    fill_mode           := GFX_Fill_Mode.FILL;
    cull_face           := GFX_Polygon_Face.BACK;
    winding_order       := GFX_Polygon_Winding_Order.CCW;

    sample_count        : u8 = 1;

    color_formats       : [GFX_MAX_COLOR_ATTACHMENTS] u8;
    blend_modes         : [GFX_MAX_COLOR_ATTACHMENTS] u8;

    depth_enabled       : bool;
    depth_write         : bool;
    depth_comp          : GFX_Compare_Func;

    /*
        Each stencil_state are packed in u64, like in that order:

        0-3:    stencil failed operations
        3-6:    stencil passed, but depth failed.
        6-9:    stencil passed and depth passed.
        9-13:   compare function.

        13-16: ununsed.
    */
    stencil_enabled     : bool;
    stencil_front       : u16;
    stencil_back        : u16;

    stencil_read_mask   : u8 = 0xff; // All bits set.
    stencil_write_mask  : u8 = 0xff;

    // Tho, stencil ref are not packed, and set all the time.
    stencil_ref   : u32;

    depth_stencil_format : GFX_Pixel_Format;

    vertex_layout       : [] GFX_Vertex_Input_Desc;
};

render_state: Render_State;

reset_render_state :: () {
    render_state = Render_State.{};
}

set_color_format :: (format: GFX_Pixel_Format, index := 0) {
    render_state.color_formats[index] = cast(u8, format);
}

set_blend_mode :: (blend_mode: Blend_Mode, index := 0) {
    render_state.blend_modes[index] = cast(u8, blend_mode);
}

set_topology :: (topology: GFX_Topology_Primitive_Type) {
    render_state.topology = topology;
}

set_fill_mode :: (fill_mode : GFX_Fill_Mode) {
    render_state.fill_mode = fill_mode;
}

set_cull_face :: (cull_face: GFX_Polygon_Face) {
    render_state.cull_face = cull_face;
}

set_pso_name :: (name: string) {
    render_state.name = name;
}

set_samples_count :: (count: u8) {
    render_state.sample_count = count;
}

set_winding_order :: (winding_order: GFX_Polygon_Winding_Order) {
    render_state.winding_order = winding_order;
}

set_depth_info :: (enabled: bool, write: bool, comp_func := GFX_Compare_Func.LESS) {
    render_state.depth_enabled = enabled;
    render_state.depth_write   = write;
    render_state.depth_comp    = comp_func;
}

set_vertex_shader :: inline (vertex_shader: *GFX_Shader) {
    render_state.vertex_shader = vertex_shader;
}

set_pixel_shader :: inline (pixel_shader: *GFX_Shader) {
    render_state.pixel_shader = pixel_shader;
}

set_scissor :: (enabled: bool, region := Recti.{}) {
    render_state.scissor_enabled   = enabled;
    render_state.scissor_rect      = region;
}

set_vertex_layout :: ($T: Type, buffer_index : s32) {
    render_state.vertex_layout = make_vertex_layout(T, buffer_index);
}

set_depth_stencil :: (depth_enabled: bool, stencil_enabled: bool) {
    render_state.depth_enabled   = depth_enabled;
    render_state.stencil_enabled = stencil_enabled;
}

set_stencil_mask_value :: (read_mask : u8 = 0xff, write_mask : u8 = 0xff) {
    render_state.stencil_read_mask  = read_mask;
    render_state.stencil_write_mask = write_mask;
}

set_stencil_ref_value :: (value : u8) {
    render_state.stencil_ref = value;
}

// @todo: add to validation code.
set_depth_stencil_format :: (format : GFX_Pixel_Format) {
    render_state.depth_stencil_format  = format;
}

set_stencil_info :: (
    stencil_face                        : enum { FRONT_FACE; BACK_FACE; },
    stencil_failed_op                   : GFX_Stencil_Operation = .KEEP,
    stencil_passed_depth_failed_op      : GFX_Stencil_Operation = .KEEP,
    stencil_passed_depth_passed_op      : GFX_Stencil_Operation = .KEEP,
    comp_func                           : GFX_Compare_Func = .STENCIL_DEFAULT
) {
    result: u16;

    render_state.stencil_enabled = true;

    result |= cast(u16, stencil_failed_op) << 0;
    result |= cast(u16, stencil_passed_depth_failed_op) << 3;
    result |= cast(u16, stencil_passed_depth_passed_op) << 6;
    result |= cast(u16, comp_func) << 9;

    if stencil_face == {
        case .FRONT_FACE; render_state.stencil_front = result;
        case .BACK_FACE;  render_state.stencil_back  = result;
    }
}


GFX_Backend :: enum {
    METAL;
    D3D11;
}

GFX_Capabilities :: struct {
    max_texture_size : u32;
    max_texture_3d_size : u32;
    max_texture_array_length : u32;
    max_texture_samples : u32;
    max_attributes : u32;
    max_buffers : u32;
    max_textures : u32;
    max_sampler_states : u32;
    max_constant_buffer_size : u32;
};

GFX_Storage_Flags :: enum_flags u8 {
    CPU_WRITE;
    CPU_READ;

    CPU_READ_WRITE :: CPU_READ | CPU_WRITE;
}

GFX_Bind_Flags :: enum_flags u8 {
    NONE             :: 0x0;
    VERTEX_BUFFER    :: 0x1;
    INDEX_BUFFER     :: 0x2;
    CONSTANT_BUFFER  :: 0x4;
    SHADER_RESOURCE  :: 0x8;
    RENDER_TARGET    :: 0x10;
    DEPTH_STENCIL    :: 0x20;
}

GFX_Map_Access_Flags :: enum {
    READ;
    WRITE_AND_FLUSH;
    WRITE_NO_FLUSH;
};

GFX_Texture_Type :: enum u8 {
    INVALID;
    TEXTURE_2D;
    TEXTURE_2D_MULTISAMPLE;
    TEXTURE_CUBE;
    TEXTURE_2D_ARRAY;
}

GFX_Pixel_Format :: enum u8 {
    INVALID;

    RED_UINT32;
    RED_INT32;
    RED_FLOAT32;

    BGRA_UNORM8;

    RGBA_UNORM8;
    RGBA_UINT8;
    RGBA_UINT32;
    RGBA_INT32;
    RGBA_FLOAT16;
    RGBA_FLOAT32;

    DEPTH_FLOAT32_STENCIL_8;
    DEPTH_FLOAT32;
    STENCIL_8;
}

get_pixel_format_size :: (format : GFX_Pixel_Format) -> total_bytes : u32, channels : u32 {
    if #complete format == {
        case .INVALID;
            return 0, 0;
        case .RED_UINT32; #through;
        case .RED_INT32; #through;
        case .RED_FLOAT32;
            return 4, 1;
        case .RGBA_UINT8; #through;
        case .RGBA_UNORM8;
            return 4, 4;
        case .RGBA_UINT32; #through;
        case .RGBA_INT32;
            return 4 * 4, 4;
        case .RGBA_FLOAT16;
            return 4 * 2, 4;
        case .RGBA_FLOAT32;
            return 4 * 4, 4;
        case .BGRA_UNORM8;
            return 4, 4;
        case .DEPTH_FLOAT32;
            return 4, 1;
        case .STENCIL_8;
            return 8, 1;
        case .DEPTH_FLOAT32_STENCIL_8;
            return 5, 2;
    }

    return 0, 0;
}

GFX_Texture_Usage :: enum_flags u8 {
    UNKNOWN;

    SHADER_READ;
    RENDER_TARGET;
}

GFX_Texture_Desc :: struct {
    type                : GFX_Texture_Type;
    pixel_format        : GFX_Pixel_Format;
    width               : u32;
    height              : u32 = 1;
    depth               : u32 = 1;
    array_length        : u32 = 1;
    num_mipmap_levels   : u32 = 1;
    num_samples         : u32 = 1;
    storage_flags       : GFX_Storage_Flags;
    usage               : GFX_Texture_Usage;
}

GFX_Texture_View_Desc :: struct {
    type                : GFX_Texture_Type;
    pixel_format        : GFX_Pixel_Format;
    first_slice         : u32;
    num_slices          : u32 = 1;
    first_mipmap_level  : u32;
    num_mipmap_levels   : u32 = 1;
    num_samples         : u32 = 1;
}

get_appropriate_num_mipmap_levels :: (w: int, h: int) -> int  {
    MAX_MIPMAP_LEVEL :: 12;
    MIN_MIPMAP_LEVEL :: 1;

    mipmap_level    := MIN_MIPMAP_LEVEL;
    dim             := max(w, h);

    while dim > 1 {
        dim /= 2;
        mipmap_level += 1;
    }

    return clamp(mipmap_level, MIN_MIPMAP_LEVEL, MAX_MIPMAP_LEVEL);
}

set_appropriate_num_mipmap_levels :: (desc : *GFX_Texture_Desc) {
    desc.num_mipmap_levels = xx get_appropriate_num_mipmap_levels(desc.width, desc.height);
}


GFX_Sampler_Filter :: enum {
    NONE;
    NEAREST;
    LINEAR;
    ANISOTROPIC;
}

GFX_Sampler_Address_Mode :: enum {
    CLAMP_TO_EDGE;
    CLAMP_TO_ZERO;
    CLAMP_TO_BORDER;
    REPEAT;
    MIRROR_CLAMP_TO_EDGE;
    MIRROR_REPEAT;
}

GFX_Sampler_Border_Color :: enum {
    TRANSPARENT;
    OPAQUE_BLACK;
    OPAQUE_WHITE;
}

GFX_Sampler_State_Desc :: struct {
    min_filter := GFX_Sampler_Filter.NEAREST;
    mag_filter := GFX_Sampler_Filter.NEAREST;
    mip_filter := GFX_Sampler_Filter.NONE;
    max_anisotropy : u32 = 1;
    u_address_mode := GFX_Sampler_Address_Mode.CLAMP_TO_EDGE;
    v_address_mode := GFX_Sampler_Address_Mode.CLAMP_TO_EDGE;
    w_address_mode := GFX_Sampler_Address_Mode.CLAMP_TO_EDGE;
    border_color := GFX_Sampler_Border_Color.TRANSPARENT;
    lod_min_clamp := 0.0;
    lod_max_clamp := FLOAT32_INFINITY;
    use_average_lod := false;
    compare_func := GFX_Compare_Func.NONE;
}


GFX_Vertex_Format :: enum u8 {
    INVALID :: 0;

    FLOAT;
    FLOAT2;
    FLOAT3;
    FLOAT4;

    CHAR2;
    CHAR4;
    UCHAR2;
    UCHAR4;

    SHORT2;
    SHORT4;
    USHORT2;
    USHORT4;

    INT;
    INT2;
    INT3;
    INT4;
    UINT;
    UINT2;
    UINT3;
    UINT4;
}

GFX_Vertex_Input_Desc :: struct {
    attribute_name      : string;
    format              : GFX_Vertex_Format = .INVALID;
    attribute_index     : u32;
    buffer_index        : u32;
    offset              : u32;
    stride              : u32;
    normalized          : bool;
}

gfx_vertex_format_from_type :: (type : *Type_Info) -> GFX_Vertex_Format {
    if type == type_info(float) {
        return .FLOAT;
    }
    if type == type_info(Vector2) {
        return .FLOAT2;
    }
    if type == type_info(Vector3) {
        return .FLOAT3;
    }
    if type == type_info(Vector4) {
        return .FLOAT4;
    }
    if type == type_info(Vector4s) {
        return .SHORT4;
    }
    if type == type_info([2]s8) {
        return .CHAR2;
    }
    if type == type_info([4]s8) {
        return .CHAR4;
    }
    if type == type_info([2]u8) {
        return .UCHAR2;
    }
    if type == type_info([4]u8) {
        return .UCHAR4;
    }
    if type == type_info([2]s16) {
        return .SHORT2;
    }
    if type == type_info([4]s16) {
        return .SHORT4;
    }
    if type == type_info([2]u16) {
        return .USHORT2;
    }
    if type == type_info([4]u16) {
        return .USHORT4;
    }
    if type == type_info(s32) {
        return .INT;
    }
    if type == type_info([2]s32) {
        return .INT2;
    }
    if type == type_info([3]s32) {
        return .INT3;
    }
    if type == type_info([4]s32) {
        return .INT4;
    }
    if type == type_info(u32) {
        return .UINT;
    }
    if type == type_info([2]u32) {
        return .UINT2;
    }
    if type == type_info([3]u32) {
        return .UINT3;
    }
    if type == type_info([4]u32) {
        return .UINT4;
    }

    return .INVALID;
}

// @todo: should use a frame allocator or something instead of temp.
// or not even, we could do no allocation... but let's DO BETTER.
make_vertex_layout :: ($T : Type, buffer_index : s32) -> [] GFX_Vertex_Input_Desc
#modify { return (cast(*Type_Info) T).type == .STRUCT, "T must be a struct"; } {
    info   := type_info(T);

    result : [..] GFX_Vertex_Input_Desc;
    array_reserve(*result, info.members.count ,, temp);

    for info.members {
        format := gfx_vertex_format_from_type(it.type);

        if format == .INVALID {
            log_error("Unhandled type % for vertex input layout", (cast(*Type) *it.type).*);
            continue;
        }

        desc := array_add(*result);
        desc.attribute_name     = ifx it.notes.count > 0 then it.notes[0] else "";
        desc.attribute_index    = xx it_index;
        desc.buffer_index       = xx buffer_index;
        desc.format             = format;
        desc.offset             = xx it.offset_in_bytes;
        desc.stride             = xx size_of(T);
    }

    return result;
}

GFX_Polygon_Winding_Order :: enum u8 {
    CCW;
    CW;
}

GFX_Fill_Mode :: enum u8 {
    FILL;
    LINES;
}

GFX_Polygon_Face :: enum u8 {
    NONE;
    FRONT;
    BACK;
}

GFX_Topology_Primitive_Type :: enum u8 {
    INVALID :: 0;

    POINT;
    LINE;
    TRIANGLE;
}

GFX_Draw_Primitive :: enum u8 {
    POINT;
    LINE;
    LINE_STRIP;
    TRIANGLE;
    TRIANGLE_STRIP;
}

GFX_Rasterizer_State_Desc :: struct {
    primitive_type      : GFX_Topology_Primitive_Type = .TRIANGLE;
    fill_mode           : GFX_Fill_Mode = .FILL;
    cull_face           : GFX_Polygon_Face = .BACK;
    winding_order       : GFX_Polygon_Winding_Order = .CCW;
    num_samples         : u32 = 1;
}

GFX_Blend_Factor :: enum u8 {
    ONE;
    ZERO;
    SRC_COLOR;
    ONE_MINUS_SRC_COLOR;
    DST_COLOR;
    ONE_MINUS_DST_COLOR;
    SRC_ALPHA;
    ONE_MINUS_SRC_ALPHA;
    DST_ALPHA;
    ONE_MINUS_DST_ALPHA;
    CONSTANT_COLOR;
    ONE_MINUS_CONSTANT_COLOR;
    CONSTANT_ALPHA;
    ONE_MINUS_CONSTANT_ALPHA;
    SRC_ALPHA_SATURATE;
    SRC1_COLOR;
    ONE_MINUS_SRC1_COLOR;
    SRC1_ALPHA;
    ONE_MINUS_SRC1_ALPHA;
}

GFX_Blend_Operation :: enum u8 {
    ADD;
    SUBTRACT;
    REVERSE_SUBTRACT;
    MIN;
    MAX;

    DEFAULT :: ADD;
}

GFX_Blend_State_Desc :: struct {
    enabled := false;
    src_RGB : GFX_Blend_Factor = .SRC_ALPHA;
    dst_RGB : GFX_Blend_Factor = .ONE_MINUS_SRC_ALPHA;
    src_alpha : GFX_Blend_Factor = .SRC_ALPHA;
    dst_alpha : GFX_Blend_Factor = .ONE_MINUS_SRC_ALPHA;
    RGB_operation : GFX_Blend_Operation = .ADD;
    alpha_operation : GFX_Blend_Operation = .ADD;
}

Blend_Mode :: enum u8 {
    NONE;       // Set blend mode enabled at false.

    ALPHA;      // src * src_alpha + dest * (1 - src_alpha).
    ADDITIVE;   // src * 1 + dest * 1.

    // Add more mode here.
};

GFX_Compare_Func :: enum u8 {
    NONE :: 0;

    NEVER;
    LESS;
    LESS_EQUAL;
    GREATER;
    GREATER_EQUAL;
    EQUAL;
    NOT_EQUAL;
    ALWAYS;

    STENCIL_DEFAULT :: ALWAYS;
    DEPTH_DEFAULT   :: LESS_EQUAL;
}

GFX_Stencil_Operation :: enum u8 {
    KEEP;
    ZERO;
    REPLACE;
    INCREMENT;
    INCREMENT_WRAP;
    DECREMENT;
    DECREMENT_WRAP;
    INVERT;

    DEFAULT :: KEEP;
}



GFX_Pipeline_Binding_Type :: enum {
    NONE :: 0;

    UNIFORM_BUFFER;
    STORAGE_BUFFER;
    TEXTURE;
    SAMPLER_STATE;
}

GFX_Pipeline_Stage :: enum {
    VERTEX;
    FRAGMENT;
}

GFX_Pipeline_Binding :: struct {
    name    : string;
    type    := GFX_Pipeline_Binding_Type.NONE;
    stage   : GFX_Pipeline_Stage;
    index   : s32 = -1;
};

get_binding :: (shader: *GFX_Shader, $T: Type) -> T #modify {
    return (cast(*Type_Info) T).type == .STRUCT;
} {
    result : T;

    #insert -> string {
        builder     : String_Builder;
        info_struct := cast(*Type_Info_Struct, T);

        for info_struct.members {
            print_to_builder(*builder, "result.% = binding(shader, \"%\");\n", it.name, it.name);
        }

        return builder_to_string(*builder);
    }

    return result;
}

binding :: (shader: *GFX_Shader, param_name: string) -> GFX_Pipeline_Binding {
    binding_index := -1;


    for shader.bindings {
        if it.name == param_name {
            binding_index = it_index;
            break;
        }
    }

    if binding_index < 0 {
        shader_param_list : [..] string;
        shader_param_list.allocator = temp;

        for shader.bindings {
            array_add(*shader_param_list, it.name);
        }

        assert(binding_index >= 0, "Parameter '%' not found in shader %.\nShader params: %",
               param_name, shader.name, shader_param_list);
    }

    return shader.bindings[binding_index];
}

GFX_MAX_COLOR_ATTACHMENTS :: 4;

GFX_Render_Pass_Desc :: struct {
    render_target_array_length  : u32 = 1;

    color_attachments           : [GFX_MAX_COLOR_ATTACHMENTS] *GFX_Texture;
    depth_attachment            : *GFX_Texture;
    stencil_attachment          : *GFX_Texture;

    color_resolve_textures      : [GFX_MAX_COLOR_ATTACHMENTS] *GFX_Texture;
    depth_resolve_texture       : *GFX_Texture;

    should_clear_color          : [GFX_MAX_COLOR_ATTACHMENTS] bool;
    should_clear_depth          : bool;
    should_clear_stencil        : bool;

    clear_color                 : [GFX_MAX_COLOR_ATTACHMENTS] Vector4;
    clear_depth                 : float;
    clear_stencil               : u32;
};

set_color_attachment :: (desc: *GFX_Render_Pass_Desc, index: int, texture: *GFX_Texture) {
    desc.color_attachments[index] = texture;
}

set_depth_attachment :: (desc: *GFX_Render_Pass_Desc, texture: *GFX_Texture) {
    desc.depth_attachment = texture;
}

set_stencil_attachment :: (desc: *GFX_Render_Pass_Desc, texture: *GFX_Texture) {
    desc.stencil_attachment = texture;
}

set_color_resolve_texture :: (desc: *GFX_Render_Pass_Desc, index: int, texture: *GFX_Texture) {
    desc.color_resolve_textures[index] = texture;
}

set_depth_resolve_texture :: (desc: *GFX_Render_Pass_Desc, texture: *GFX_Texture) {
    desc.depth_resolve_texture = texture;
}

clear_color :: (desc: *GFX_Render_Pass_Desc, index: int, value: Vector4) {
    desc.should_clear_color[index] = true;
    desc.clear_color[index] = value;
}

clear_depth :: (desc: *GFX_Render_Pass_Desc, value: float) {
    desc.should_clear_depth = true;
    desc.clear_depth = value;
}

clear_stencil :: (desc: *GFX_Render_Pass_Desc, value: u32) {
    desc.should_clear_stencil = true;
    desc.clear_stencil = value;
}

GFX_Viewport :: struct {
    top_left_x      : float;
    top_left_y      : float;
    width           : float;
    height          : float;
    min_depth       : float = 0;
    max_depth       : float = 1;
};

GFX_Index_Type :: enum {
    UINT16;
    UINT32;
};

get_bytes_per_pixel :: (pixel_format: GFX_Pixel_Format) -> u64 {
    bytes_per_pixel : u64;

    if #complete pixel_format == {
        case .INVALID;
            crash("Invalid pixel format.");
        case .DEPTH_FLOAT32_STENCIL_8;
            bytes_per_pixel = 8;
        case .RED_INT32;    #through;
        case .RED_UINT32;   #through;
        case .RED_FLOAT32;  #through;
        case .RGBA_UINT8;   #through;
        case .BGRA_UNORM8;  #through;
        case .RGBA_UNORM8;  #through;
        case .DEPTH_FLOAT32; bytes_per_pixel = 4;
        case .RGBA_INT32;   #through;
        case .RGBA_UINT32;  #through;
        case .RGBA_FLOAT32;  bytes_per_pixel = 4 * 4;
        case .RGBA_FLOAT16;  bytes_per_pixel = 4 * 2;
        case .STENCIL_8;     bytes_per_pixel = 1;
    }

    assert(bytes_per_pixel != 0);
    return bytes_per_pixel;
}

GFX_Shader :: struct {
    name            : string;
    filepath        : string;     // Empty if packed?
    dependencies    : [] string; // Empty as well.

    bindings        : [] GFX_Pipeline_Binding;
    stage           : GFX_Pipeline_Stage;
    shader          : GFX_Platform_Shader;

    compiled        : bool;
};

destroy_shader :: (shader: *GFX_Shader) {
    destroy_shader(*shader.shader);

    for shader.bindings {
        free(it.name.data);
    }

    free(shader.bindings.data);

    shader.* = .{};
}

mesh_draw_calls     : int;

crash :: inline (msg: string, args: ..Any) {
    assert(false, join("[CRASH] ", msg), ..args);
}

Recti :: struct {
    x, y, w, h: s32;
}

Vector3u :: struct {
    x, y, z : u32;
    #overlay (x) component: [3]u32 = ---;
}

// Grrrr I want s32....
Vector4s :: struct {
    x, y, z, w : s16;
    #overlay (x) component: [4]s16 = ---;
}

Texture :: struct {
    #as using gfx_handle  : GFX_Texture;
    // If GFX_Texture is a TextureArray, this index refer to the corresponding slice.
    // Useful mostly when the texture type is set to env.
    texture_index   : s32 = -1;
};

operator == :: inline (a: Recti, b: Recti) -> bool {
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

#scope_module;

VERTEX_BUFFER_INDEX : s32 : 10;

#import "Math";
#import "String";
#import "Hash";
#import "Basic";
#import "Hash_Table";
#import "System";

#load "shader.jai";

#if OS == {
    case .MACOS;    #load "metal.jai";
    case .WINDOWS;  #load "d3d11.jai";
}










#scope_file;

// A check to ensure all necessary API procedures are implemented by the chosen backend.
#run () {
    API :: struct {
        // Context.
        create_context          : (window : *void) -> bool;
        destroy_context         : ();
        get_capabilities        : () -> GFX_Capabilities;
        get_storage_alignment   : () -> u64;
        get_constant_alignment  : () -> u64;

        // Swapchain.
        get_swapchain_texture       : () -> *GFX_Texture;
        get_swapchain_pixel_format  : () -> GFX_Pixel_Format;
        get_swapchain_interval      : () -> s32;
        set_swapchain_interval      : (interval : s32);

        // Frame.
        begin_frame             : ();
        present                 : ();
        get_backbuffer_index    : () -> int;
        get_last_frame_gpu_time : () -> float;


        // Command buffer.
        create_command_buffer : (name : string) -> GFX_Command_Buffer;
        submit_command_buffer : (cmd_buffer : *GFX_Command_Buffer);
        begin_debug_group     : (cmd_buffer : *GFX_Command_Buffer, name : string);
        end_debug_group       : (cmd_buffer : *GFX_Command_Buffer);

        // Textures.
        create_texture          : (name : string, desc : GFX_Texture_Desc, data : *void = null) -> GFX_Texture;
        create_texture_view     : (name : string, texture : GFX_Texture, desc : GFX_Texture_View_Desc) -> GFX_Texture;
        destroy_texture         : (texture : *GFX_Texture);
        replace_texture_region  : (texture : *GFX_Texture, origin : Vector3u, size : Vector3u, mipmap_level : u32, array_slice : u32, bytes : *void);
        create_texture_2d_rgba8 : (name: string, data: *u8, width: s32, height: s32, mipmapped := true) -> GFX_Texture;

        is_null : (texture: *GFX_Texture) -> bool;
        get_desc : (texture: *GFX_Texture) -> GFX_Texture_Desc;

        // Samplers.
        create_sampler_state    : (name : string, desc : GFX_Sampler_State_Desc) -> GFX_Sampler_State;
        destroy_sampler_state   : (sampler : *GFX_Sampler_State);

        // Buffers.
        create_buffer   : (name: string, size: u64, stride: u32, data: *void, storage_flags: GFX_Storage_Flags, flags: GFX_Bind_Flags) -> GFX_Buffer;
        destroy_buffer  : (using buffer: *GFX_Buffer);
        lock_buffer     : (buffer : *GFX_Buffer, flags: GFX_Map_Access_Flags);
        unlock_buffer   : (buffer : *GFX_Buffer);

        // Readback buffer.
        create_readbackbuffer : (name : string, desc: GFX_Texture_Desc) -> GFX_Readback_Buffer;
        destroy_readbackbuffer : (buffer: *GFX_Readback_Buffer);
        lock_readbackbuffer : (resource: *GFX_Readback_Buffer, _: GFX_Map_Access_Flags);
        unlock_readbackbuffer : (resource : *GFX_Readback_Buffer);

        // Copy buffer.
        begin_copy_pass : (pass : *GFX_Copy_Pass, name : string, cmd_buffer : *GFX_Command_Buffer);
        end_copy_pass   : (pass : *GFX_Copy_Pass);
        copy_texture : (pass : *GFX_Copy_Pass, source : *GFX_Texture, dest : *GFX_Texture);
        generate_mipmaps    : (pass : *GFX_Copy_Pass, texture : Texture);
        copy_texture_to_readbackbuffer : (pass : *GFX_Copy_Pass, source : *GFX_Texture, dest : *GFX_Readback_Buffer);


        // Render pass.
        begin_render_pass   : (pass : *GFX_Render_Pass, name : string, cmd_buffer : *GFX_Command_Buffer, desc : GFX_Render_Pass_Desc);
        end_render_pass     : (pass : *GFX_Render_Pass);

        set_buffer          : (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, buffer : *GFX_Buffer, offset : u64, size : u64);
        set_viewport        : (pass : *GFX_Render_Pass, viewport : GFX_Viewport);
        set_viewports       : (pass : *GFX_Render_Pass, viewports : []GFX_Viewport);

        set_vertex_buffer   : (pass : *GFX_Render_Pass, index : s32, buffer : *GFX_Buffer, offset : u64, size : u64, stride : u64);

        set_texture         : (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, texture : *GFX_Texture, fallback: *GFX_Texture = null);
        set_sampler_state   : (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, sampler : *GFX_Sampler_State);

        draw : (
            pass : *GFX_Render_Pass,
            vertex_count : u32,
            instance_count : u32,
            base_vertex : u32 = 0,
            base_instance : u32 = 0,
            primitive_type  : GFX_Draw_Primitive,
        );

        draw_indexed : (
            pass : *GFX_Render_Pass,
            index_buffer : *GFX_Buffer,
            index_count : u32,
            index_type : GFX_Index_Type,
            instance_count : u32,
            base_index : u32 = 0,
            base_vertex : u32 = 0,
            base_instance : u32 = 0,
            primitive_type  : GFX_Draw_Primitive,
        );

        // Shaders.
        compile_shader      : (name: string, source: string, stage: GFX_Pipeline_Stage) -> bool, GFX_Platform_Shader;
        destroy_shader      : (platform_shader : *GFX_Platform_Shader);
    };

    #insert -> string {
        builder : String_Builder;
        info    := cast(*Type_Info_Struct) API;

        for info.members {
            append(*builder, tprint("__check_%: type_of(API.%) = %;\n", it.name, it.name, it.name));
        }

        return builder_to_string(*builder);
    }
}
