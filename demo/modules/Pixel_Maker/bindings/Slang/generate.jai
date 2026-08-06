/*
    Currently, the slang version is v2025.24.2.

    Note: On windows, we need to link against slang-compiler only, and on
          macOS on slang.
*/

#run generate_bindings();

generate_bindings :: () -> bool {
    set_build_options_dc(.{ do_output=false });

    #if OS == .MACOS {
        file_delete("lib/macos/libslang.dylib");

        run_or_exit("lipo", "-create", "lib/macos/libslang_x86_64.dylib", "lib/macos/libslang_arm64.dylib", "-output", "lib/macos/libslang.dylib");

        run_or_exit("install_name_tool", "-id", "@rpath/libslang.dylib", "lib/macos/libslang.dylib");
        run_command("codesign", "--force", "--sign", "-", "lib/macos/libslang.dylib");
    }

    output_filename: string;
    opts: Generate_Bindings_Options; {
        using opts;

        if OS == {
            case .WINDOWS; output_filename = "windows.jai";
            case .MACOS;   output_filename = "macos.jai";
        }

        if OS == {
            case .WINDOWS; array_add(*library_search_paths, "./lib/windows");
            case .MACOS;   array_add(*library_search_paths, "./lib/macos");
        }

        if OS == {
            case .WINDOWS; array_add(*libraries, { filename = "slang-compiler" });
            case .MACOS;   array_add(*libraries, { filename = "libslang" });
        }

        array_add(*source_files, "./include/slang.h");

        array_add(*flatten_namespaces, "slang");

        array_add(*extra_clang_arguments, "-x", "c++");

        mimic_spacing_flags &= ~(Mimic_Spacing_Flags.VTABLE);
        log_stripped_declarations = true;
        // generate_compile_time_struct_checks = false;

        generate_library_declarations=false;
        visitor=handle_declaration;
    }

    return generate_bindings(opts, output_filename);
}

#scope_file

handle_declaration :: (decl: *Declaration, parent_decl: *Declaration) -> result: Declaration_Visit_Result = .RECURSE {
    // This is being set to an invalid `~u64(0)`, so manually setting it to `U64_MAX` to make it unbounded.
    if decl.name == "SLANG_UNBOUNDED_SIZE" {
        literal := cast(*Literal) decl.expression;
        literal.raw_value = tprint("%", U64_MAX);
    }

    return;
}

run_or_exit :: (command: .. string, working_directory := "") -> string {
    // Enable this to see the commands being executed.
    // Might be useful if, for example, you need to compile LLVM on a platform where we don’t have a Jai compiler yet and want to do it manually.
    log("Executing command \"%\" in directory \"%\"\n", join(..command, separator = " "), working_directory);

    result, output_string, error_string := run_command(..command, working_directory = working_directory, capture_and_return_output = true, print_captured_output = true);
    defer {
        free(error_string);
    }

    if result.exit_code != 0 {
        log_error("Could not run command \"%\" in directory \"%\". Exit code: %\nError:\n%", get_quoted_command_string(command), working_directory, result.exit_code, error_string);
        exit(1);
    }

    return output_string;
}


#import "Basic";
#import "Math";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "String";
#import "Process";
