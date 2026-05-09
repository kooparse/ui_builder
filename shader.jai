Slang :: #import "Slang";

VERTEX_ENTRY_POINT      :: "vertex_main";
FRAGMENT_ENTRY_POINT    :: "fragment_main";

disable_slang_optimizations         := false;

loaded_shader := GFX_Loaded_Shader.{ name = "ui" };

load_all_shaders :: () {
    reload_shader(*loaded_shader);
}

#scope_file

reload_shader :: (using loaded_shader: *GFX_Loaded_Shader) -> bool {
    using Slang;

    failed_to_reload = true;


    slang_filepath  := tprint("shaders/%.slang", name);
    slang_buffer    := read_entire_file(slang_filepath ,, temp);

    success, result := transpile_shader_to_native(name, slang_filepath, slang_buffer);
    if !success return false;

    // Set shader dependencies.
    // Tho, we don't do it when shader are packed.
    array_reset(*dependencies);
    dependencies = result.shader_dependencies;

    using result;

    success=, native_time: = compile_native_shader(loaded_shader, native_vertex_buffer, native_fragment_buffer, vertex_bindings, fragment_bindings);
    if !success return false;


    total_time := slang_time + native_time;

    log("Loaded shader '%' (%) in % s", name, ifx has_vertex_shader && has_fragment_shader then "vertex and fragment" else ifx has_vertex_shader then "vertex only" else "fragment only", total_time);
    for reload_callbacks {
        it.proc(loaded_shader, it.pso_key);
    }

    failed_to_reload = false;

    return true;
}


// Takes a long time to create, so we reuse it for all shaders
slang_global_session : *Slang.IGlobalSession;

Shader_Transpilation_Result :: struct {
    native_vertex_buffer    : string;
    native_fragment_buffer  : string;

    vertex_bindings         : [] GFX_Pipeline_Binding;
    fragment_bindings       : [] GFX_Pipeline_Binding;

    shader_dependencies     : [] string;

    has_vertex_shader       := false;
    has_fragment_shader     := false;

    slang_time              : float64;
};

