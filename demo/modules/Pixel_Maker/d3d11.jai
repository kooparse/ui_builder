GFX_Window :: HWND;

GFX_Context :: struct {
    device      : *ID3D11Device;
    swapchain   : *IDXGISwapChain;
    d3d_context : *ID3D11DeviceContext1;

    backbuffer  : GFX_Texture;
    backbuffer_index : int;

    d3d_annotation: *ID3DUserDefinedAnnotation;

    capabilities : GFX_Capabilities;

    // frame_time_queries  : [MAX_FRAME_IN_FLIGHT][2]GLuint;
    // last_frame_time     : float;

    feature_level   : D3D_FEATURE_LEVEL;


    window: HWND;

    // If swapchain bounds differ from window bounds, we trigger a swapchain
    // resize.
    swapchain_width  : s32;
    swapchain_height : s32;
};


#add_context graphics_context: *GFX_Context;



create_context :: (hwnd: *void) -> bool {
    assert(context.graphics_context == null);

    using ctx := New(GFX_Context);
    context.graphics_context = ctx;

    window = cast(HWND) hwnd;

    client_rect: RECT;
    GetClientRect(window, *client_rect);

    swapchain_width  = client_rect.right  - client_rect.left;
    swapchain_height = client_rect.bottom - client_rect.top;

    sd : DXGI_SWAP_CHAIN_DESC;
    sd.BufferCount = 1;
    sd.BufferDesc.Width  = xx swapchain_width ;
    sd.BufferDesc.Height = xx swapchain_height;
    sd.BufferDesc.Format = .R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.BufferUsage = .RENDER_TARGET_OUTPUT;
    sd.OutputWindow = ctx.window;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = BOOL.TRUE;

    hr             : HRESULT;
    feature_levels := D3D_FEATURE_LEVEL.[._11_1, ._11_0, ._10_1, ._10_0];
    flags          :  D3D11_CREATE_DEVICE_FLAG;

    #if DEBUG_LAYER {
        flags |= (.D3D11_CREATE_DEVICE_DEBUG | .DEBUG);
    }

    adapter, name := find_best_gpu();
    log("GPU: %", name);

    hr = D3D11CreateDeviceAndSwapChain(adapter, .UNKNOWN, null,
                                    xx flags, feature_levels.data, feature_levels.count, D3D11_SDK_VERSION,
                                      *sd, *swapchain, *device, *feature_level, cast(**ID3D11DeviceContext) *d3d_context);

    if FAILED(hr) {
        log_error("Creating D3D11 Device and Swapchain failed.");
        return false;
    }

    {
        options3 : D3D11_FEATURE_DATA_D3D11_OPTIONS3;
        hr = ID3D11Device_CheckFeatureSupport(device, .D3D11_OPTIONS3, *options3, size_of(type_of(options3)));
    }


    hr = IDXGISwapChain_GetBuffer(swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *backbuffer.handle);
    if FAILED(hr) {
        log_error("GetBuffer failed: %", hr);
        return false;
    }

    hr = ID3D11Device_CreateRenderTargetView(device, backbuffer.handle, null, *backbuffer.rtv);
    if FAILED(hr) {
        log_error("CreateRenderTargetView failed: %", hr);
        return false;
    }

    hr = IUnknown_QueryInterface(cast(*IUnknown) d3d_context, *uid(ID3DUserDefinedAnnotation_UUID), xx *d3d_annotation);
    if FAILED(hr) {
        log_error("Cannot find Annotation interface: %", get_hr_error_string(hr));
        return false;
    }

    return true;
}

destroy_context :: () {
    using context.graphics_context;

    ID3D11DeviceContext_ClearState(d3d_context);
    ID3D11DeviceContext_Flush(d3d_context);

    IUnknown_Release(swapchain);
    IUnknown_Release(d3d_context);
    IUnknown_Release(device);

    free(context.graphics_context);
    context.graphics_context = null;
}

get_swapchain_texture :: () -> *GFX_Texture {
    return *context.graphics_context.backbuffer;
}

get_swapchain_pixel_format :: () -> GFX_Pixel_Format {
    using context.graphics_context;

    desc : DXGI_SWAP_CHAIN_DESC;
    hr := IDXGISwapChain_GetDesc(swapchain, *desc);
    assert(SUCCEEDED(hr));

    return d3d_pixel_format(desc.BufferDesc.Format);
}

get_swapchain_interval :: () -> s32 {
    return 0;

    // using context.graphics_context;
    //
    // interval := SDL_GL_GetSwapInterval();
    //
    // return interval;
}

set_swapchain_interval :: (interval : s32) {
    // using context.graphics_context;
    //
    // SDL_GL_SetSwapInterval(interval);
}

begin_frame :: () {
    using context.graphics_context;

    gpu_frame_count += 1;

    // If window was resized, we resize the swapchain buffer as well.
    {
        client_rect: RECT;
        GetClientRect(window, *client_rect);

        window_width  := client_rect.right  - client_rect.left;
        window_height := client_rect.bottom - client_rect.top;

        if window_width != swapchain_width || window_height != swapchain_height {
            // Release everything first.
            ID3D11DeviceContext_OMSetRenderTargets(d3d_context, 0, null, null);
            IUnknown_Release(cast(*IUnknown) backbuffer.rtv);
            IUnknown_Release(cast(*IUnknown) backbuffer.handle);
            backbuffer.rtv    = null;
            backbuffer.handle = null;

            hr : HRESULT;
            IDXGISwapChain_ResizeBuffers(swapchain, 1, xx window_width, xx window_height, .UNKNOWN, 0x0);

            if FAILED(hr) {
                log_error("ResizeBuffers failed: %", hr);
                return;
            }

            hr = IDXGISwapChain_GetBuffer(swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *backbuffer.handle);
            if FAILED(hr) {
                log_error("GetBuffer failed: %", hr);
                return;
            }

            hr = ID3D11Device_CreateRenderTargetView(device, backbuffer.handle, null, *backbuffer.rtv);
            if FAILED(hr) {
                log_error("CreateRenderTargetView failed: %", hr);
                return;
            }


            swapchain_width  = window_width;
            swapchain_height = window_height;
        }
    }


    for srv_offset_table {
        if it != null then IUnknown_Release(it);
    }

    table_reset(*srv_offset_table);
}

present :: () {
    using context.graphics_context;

    hr := IDXGISwapChain_Present(swapchain, 0, 0);
    if FAILED(hr) then assert(false, "Present frame failed: %", get_hr_error_string(hr));

    backbuffer_index = (backbuffer_index + 1) % MAX_FRAME_IN_FLIGHT;
}

get_backbuffer_index :: () -> int {
    return context.graphics_context.backbuffer_index;
}

get_last_frame_gpu_time :: () -> float {
    // using context.graphics_context;
    //
    // return last_frame_time;
    return 0;
}

get_capabilities :: () -> GFX_Capabilities {
    using context.graphics_context;

    if capabilities.max_texture_size {
        return capabilities;
    }

    capabilities.max_texture_size         = D3D11_REQ_TEXTURE2D_U_OR_V_DIMENSION;
    capabilities.max_texture_3d_size      = D3D11_REQ_TEXTURE3D_U_V_OR_W_DIMENSION;
    capabilities.max_texture_array_length = D3D11_REQ_TEXTURE2D_ARRAY_AXIS_DIMENSION;
    capabilities.max_texture_samples      = D3D11_MAX_MULTISAMPLE_SAMPLE_COUNT;
    capabilities.max_attributes           = D3D11_IA_VERTEX_INPUT_RESOURCE_SLOT_COUNT;
    capabilities.max_textures             = D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT;
    capabilities.max_sampler_states       = D3D11_COMMONSHADER_SAMPLER_SLOT_COUNT;
    capabilities.max_buffers              = D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT;
    capabilities.max_constant_buffer_size = D3D11_REQ_CONSTANT_BUFFER_ELEMENT_COUNT * 16;

    return capabilities;
}


GFX_Command_Buffer :: struct {
    handle: *void;
}


create_command_buffer :: (name : string) -> GFX_Command_Buffer {
    return .{};
}

submit_command_buffer :: (cmd_buffer : *GFX_Command_Buffer) {
}

