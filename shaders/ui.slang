struct Vertex_Out {
    float4 position     : SV_Position;
    float2 uv           : TEXCOORD0;
    float4 color        : COLOR;
};

struct Vertex {
    float2 position     : TEXCOORD0;
    float2 tex_coords   : TEXCOORD1;
    float4 color        : TEXCOORD2;
};

struct Frame_Info {
    float4x4 ortho;
};

ConstantBuffer<Frame_Info>  frame_info;
Texture2D                   immediate_texture;
SamplerState                default_sampler;

[shader("vertex")]
Vertex_Out vertex_main(Vertex vertex) {
    Vertex_Out result;

    float4 position     = float4(vertex.position.xy, 0, 1);

    result.position     = mul(frame_info.ortho, position);
    result.uv           = vertex.tex_coords;
    result.color        = vertex.color;

    return result;
}

[shader("fragment")]
float4 fragment_main(Vertex_Out input) : SV_Target {
    float4 sampled = immediate_texture.Sample(default_sampler, input.uv);
    return input.color * sampled;
}