transpile_shader_to_native :: (shader_name: string, slang_filepath: string, slang_buffer: string) -> success: bool, result: Shader_Transpilation_Result {
    using result: Shader_Transpilation_Result;

    vertex_shader_buffer   : string;
    fragment_shader_buffer : string;

    defer free(vertex_shader_buffer);
    defer free(fragment_shader_buffer);

    using Slang;

    program: *IComponentType;
    defer safe_release(program);


    diagnostic_blob: *ISlangBlob;
    defer safe_release(diagnostic_blob);

    if !slang_global_session {
        slang_createGlobalSession(SLANG_API_VERSION, *slang_global_session);
    }

    if !slang_global_session {
        shader_log(shader_name, "Could not create slang global session.");
        return false, result;
    }

    slang_time_start := current_time_monotonic();

    session_desc : SessionDesc;
    target_descs : [..] TargetDesc;
    target_descs.allocator = temp;

    if OS == {
        case .MACOS;
            array_add(*target_descs, .{ format = .METAL, flags = xx SLANG_TARGET_FLAG.GENERATE_WHOLE_PROGRAM });
        case .WINDOWS;
            array_add(*target_descs, .{
                format  = .HLSL,
                flags   = xx SLANG_TARGET_FLAG.GENERATE_WHOLE_PROGRAM,
                profile = IGlobalSession_findProfile(slang_global_session, "sm_5_0"),
            });
    }

    session_desc.targets                    = target_descs.data;
    session_desc.targetCount                = xx target_descs.count;
    session_desc.defaultMatrixLayoutMode    = .ROW_MAJOR; // Already the default but just to be explicit


    options: [..] CompilerOptionEntry;
    options.allocator = temp;

    array_add(*options, .{ .VulkanUseEntryPointName, .{ kind = .Int, intValue0 = 1 } });

    array_add(*options, .{
        .Language, .{ kind = .Int, intValue0 = xx SlangSourceLanguage.SLANG_SOURCE_LANGUAGE_HLSL },
    });

    if disable_slang_optimizations {
        array_add(*options, .{ .Optimization, .{ kind = .Int, intValue0 = 0 } });
    }

    session_desc.compilerOptionEntries      = options.data;
    session_desc.compilerOptionEntryCount   = xx options.count;

    session: *ISession;
    defer safe_release(session);

    IGlobalSession_createSession(slang_global_session, *session_desc, *session);
    if !session {
        shader_log(shader_name, "Could not create slang session");
        return false, result;
    }

    slang_cfilepath   := to_c_string(slang_filepath ,, temp);
    slang_cbuffer     := to_c_string(slang_buffer   ,, temp);

    slang_module         := ISession_loadModuleFromSourceString(session, slang_cfilepath, slang_cfilepath, slang_cbuffer, *diagnostic_blob);
    defer safe_release(slang_module);

    if !slang_module {
        shader_log(shader_name, diagnostic_blob);
        return false, result;
    }

    if diagnostic_blob {
        log("Shader '%' compilation messages:\n%", shader_name, diagnostic_to_string(diagnostic_blob), flags=.WARNING);
    }

    vertex_main, fragment_main: *IEntryPoint;
    defer safe_release(vertex_main);
    defer safe_release(fragment_main);

    IModule_findEntryPointByName(slang_module, VERTEX_ENTRY_POINT, *vertex_main);
    IModule_findEntryPointByName(slang_module, FRAGMENT_ENTRY_POINT, *fragment_main);

    if !vertex_main && !fragment_main {
        shader_log(shader_name, "No entry point was found in shader. This may be due to Slang library not being present in the same directory as the executable");
        return false, result;
    }

    component_types: [..] *IComponentType;
    component_types.allocator = temp;
    array_add(*component_types, slang_module);

    vertex_main_index, fragment_main_index : s32 = -1;
    if vertex_main {
        vertex_main_index = xx (component_types.count - 1);
        array_add(*component_types, vertex_main);
    }

    if fragment_main {
        fragment_main_index = xx (component_types.count - 1);
        array_add(*component_types, fragment_main);
    }


    if ISession_createCompositeComponentType(session, component_types.data, component_types.count, *program, *diagnostic_blob) < 0 {
        shader_log(shader_name, diagnostic_blob);
        return false, result;
    }

    if IComponentType_link(program, *program, *diagnostic_blob) < 0 {
        shader_log(shader_name, diagnostic_blob);
        return false, result;
    }

    vertex_blob   : *ISlangBlob;
    defer safe_release(vertex_blob);

    fragment_blob : *ISlangBlob;
    defer safe_release(fragment_blob);

    vertex_buffer, fragment_buffer: string;

    if vertex_main {
        if IComponentType_getEntryPointCode(program, vertex_main_index, 0, *vertex_blob, *diagnostic_blob) < 0 {
            shader_log(shader_name, diagnostic_blob);
            return false, result;
        }

        vertex_buffer = string.{
            data    = ISlangBlob_getBufferPointer(vertex_blob),
            count   = xx ISlangBlob_getBufferSize(vertex_blob),
        };
    }

    if fragment_main {
        if IComponentType_getEntryPointCode(program, fragment_main_index, 0, *fragment_blob, *diagnostic_blob) < 0 {
            shader_log(shader_name, diagnostic_blob);
            return false, result;
        }

        fragment_buffer = string.{
            data    = ISlangBlob_getBufferPointer(fragment_blob),
            count   = xx ISlangBlob_getBufferSize(fragment_blob),
        };
    }

    slang_time_end := current_time_monotonic();

    has_vertex_shader               = vertex_main   != null;
    has_fragment_shader             = fragment_main != null;
    slang_time                      = to_float64_seconds(slang_time_end - slang_time_start);

    // No hot reload when shaders are packed in executable.
    shader_dependencies = get_shader_dependencies(slang_filepath, slang_module);

    if has_vertex_shader {
        native_vertex_buffer    = copy_string(vertex_buffer);
        vertex_bindings         = get_slang_bindings(program, .VERTEX);
    }

    if has_fragment_shader {
        native_fragment_buffer  = copy_string(fragment_buffer);
        fragment_bindings       = get_slang_bindings(program, .FRAGMENT);
    }

    // if write_transpiled_shaders_to_disk {
    //     ext : string;
    //
    //     #if GRAPHICS_BACKEND == {
    //         case .METAL;
    //             TARGET :: "metal";
    //             ext = "metal";
    //         case .D3D11;
    //             TARGET :: "d3d11";
    //             ext = "hlsl";
    //     }
    //
    //     transpiled_vertex_filename   := tprint("src/render/shaders/transpiled_%/%.vert.%", TARGET, shader_name, ext);
    //     transpiled_fragment_filename := tprint("src/render/shaders/transpiled_%/%.frag.%", TARGET, shader_name, ext);
    //
    //     make_directory_if_it_does_not_exist(path_strip_filename(transpiled_vertex_filename), recursive=true);
    //
    //     if has_vertex_shader {
    //         log("Writing transpiled % vertex shader to '%'", TARGET, transpiled_vertex_filename);
    //         write_entire_file(transpiled_vertex_filename, native_vertex_buffer);
    //     }
    //
    //     if has_fragment_shader {
    //         log("Writing transpiled % fragment shader to '%'", TARGET, transpiled_fragment_filename);
    //         write_entire_file(transpiled_fragment_filename, native_fragment_buffer);
    //     }
    // }

    return true, result;
}