begin_debug_group :: (cmd_buffer : *GFX_Command_Buffer, name : string) {
    using context.graphics_context;

    wide_string := Utf8.utf8_to_wide(name ,, temp);
    ID3DUserDefinedAnnotation_BeginEvent(d3d_annotation, cast(*s16) wide_string);
}

end_debug_group :: (cmd_buffer : *GFX_Command_Buffer) {
    using context.graphics_context;
    ID3DUserDefinedAnnotation_EndEvent(d3d_annotation);
}


find_best_gpu :: () -> *IDXGIAdapter, string {
    dxgi_factory : *IDXGIFactory;
    hr := CreateDXGIFactory(uid(IDXGIFactory_UUID), xx *dxgi_factory);
    if !SUCCEEDED(hr) return null, "";

    best_adapter : *IDXGIAdapter = null;
    gpu_name     : string;
    highest_vram := S64_MIN;

    i : u32 = 0;
    while true {
        defer i += 1;

        dxgi_adapter: *IDXGIAdapter;
        hr = IDXGIFactory_EnumAdapters(dxgi_factory, i, *dxgi_adapter);
        if !SUCCEEDED(hr) || dxgi_adapter == null break;

        dxgi_adapter_desc: DXGI_ADAPTER_DESC;
        hr = IDXGIAdapter_GetDesc(dxgi_adapter, *dxgi_adapter_desc);
        assert(SUCCEEDED(hr));

        vram := cast(s64) dxgi_adapter_desc.DedicatedVideoMemory;

        if vram > highest_vram {
            if best_adapter then IUnknown_Release(best_adapter);

            best_adapter = dxgi_adapter;
            highest_vram = vram;
            gpu_name     = wide_to_utf8(cast(*u16) *dxgi_adapter_desc.Description[0] ,, temp);
        }
    }

    IUnknown_Release(dxgi_factory);

    return best_adapter, gpu_name;
}


get_hr_error_string :: (hr: HRESULT) -> string {
    error_msg := get_error_string(xx cast,no_check(u32, hr));
    return sprint("Window Error; %", error_msg ,, temp);
}




/*

    On DirectX Readback buffer are simply GFX_Texture that we map/unmap at the
    reading moment.

*/

GFX_Readback_Buffer :: GFX_Texture;

lock_readbackbuffer :: (using resource: *GFX_Readback_Buffer, map_access: GFX_Map_Access_Flags) {
    using context.graphics_context;

    assert(resource.locked == false, "GPU Readback Buffer was already locked!");

    hr          : HRESULT;
    map_flags   : D3D11_MAP;

    map_buffer : D3D11_MAPPED_SUBRESOURCE;

    if #complete map_access == {
        case .READ;             map_flags = .READ;
        case .WRITE_AND_FLUSH;  map_flags = .WRITE_DISCARD;
        case .WRITE_NO_FLUSH;   map_flags = .WRITE_NO_OVERWRITE;
    }

    hr = ID3D11DeviceContext_Map(d3d_context, resource.handle, 0, map_flags, 0, *map_buffer);

    resource.locked          = true;
    resource.data_row_pitch  = cast(s32, map_buffer.RowPitch);
    resource.data_ptr        = map_buffer.pData;
}

unlock_readbackbuffer :: (resource : *GFX_Readback_Buffer) {
    using context.graphics_context;

    resource.locked = false;
    ID3D11DeviceContext_Unmap(d3d_context, resource.handle, 0);
}

copy_texture_to_readbackbuffer :: (using pass : *GFX_Copy_Pass, source : *GFX_Texture, dest : *GFX_Readback_Buffer) {
    copy_texture(pass, source = source, dest = dest);
}

create_readbackbuffer :: (name : string, desc: GFX_Texture_Desc) -> GFX_Readback_Buffer {
    return create_texture(name, desc);
}

destroy_readbackbuffer :: (buffer: *GFX_Readback_Buffer) {
    destroy_texture(buffer);
}




GFX_Buffer :: struct {
    #as handle  : *ID3D11Buffer;

    srv         : *ID3D11ShaderResourceView;

    stride      : u32;

    locked      : bool;
    data_ptr    : *void;
    size        : u64;
};

is_null :: (buffer : *GFX_Buffer) -> bool {
    return buffer == null || buffer.handle == null;
}

// gfx_create_buffer
create_buffer :: (name : string, size : u64, stride: u32, data : *void, storage_flags : GFX_Storage_Flags, bind_flags: GFX_Bind_Flags) -> GFX_Buffer {
    using context.graphics_context;

    hr  : HRESULT;

    bd  : D3D11_BUFFER_DESC;
    bd.ByteWidth = cast(u32, size);

    if bind_flags & .SHADER_RESOURCE {
        bd.StructureByteStride = stride;
        bd.MiscFlags |= .BUFFER_STRUCTURED;
    }

    if storage_flags & .CPU_WRITE {
        bd.Usage           = .DYNAMIC;
        bd.CPUAccessFlags |= .WRITE;
    } else if storage_flags & .CPU_READ {
        bd.Usage           = .STAGING;
        bd.CPUAccessFlags |= .READ;
    } else {
        bd.Usage = .DEFAULT;
    }


    if bind_flags & .VERTEX_BUFFER {
        bd.BindFlags |= .VERTEX_BUFFER;
    }

    if bind_flags & .INDEX_BUFFER {
        bd.BindFlags |= .INDEX_BUFFER;
    }

    if bind_flags & .CONSTANT_BUFFER {
        bd.BindFlags |= .CONSTANT_BUFFER;
    }

    if bind_flags & .SHADER_RESOURCE {
        bd.BindFlags |= .SHADER_RESOURCE;
    }

    if bind_flags & .RENDER_TARGET {
        bd.BindFlags |= .RENDER_TARGET;
    }

    if bind_flags & .DEPTH_STENCIL {
        bd.BindFlags |= .DEPTH_STENCIL;
    }

    InitData : D3D11_SUBRESOURCE_DATA;
    InitData.pSysMem = data;

    buffer : *ID3D11Buffer;
    hr = ID3D11Device_CreateBuffer(device, *bd, ifx data then *InitData else null, *buffer);

    if FAILED(hr) {
        error_msg := get_hr_error_string(hr);
        log_error("Could not create buffer '%'. Buffer desc: % \n\n%", name, bd, error_msg);
        return .{};
    }

    srv : *ID3D11ShaderResourceView;

    if bind_flags & .SHADER_RESOURCE {
        hr = ID3D11Device_CreateShaderResourceView(device, cast(*ID3D11Resource) buffer, null, *srv);

        if FAILED(hr) {
            error_msg := get_hr_error_string(hr);
            log_error("Could not create buffer SRV '%'.\nBuffer desc: %\n\n%", name, bd, error_msg);
            return .{};
        }
    }

    return .{ handle = buffer, srv = srv, size = size, stride = stride };
}

destroy_buffer :: (buffer : *GFX_Buffer) {
    if buffer == null || buffer.handle == null {
        return;
    }

    if buffer.srv IUnknown_Release(buffer.srv);
    IUnknown_Release(buffer.handle);

    buffer.* = .{};
}

lock_buffer :: (using buffer : *GFX_Buffer, map_access: GFX_Map_Access_Flags) {
    using context.graphics_context;

    assert(buffer.locked == false, "GPU Buffer was already locked!");

    hr          : HRESULT;
    map_flags   : D3D11_MAP;

    map_buffer : D3D11_MAPPED_SUBRESOURCE;

    if #complete map_access == {
        case .READ;             map_flags = .READ;
        case .WRITE_AND_FLUSH;  map_flags = .WRITE_DISCARD;
        case .WRITE_NO_FLUSH;   map_flags = .WRITE_NO_OVERWRITE;
    }

    hr = ID3D11DeviceContext_Map(d3d_context, buffer.handle, 0, map_flags, 0, *map_buffer);

    buffer.locked   = true;
    buffer.data_ptr = map_buffer.pData;
}

unlock_buffer :: (using buffer : *GFX_Buffer) {
    using context.graphics_context;

    buffer.locked = false;
    ID3D11DeviceContext_Unmap(d3d_context, buffer.handle, 0);
}

get_storage_alignment :: inline () -> u64 {
    return 16;
}

get_constant_alignment :: inline () -> u64 {
    return 256;
}




