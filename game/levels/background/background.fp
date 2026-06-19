#version 140

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4 u_repeat;
    mediump vec4 u_offset;
};

void main()
{
    // Tile the texture across the quad and add the scrolling offset
    vec2 uv = var_texcoord0.xy * u_repeat.xy + u_offset.xy;
    // Wrap so the tile repeats seamlessly
    out_fragColor = texture(tex0, fract(uv));
}
