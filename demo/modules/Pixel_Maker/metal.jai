/*

    Grep "GREP_[Texture, PSO, etc..] to easily get to a section.

*/

GFX_Context :: struct {
    swapchain   : *CAMetalLayer;
    device      : *MTLDevice;
    cmd_queue   : *MTLCommandQueue;

    window      : *NSWindow;

    frame_semaphore     : dispatch_semaphore_t;
    backbuffer_index    : int;

    frame_completed_block_desc : Objective_C_Block_Basic_Descriptor;
    frame_completed_block      : Objective_C_Block_Basic;

    first_cmd_buffer_completed_block_desc : Objective_C_Block_Basic_Descriptor;
    first_cmd_buffer_completed_block      : Objective_C_Block_Basic;

    frame_autorelease_pool      : *NSAutoreleasePool;
    current_drawable            : *CAMetalDrawable;
    current_drawable_texture    : GFX_Texture;

    is_first_cmd_buffer_in_frame    := true;
    last_frame_gpu_start_time       : float64;
    last_frame_gpu_end_time         : float64;

    capabilities : GFX_Capabilities;
}

#add_context graphics_context : *GFX_Context;

#scope_file

latest_bounds  : NSRect;

// @Todo @Cleanup: this is here because we need it in a callback where we
// cannot pass user data. Remove this for thread safety!
global_context : *GFX_Context;


PSO_Key           :: u32;
Depth_Stencil_Key :: u32;

depth_stencil_table : Table(Depth_Stencil_Key, *MTLDepthStencilState);
pso_table           : Table(PSO_Key,           *MTLRenderPipelineState);

set_layer :: (view: *NSView, layer: *CAMetalLayer) {
    sel := sel_registerName("setLayer:");

    func :: #type (*void, Selector, *CAMetalLayer) -> void #c_call;
    (cast(func) objc_msgSend)(view, sel, layer);
}

#scope_export

create_context :: (ns_window: *void) -> bool {
    init_objective_c();
    init_app_kit();
    init_metal();

    using ctx := New(GFX_Context);

    window      = cast(*NSWindow) ns_window;
    device      = cast(*MTLDevice) MTLCreateSystemDefaultDevice();
    assert(device != null);

    swapchain  = objc_new(CAMetalLayer);
    assert(swapchain != null);

    CAMetalLayer.setDevice(swapchain, device);
    CAMetalLayer.setPixelFormat(swapchain, MTLPixelFormatBGRA8Unorm);
    CAMetalLayer.setMaximumDrawableCount(swapchain, MAX_FRAME_IN_FLIGHT);
    CAMetalLayer.setDisplaySyncEnabled(swapchain, YES);

    view := NSWindow.contentView(window);
    NSView.setWantsLayer(view, YES);
    set_layer(view, swapchain);

    scale  := NSWindow.backingScaleFactor(window);
    bounds := NSView.bounds(view);
    CAMetalLayer.setDrawableSize(swapchain, .{
        bounds.size.width  * scale,
        bounds.size.height * scale,
    });

    cmd_queue = device.newCommandQueue(device);
    assert(cmd_queue != null);

    log("GPU: %", to_string(device.name(device)));
    log("Ray Tracing: %", device.supportsRaytracing(device));

    frame_semaphore = dispatch_semaphore_create(MAX_FRAME_IN_FLIGHT);

    frame_completed_block_desc.size = size_of(Objective_C_Block_Basic);
    frame_completed_block.isa        = xx _NSConcreteGlobalBlock;
    frame_completed_block.invoke     = xx frame_completed_handler;
    frame_completed_block.descriptor = *frame_completed_block_desc;

    first_cmd_buffer_completed_block_desc.size = size_of(Objective_C_Block_Basic);
    first_cmd_buffer_completed_block.isa        = xx _NSConcreteGlobalBlock;
    first_cmd_buffer_completed_block.invoke     = xx first_command_buffer_completed_handler;
    first_cmd_buffer_completed_block.descriptor = *first_cmd_buffer_completed_block_desc;

    context.graphics_context = ctx;
    global_context = ctx;

    return true;
}

destroy_context :: () {
    using context.graphics_context;

    release(cmd_queue);
    release(device);
    release(swapchain);

    free(context.graphics_context);
    context.graphics_context = null;
    global_context = null;
}

get_swapchain_texture :: () -> *GFX_Texture {
    using context.graphics_context;

    return *current_drawable_texture;
}

get_swapchain_pixel_format :: () -> GFX_Pixel_Format {
    using context.graphics_context;

    return make_gfx_pixel_format(swapchain.pixelFormat(swapchain));
}

get_swapchain_interval :: () -> s32 {
    using context.graphics_context;

    return xx swapchain.displaySyncEnabled(swapchain);
}

set_swapchain_interval :: (interval : s32) {
    using context.graphics_context;

    swapchain.setDisplaySyncEnabled(swapchain, xx (interval != 0));
}

get_backbuffer_index :: () -> int {
    using context.graphics_context;

    return backbuffer_index;
}

begin_frame :: () {
    using context.graphics_context;

    gpu_frame_count += 1;

    dispatch_semaphore_wait(frame_semaphore, DISPATCH_TIME_FOREVER);
    backbuffer_index = (backbuffer_index + 1) % MAX_FRAME_IN_FLIGHT;

    view    := NSWindow.contentView(window);
    bounds  := NSView.bounds(view);

    if memcmp(*bounds, *latest_bounds, size_of(NSRect)) {
        scale := NSWindow.backingScaleFactor(window);

        CAMetalLayer.setDrawableSize(swapchain, .{
            bounds.size.width  * scale,
            bounds.size.height * scale,
        });

        latest_bounds = bounds;
    }

    if frame_autorelease_pool {
        release(frame_autorelease_pool);
    }

    frame_autorelease_pool = objc_new(NSAutoreleasePool);

    current_drawable = swapchain.nextDrawable(swapchain);
    current_drawable_texture.handle = cast(*MTLTexture) current_drawable.texture(current_drawable);

    current_drawable_texture.handle.setLabel(xx current_drawable_texture.handle, NSString.getTempString("Texture 'Backbuffer'"));

    current_drawable_texture.type = .TEXTURE_2D;
    current_drawable_texture.pixel_format = get_swapchain_pixel_format();
    current_drawable_texture.usage = .RENDER_TARGET;
    current_drawable_texture.width = xx current_drawable_texture.handle.width(current_drawable_texture.handle);
    current_drawable_texture.height = xx current_drawable_texture.handle.height(current_drawable_texture.handle);

    is_first_cmd_buffer_in_frame = true;
}

present :: () {
    using context.graphics_context;

    cmd_buffer := cmd_queue.commandBuffer(cmd_queue);

    cmd_buffer.setLabel(cmd_buffer, NSString.getTempString("Command Buffer 'submit_gfx_frame'"));

    cmd_buffer.addCompletedHandler(cmd_buffer, *frame_completed_block);

    cmd_buffer.presentDrawable(cmd_buffer, xx current_drawable);
    cmd_buffer.commit(cmd_buffer);

    current_drawable = null;
    current_drawable_texture.handle = null;
}

get_last_frame_gpu_time :: () -> float {
    using context.graphics_context;

    return xx (last_frame_gpu_end_time - last_frame_gpu_start_time);
}