compile_native_shader :: (using loaded_shader: *GFX_Loaded_Shader,
                          native_vertex_source: string, native_fragment_source: string,
                          vertex_bindings: [] GFX_Pipeline_Binding, fragment_bindings: [] GFX_Pipeline_Binding) -> bool, float64 {

    native_time_start := current_time_monotonic();

    if native_vertex_source.count > 0 {
        ok := load_gfx_shader(loaded_shader, .VERTEX, native_vertex_source, vertex_bindings);
        if !ok return false, 0.;
    } else {
        if !is_null(*vertex_shader) then destroy_gfx_shader(*vertex_shader);
        stages &= ~.VERTEX;
    }

    if native_fragment_source.count > 0 {
        ok := load_gfx_shader(loaded_shader, .FRAGMENT, native_fragment_source, fragment_bindings);
        if !ok return false, 0.;
    } else {
        if !is_null(*fragment_shader) then destroy_gfx_shader(*fragment_shader);
        stages &= ~.FRAGMENT;
    }

    native_time_end := current_time_monotonic();

    return true, to_float64_seconds(native_time_end - native_time_start);
}


shader_log :: (shader_name: string, msg: string) {
    log_error("Could not load shader '%'\n%", shader_name, msg);
}

shader_log :: (shader_name: string, diagnostic_blob: *Slang.ISlangBlob) {
    using Slang;

    error_string := diagnostic_to_string(diagnostic_blob);

    if error_string.count < 0 {
        log_error("Could not load shader '%'", shader_name);
        return;
    }

    log_error("Could not load shader '%':\n%", shader_name, error_string);
}

