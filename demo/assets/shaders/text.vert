#version 330 core

layout (location = 0) in vec2 inPos;
layout (location = 1) in vec2 inTexCoord;
layout (location = 2) in vec4 inColor;

out vec2 TexCoord;
out vec4 Color;

// Orthogonal 
uniform mat4 projection;

void main() {
    TexCoord = inTexCoord;
    Color = inColor;

    gl_Position = projection * vec4(inPos, 0, 1);
}