get_capabilities :: () -> GFX_Capabilities {
    using context.graphics_context;

    if capabilities.max_texture_size {
        return capabilities;
    }


    // Reference:
    //   https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
    // Last updated 25 march 2025

    using capabilities;
    max_attributes = 31;
    max_buffers = 31;

    if MTLDevice.supportsFamily(device, .Apple6)
    || MTLDevice.supportsFamily(device, .Apple7)
    || MTLDevice.supportsFamily(device, .Apple8)
    || MTLDevice.supportsFamily(device, .Apple9)
    || MTLDevice.supportsFamily(device, .Mac2) {
        max_textures = 128;
    } else if MTLDevice.supportsFamily(device, .Apple4) || MTLDevice.supportsFamily(device, .Apple5) {
        max_textures = 96;
    } else {
        max_textures = 31;
    }

    max_sampler_states = 16;
    max_constant_buffer_size = 4096;

    if MTLDevice.supportsFamily(device, .Apple3)
    || MTLDevice.supportsFamily(device, .Apple4)
    || MTLDevice.supportsFamily(device, .Apple5)
    || MTLDevice.supportsFamily(device, .Apple6)
    || MTLDevice.supportsFamily(device, .Apple7)
    || MTLDevice.supportsFamily(device, .Apple8)
    || MTLDevice.supportsFamily(device, .Apple9)
    || MTLDevice.supportsFamily(device, .Mac2) {
        max_texture_size = 16384;
    } else {
        max_texture_size = 8192;
    }

    max_texture_3d_size = 2048;
    max_texture_array_length = 2048;
    max_texture_samples = 32;

    return capabilities;
}

frame_completed_handler :: (block : *Objective_C_Block_Basic, cmd_buffer : *MTLCommandBuffer) #c_call {
    if !global_context {
        return;
    }

    push_context, defer_pop;

    using global_context;

    dispatch_semaphore_signal(frame_semaphore);
    last_frame_gpu_end_time = cmd_buffer.GPUEndTime(cmd_buffer);
}

first_command_buffer_completed_handler :: (block : *Objective_C_Block_Basic, cmd_buffer : *MTLCommandBuffer) #c_call {
    if !global_context {
        return;
    }

    push_context, defer_pop;

    using global_context;

    last_frame_gpu_start_time = cmd_buffer.GPUStartTime(cmd_buffer);
}

GFX_Command_Buffer :: struct {
    using handle: *MTLCommandBuffer;
}

create_command_buffer :: (name: string) -> GFX_Command_Buffer {
    using context.graphics_context;

    buffer := cmd_queue.commandBuffer(cmd_queue);
    buffer.setLabel(buffer, NSString.getTempString(tprint("Command Buffer '%'", name)));

    if is_first_cmd_buffer_in_frame {
        buffer.addCompletedHandler(buffer, *first_cmd_buffer_completed_block);
    }

    is_first_cmd_buffer_in_frame = false;

    return .{
        buffer,
    };
}

submit_command_buffer :: (cmd_buffer: *GFX_Command_Buffer) {
    using context.graphics_context;

    cmd_buffer.commit(cmd_buffer.handle);
}

begin_debug_group :: (cmd_buffer: *GFX_Command_Buffer, name: string) {
    cmd_buffer.pushDebugGroup(cmd_buffer.handle, NSString.getTempString(name));
}

end_debug_group :: (cmd_buffer: *GFX_Command_Buffer) {
    cmd_buffer.popDebugGroup(cmd_buffer.handle);
}


crash :: (error: *NSError, msg: string) {
    error_msg := to_string(NSError.localizedDescription(error));
    crash("%: %", msg, error_msg);
}





/*

    About buffers on Metal:

    On Apple devices (since M chips), the GPU and the CPU shared the same piece
    of memory, so on the shader it's just a pointer to the same block of memory
    that we would access on the CPU. So no need to map or unmap buffers
    actually.

*/

GFX_Buffer :: struct {
    #as handle      : *MTLBuffer;

    locked          : bool;
    size            : u64;
    data_ptr        : *void;
};

is_null :: (buffer: *GFX_Buffer) -> bool {
    return buffer == null || buffer.handle == null;
}

create_buffer :: (name: string, size: u64, stride: u32, data: *void, storage_flags: GFX_Storage_Flags, _: GFX_Bind_Flags) -> GFX_Buffer {
    using context.graphics_context;

    options: MTLResourceOptions;
    if (storage_flags & .CPU_WRITE) || (storage_flags & .CPU_READ) {
        options |= MTLResourceStorageModeShared;
    } else {
        options |= MTLResourceStorageModePrivate;
    }

    buffer: *MTLBuffer;
    if data {
        buffer = device.newBufferWithBytes_length_options(device, data, size, options);
    } else {
        buffer = device.newBufferWithLength_options(device, size, options);
    }

    if !buffer {
        log_error("Failed to create graphics buffer '%'", name);
        return .{};
    }

    buffer.setLabel(buffer, NSString.getTempString(tprint("Buffer '%'", name)));

    return .{handle=buffer, size=size};
}

destroy_buffer :: (using buffer: *GFX_Buffer) {
    release(handle);
    buffer.* = .{};
}

lock_buffer :: (using buffer : *GFX_Buffer, _: GFX_Map_Access_Flags) {
    assert(buffer.locked == false, "GPU Buffer was already locked!");

    buffer.locked   = true;
    buffer.data_ptr = buffer.handle.contents(buffer.handle);
}

unlock_buffer :: (buffer : *GFX_Buffer) {
    buffer.locked   = false;
    buffer.data_ptr = null;
}

get_storage_alignment :: inline () -> u64 {
    return 16;
}

get_constant_alignment :: inline () -> u64 {
    return 16;
}



/*

    The Metal way for reading texture contents from the CPU, is to copy a
    texture to a buffer. That's significantly different that DirectX where we
    copy a texture and then map/unmap while reading it.

    I first tried to do the same things on Metal, in order to have no readback
    API, but getBytes stalls the CPU while reading the texture, really not
    great.

*/

GFX_Readback_Buffer :: GFX_Buffer;

lock_readbackbuffer :: (using resource: *GFX_Readback_Buffer, _: GFX_Map_Access_Flags) {
    assert(resource.locked == false, "GPU ReadbackBbuffer was already locked!");

    resource.locked   = true;
    resource.data_ptr = MTLBuffer.contents(resource.handle);
}

unlock_readbackbuffer :: (resource : *GFX_Readback_Buffer) {
    resource.data_ptr = null;
    resource.locked   = false;
}

copy_texture_to_readbackbuffer :: (using pass : *GFX_Copy_Pass, source : *GFX_Texture, dest : *GFX_Readback_Buffer) {
    pixel_bytes := get_bytes_per_pixel(source.pixel_format);

    MTLBlitCommandEncoder.copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage(
        encoder,
        sourceTexture= cast(*NSObject, source.handle),
        sourceSlice=0,
        sourceLevel=0,
        sourceOrigin=.{ 0, 0, 0 },
        sourceSize=.{ source.width, source.height, 1 },
        destinationBuffer = cast(*NSObject) dest.handle,
        destinationOffset = 0,
        destinationBytesPerRow = source.width * pixel_bytes,
        destinationBytesPerImage = source.width * source.height * pixel_bytes,
    );
}

create_readbackbuffer :: (name : string, desc: GFX_Texture_Desc) -> GFX_Readback_Buffer {
    size    := desc.width * desc.height * get_bytes_per_pixel(desc.pixel_format);
    stride  := cast(u32) get_bytes_per_pixel(desc.pixel_format);

    return create_buffer(name, size, stride, null, desc.storage_flags, .NONE);
}

destroy_readbackbuffer :: (buffer: *GFX_Readback_Buffer) {
    destroy_buffer(buffer);
}



/*

    GREP_Texture

*/



GFX_Texture :: struct {
    handle          : *MTLTexture;

    name            : string;
    locked          : bool;

    data_ptr        : *void;
    data_row_pitch  : int;

    using desc      : GFX_Texture_Desc;
}

GFX_NULL_TEXTURE :: GFX_Texture.{};