GFX_Platform_Shader :: struct {
    handle   : *void;
    bytecode : string;
};

compile_shader :: (name: string, source: string, stage: GFX_Pipeline_Stage) -> bool, GFX_Platform_Shader {
    using context.graphics_context;

    hr : HRESULT;

    flags := D3DCOMPILE.ENABLE_STRICTNESS;

    // #if DEBUG {
    //     // Set the D3DCOMPILE_DEBUG flag to embed debug information in the shaders.
    //     // Setting this flag improves the shader debugging experience, but still allows
    //     // the shaders to be optimized and to run exactly the way they will run in
    //     // the release configuration of this program.
    flags |= .DEBUG;
    //
    //     // Disable optimizations to further improve shader debugging
    flags |= .SKIP_OPTIMIZATION;
    // }

    shader_model := ifx stage == .VERTEX "vs_5_0" else "ps_5_0";
    entry_point  := ifx stage == .VERTEX vertex_entry_point else fragment_entry_point;
    defines      : [] string;

    bytecode:, errors:, hr = D3DCompile(source, name, defines, null, entry_point, shader_model, xx flags, 0);
    defer free(errors);

    if FAILED(hr) {
        free(bytecode);
        if errors then log_error("Failed compiling: %\n", errors);
        return false, .{};
    }


    handle: *void;

    if stage == {
        case .VERTEX;
            vertex_shader_handle: *ID3D11VertexShader;

            hr = ID3D11Device_CreateVertexShader(device, bytecode.data, cast(u64) bytecode.count, null, *vertex_shader_handle);
            if FAILED(hr) {
                log_error("CreateVertexShader failed: %", hr);
                free(bytecode);
                return false, .{};
            }

            handle = cast(*void) vertex_shader_handle;

        case .FRAGMENT;
            pixel_shader_handle: *ID3D11PixelShader;

            hr = ID3D11Device_CreatePixelShader(device, bytecode.data, cast(u64) bytecode.count, null, *pixel_shader_handle);
            if FAILED(hr) {
                log_error("CreatePixelShader failed: %", hr);
                free(bytecode);
                return false, .{};
            }

            handle = cast(*void) pixel_shader_handle;
    }

    platform_shader := GFX_Platform_Shader.{
        handle           = handle,
        bytecode         = bytecode,
    };

    return true, platform_shader;
}

destroy_shader :: (shader : *GFX_Platform_Shader) {
    IUnknown_Release(shader.handle);
    free(shader.bytecode);

    shader.* = .{};
}






GFX_Render_Pass :: struct {
    cmd_buffer              : *GFX_Command_Buffer; // @note Not really used... to remove?
    desc                    : GFX_Render_Pass_Desc;
    name                    : string;
    current_index_buffer    : *GFX_Buffer;
};

// @todo: I think we should return a GFX_Render_Pass, and remove passing it as args.
begin_render_pass :: (pass : *GFX_Render_Pass, name : string, cmd_buffer : *GFX_Command_Buffer, desc : GFX_Render_Pass_Desc) {
    begin_debug_group(cmd_buffer, name);

    using context.graphics_context;

    pass.cmd_buffer = cmd_buffer;
    pass.desc       = desc;
    pass.name       = name;


    rtv_array   : [GFX_MAX_COLOR_ATTACHMENTS] *ID3D11RenderTargetView;
    dsv         : *ID3D11DepthStencilView;

    render_target_count : u32;

    for 0..GFX_MAX_COLOR_ATTACHMENTS - 1 {
        if desc.color_attachments[it] != null {
            render_target_count += 1;

            rtv_array[it] = desc.color_attachments[it].rtv;
            if desc.should_clear_color[it] {
                ID3D11DeviceContext_ClearRenderTargetView(d3d_context, rtv_array[it], *desc.clear_color[it].component);
            }
        }
    }

    if desc.depth_attachment != null {
        dsv = desc.depth_attachment.dsv;
    }

    // Not sure... to be honest, stencil and depth attachement are the same texture in d3d11.
    if desc.stencil_attachment != null {
        dsv = desc.stencil_attachment.dsv;
    }

    clear_flags : D3D11_CLEAR_FLAG;

    if desc.should_clear_depth   then clear_flags |= D3D11_CLEAR_FLAG.D3D11_CLEAR_DEPTH;
    if desc.should_clear_stencil then clear_flags |= D3D11_CLEAR_FLAG.D3D11_CLEAR_STENCIL;

    if dsv != null {
        ID3D11DeviceContext_ClearDepthStencilView(d3d_context, dsv, cast(u32) clear_flags, desc.clear_depth, cast(u8) desc.clear_stencil);
    }

    ID3D11DeviceContext_OMSetRenderTargets(d3d_context, render_target_count, rtv_array.data, dsv);
}

// @note: No resolve_texture for depth tho...
end_render_pass :: (using pass : *GFX_Render_Pass) {
    using context.graphics_context;

    for 0..GFX_MAX_COLOR_ATTACHMENTS - 1 {
        if desc.color_resolve_textures[it] && desc.color_attachments[it] {
            ID3D11DeviceContext_ResolveSubresource(d3d_context,
            desc.color_resolve_textures[it].handle, 0,
            desc.color_attachments[it].handle, 0,
            to_d3d_pixel_format(desc.color_attachments[it].pixel_format));
        }
    }

    end_debug_group(cmd_buffer);
}

set_viewport :: (pass : *GFX_Render_Pass, viewport : GFX_Viewport) {
    using context.graphics_context;

    d3d_viewport: D3D11_VIEWPORT;

    d3d_viewport.TopLeftX = viewport.top_left_x;
    d3d_viewport.TopLeftY = viewport.top_left_y;
    d3d_viewport.Width    = viewport.width;
    d3d_viewport.Height   = viewport.height;
    d3d_viewport.MinDepth = viewport.min_depth;
    d3d_viewport.MaxDepth = viewport.max_depth;

    ID3D11DeviceContext_RSSetViewports(d3d_context, 1, *d3d_viewport);
}

set_viewports :: (pass : *GFX_Render_Pass, viewports : []GFX_Viewport) {
    using context.graphics_context;

    d3d_viewports := NewArray(viewports.count, D3D11_VIEWPORT ,, temp);

    for viewports {
        d3d_viewports[it_index].TopLeftX = it.top_left_x;
        d3d_viewports[it_index].TopLeftY = it.top_left_y;
        d3d_viewports[it_index].Width    = it.width;
        d3d_viewports[it_index].Height   = it.height;
        d3d_viewports[it_index].MinDepth = it.min_depth;
        d3d_viewports[it_index].MaxDepth = it.max_depth;

    }

    ID3D11DeviceContext_RSSetViewports(d3d_context, cast(u32) viewports.count, d3d_viewports.data);
}

set_vertex_buffer :: (pass : *GFX_Render_Pass, index : s32, buffer : *GFX_Buffer, offset : u64, size : u64, stride : u64) {
    using context.graphics_context;

    if index < 0 return;

    ID3D11DeviceContext_IASetVertexBuffers(d3d_context, cast(u32) index, 1, *buffer.handle, cast(*u32) *stride, cast(*u32) *offset);
}

