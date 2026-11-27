shader_type canvas_item;
render_mode unshaded;
uniform sampler2D atlas : source_color, filter_nearest, repeat_disable;
uniform vec2 quadrant = vec2(0.0);
uniform vec2 offset = vec2(0.0);
uniform float tile_world = 700.0;
uniform float tone = 1.0;
varying vec2 ground;
void vertex() { ground = VERTEX + offset; }
void fragment() {
    // Mirrored sampling joins any source edge to itself: no atlas gutters/seams.
    // Quantize in world space to retain the reference art's chunky pixels.
    vec2 p = floor(ground / 3.0) * 3.0 / tile_world;
    vec2 local_uv = 1.0 - abs(mod(p, 2.0) - 1.0);
    vec2 inset_uv = mix(vec2(0.004), vec2(0.996), local_uv);
    vec3 base = texture(atlas, (quadrant + inset_uv) * 0.5).rgb;
    // A second incommensurate sample breaks the repeated diamond/mirror pattern.
    vec2 alternate = 1.0 - abs(mod(p.yx * 0.731 + vec2(0.37,0.63), 2.0) - 1.0);
    vec3 detail = texture(atlas,(quadrant+mix(vec2(0.004),vec2(0.996),alternate))*0.5).rgb;
    COLOR = vec4(floor(mix(base,detail,0.38)*tone*64.0)/64.0,1.0);
}