operator == :: inline (a: GFX_Texture, b: GFX_Texture) -> bool {
    return a.width == b.width && a.height == b.height && a.handle == b.handle;
}


is_null :: (texture: *GFX_Texture) -> bool {
    return texture == null || texture.handle == null;
}

get_desc :: (texture: *GFX_Texture) -> GFX_Texture_Desc {
    return texture.desc;
}

create_texture :: (name : string, desc : GFX_Texture_Desc, data : *void = null) -> GFX_Texture {
    using context.graphics_context;

    // assert(desc.usage != .UNKNOWN, "desc.usage is %", desc.usage);

    texture_desc := objc_new(MTLTextureDescriptor);
    defer release(texture_desc);

    texture_desc.setTextureType(texture_desc, make_metal_texture_type(desc.type));
    texture_desc.setPixelFormat(texture_desc, make_metal_pixel_format(desc.pixel_format));
    texture_desc.setWidth(texture_desc, desc.width);
    texture_desc.setHeight(texture_desc, desc.height);
    texture_desc.setDepth(texture_desc, desc.depth);
    texture_desc.setMipmapLevelCount(texture_desc, desc.num_mipmap_levels);
    texture_desc.setSampleCount(texture_desc, desc.num_samples);
    texture_desc.setArrayLength(texture_desc, desc.array_length);
    texture_desc.setUsage(texture_desc, make_metal_texture_usage(desc.usage));

    storage_mode : MTLStorageMode;
    if (desc.storage_flags & .CPU_READ) || (desc.storage_flags & .CPU_WRITE) {
        storage_mode = MTLStorageModeShared;
    } else {
        storage_mode = MTLStorageModePrivate;
    }

    texture_desc.setStorageMode(texture_desc, storage_mode);

    texture := cast(*MTLTexture) device.newTextureWithDescriptor(device, texture_desc);
    if !texture
    {
        log_error("Failed to create texture '%'. Texture desc: %", name, desc);

        return .{};
    }

    texture.setLabel(xx texture, NSString.getTempString(tprint("Texture '%'", name)));

    result := GFX_Texture.{
        handle=texture,
        desc=desc,
    };

    if data {
        replace_texture_region(
            *result,
            .{0,0,0},
            .{desc.width, desc.height, desc.depth},
            0,
            0,
            data
        );
    }

    return result;
}

destroy_texture :: (using texture : *GFX_Texture) {
    release(handle);
    if name then free(name);
    texture.* = .{};
}

replace_texture_region :: (using texture : *GFX_Texture, origin : Vector3u, size : Vector3u, mipmap_level : u32, array_slice : u32, bytes : *void) {
    bytes_per_pixel : u64;
    if #complete pixel_format == {
        case .INVALID;
            crash("replace_texture_region: Invalid pixel format");
        case .DEPTH_FLOAT32_STENCIL_8;
            crash("replace_texture_region: Invalid pixel format %", pixel_format);
        case .RED_INT32; #through;
        case .RED_UINT32; #through;
        case .RED_FLOAT32; #through;
        case .RGBA_UINT8; #through;
        case .BGRA_UNORM8; #through;
        case .RGBA_UNORM8; #through;
        case .DEPTH_FLOAT32;
            bytes_per_pixel = 4;
        case .RGBA_INT32; #through;
        case .RGBA_UINT32; #through;
        case .RGBA_FLOAT32;
            bytes_per_pixel = 4 * 4;
        case .RGBA_FLOAT16;
            bytes_per_pixel = 4 * 2;
        case .STENCIL_8;
            bytes_per_pixel = 1;
    }
    assert(bytes_per_pixel != 0);

    bytes_per_row := size.x * bytes_per_pixel;
    bytes_per_image : u64;

    MTLTexture.replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage(
        texture.handle,
        .{
            origin=.{origin.x,origin.y,origin.z},
            size=.{size.x,size.y,size.z},
        },
        mipmap_level,
        array_slice,
        bytes,
        bytes_per_row,
        bytes_per_image
    );

}

create_texture_view :: (name : string, texture : GFX_Texture, desc : GFX_Texture_View_Desc) -> GFX_Texture {
    view := cast(*MTLTexture, MTLTexture.newTextureViewWithPixelFormat_textureType_levels_slices(
        texture.handle,
        make_metal_pixel_format(desc.pixel_format),
        make_metal_texture_type(desc.type),
        NSRange.{desc.first_mipmap_level, desc.num_mipmap_levels},
        NSRange.{desc.first_slice, desc.num_slices}
    ));

    view.setLabel(xx view, NSString.getTempString(tprint("Texture View '%'", name)));

    texture_desc := texture.desc;

    texture_desc.type               = desc.type;
    texture_desc.pixel_format       = desc.pixel_format;
    texture_desc.num_mipmap_levels  = desc.num_mipmap_levels;
    texture_desc.array_length       = desc.num_slices;

    return GFX_Texture.{ handle = xx view, desc = texture_desc };
}

create_texture_2d_rgba8 :: (name := "", data: *u8, width: s32, height: s32, mipmapped := true) -> GFX_Texture {
    using context.graphics_context;;

    desc : GFX_Texture_Desc;
    desc.type = .TEXTURE_2D;
    desc.pixel_format = .RGBA_UNORM8;
    desc.usage = .SHADER_READ;
    desc.width = xx width;
    desc.height = xx height;
    desc.storage_flags = .CPU_WRITE;

    if mipmapped {
        set_appropriate_num_mipmap_levels(*desc);
    }

    result := create_texture(name, desc, data=data);

    if is_null(*result) {
        return result;
    }

    return result;
}

make_metal_pixel_format :: (format : GFX_Pixel_Format) -> MTLPixelFormat {
    if #complete format == {
        case .INVALID;
            return MTLPixelFormatInvalid;

        case .RED_UINT32;
            return MTLPixelFormatR32Uint;
        case .RED_INT32;
            return MTLPixelFormatR32Sint;
        case .RED_FLOAT32;
            return MTLPixelFormatR32Float;

        case .BGRA_UNORM8;
            return MTLPixelFormatBGRA8Unorm;
        case .RGBA_UINT8;
            return MTLPixelFormatRGBA8Uint;
        case .RGBA_UNORM8;
            return MTLPixelFormatRGBA8Unorm;
        case .RGBA_INT32;
            return MTLPixelFormatRGBA32Sint;
        case .RGBA_UINT32;
            return MTLPixelFormatRGBA32Uint;
        case .RGBA_FLOAT16;
            return MTLPixelFormatRGBA16Float;
        case .RGBA_FLOAT32;
            return MTLPixelFormatRGBA32Float;

        case .DEPTH_FLOAT32;
            return MTLPixelFormatDepth32Float;
        case .STENCIL_8;
            return MTLPixelFormatStencil8;
        case .DEPTH_FLOAT32_STENCIL_8;
            return MTLPixelFormatDepth32Float_Stencil8;
    }
}

make_gfx_pixel_format :: (format : MTLPixelFormat) -> GFX_Pixel_Format {
    if format == {
        case MTLPixelFormatInvalid;
            return .INVALID;

        case MTLPixelFormatR32Uint;
            return .RED_UINT32;
        case MTLPixelFormatR32Sint;
            return .RED_INT32;
        case MTLPixelFormatR32Float;
            return .RED_FLOAT32;

        case MTLPixelFormatBGRA8Unorm;
            return .BGRA_UNORM8;
        case MTLPixelFormatRGBA8Uint;
            return .RGBA_UINT8;
        case MTLPixelFormatRGBA8Unorm;
            return .RGBA_UNORM8;
        case MTLPixelFormatRGBA32Sint;
            return .RGBA_INT32;
        case MTLPixelFormatRGBA32Uint;
            return .RGBA_UINT32;
        case MTLPixelFormatRGBA16Float;
            return .RGBA_FLOAT16;
        case MTLPixelFormatRGBA32Float;
            return .RGBA_FLOAT32;

        case MTLPixelFormatDepth32Float;
            return .DEPTH_FLOAT32;
        case MTLPixelFormatStencil8;
            return .STENCIL_8;
        case MTLPixelFormatDepth32Float_Stencil8;
            return .DEPTH_FLOAT32_STENCIL_8;
    }

    return .INVALID;
}