set_buffer :: (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, buffer : *GFX_Buffer, offset : u64, size : u64) {
    using context.graphics_context;

    if binding.index < 0 return;

    if binding.type == {
        case .UNIFORM_BUFFER;
            first := cast(u32) (offset / 16);
            count := cast(u32) (((size + 255) & ~255) / 16);

            if binding.stage == {
                case .VERTEX;
                    ID3D11DeviceContext1_VSSetConstantBuffers1(d3d_context, cast(u32) binding.index, 1, *buffer.handle, *first, *count);
                case .FRAGMENT;
                    ID3D11DeviceContext1_PSSetConstantBuffers1(d3d_context, cast(u32) binding.index, 1, *buffer.handle, *first, *count);
            }

        case .STORAGE_BUFFER;
            srv := buffer.srv;

            if offset > 0 {
                hash  := fnv1a_hash(cast(u64) buffer.handle);
                hash   = fnv1a_hash(cast(u64) offset, hash);
                hash   = fnv1a_hash(cast(u64) size, hash);

                upper_half := cast, trunc(u32) (hash >> 32);
                lower_half := cast, trunc(u32) hash;

                key := upper_half ^ lower_half;

                offset_srv, newly_add := find_or_add(*srv_offset_table, key);

                if newly_add {
                    buf_desc : D3D11_SHADER_RESOURCE_VIEW_DESC;
                    ID3D11ShaderResourceView_GetDesc(buffer.srv, *buf_desc);

                    srv_desc: D3D11_SHADER_RESOURCE_VIEW_DESC;
                    srv_desc.Format         = buf_desc.Format;
                    srv_desc.ViewDimension  = buf_desc.ViewDimension;

                    assert(buffer.stride > 0, "Invalid stride value.");

                    srv_desc.Buffer = .{
                        FirstElement = cast(u32) (offset / buffer.stride),
                        NumElements  = cast(u32) (size / buffer.stride),
                    };

                    hr := ID3D11Device_CreateShaderResourceView(device, cast(*ID3D11Resource) buffer.handle, *srv_desc, offset_srv);
                    if FAILED(hr) {
                        msg := get_hr_error_string(hr);
                        assert(false, "SRV creation failed: %\n\nDesc: %", msg, srv_desc);
                    }
                }

                srv = offset_srv.*;
            }

            if binding.stage == {
                case .VERTEX;
                    ID3D11DeviceContext_VSSetShaderResources(d3d_context, cast(u32) binding.index, 1, *srv);
                case .FRAGMENT;
                    ID3D11DeviceContext_PSSetShaderResources(d3d_context, cast(u32) binding.index, 1, *srv);
            }
    }
}

srv_offset_table : Table(u32, *ID3D11ShaderResourceView);

set_texture :: (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, texture : *GFX_Texture, fallback : *GFX_Texture = null) {
    using context.graphics_context;

    if binding.index < 0 return;
    assert(binding.type == .TEXTURE, "set_texture: Invalid binding type %", binding.type);

    binded_texture := texture;

    if texture == null || texture.handle == null || texture.srv == null {
        binded_texture = fallback;
    }

    if binded_texture == null return;

    if binding.stage == {
        case .VERTEX;
            ID3D11DeviceContext_VSSetShaderResources(d3d_context, cast(u32) binding.index, 1, *binded_texture.srv);
        case .FRAGMENT;
            ID3D11DeviceContext_PSSetShaderResources(d3d_context, cast(u32) binding.index, 1, *binded_texture.srv);
    }
}

set_sampler_state :: (pass : *GFX_Render_Pass, binding : GFX_Pipeline_Binding, sampler : *GFX_Sampler_State) {
    if binding.index < 0 return;

    assert(binding.type == .SAMPLER_STATE, "set_sampler_state: Invalid binding type %", binding.type);

    using context.graphics_context;
    ID3D11DeviceContext_PSSetSamplers(d3d_context, cast(u32) binding.index, 1, *sampler.handle);
}

draw :: (
    pass : *GFX_Render_Pass,
    vertex_count : u32,
    instance_count : u32,
    base_vertex : u32 = 0,
    base_instance : u32 = 0,
    primitive_type  : GFX_Draw_Primitive = .TRIANGLE
) {
    using context.graphics_context;

    submit_gfx_state_to_pass();

    mesh_draw_calls += 1;

    if instance_count > 1 || base_instance > 0 {
        ID3D11DeviceContext_DrawInstanced(d3d_context, vertex_count, instance_count, base_vertex, base_instance);
    } else {
        ID3D11DeviceContext_Draw(d3d_context, vertex_count, base_vertex);
    }
}

draw_indexed :: (
    pass : *GFX_Render_Pass,
    index_buffer : *GFX_Buffer,
    index_count : u32,
    index_type : GFX_Index_Type,
    instance_count : u32,
    base_vertex : u32 = 0,
    base_index : u32 = 0,
    base_instance : u32 = 0,
    primitive_type  : GFX_Draw_Primitive = .TRIANGLE
) {
    using context.graphics_context;

    submit_gfx_state_to_pass();

    mesh_draw_calls += 1;

    format : DXGI_FORMAT;

    if index_type == {
        case .UINT16; format = .R16_UINT;
        case .UINT32; format = .R32_UINT;
    }

    ID3D11DeviceContext_IASetIndexBuffer(d3d_context, index_buffer.handle, format, 0);

    if instance_count > 1 || base_instance > 0 {
        ID3D11DeviceContext_DrawIndexedInstanced(d3d_context, index_count, instance_count, base_index, cast(s32) base_vertex, base_instance);
    } else {
        ID3D11DeviceContext_DrawIndexed(d3d_context, index_count, base_index, cast(s32) base_vertex);
    }
}

Rasterizer_Key          :: u32;
Blend_State_Key         :: u32;
Depth_Stencil_State_Key :: u32;

Vertex_Layout_Key       :: u64; // Pointer to shader.

rasterizer              : Table(Rasterizer_Key,          *ID3D11RasterizerState);
blend_state             : Table(Blend_State_Key,         *ID3D11BlendState);
depth_stencil_state     : Table(Depth_Stencil_State_Key, *ID3D11DepthStencilState);

vertex_layout_catalog   : Table(Vertex_Layout_Key,       *ID3D11InputLayout);

hash_depth_stencil_data :: (using render_state: Render_State) -> Depth_Stencil_State_Key {
    hash  := fnv1a_hash(cast(u64) depth_enabled);
    hash   = fnv1a_hash(cast(u64) depth_write, hash);

    if depth_enabled {
        hash   = fnv1a_hash(cast(u64) depth_comp, hash);
    }

    if stencil_enabled {
        hash  = fnv1a_hash(cast(u64) stencil_enabled, hash);
        hash  = fnv1a_hash(cast(u64) stencil_front, hash);
        hash  = fnv1a_hash(cast(u64) stencil_back, hash);
        hash  = fnv1a_hash(cast(u64) stencil_read_mask, hash);
        hash  = fnv1a_hash(cast(u64) stencil_write_mask, hash);
    }

    upper_half := cast, trunc(u32) (hash >> 32);
    lower_half := cast, trunc(u32) hash;

    return upper_half ^ lower_half;
}

hash_blend_data :: (using render_state: Render_State) -> Blend_State_Key {
    hash  := FNV_64_PRIME;

    for blend_modes {
        hash   = fnv1a_hash(cast(u64) it, hash);
    }

    upper_half := cast, trunc(u32) (hash >> 32);
    lower_half := cast, trunc(u32) hash;

    return upper_half ^ lower_half;
}

hash_rasterizer_data :: (using render_state: Render_State) -> Rasterizer_Key {
    hash  := fnv1a_hash(cast(u64) fill_mode);
    hash   = fnv1a_hash(cast(u64) cull_face, hash);
    hash   = fnv1a_hash(cast(u64) winding_order, hash);

    hash   = fnv1a_hash(cast(u64) scissor_enabled, hash);
    hash   = fnv1a_hash(cast(u64) (sample_count > 1), hash);

    upper_half := cast, trunc(u32) (hash >> 32);
    lower_half := cast, trunc(u32) hash;

    return upper_half ^ lower_half;
}