get_shader_dependencies :: (shader_filename: string, module: *Slang.IModule) -> []string {
    using Slang;

    dependencies: [..] string;

    for dependencies {
        free(it.data);
    }

    array_reset_keeping_memory(*dependencies);

    filename := copy_string(get_absolute_path(shader_filename ,, temp));

    path_overwrite_separators(filename, #char "/");
    array_add(*dependencies, filename);

    if module {
        num_dependencies := IModule_getDependencyFileCount(module);

        for i : 0..num_dependencies - 1 {
            dependency := to_string(IModule_getDependencyFilePath(module, i));
            dependency = copy_string(dependency);
            path_overwrite_separators(dependency, #char "/");

            array_add(*dependencies, dependency);
        }
    }

    return dependencies;
}

safe_release :: (obj: *Slang.ISlangUnknown) {
    if obj then Slang.ISlangUnknown_release(obj);
}

diagnostic_to_string :: inline (diagnostic_blob: *Slang.ISlangBlob) -> string {
    using Slang;

    if !diagnostic_blob return "";

    return string.{
        data    = ISlangBlob_getBufferPointer(diagnostic_blob),
        count   = cast(s64) ISlangBlob_getBufferSize(diagnostic_blob),
    };
}


get_slang_bindings :: (program: *Slang.IComponentType, stage: GFX_Pipeline_Stage) -> [..] GFX_Pipeline_Binding {
    using Slang;

    bindings: [..] GFX_Pipeline_Binding;

    // In the C++ API these are the same opaque pointer, so we cast it.
    layout_ptr := IComponentType_getLayout(program, 0, null);
    reflection := cast(*SlangReflection) layout_ptr;

    if !reflection return bindings;

    // Iterate over all global parameters (Uniforms, Textures, Samplers, Buffers).
    // @note: Slang only lists parameters that are actually active/used in the shader.
    param_count := spReflection_GetParameterCount(reflection);

    if param_count <= 0 return bindings;

    for i: 0..param_count - 1 {
        param := spReflection_GetParameterByIndex(reflection, i);

        binding_index := spReflectionParameter_GetBindingIndex(param);

        var         := spReflectionVariableLayout_GetVariable(param);
        name_cstr   := spReflectionVariable_GetName(var);

        if !name_cstr continue;

        type_layout := spReflectionVariableLayout_GetTypeLayout(param);
        type        := spReflectionTypeLayout_GetType(type_layout);
        kind        := spReflectionType_GetKind(type);

        binding_type := GFX_Pipeline_Binding_Type.UNIFORM_BUFFER;
        is_valid     := false;

        if kind == {
            case .SLANG_TYPE_KIND_CONSTANT_BUFFER;
                binding_type = .UNIFORM_BUFFER;
                is_valid = true;

            case .SLANG_TYPE_KIND_SAMPLER_STATE;
                binding_type = .SAMPLER_STATE;
                is_valid = true;

            case .SLANG_TYPE_KIND_RESOURCE;
                // Resources can be Textures or Storage Buffers.
                shape := spReflectionType_GetResourceShape(type);

                // Mask out the flags to get the base shape.
                base_shape := shape & .SLANG_RESOURCE_BASE_SHAPE_MASK;

                if base_shape == .SLANG_STRUCTURED_BUFFER || base_shape == .SLANG_BYTE_ADDRESS_BUFFER {
                    binding_type = .STORAGE_BUFFER;
                } else {
                    binding_type = .TEXTURE;
                }


                is_valid = true;

            case; continue;
        }

        if is_valid {
            binding      := array_add(*bindings);
            binding.name  = copy_string(to_string(name_cstr));
            binding.type  = binding_type;
            binding.stage = stage;
            binding.index = xx binding_index;
        }
    }

    return bindings;
}
//
// get_vertex_shader :: (name: string) -> *GFX_Shader {
//     for * loaded_shaders {
//         if it.name == name {
//             assert(!is_null(*it.vertex_shader), "Shader '%' has no vertex entry point", name);
//             return *it.vertex_shader;
//         }
//     }
//
//     crash("No shader named '%'", name);
//
//     return null;
// }
//
// get_fragment_shader :: (name: string) -> *GFX_Shader {
//     for * loaded_shaders {
//         if it.name == name {
//             assert(!is_null(*it.fragment_shader), "Shader '%' has no fragment entry point", name);
//             return *it.fragment_shader;
//         }
//     }
//
//     crash("No shader named '%'", name);
//
//     return null;
// }

#scope_export

// set_vertex_shader :: (shader_name: string) {
//     set_vertex_shader(get_vertex_shader(shader_name));
// }
//
// set_pixel_shader :: (shader_name : string) {
//     set_pixel_shader(get_fragment_shader(shader_name));
// }

#import "File_Watcher";
#import "File";