make_metal_texture_type :: (type : GFX_Texture_Type) -> MTLTextureType {
    if #complete type == {
        case .INVALID;
            return xx,no_check -1;
        case .TEXTURE_2D;
            return MTLTextureType2D;
        case .TEXTURE_CUBE;
            return MTLTextureTypeCube;
        case .TEXTURE_2D_ARRAY;
            return MTLTextureType2DArray;
        case .TEXTURE_2D_MULTISAMPLE;
            return MTLTextureType2DMultisample;
    }
}

make_metal_texture_usage :: (usage : GFX_Texture_Usage) -> MTLTextureUsage {
    result : MTLTextureUsage;
    if usage & .SHADER_READ {
        result |= MTLTextureUsageShaderRead;
    }
    if usage & .RENDER_TARGET {
        result |= MTLTextureUsageRenderTarget;
    }

    return result;
}

GFX_Sampler_State :: struct {
    handle : *MTLSamplerState;
}

is_null :: (sampler : *GFX_Sampler_State) -> bool {
    return sampler == null || sampler.handle == null;
}

create_sampler_state :: (name : string, desc : GFX_Sampler_State_Desc) -> GFX_Sampler_State {
    using context.graphics_context;

    mtl_desc := objc_new(MTLSamplerDescriptor);
    defer release(mtl_desc);

    mtl_desc.setMinFilter(mtl_desc, make_metal_sampler_min_mag_filter(desc.min_filter));
    mtl_desc.setMagFilter(mtl_desc, make_metal_sampler_min_mag_filter(desc.mag_filter));
    mtl_desc.setMipFilter(mtl_desc, make_metal_sampler_mip_filter(desc.mip_filter));
    mtl_desc.setMaxAnisotropy(mtl_desc, desc.max_anisotropy);

    mtl_desc.setSAddressMode(mtl_desc, make_metal_sampler_address_mode(desc.u_address_mode));
    mtl_desc.setTAddressMode(mtl_desc, make_metal_sampler_address_mode(desc.v_address_mode));
    mtl_desc.setRAddressMode(mtl_desc, make_metal_sampler_address_mode(desc.w_address_mode));

    if #complete desc.border_color == {
        case .TRANSPARENT;
            mtl_desc.setBorderColor(mtl_desc, MTLSamplerBorderColorTransparentBlack);
        case .OPAQUE_BLACK;
            mtl_desc.setBorderColor(mtl_desc, MTLSamplerBorderColorOpaqueBlack);
        case .OPAQUE_WHITE;
            mtl_desc.setBorderColor(mtl_desc, MTLSamplerBorderColorOpaqueWhite);
    }

    mtl_desc.setNormalizedCoordinates(mtl_desc, 1);
    mtl_desc.setLodMinClamp(mtl_desc, desc.lod_min_clamp);
    mtl_desc.setLodMaxClamp(mtl_desc, desc.lod_max_clamp);
    mtl_desc.setLodAverage(mtl_desc, xx desc.use_average_lod);
    mtl_desc.setCompareFunction(mtl_desc, make_metal_compare_function(desc.compare_func));

    mtl_desc.setLabel(mtl_desc, NSString.getTempString(name));

    result := cast(*MTLSamplerState) device.newSamplerStateWithDescriptor(device, mtl_desc);
    if !result {
        return .{};
    }

    return .{result};
}

destroy_sampler_state :: (using sampler : *GFX_Sampler_State) {
    release(handle);
    handle = null;
}


make_metal_sampler_min_mag_filter :: inline (filter : GFX_Sampler_Filter) -> MTLSamplerMinMagFilter {
    if #complete filter == {
        case .NONE;
            crash("Min/mag filter cannot be NONE");
            return 0;
        case .NEAREST;
            return MTLSamplerMinMagFilterNearest;
        case .LINEAR;
            return MTLSamplerMinMagFilterLinear;
        case .ANISOTROPIC;
            return MTLSamplerMinMagFilterLinear;
    }
}

make_metal_sampler_mip_filter :: inline (filter : GFX_Sampler_Filter) -> MTLSamplerMipFilter{
    if #complete filter == {
        case .NONE;
            return MTLSamplerMipFilterNotMipmapped;
        case .NEAREST;
            return MTLSamplerMipFilterNearest;
        case .LINEAR;
            return MTLSamplerMipFilterLinear;
        case .ANISOTROPIC;
            return MTLSamplerMipFilterLinear;
    }
}

make_metal_sampler_address_mode :: inline (mode : GFX_Sampler_Address_Mode) -> MTLSamplerAddressMode {
    if #complete mode == {
        case .CLAMP_TO_EDGE;
            return MTLSamplerAddressModeClampToEdge;
        case .CLAMP_TO_ZERO;
            return MTLSamplerAddressModeClampToZero;
        case .CLAMP_TO_BORDER;
            return MTLSamplerAddressModeClampToBorderColor;
        case .REPEAT;
            return MTLSamplerAddressModeRepeat;
        case .MIRROR_CLAMP_TO_EDGE;
            return MTLSamplerAddressModeMirrorClampToEdge;
        case .MIRROR_REPEAT;
            return MTLSamplerAddressModeMirrorRepeat;
    }
}








/*


        GREP_Shader

*/



GFX_Shader :: struct {
    loaded_shader   : *GFX_Loaded_Shader;
    library         : *MTLLibrary;
    function        : *MTLFunction;
    bindings        : [] GFX_Pipeline_Binding;
}


is_null :: (shader: *GFX_Shader) -> bool {
    return shader == null || shader.library == null || shader.function == null;
}

load_shader :: (using loaded_shader: *GFX_Loaded_Shader, stage: GFX_Pipeline_Stage, source: string, bindings: []GFX_Pipeline_Binding) -> bool {
    using context.graphics_context;

    stage_flag := cast(GFX_Pipeline_Stage_Flags, 1 << stage);
    stages &= ~stage_flag;

    options := objc_new(MTLCompileOptions);
    defer release(options);

    options.setLanguageVersion(options, MTLLanguageVersion4_0);

    error: *NSError;
    library := device.newLibraryWithSource_options_error(device, NSString.getTempString(source), options, *error);
    if !library {
        log_error("Could not load shader '%':\n%", name, to_string(error.localizedDescription(error)));
        return false;
    }

    VERTEX_ENTRY_POINT      :: "vertex_main";
    FRAGMENT_ENTRY_POINT    :: "fragment_main";

    entry_point_name := ifx stage == .VERTEX then VERTEX_ENTRY_POINT else FRAGMENT_ENTRY_POINT;

    function := library.newFunctionWithName(library, NSString.getTempString(entry_point_name));
    if !function {
        log_error("Function '%' not found in shader '%'", entry_point_name, name);
        return false;
    }

    shader := ifx stage == .VERTEX then *vertex_shader else *fragment_shader;
    if !is_null(shader) {
        destroy_shader(shader);
    }

    shader.loaded_shader    = loaded_shader;
    shader.library          = library;
    shader.function         = xx function;
    shader.bindings         = bindings;
    stages                 |= stage_flag;

    return true;
}