submit_gfx_state_to_pass :: () {
    using context.graphics_context;

    ID3D11DeviceContext_IASetPrimitiveTopology(d3d_context, to_d3d_topology(render_state.topology));

    rasterizer_key                     := hash_rasterizer_data(render_state);
    rasterizer, rasterizer_newly_added := find_or_add(*rasterizer, rasterizer_key);

    if rasterizer_newly_added {
        desc : D3D11_RASTERIZER_DESC;

        desc.FillMode               = to_d3d_fill_mode(render_state.fill_mode);
        desc.CullMode               = to_d3d_cull_mode(render_state.cull_face);
        desc.ScissorEnable          = cast(BOOL) render_state.scissor_enabled;
        desc.MultisampleEnable      = cast(BOOL) (render_state.sample_count > 1);
        desc.FrontCounterClockwise  = cast(BOOL) (render_state.winding_order == .CCW);

        hr := ID3D11Device_CreateRasterizerState(device, *desc, rasterizer);

        if FAILED(hr) {
            assert(false, "Could not create rasterizer desc.\nDesc: %\n\n%", desc, get_hr_error_string(hr));
        }
    }

    // Set rasterizer state.
    ID3D11DeviceContext_RSSetState(d3d_context, rasterizer.*);


    blend_state_key                      := hash_blend_data(render_state);
    blend_state, blend_state_newly_added := find_or_add(*blend_state, blend_state_key);

    if blend_state_newly_added {
        desc : D3D11_BLEND_DESC;

        for render_state.blend_modes {
            blend_mode := cast(Blend_Mode) it;

            if #complete blend_mode == {
                case .ALPHA;
                    desc.RenderTarget[it_index] = .{
                        BlendEnable     = cast(BOOL, true),
                        SrcBlend              = .SRC_ALPHA,
                        DestBlend             = .INV_SRC_COLOR,
                        BlendOp               = .ADD,
                        SrcBlendAlpha         = .SRC_ALPHA,
                        DestBlendAlpha        = .INV_SRC_COLOR,
                        BlendOpAlpha          = .ADD,
                        RenderTargetWriteMask = cast(u8) D3D11_COLOR_WRITE_ENABLE.ALL,
                    };
                case .ADDITIVE;
                    desc.RenderTarget[it_index] = .{
                        BlendEnable     = cast(BOOL, true),
                          SrcBlend              = .SRC_ALPHA,
                          DestBlend             = .INV_SRC_ALPHA,
                          BlendOp               = .ADD,
                          SrcBlendAlpha         = .ONE,
                          DestBlendAlpha        = .INV_SRC_ALPHA,
                          BlendOpAlpha          = .ADD,
                        RenderTargetWriteMask = cast(u8) D3D11_COLOR_WRITE_ENABLE.ALL,
                    };

                case .NONE;
                      desc.RenderTarget[it_index].RenderTargetWriteMask = cast(u8) D3D11_COLOR_WRITE_ENABLE.ALL;

            }
        }

        hr := ID3D11Device_CreateBlendState(device, *desc, blend_state);

        if FAILED(hr) {
            assert(false, "Could not create blend state.\nDesc: %\n\n%", desc, get_hr_error_string(hr));
        }
    }

    // Set Blend state.
    ID3D11DeviceContext_OMSetBlendState(d3d_context, blend_state.*, null, 0xFFFFFFFF);


    depth_stencil_state_key                        := hash_depth_stencil_data(render_state);
    depth_stencil_state, depth_stencil_newly_added := find_or_add(*depth_stencil_state, depth_stencil_state_key);

    if depth_stencil_newly_added {
        desc: D3D11_DEPTH_STENCIL_DESC;

        desc.DepthEnable        = cast(BOOL) render_state.depth_enabled;
        desc.DepthWriteMask     = ifx render_state.depth_write then .ALL else .ZERO;
        desc.DepthFunc          = to_d3d_comp_func(render_state.depth_comp);

        desc.StencilEnable      = cast(BOOL) render_state.stencil_enabled;
        desc.StencilReadMask    = render_state.stencil_read_mask;
        desc.StencilWriteMask   = render_state.stencil_write_mask;

        desc.FrontFace          = _d3d11_fill_up_stencil_desc(render_state.stencil_front);
        desc.BackFace           = _d3d11_fill_up_stencil_desc(render_state.stencil_back);

        hr := ID3D11Device_CreateDepthStencilState(device, *desc, depth_stencil_state);

        if FAILED(hr) {
            assert(false, "Could not create stencil depth state.\nDesc: %\n\n%", desc, get_hr_error_string(hr));
        }
    }


    ID3D11DeviceContext_OMSetDepthStencilState(d3d_context, depth_stencil_state.*, render_state.stencil_ref);

    if render_state.scissor_enabled {
        d3d_rect: D3D11_RECT;
        d3d_rect.left   = render_state.scissor_rect.x;
        d3d_rect.top    = render_state.scissor_rect.y;
        d3d_rect.right  = render_state.scissor_rect.x + render_state.scissor_rect.w;
        d3d_rect.bottom = render_state.scissor_rect.y + render_state.scissor_rect.h;

        ID3D11DeviceContext_RSSetScissorRects(d3d_context, 1, *d3d_rect);
    }

    if render_state.vertex_shader {
        ID3D11DeviceContext_VSSetShader(d3d_context, cast(*ID3D11VertexShader) render_state.vertex_shader.shader.handle, null, 0);
    }

    if render_state.pixel_shader {
        ID3D11DeviceContext_PSSetShader(d3d_context, cast(*ID3D11PixelShader) render_state.pixel_shader.shader.handle, null, 0);
    }

    if render_state.vertex_layout.count > 0 {
        vertex_layout, vertex_layout_newly_added := find_or_add(*vertex_layout_catalog, cast(u64) render_state.vertex_shader.shader.handle);

        if vertex_layout_newly_added {
            vertex_layout.* = to_d3d_input_layout(render_state.vertex_layout, render_state.vertex_shader.shader.bytecode);
        }

        ID3D11DeviceContext_IASetInputLayout(d3d_context, vertex_layout.*);
    }
}










GFX_Texture :: struct {
    handle      : *ID3D11Texture2D;

    name        : string;

    srv         : *ID3D11ShaderResourceView;
    dsv         : *ID3D11DepthStencilView;
    rtv         : *ID3D11RenderTargetView;

    locked      : bool;
    data_ptr    : *void;
    data_row_pitch : s32;

    using desc  : GFX_Texture_Desc;
}

GFX_NULL_TEXTURE :: GFX_Texture.{};

operator == :: inline (a: GFX_Texture, b: GFX_Texture) -> bool {
    return a.width == b.width && a.height == b.height && a.handle == b.handle;
}

is_null :: (texture : *GFX_Texture) -> bool {
    return texture == null || texture.handle == null;
}

get_desc :: (texture: *GFX_Texture) -> GFX_Texture_Desc {
    return texture.desc;
}

