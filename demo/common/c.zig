pub const glfw = @cImport({
    @cDefine("GL_SILENCE_DEPRECATION", "");
    @cDefine("GLFW_INCLUDE_GLCOREARB", "");
    @cInclude("GLFW/glfw3.h");
});

pub const stb = @cImport({
     @cInclude("stb_image.h");
});

pub const gl = @cImport({
     @cInclude("epoxy/gl.h");
});