destroy_shader :: (shader: *GFX_Shader) {
    if shader.function {
        release(shader.function);
    }

    if shader.library {
        release(shader.library);
    }

    for shader.bindings {
        free(it.name.data);
    }
    free(shader.bindings.data);

    shader.* = .{};
}

get_loaded_shader :: (shader: *GFX_Shader) -> *GFX_Loaded_Shader {
    return shader.loaded_shader;
}






// Everything about render pass:

// Good read to understand all the command queue/buffer/encoder stuff
// https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Cmd-Submiss/Cmd-Submiss.html

GFX_Render_Pass :: struct {
    encoder : *MTLRenderCommandEncoder;
    desc    : GFX_Render_Pass_Desc;
    name    : string;

    current_primitive_type : MTLPrimitiveType;
}


begin_render_pass :: (pass : *GFX_Render_Pass, name : string, cmd_buffer : *GFX_Command_Buffer, desc : GFX_Render_Pass_Desc) {
    pass.desc = desc;

    pass_desc := MTLRenderPassDescriptor.renderPassDescriptor();
    pass_desc.setRenderTargetArrayLength(pass_desc, desc.render_target_array_length);

    color_attachments := pass_desc.colorAttachments(pass_desc);
    for i : 0..GFX_MAX_COLOR_ATTACHMENTS - 1 {
        if !desc.color_attachments[i] {
            continue;
        }

        assert(!is_null(desc.color_attachments[i]), "Color attachment % is not valid", i);

        attachment := color_attachments.objectAtIndexedSubscript(color_attachments, xx i);
        attachment.setTexture(attachment, xx desc.color_attachments[i].handle);

        if desc.should_clear_color[i] {
            attachment.setLoadAction(attachment, MTLLoadActionClear);
            color := desc.clear_color[i];
            attachment.setClearColor(attachment, MTLClearColorMake(color.x, color.y, color.z, color.w));
        } else {
            attachment.setLoadAction(attachment, MTLLoadActionLoad);
        }

        if !is_null(desc.color_resolve_textures[i]) {
            attachment.setResolveTexture(attachment, xx desc.color_resolve_textures[i].handle);
            attachment.setStoreAction(attachment, MTLStoreActionStoreAndMultisampleResolve);
        }
        else
        {
            attachment.setStoreAction(attachment, MTLStoreActionStore);
        }
    }

    if desc.depth_attachment {
        assert(!is_null(desc.depth_attachment), "Depth attachment is not valid");

        depth_attachment := pass_desc.depthAttachment(pass_desc);
        attachment := *depth_attachment.mtlrenderpassattachmentdescriptor;
        attachment.setTexture(attachment, xx desc.depth_attachment.handle);

        if desc.should_clear_depth {
            attachment.setLoadAction(attachment, MTLLoadActionClear);
            depth_attachment.setClearDepth(depth_attachment, desc.clear_depth);
        } else {
            attachment.setLoadAction(attachment, MTLLoadActionLoad);
        }

        if !is_null(desc.depth_resolve_texture) {
            attachment.setResolveTexture(attachment, xx desc.depth_resolve_texture.handle);
            attachment.setStoreAction(attachment, MTLStoreActionStoreAndMultisampleResolve);
        } else {
            attachment.setStoreAction(attachment, MTLStoreActionStore);
        }
    }

    if desc.stencil_attachment {
        assert(!is_null(desc.stencil_attachment), "Stencil attachment is not valid");

        stencil_attachment := pass_desc.stencilAttachment(pass_desc);
        attachment := *stencil_attachment.mtlrenderpassattachmentdescriptor;
        attachment.setTexture(attachment, xx desc.stencil_attachment.handle);

        if desc.should_clear_stencil {
            attachment.setLoadAction(attachment, MTLLoadActionClear);
            stencil_attachment.setClearStencil(stencil_attachment, desc.clear_stencil);
        } else {
            attachment.setLoadAction(attachment, MTLLoadActionLoad);
        }

        attachment.setStoreAction(attachment, MTLStoreActionStore);
    }

    pass.encoder = cmd_buffer.renderCommandEncoderWithDescriptor(cmd_buffer.handle, pass_desc);

    pass.name = name;
    pass.encoder.setLabel(pass.encoder, NSString.getTempString(tprint("Render Pass '%'", name)));
}

end_render_pass :: (using pass : *GFX_Render_Pass) {
    encoder.endEncoding(encoder);
}

set_viewport :: (using pass : *GFX_Render_Pass, viewport : GFX_Viewport) {
    encoder.setViewport(encoder, .{
        originX = viewport.top_left_x,
        originY = viewport.top_left_y,
        width  = viewport.width,
        height = viewport.height,
        znear = viewport.min_depth,
        zfar  = viewport.max_depth,
    });
}

set_viewports :: (using pass : *GFX_Render_Pass, viewports : []GFX_Viewport) {
    mtl_viewports := NewArray(viewports.count, MTLViewport ,, temp);
    for viewports {
        mtl_viewports[it_index] = .{
            originX = it.top_left_x,
            originY = it.top_left_y,
            width  = it.width,
            height = it.height,
            znear = it.min_depth,
            zfar  = it.max_depth,
        };
    }

    encoder.setViewports_count(encoder, mtl_viewports.data, xx mtl_viewports.count);
}

set_vertex_buffer :: (using pass : *GFX_Render_Pass, index : s32, buffer : *GFX_Buffer, offset : u64, size : u64, stride : u64) {
    if index < 0 {
        return;
    }

    encoder.setVertexBuffer_offset_atIndex(encoder, xx ifx buffer then buffer.handle, offset, xx index);
}

set_buffer :: (using pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, buffer : *GFX_Buffer, offset : u64, size : u64) {
    if binding.index < 0 {
        return;
    }

    if binding.stage == {
        case .VERTEX;
            encoder.setVertexBuffer_offset_atIndex(encoder, xx ifx buffer then buffer.handle, offset, xx binding.index);
        case .FRAGMENT;
            encoder.setFragmentBuffer_offset_atIndex(encoder, xx ifx buffer then buffer.handle, offset, xx binding.index);
    }
}

set_texture :: (using pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, texture : *GFX_Texture, fallback: *GFX_Texture = null) {
    if binding.index < 0 {
        return;
    }

    texture_handle := ifx is_null(texture) fallback else texture;

    if binding.stage == {
        case .VERTEX;
            encoder.setVertexTexture_atIndex(encoder, xx ifx texture_handle then texture_handle.handle, xx binding.index);
        case .FRAGMENT;
            encoder.setFragmentTexture_atIndex(encoder, xx ifx texture_handle then texture_handle.handle, xx binding.index);
    }


}

set_sampler_state :: (using pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, sampler : *GFX_Sampler_State) {
    if binding.index < 0 {
        return;
    }

    if binding.stage == {
        case .VERTEX;
            encoder.setVertexSamplerState_atIndex(encoder, xx ifx sampler then sampler.handle, xx binding.index);
        case .FRAGMENT;
            encoder.setFragmentSamplerState_atIndex(encoder, xx ifx sampler then sampler.handle, xx binding.index);
    }
}

draw :: (
    using pass      : *GFX_Render_Pass,
    vertex_count    : u32,
    instance_count  : u32,
    base_vertex     : u32 = 0,
    base_instance   : u32 = 0,
    primitive_type  : GFX_Draw_Primitive = .TRIANGLE
) {
    drawPrimitives :: encoder.drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance;

    submit_gfx_state_to_pass(pass.encoder);

    mesh_draw_calls += 1;

    drawPrimitives(encoder,
        to_metal_primitive_type(primitive_type),
        base_vertex, vertex_count,
        instance_count, base_instance
    );
}