create_texture :: (name : string, desc : GFX_Texture_Desc, data : *void = null) -> GFX_Texture {
    using context.graphics_context;

    // assert(desc.usage != .UNKNOWN, "desc.usage is %", desc.usage);

    d3d11_texture_desc  : D3D11_TEXTURE2D_DESC;

    d3d11_texture_desc.Width            = desc.width;
    d3d11_texture_desc.Height           = desc.height;
    d3d11_texture_desc.MipLevels        = desc.num_mipmap_levels;
    d3d11_texture_desc.SampleDesc.Count = desc.num_samples;
    d3d11_texture_desc.ArraySize        = desc.array_length;
    d3d11_texture_desc.Format           = to_d3d_pixel_format(desc.pixel_format);
    d3d11_texture_desc.CPUAccessFlags   = 0x00;

    is_cpu_read  := (desc.storage_flags & .CPU_READ);
    is_cpu_write := (desc.storage_flags & .CPU_WRITE);

    if desc.num_mipmap_levels > 1 {
        d3d11_texture_desc.MiscFlags |= .GENERATE_MIPS;
        d3d11_texture_desc.BindFlags |= (.RENDER_TARGET | .SHADER_RESOURCE);
    }

    if is_cpu_read {
        d3d11_texture_desc.Usage              = .D3D11_USAGE_STAGING;
        d3d11_texture_desc.CPUAccessFlags     = .D3D11_CPU_ACCESS_READ;
        if is_cpu_write {
            d3d11_texture_desc.CPUAccessFlags |= .D3D11_CPU_ACCESS_WRITE;
        }
    } else if is_cpu_write {
        d3d11_texture_desc.Usage            = .DEFAULT;
        d3d11_texture_desc.CPUAccessFlags   = 0x00;
    } else {
        d3d11_texture_desc.Usage = .D3D11_USAGE_DEFAULT;
    }

    if desc.usage & .SHADER_READ {
        d3d11_texture_desc.BindFlags |= .SHADER_RESOURCE;
    }

    if desc.usage & .RENDER_TARGET {
        d3d11_texture_desc.BindFlags |= .RENDER_TARGET;
    }

    // Also, if pixel format is a depth format, the bind flags should be set accordingly.
    if desc.pixel_format == .DEPTH_FLOAT32_STENCIL_8 || desc.pixel_format == .DEPTH_FLOAT32 || desc.pixel_format == .STENCIL_8 {
        d3d11_texture_desc.BindFlags &= ~.RENDER_TARGET; // Can't be both.
        d3d11_texture_desc.BindFlags |= .D3D11_BIND_DEPTH_STENCIL;
    }

    is_typeless     := is_typeless_format(d3d11_texture_desc.Format);
    bytes_per_pixel := get_bytes_per_pixel(desc.pixel_format);

    initial_data := D3D11_SUBRESOURCE_DATA.{
        pSysMem     = data,
        SysMemPitch = cast, no_check(u32, desc.width * bytes_per_pixel),
    };

    handle  : *ID3D11Texture2D;
    hr      := ID3D11Device_CreateTexture2D(device, *d3d11_texture_desc, ifx data == null then null else *initial_data, *handle);

    if FAILED(hr) {
        error_msg := get_hr_error_string(hr);
        log_error("Could not create texture '%'. Texture desc: % \n\n%", name, desc, error_msg);
        return .{};
    }

    result: GFX_Texture;
    result.handle   = handle;
    result.desc     = desc;
    result.name     = copy_string(name);

    if result.name.count > 0 {
        WKPDID_D3DDebugObjectName :: GUID.{ 0x429b8c22, 0x9188, 0x4b0c, .[ 0x87, 0x42, 0xac, 0xb0, 0xbf, 0x85, 0xc2, 0x00 ] };
        ID3D11DeviceChild_SetPrivateData(handle, *WKPDID_D3DDebugObjectName, cast(u32) result.name.count, result.name.data);
    }

    // Create SRV for binding later on.
    if desc.usage & .SHADER_READ {
        srv_desc: D3D11_SHADER_RESOURCE_VIEW_DESC;

            if is_typeless {
                srv_desc.Format                       = resolve_srv_format(d3d11_texture_desc.Format);
                if desc.type == {
                    case .TEXTURE_2D;
                        srv_desc.ViewDimension                = .D3D11_SRV_DIMENSION_TEXTURE2D;
                        srv_desc.Texture2D.MostDetailedMip    = 0;
                        srv_desc.Texture2D.MipLevels          = desc.num_mipmap_levels;
                    case .TEXTURE_2D_ARRAY;
                        srv_desc.ViewDimension                  = .D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
                        srv_desc.Texture2DArray.MostDetailedMip    = 0;
                        srv_desc.Texture2DArray.MipLevels          = desc.num_mipmap_levels;
                        srv_desc.Texture2DArray.FirstArraySlice = 0;
                        srv_desc.Texture2DArray.ArraySize       = desc.array_length;
                }
            }

        hr =  ID3D11Device_CreateShaderResourceView(device, handle, ifx is_typeless then *srv_desc else null, *result.srv);
        if FAILED(hr) then assert(false, "SRV creation failed: %\n\nDesc: %", get_hr_error_string(hr), desc);
    }

    // Create DSV and RTV for binding later on too.
    if desc.usage & .RENDER_TARGET {
        if d3d11_texture_desc.BindFlags & .D3D11_BIND_DEPTH_STENCIL {
            dsv_desc: D3D11_DEPTH_STENCIL_VIEW_DESC;

            if is_typeless {
                dsv_desc.Format                       = resolve_dsv_format(d3d11_texture_desc.Format);
                if desc.type == {
                    case .TEXTURE_2D;
                        dsv_desc.ViewDimension        = .D3D11_DSV_DIMENSION_TEXTURE2D;
                        dsv_desc.Texture2D.MipSlice   = 0;
                    case .TEXTURE_2D_ARRAY;
                        dsv_desc.ViewDimension                  = .D3D11_DSV_DIMENSION_TEXTURE2DARRAY;
                        dsv_desc.Texture2DArray.MipSlice        = 0;
                        dsv_desc.Texture2DArray.FirstArraySlice = 0;
                        dsv_desc.Texture2DArray.ArraySize       = desc.array_length;
                }
            }

            hr = ID3D11Device_CreateDepthStencilView(device, handle, ifx is_typeless then *dsv_desc else null, *result.dsv);

            if FAILED(hr) {
                assert(false, "DSV creation failed: %\n\nDesc: %", get_hr_error_string(hr), desc);
            }

        } else {
            hr = ID3D11Device_CreateRenderTargetView(device, handle, null, *result.rtv);

            if FAILED(hr) {
                assert(false, "RTV creation failed: %\n\nDesc: %", get_hr_error_string(hr), desc);
            }
        }
    }

    return result;
}

destroy_texture :: (using texture : *GFX_Texture) {
    IUnknown_Release(texture.handle);
    if name then free(name);
    texture.* = {};
}

replace_texture_region :: (using texture : *GFX_Texture, origin : Vector3u, size : Vector3u, mipmap_level : u32, array_slice : u32, bytes : *void) {
    using context.graphics_context;

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

    subresource := mipmap_level + array_slice * desc.num_mipmap_levels;

    box : D3D11_BOX;
    box.left   = origin.x;
    box.top    = origin.y;
    box.front  = origin.z;
    box.right  = origin.x + size.x;
    box.bottom = origin.y + size.y;
    box.back   = origin.z + size.z;

    row_pitch   := cast(u32) (size.x * bytes_per_pixel);
    depth_pitch := cast(u32) (row_pitch * size.y);

    ID3D11DeviceContext_UpdateSubresource(d3d_context, handle, subresource, *box, bytes, row_pitch, depth_pitch);
}

create_texture_view :: (name : string, texture : GFX_Texture, desc : GFX_Texture_View_Desc) -> GFX_Texture {
    using context.graphics_context;

    srv_desc: D3D11_SHADER_RESOURCE_VIEW_DESC;
    srv_desc.Format = resolve_srv_format(to_d3d_pixel_format(desc.pixel_format));

    if #complete desc.type == {
        case .TEXTURE_2D;
            srv_desc.ViewDimension                  = .D3D11_SRV_DIMENSION_TEXTURE2D;
            srv_desc.Texture2D.MostDetailedMip      = desc.first_mipmap_level;
            srv_desc.Texture2D.MipLevels            = desc.num_mipmap_levels;

        case .TEXTURE_2D_MULTISAMPLE;
            srv_desc.ViewDimension                  = .D3D11_SRV_DIMENSION_TEXTURE2DMS;

        case .TEXTURE_2D_ARRAY;
            srv_desc.ViewDimension                  = .D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
            srv_desc.Texture2DArray.MostDetailedMip = desc.first_mipmap_level;
            srv_desc.Texture2DArray.MipLevels       = desc.num_mipmap_levels;
            srv_desc.Texture2DArray.FirstArraySlice = desc.first_slice;
            srv_desc.Texture2DArray.ArraySize       = desc.num_slices;

        case .TEXTURE_CUBE;
            srv_desc.ViewDimension                  = .D3D11_SRV_DIMENSION_TEXTURECUBE;
            srv_desc.TextureCube.MostDetailedMip    = desc.first_mipmap_level;
            srv_desc.TextureCube.MipLevels          = desc.num_mipmap_levels;

        case .INVALID;
            crash("create_texture_view: Invalid texture type %", desc.type);
    }

    srv : *ID3D11ShaderResourceView;
    hr  := ID3D11Device_CreateShaderResourceView(device, texture.handle, *srv_desc, *srv);

    if FAILED(hr) {
        assert(false, "CreateShaderResourceView failed: %\nDesc: %", get_hr_error_string(hr), srv_desc);
    }

    texture_desc                   := texture.desc;
    texture_desc.type               = desc.type;
    texture_desc.pixel_format       = desc.pixel_format;
    texture_desc.num_mipmap_levels  = desc.num_mipmap_levels;
    texture_desc.array_length       = desc.num_slices;

    return .{ handle = texture.handle, desc = texture_desc, srv = srv };
}

create_texture_2d_rgba8 :: (name := "", data : *u8, width: s32, height: s32, mipmapped := true) -> GFX_Texture {
    desc : GFX_Texture_Desc;

    desc.type           = .TEXTURE_2D;
    desc.pixel_format   = .RGBA_UNORM8;
    desc.usage          = .SHADER_READ;
    desc.width          = xx width;
    desc.height         = xx height;
    desc.storage_flags  = .CPU_WRITE;

    if mipmapped {
        set_appropriate_num_mipmap_levels(*desc);
    }

    result := create_texture(name, desc, data = data);
    if is_null(*result) return result;

    return result;
}

