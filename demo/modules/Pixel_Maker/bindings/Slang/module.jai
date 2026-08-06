#if OS == {
    case .WINDOWS;
        #load "windows.jai";
        slang_compiler :: #library "lib/windows/slang-compiler";
    case .MACOS;
        #load "macos.jai";
        libslang :: #library "lib/macos/libslang";

    case; assert(false, "Slang not compiled for this OS.");
}