draw_indexed :: (
    using pass : *GFX_Render_Pass,
    index_buffer : *GFX_Buffer,
    index_count : u32,
    index_type : GFX_Index_Type,
    instance_count : u32,
    base_index : u32 = 0,
    base_vertex : u32 = 0,
    base_instance : u32 = 0,
    primitive_type  : GFX_Draw_Primitive = .TRIANGLE
) {
    drawIndexedPrimitives :: encoder.drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance;

    submit_gfx_state_to_pass(pass.encoder);

    mesh_draw_calls += 1;

    drawIndexedPrimitives(encoder,
        to_metal_primitive_type(primitive_type),
        indexCount=index_count,
        indexType=ifx index_type == .UINT16 then MTLIndexTypeUInt16 else MTLIndexTypeUInt32,
        indexBuffer=xx index_buffer.handle,
        indexBufferOffset=xx ifx index_type == .UINT16 then base_index * 2 else base_index * 4,
        instanceCount=instance_count,
        baseVertex=base_vertex,
        baseInstance=base_instance,
    );
}


submit_gfx_state_to_pass :: (encoder: *MTLRenderCommandEncoder) {
    pso_key     := hash_pso_metal_data(render_state);
    depth_key   := hash_depth_stencil_metal_data(render_state);

    pso, pso_newly_added            := find_or_add(*pso_table, pso_key);
    depth_state, depth_newly_added  := find_or_add(*depth_stencil_table, depth_key);

    if pso_newly_added {
        pso.* = make_metal_pso(*render_state);

        callback            : GFX_Shader_Reload_Callback;
        callback.pso_key    = pso_key;
        callback.proc       = (shader, pso_key) => {
            success, pso_removed := table_remove(*pso_table, pso_key);
            if success then release(pso_removed);
        };

        if render_state.vertex_shader {
            add_shader_reload_callback(render_state.vertex_shader.loaded_shader, callback);
        }
        if render_state.pixel_shader {
            add_shader_reload_callback(render_state.pixel_shader.loaded_shader, callback);
        }
    }

    if depth_newly_added {
        depth_state.* = make_metal_depth_stencil_state(*render_state);
    }

    encoder.setRenderPipelineState(encoder,   cast(*NSObject, pso.*));
    encoder.setDepthStencilState(encoder,     cast(*NSObject, depth_state.*));

    if render_state.stencil_enabled {
        encoder.setStencilFrontReferenceValue_backReferenceValue(encoder, render_state.stencil_ref, render_state.stencil_ref);
    }


    if render_state.scissor_enabled {
        encoder.setScissorRect(encoder, .{
            x       = xx render_state.scissor_rect.x,
            y       = xx render_state.scissor_rect.y,
            width   = xx render_state.scissor_rect.w,
            height  = xx render_state.scissor_rect.h,
        });
    }

    if #complete render_state.winding_order == {
        case .CW;  encoder.setFrontFacingWinding(encoder, MTLWindingClockwise);
        case .CCW; encoder.setFrontFacingWinding(encoder, MTLWindingCounterClockwise);
    }

    if #complete render_state.cull_face == {
        case .NONE;  encoder.setCullMode(encoder, MTLCullModeNone);
        case .FRONT; encoder.setCullMode(encoder, MTLCullModeFront);
        case .BACK;  encoder.setCullMode(encoder, MTLCullModeBack);
    }

    if #complete render_state.fill_mode == {
        case .FILL;  encoder.setTriangleFillMode(encoder, MTLTriangleFillModeFill);
        case .LINES; encoder.setTriangleFillMode(encoder, MTLTriangleFillModeLines);
    }
}




// Copy pass:


GFX_Copy_Pass :: struct {
    encoder : *MTLBlitCommandEncoder;
}

begin_copy_pass :: (using pass : *GFX_Copy_Pass, name : string, cmd_buffer : *GFX_Command_Buffer) {
    encoder = cmd_buffer.blitCommandEncoder(cmd_buffer.handle);
    begin_debug_group(cmd_buffer, tprint("Copy Pass '%'", name));
}

end_copy_pass :: (using pass : *GFX_Copy_Pass) {
    MTLCommandEncoder.endEncoding(xx encoder);

    gfx_encoder := GFX_Command_Buffer.{ handle = xx pass.encoder };
    end_debug_group(*gfx_encoder);
}

generate_mipmaps :: (using pass : *GFX_Copy_Pass, texture : Texture) {
    if texture.texture_index >= 0 {
        view := cast(*MTLTexture, MTLTexture.newTextureViewWithPixelFormat_textureType_levels_slices(
            texture.gfx_handle.handle,
            make_metal_pixel_format(texture.gfx_handle.desc.pixel_format),
            MTLTextureType2D,
            NSRange.{ 0, texture.gfx_handle.desc.num_mipmap_levels },
            NSRange.{ xx texture.texture_index, 1 }
        ));

        encoder.generateMipmapsForTexture(encoder, xx view);

    } else {
        encoder.generateMipmapsForTexture(encoder, xx texture.gfx_handle.handle);
    }
}

copy_texture :: (using pass : *GFX_Copy_Pass, source : *GFX_Texture, dest : *GFX_Texture) {
    MTLBlitCommandEncoder.copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin(
        encoder,
        sourceTexture= cast(*NSObject, source.handle),
        sourceSlice=0,
        sourceLevel=0,
        sourceOrigin=.{ 0, 0, 0 },
        sourceSize=.{ source.width, source.height, 1 },
        destinationTexture= cast(*NSObject, dest.handle),
        destinationSlice=0,
        destinationLevel=0,
        destinationOrigin=.{ 0, 0, 0 }
    );
}



#scope_file;

make_metal_depth_stencil_state :: (using render_state: *Render_State) -> *MTLDepthStencilState {
    using context.graphics_context;

    desc := objc_new(MTLDepthStencilDescriptor);
    defer release(desc);

    if depth_enabled {
        desc.setDepthCompareFunction(desc, to_metal_compare_func(depth_comp));
    } else {
        desc.setDepthCompareFunction(desc, .MTLCompareFunctionAlways);
    }

    desc.setDepthWriteEnabled(desc, xx depth_write);

    if stencil_enabled {
        front_stencil_desc  := objc_new(MTLStencilDescriptor);
        back_stencil_desc   := objc_new(MTLStencilDescriptor);

        defer release(front_stencil_desc);
        defer release(back_stencil_desc);

        _metal_fill_up_stencil_desc(front_stencil_desc, stencil_front, stencil_read_mask, stencil_write_mask);
        desc.setFrontFaceStencil(desc, front_stencil_desc);

        _metal_fill_up_stencil_desc(back_stencil_desc, stencil_back, stencil_read_mask, stencil_write_mask);
        desc.setBackFaceStencil(desc, back_stencil_desc);
    }

    depth_state := cast(*MTLDepthStencilState) device.newDepthStencilStateWithDescriptor(device, desc);
    assert(depth_state != null);

    return depth_state;
}