GFX_Sampler_State :: struct {
    handle : *ID3D11SamplerState;
}

is_null :: (sampler : *GFX_Sampler_State) -> bool {
    return sampler == null || sampler.handle == null;
}

create_sampler_state :: (name : string, desc : GFX_Sampler_State_Desc) -> GFX_Sampler_State {
    using context.graphics_context;

    d3d_desc : D3D11_SAMPLER_DESC;

    d3d_desc.ComparisonFunc = to_d3d_comp_func(desc.compare_func);
    d3d_desc.MinLOD = desc.lod_min_clamp;
    d3d_desc.MaxLOD = desc.lod_max_clamp;
    d3d_desc.MaxAnisotropy = desc.max_anisotropy;
    d3d_desc.AddressU = to_d3d_sampler_address_mode(desc.u_address_mode);
    d3d_desc.AddressV = to_d3d_sampler_address_mode(desc.v_address_mode);
    d3d_desc.AddressW = to_d3d_sampler_address_mode(desc.w_address_mode);

    d3d_desc.Filter = to_d3d_sampler_filter(desc);

    if desc.border_color == {
        case .TRANSPARENT;  d3d_desc.BorderColor = .[0, 0, 0, 0];
        case .OPAQUE_BLACK; d3d_desc.BorderColor = .[0, 0, 0, 1];
        case .OPAQUE_WHITE; d3d_desc.BorderColor = .[1, 1, 1, 1];
    }

    sample_handle   : *ID3D11SamplerState;
    hr              := ID3D11Device_CreateSamplerState(device, *d3d_desc, *sample_handle);

    if FAILED(hr) {
        error_msg := get_hr_error_string(hr);
        log_error("Could not create sample state '%'. Sample desc: % \n\n%", name, desc, error_msg);
        return .{};
    }

    return .{ handle = sample_handle };
}

destroy_sampler_state :: (sampler : *GFX_Sampler_State) {
    IUnknown_Release(sampler.handle);
    sampler.* = {};
}








GFX_Copy_Pass :: struct {
    cmd_buffer : *GFX_Command_Buffer;
}

begin_copy_pass :: (pass : *GFX_Copy_Pass, name : string, cmd_buffer : *GFX_Command_Buffer) {
    pass.cmd_buffer = cmd_buffer;
    begin_debug_group(cmd_buffer, name);
}

end_copy_pass :: (pass : *GFX_Copy_Pass) {
    end_debug_group(pass.cmd_buffer);
}

generate_mipmaps :: (using pass : *GFX_Copy_Pass, texture : Texture) {
    using context.graphics_context;

    if texture.texture_index >= 0 {
        srv_desc : D3D11_SHADER_RESOURCE_VIEW_DESC;
        srv_desc.Format                         = to_d3d_pixel_format(texture.gfx_handle.desc.pixel_format);
        srv_desc.ViewDimension                  = .TEXTURE2DARRAY;
        srv_desc.Texture2DArray.MostDetailedMip = 0;
        srv_desc.Texture2DArray.MipLevels       = texture.gfx_handle.desc.num_mipmap_levels;
        srv_desc.Texture2DArray.FirstArraySlice  = cast(u32) texture.texture_index;
        srv_desc.Texture2DArray.ArraySize        = 1;

        slice_srv : *ID3D11ShaderResourceView;
        hr := ID3D11Device_CreateShaderResourceView(device, cast(*ID3D11Resource) texture.gfx_handle.handle, *srv_desc, *slice_srv);
        assert(SUCCEEDED(hr));

        ID3D11DeviceContext_GenerateMips(d3d_context, slice_srv);
        IUnknown_Release(slice_srv);
    } else {
        ID3D11DeviceContext_GenerateMips(d3d_context, texture.gfx_handle.srv);
    }
}

copy_texture :: (pass: *GFX_Copy_Pass, source: *GFX_Texture, dest: *GFX_Texture) {
    using context.graphics_context;
    ID3D11DeviceContext_CopyResource(d3d_context, dest.handle, source.handle);
}



#scope_file;

to_d3d_sampler_address_mode :: (mode: GFX_Sampler_Address_Mode) -> D3D11_TEXTURE_ADDRESS_MODE {
    if #complete mode == {
        case .CLAMP_TO_EDGE;        return .CLAMP;
        case .CLAMP_TO_ZERO;        return .BORDER;
        case .CLAMP_TO_BORDER;      return .BORDER;
        case .REPEAT;               return .WRAP;
        case .MIRROR_CLAMP_TO_EDGE; return .MIRROR_ONCE;
        case .MIRROR_REPEAT;        return .MIRROR;
    }
}

is_typeless_format :: (format : DXGI_FORMAT) -> bool {
    return format == .R32_TYPELESS
        || format == .R32G8X24_TYPELESS
        || format == .R24G8_TYPELESS
        || format == .R8G8B8A8_TYPELESS;
}

resolve_srv_format :: (format : DXGI_FORMAT) -> DXGI_FORMAT {
    if format == {
        case .R32_TYPELESS;         return .R32_FLOAT;
        case .R32G8X24_TYPELESS;    return .R32_FLOAT_X8X24_TYPELESS;
        case .R24G8_TYPELESS;       return .R24_UNORM_X8_TYPELESS;
        case .R8G8B8A8_TYPELESS;    return .R8G8B8A8_UNORM;
        case;                       return format;
    }
}

resolve_dsv_format :: (format : DXGI_FORMAT) -> DXGI_FORMAT {
    if format == {
        case .R32_TYPELESS;         return .D32_FLOAT;
        case .R32G8X24_TYPELESS;    return .D32_FLOAT_S8X24_UINT;
        case .R24G8_TYPELESS;       return .D24_UNORM_S8_UINT;
        case;                       return format;
    }
}

to_d3d_sampler_filter :: (desc: GFX_Sampler_State_Desc) -> D3D11_FILTER {
    if desc.max_anisotropy > 1 {
        if desc.compare_func != .NONE {
            return .COMPARISON_ANISOTROPIC;
        } else {
            return .ANISOTROPIC;
        }
    }

    min_linear := desc.min_filter == .LINEAR;
    mag_linear := desc.mag_filter == .LINEAR;
    mip_linear := desc.mip_filter == .LINEAR;

    base : D3D11_FILTER;

    if  min_linear &&  mag_linear &&  mip_linear  base = .MIN_MAG_MIP_LINEAR;
    if  min_linear &&  mag_linear && !mip_linear  base = .MIN_MAG_LINEAR_MIP_POINT;
    if  min_linear && !mag_linear &&  mip_linear  base = .MIN_LINEAR_MAG_POINT_MIP_LINEAR;
    if  min_linear && !mag_linear && !mip_linear  base = .MIN_LINEAR_MAG_MIP_POINT;
    if !min_linear &&  mag_linear &&  mip_linear  base = .MIN_POINT_MAG_MIP_LINEAR;
    if !min_linear &&  mag_linear && !mip_linear  base = .MIN_POINT_MAG_LINEAR_MIP_POINT;
    if !min_linear && !mag_linear &&  mip_linear  base = .MIN_MAG_POINT_MIP_LINEAR;
    if !min_linear && !mag_linear && !mip_linear  base = .MIN_MAG_MIP_POINT;

    if desc.compare_func != .NONE {
        base = cast(D3D11_FILTER, cast(u32, base) | 0x80);
    }

    return base;
}

to_d3d_input_layout :: (vertex_layout: [] GFX_Vertex_Input_Desc, vertex_bytecode: string) -> *ID3D11InputLayout {
    using context.graphics_context;

    layout          : *ID3D11InputLayout;
    d3d_elements    : [12] D3D11_INPUT_ELEMENT_DESC;

    for vertex_layout {
        d3d_elements[it_index] = .{
            SemanticName         = to_c_string(it.attribute_name ,, temp),
            SemanticIndex        = it.attribute_index,
            Format               = to_d3d_vertex_format(it.format, it.normalized),
            InputSlot            = it.buffer_index,
            AlignedByteOffset    = it.offset,
            InputSlotClass       = .VERTEX_DATA,
            InstanceDataStepRate = 0,
        };
    }


    hr := ID3D11Device_CreateInputLayout(device,
        d3d_elements.data,
        cast(u32) vertex_layout.count,
        vertex_bytecode.data,
        cast(u64) vertex_bytecode.count,
        *layout,
    );

    if FAILED(hr) {
        assert(false, "Could not create input layout: %", get_hr_error_string(hr));
    }
    return layout;
}

