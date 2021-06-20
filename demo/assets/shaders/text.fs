#version 330 core

out vec4 FragColor;

in vec2 TexCoord;
in vec4 Color;

uniform sampler2D glyph;

float width = 0.50; 
const float edge = 1.0/16.0;

void main() {
  float distance = texture(glyph, TexCoord).r;
  float alpha = smoothstep(width - edge, width + edge, distance);

  FragColor = vec4(Color.xyz, alpha);
}