make_metal_pso :: (using render_state: *Render_State) -> *MTLRenderPipelineState {
    using context.graphics_context;

    error : *NSError;

    desc := objc_new(MTLRenderPipelineDescriptor);
    defer release(desc);

    desc.setLabel(desc, NSString.getTempString(tprint("Pipeline State '%'", name)));
    desc.setRasterSampleCount(desc, sample_count);

    if vertex_shader {
        desc.setVertexFunction(desc, xx vertex_shader.function);
    }

    if pixel_shader {
        desc.setFragmentFunction(desc, xx pixel_shader.function);
    }

    color_attachments := MTLRenderPipelineDescriptor.colorAttachments(desc);

    for i : 0..GFX_MAX_COLOR_ATTACHMENTS - 1 {
        color_format    := cast(GFX_Pixel_Format) color_formats[i];
        if color_format == .INVALID continue;

        attachment := color_attachments.objectAtIndexedSubscript(color_attachments, xx i);
        attachment.setPixelFormat(attachment, make_metal_pixel_format(color_format));

        blend_mode := cast(Blend_Mode, blend_modes[i]);

        if #complete blend_mode == {
            case .NONE;
                attachment.setBlendingEnabled(attachment, xx false);
            case .ALPHA;
                attachment.setBlendingEnabled(attachment, xx true);
                attachment.setSourceRGBBlendFactor(attachment, .MTLBlendFactorSourceAlpha);
                attachment.setSourceAlphaBlendFactor(attachment, .MTLBlendFactorSourceAlpha);
                attachment.setDestinationRGBBlendFactor(attachment, .MTLBlendFactorOneMinusSourceColor);
                attachment.setDestinationAlphaBlendFactor(attachment, .MTLBlendFactorOneMinusSourceColor);
                attachment.setRgbBlendOperation(attachment, .MTLBlendOperationAdd);
                attachment.setAlphaBlendOperation(attachment, .MTLBlendOperationAdd);
            case .ADDITIVE;
                attachment.setBlendingEnabled(attachment, xx true);

                attachment.setSourceRGBBlendFactor(attachment, .MTLBlendFactorSourceAlpha);

                attachment.setDestinationRGBBlendFactor(attachment, .MTLBlendFactorOneMinusSourceAlpha);
                attachment.setSourceAlphaBlendFactor(attachment, .MTLBlendFactorOne);
                attachment.setDestinationAlphaBlendFactor(attachment, .MTLBlendFactorOneMinusSourceAlpha);

                attachment.setRgbBlendOperation(attachment, .MTLBlendOperationAdd);
                attachment.setAlphaBlendOperation(attachment, .MTLBlendOperationAdd);

        }
    }

    if #complete cast(GFX_Topology_Primitive_Type, topology) == {
        case .INVALID;
            assert(false, "Topology is set to invalid.");
        case .TRIANGLE;
            desc.setInputPrimitiveTopology(desc, MTLPrimitiveTopologyClassTriangle);
        case .POINT;
            desc.setInputPrimitiveTopology(desc, MTLPrimitiveTopologyClassPoint);
        case .LINE;
            desc.setInputPrimitiveTopology(desc, MTLPrimitiveTopologyClassLine);
    }

    if depth_stencil_format != .INVALID {
        pixel_format := make_metal_pixel_format(depth_stencil_format);

        has_depth    := depth_stencil_format == .DEPTH_FLOAT32_STENCIL_8 ||
                        depth_stencil_format == .DEPTH_FLOAT32;
        has_stencil  := depth_stencil_format == .DEPTH_FLOAT32_STENCIL_8 ||
                        depth_stencil_format == .STENCIL_8;

        if has_depth   then desc.setDepthAttachmentPixelFormat(desc, pixel_format);
        if has_stencil then desc.setStencilAttachmentPixelFormat(desc, pixel_format);
    }


    {
        input_desc := objc_new(MTLVertexDescriptor);
        defer release(input_desc);

        attributes := input_desc.attributes(input_desc);
        layouts := input_desc.layouts(input_desc);

        for vertex_layout {
            attribute := attributes.objectAtIndexedSubscript(attributes, xx it.attribute_index);
            layout    := layouts.objectAtIndexedSubscript(layouts, xx it.buffer_index);

            attribute.setFormat(attribute, make_metal_vertex_format(it.format, it.normalized));
            attribute.setOffset(attribute, xx it.offset);
            attribute.setBufferIndex(attribute, xx it.buffer_index);
            layout.setStride(layout, xx it.stride);
        }

        desc.setVertexDescriptor(desc, input_desc);

    }



    pipeline_state := cast(*MTLRenderPipelineState) device.newRenderPipelineStateWithDescriptor_error(device, desc, *error);

    if !pipeline_state {
        log_error("Failed to create MTLRenderPipelineState for '%': %",
        name, to_string(error.localizedDescription(error)));
    }

    return pipeline_state;
}


to_metal_compare_func :: (comp_func: GFX_Compare_Func) -> MTLCompareFunction {
    if #complete comp_func == {
        case .NONE; #through;
        case .NEVER;            return .MTLCompareFunctionNever;
        case .LESS;             return .MTLCompareFunctionLess;
        case .LESS_EQUAL;       return .MTLCompareFunctionLessEqual;
        case .GREATER;          return .MTLCompareFunctionGreater;
        case .GREATER_EQUAL;    return .MTLCompareFunctionGreaterEqual;
        case .EQUAL;            return .MTLCompareFunctionEqual;
        case .NOT_EQUAL;        return .MTLCompareFunctionNotEqual;
        case .ALWAYS;           return .MTLCompareFunctionAlways;
    }
}

to_metal_stencil_op :: (stencil_op: GFX_Stencil_Operation) -> MTLStencilOperation {
    if #complete stencil_op == {
        case .KEEP;             return .MTLStencilOperationKeep;
        case .ZERO;             return .MTLStencilOperationZero;
        case .REPLACE;          return .MTLStencilOperationReplace;
        case .INCREMENT;        return .MTLStencilOperationIncrementClamp;
        case .INCREMENT_WRAP;   return .MTLStencilOperationIncrementWrap;
        case .DECREMENT;        return .MTLStencilOperationDecrementClamp;
        case .DECREMENT_WRAP;   return .MTLStencilOperationDecrementWrap;
        case .INVERT;           return .MTLStencilOperationInvert;
    }
}

to_metal_primitive_type :: (prim: GFX_Draw_Primitive) -> MTLPrimitiveType {
    if #complete prim == {
        case .POINT;            return MTLPrimitiveTypePoint;
        case .LINE;             return MTLPrimitiveTypeLine;
        case .LINE_STRIP;      return MTLPrimitiveTypeLineStrip;
        case .TRIANGLE;         return MTLPrimitiveTypeTriangle;
        case .TRIANGLE_STRIP;  return MTLPrimitiveTypeTriangleStrip;
    }
}



hash_depth_stencil_metal_data :: (key: Render_State) -> Depth_Stencil_Key {
    hash  := fnv1a_hash(cast(u64) key.depth_enabled);
    hash   = fnv1a_hash(cast(u64) key.depth_write, hash);

    if key.depth_enabled {
        hash   = fnv1a_hash(cast(u64) key.depth_comp, hash);
    }

    if key.stencil_enabled {
        hash  = fnv1a_hash(cast(u64) key.stencil_enabled, hash);
        hash  = fnv1a_hash(cast(u64) key.stencil_front, hash);
        hash  = fnv1a_hash(cast(u64) key.stencil_back, hash);
    }

    upper_half := cast, trunc(u32) (hash >> 32);
    lower_half := cast, trunc(u32) hash;

    return upper_half ^ lower_half;
}

hash_pso_metal_data :: (key: Render_State) -> PSO_Key {
    hash: u64;

    if key.vertex_shader != null {
        hash = fnv1a_hash(cast(u64) key.vertex_shader.function);
    }

    if key.pixel_shader != null {
        hash  = fnv1a_hash(cast(u64) key.pixel_shader.function, hash);
    }

    hash  = fnv1a_hash(cast(u64) key.topology, hash);
    hash  = fnv1a_hash(cast(u64) key.sample_count, hash);

    // Here, we could cast them to u32 'cause it's currently an array of 4 u8.
    for key.color_formats {
        hash = fnv1a_hash(cast(u64) it, hash);
    }

    // Here, we could cast them to u32 'cause it's currently an array of 4 u8.
    for key.blend_modes {
        hash = fnv1a_hash(cast(u64) it, hash);
    }

    hash = fnv1a_hash(cast(u64) key.depth_stencil_format, hash);

    for * key.vertex_layout {
        hash = fnv1a_hash(it, size_of(GFX_Vertex_Input_Desc), hash);
    }

    // A simple cast to 32-bit number would trash half of the hash.
    // Here, we split the 64-bit value into two 32-bit values
    // then blend them together instead.
    upper_half := cast, trunc(u32) (hash >> 32);
    lower_half := cast, trunc(u32) hash;

    return upper_half ^ lower_half;
};