to_d3d_topology :: (topology: GFX_Topology_Primitive_Type) -> D3D11_PRIMITIVE_TOPOLOGY {
    if #complete topology == {
        case .INVALID;
            return .UNDEFINED;
        case .POINT;
            return .POINTLIST;
        case .LINE;
            return .LINELIST;
        case .TRIANGLE;
            return .TRIANGLELIST;

    }
}

to_d3d_fill_mode :: (fill_mode: GFX_Fill_Mode) -> D3D11_FILL_MODE {
    if #complete fill_mode == {
        case .FILL;  return .SOLID;
        case .LINES; return .WIREFRAME;
    }
}

to_d3d_cull_mode :: (cull_mode: GFX_Polygon_Face) -> D3D11_CULL_MODE {
    if #complete cull_mode == {
        case .NONE;  return .NONE;
        case .FRONT; return .FRONT;
        case .BACK;  return .BACK;
    }
}

to_d3d_comp_func :: (comp: GFX_Compare_Func) -> D3D11_COMPARISON_FUNC {
    if #complete comp == {
        case .NONE;             #through;
        case .NEVER;            return .NEVER;
        case .LESS;             return .LESS;
        case .LESS_EQUAL;       return .LESS_EQUAL;
        case .GREATER;          return .GREATER;
        case .GREATER_EQUAL;    return .GREATER_EQUAL;
        case .EQUAL;            return .EQUAL;
        case .NOT_EQUAL;        return .NOT_EQUAL;
        case .ALWAYS;           return .ALWAYS;
    }
}

to_d3d_stencil_op :: (stencil_op: GFX_Stencil_Operation) -> D3D11_STENCIL_OP {
    if #complete stencil_op == {
        case .KEEP;             return .KEEP;
        case .ZERO;             return .ZERO;
        case .REPLACE;          return .REPLACE;
        case .INCREMENT;        return .INCR_SAT;
        case .INCREMENT_WRAP;   return .INCR;
        case .DECREMENT;        return .DECR_SAT;
        case .DECREMENT_WRAP;   return .DECR;
        case .INVERT;           return .INVERT;
    }
}


_d3d11_fill_up_stencil_desc :: (packed_values: u64) -> D3D11_DEPTH_STENCILOP_DESC {
    desc: D3D11_DEPTH_STENCILOP_DESC;

    _3bit_mask  : u8  = 0x07;
    _4bit_mask  : u8  = 0xF;

    // Unpack stencil values.
    stencil_failed              := (packed_values >> 0) & _3bit_mask;
    stencil_passed_depth_failed := (packed_values >> 3) & _3bit_mask;
    stencil_passed_depth_passed := (packed_values >> 6) & _3bit_mask;
    comp_func                   := (packed_values >> 9) & _4bit_mask;

    desc.StencilFailOp      = to_d3d_stencil_op(xx stencil_failed);
    desc.StencilDepthFailOp = to_d3d_stencil_op(xx stencil_passed_depth_failed);
    desc.StencilPassOp      = to_d3d_stencil_op(xx stencil_passed_depth_passed);
    desc.StencilFunc        = to_d3d_comp_func(xx comp_func);

    return desc;
}

d3d_pixel_format :: (format: DXGI_FORMAT) -> GFX_Pixel_Format {
    result := GFX_Pixel_Format.INVALID;

    if format == {
        case .R32_UINT;             result = .RED_UINT32;
        case .R32_SINT;             result = .RED_INT32;
        case .R32_FLOAT;            result = .RED_FLOAT32;

        case .B8G8R8A8_UNORM;       result = .BGRA_UNORM8;

        case .R8G8B8A8_UNORM;       result = .RGBA_UNORM8;
        case .R8G8B8A8_UINT;        result = .RGBA_UINT8;
        case .R32G32B32A32_UINT;    result = .RGBA_UINT32;
        case .R32G32B32A32_SINT;    result = .RGBA_INT32;
        case .R16G16B16A16_FLOAT;   result = .RGBA_FLOAT16;
        case .R32G32B32A32_FLOAT;   result = .RGBA_FLOAT32;

        // Typeless, but perhaps we need SRV/DRV ones.
        case .R32G8X24_TYPELESS;    result = .DEPTH_FLOAT32_STENCIL_8;
        case .R32_TYPELESS;         result = .DEPTH_FLOAT32;
        case .R24G8_TYPELESS;       result = .STENCIL_8;
    }

    return result;
}

to_d3d_pixel_format :: (format: GFX_Pixel_Format) -> DXGI_FORMAT {
    result : DXGI_FORMAT;

    if format == {
        case .RED_UINT32;               result = .R32_UINT;
        case .RED_INT32;                result = .R32_SINT;
        case .RED_FLOAT32;              result = .R32_FLOAT;
        case .BGRA_UNORM8;              result = .B8G8R8A8_UNORM;;
        case .RGBA_UNORM8;              result = .R8G8B8A8_UNORM;
        case .RGBA_UINT8;               result = .R8G8B8A8_UINT;
        case .RGBA_UINT32;              result = .R32G32B32A32_UINT;
        case .RGBA_INT32;               result = .R32G32B32A32_SINT;
        case .RGBA_FLOAT16;             result = .R16G16B16A16_FLOAT;
        case .RGBA_FLOAT32;             result = .R32G32B32A32_FLOAT;

        // Typeless, but perhaps we need SRV/DRV ones.
        case .DEPTH_FLOAT32_STENCIL_8;  result = .R32G8X24_TYPELESS;
        case .DEPTH_FLOAT32;            result = .R32_TYPELESS;
        case .STENCIL_8;                result = .R24G8_TYPELESS;
    }

    return result;
}

to_d3d_vertex_format :: (format : GFX_Vertex_Format, normalized : bool) -> DXGI_FORMAT {
    if #complete format == {
        case .INVALID;  return .UNKNOWN;
        case .FLOAT;    return .R32_FLOAT;
        case .FLOAT2;   return .R32G32_FLOAT;
        case .FLOAT3;   return .R32G32B32_FLOAT;
        case .FLOAT4;   return .R32G32B32A32_FLOAT;
        case .CHAR2;    return ifx normalized then .R8G8_SNORM else .R8G8_SINT;
        case .CHAR4;    return ifx normalized then .R8G8B8A8_SNORM else .R8G8B8A8_SINT;
        case .UCHAR2;   return ifx normalized then .R8G8_UNORM else .R8G8_UINT;
        case .UCHAR4;   return ifx normalized then .R8G8B8A8_UNORM else .R8G8B8A8_UINT;
        case .SHORT2;   return ifx normalized then .R16G16_SNORM else .R16G16_SINT;
        case .SHORT4;   return ifx normalized then .R16G16B16A16_SNORM else .R16G16B16A16_SINT;
        case .USHORT2;  return ifx normalized then .R16G16_UNORM else .R16G16_UINT;
        case .USHORT4;  return ifx normalized then .R16G16B16A16_UNORM else .R16G16B16A16_UINT;
        case .INT;      return .R32_SINT;
        case .INT2;     return .R32G32_SINT;
        case .INT3;     return .R32G32B32_SINT;
        case .INT4;     return .R32G32B32A32_SINT;
        case .UINT;     return .R32_UINT;
        case .UINT2;    return .R32G32_UINT;
        case .UINT3;    return .R32G32B32_UINT;
        case .UINT4;    return .R32G32B32A32_UINT;
    }
}

to_d3d11_storage_flags :: (access_flag: GFX_Storage_Flags) -> D3D11_CPU_ACCESS_FLAG {
    result : D3D11_CPU_ACCESS_FLAG;

    if access_flag & .CPU_WRITE {
        result |= .WRITE;
    }

    if access_flag & .CPU_READ {
        result |= .READ;
    }

    return result;
}



#import, dir "bindings/D3D11";
#import "dxgi";
#import "d3d_compiler";
#import "Windows";
#import "Windows_Utf8";

Utf8 :: #import "Windows_Utf8";