_metal_fill_up_stencil_desc :: (desc: *MTLStencilDescriptor, packed_values: u16, read_mask: u8, write_mask: u8) {
    _3bit_mask  : u8  = 0x07;
    _4bit_mask  : u8  = 0xF;

    // Unpack stencil values.
    stencil_failed              := (packed_values >> 0) & _3bit_mask;
    stencil_passed_depth_failed := (packed_values >> 3) & _3bit_mask;
    stencil_passed_depth_passed := (packed_values >> 6) & _3bit_mask;
    comp_func                   := (packed_values >> 9) & _4bit_mask;

    desc.setStencilFailureOperation(desc, to_metal_stencil_op(xx stencil_failed));
    desc.setDepthFailureOperation(desc, to_metal_stencil_op(xx stencil_passed_depth_failed));
    desc.setDepthStencilPassOperation(desc, to_metal_stencil_op(xx stencil_passed_depth_passed));
    desc.setStencilCompareFunction(desc, to_metal_compare_func(xx comp_func));
    desc.setWriteMask(desc, cast(u32, write_mask));
    desc.setReadMask(desc,  cast(u32, read_mask));
}


make_metal_blend_operation :: inline (op : GFX_Blend_Operation) -> MTLBlendOperation {
    if #complete op == {
        case .ADD;
            return MTLBlendOperationAdd;
        case .SUBTRACT;
            return MTLBlendOperationSubtract;
        case .REVERSE_SUBTRACT;
            return MTLBlendOperationReverseSubtract;
        case .MIN;
            return MTLBlendOperationMin;
        case .MAX;
            return MTLBlendOperationMax;
    }
}

make_metal_blend_factor :: inline (factor : GFX_Blend_Factor) -> MTLBlendFactor {
    if #complete factor == {
        case .ONE;
            return MTLBlendFactorOne;
        case .ZERO;
            return MTLBlendFactorZero;
        case .SRC_COLOR;
            return MTLBlendFactorSourceColor;
        case .ONE_MINUS_SRC_COLOR;
            return MTLBlendFactorOneMinusSourceColor;
        case .DST_COLOR;
            return MTLBlendFactorDestinationColor;
        case .ONE_MINUS_DST_COLOR;
            return MTLBlendFactorOneMinusDestinationColor;
        case .SRC_ALPHA;
            return MTLBlendFactorSourceAlpha;
        case .ONE_MINUS_SRC_ALPHA;
            return MTLBlendFactorOneMinusSourceAlpha;
        case .DST_ALPHA;
            return MTLBlendFactorDestinationAlpha;
        case .ONE_MINUS_DST_ALPHA;
            return MTLBlendFactorOneMinusDestinationAlpha;
        case .CONSTANT_COLOR;
            return MTLBlendFactorBlendColor;
        case .ONE_MINUS_CONSTANT_COLOR;
            return MTLBlendFactorOneMinusBlendColor;
        case .CONSTANT_ALPHA;
            return MTLBlendFactorBlendAlpha;
        case .ONE_MINUS_CONSTANT_ALPHA;
            return MTLBlendFactorOneMinusBlendAlpha;
        case .SRC_ALPHA_SATURATE;
            return MTLBlendFactorSourceAlphaSaturated;
        case .SRC1_COLOR;
            return MTLBlendFactorSource1Color;
        case .ONE_MINUS_SRC1_COLOR;
            return MTLBlendFactorOneMinusSource1Color;
        case .SRC1_ALPHA;
            return MTLBlendFactorSource1Alpha;
        case .ONE_MINUS_SRC1_ALPHA;
            return MTLBlendFactorOneMinusSource1Alpha;
    }
}

make_metal_vertex_format :: inline (format : GFX_Vertex_Format, normalized : bool) -> MTLVertexFormat {
    if #complete format == {
        case .INVALID;
            return MTLVertexFormatInvalid;
        case .FLOAT;
            return MTLVertexFormatFloat;
        case .FLOAT2;
            return MTLVertexFormatFloat2;
        case .FLOAT3;
            return MTLVertexFormatFloat3;
        case .FLOAT4;
            return MTLVertexFormatFloat4;
        case .CHAR2;
            return ifx normalized then MTLVertexFormatChar2Normalized else MTLVertexFormatChar2;
        case .CHAR4;
            return ifx normalized then MTLVertexFormatChar4Normalized else MTLVertexFormatChar4;
        case .UCHAR2;
            return ifx normalized then MTLVertexFormatUChar2Normalized else MTLVertexFormatUChar2;
        case .UCHAR4;
            return ifx normalized then MTLVertexFormatUChar4Normalized else MTLVertexFormatUChar4;
        case .SHORT2;
            return ifx normalized then MTLVertexFormatShort2Normalized else MTLVertexFormatShort2;
        case .SHORT4;
            return ifx normalized then MTLVertexFormatShort4Normalized else MTLVertexFormatShort4;
        case .USHORT2;
            return ifx normalized then MTLVertexFormatUShort2Normalized else MTLVertexFormatUShort2;
        case .USHORT4;
            return ifx normalized then MTLVertexFormatUShort4Normalized else MTLVertexFormatUShort4;
        case .INT;
            return MTLVertexFormatInt;
        case .INT2;
            return MTLVertexFormatInt2;
        case .INT3;
            return MTLVertexFormatInt3;
        case .INT4;
            return MTLVertexFormatInt4;
        case .UINT;
            return MTLVertexFormatUInt;
        case .UINT2;
            return MTLVertexFormatUInt2;
        case .UINT3;
            return MTLVertexFormatUInt3;
        case .UINT4;
            return MTLVertexFormatUInt4;
    }
}

make_metal_compare_function :: inline (func : GFX_Compare_Func) -> MTLCompareFunction {
    if #complete func == {
        case .NONE;
            return MTLCompareFunctionNever;
        case .NEVER;
            return MTLCompareFunctionNever;
        case .LESS;
            return MTLCompareFunctionLess;
        case .EQUAL;
            return MTLCompareFunctionEqual;
        case .LESS_EQUAL;
            return MTLCompareFunctionLessEqual;
        case .GREATER;
            return MTLCompareFunctionGreater;
        case .NOT_EQUAL;
            return MTLCompareFunctionNotEqual;
        case .GREATER_EQUAL;
            return MTLCompareFunctionGreaterEqual;
        case .ALWAYS;
            return MTLCompareFunctionAlways;
    }
}

make_metal_stencil_operation :: inline (op : GFX_Stencil_Operation) -> MTLStencilOperation {
    if #complete op == {
        case .KEEP;
            return MTLStencilOperationKeep;
        case .ZERO;
            return MTLStencilOperationZero;
        case .REPLACE;
            return MTLStencilOperationReplace;
        case .INCREMENT;
            return MTLStencilOperationIncrementClamp;
        case .INCREMENT_WRAP;
            return MTLStencilOperationIncrementWrap;
        case .DECREMENT;
            return MTLStencilOperationDecrementClamp;
        case .DECREMENT_WRAP;
            return MTLStencilOperationDecrementWrap;
        case .INVERT;
            return MTLStencilOperationInvert;
    }
}

using, except(Category) OBJC :: #import "Objective_C";

#import "Objective_C/AppKit";
#import, dir "bindings/Metal";
