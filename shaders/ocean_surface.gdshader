shader_type canvas_item;
uniform float danger_edge = 11000.0;
#include "res://shaders/sea_surface.gdshaderinc"
uniform bool world_anchored = false;
uniform bool screen_space = false;
uniform float ambient_scroll = 0.0;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
 vec2 p = screen_space ? FRAGCOORD.xy : world_position;
 vec3 color = sea(p + vec2(0.0, ambient_scroll));
 if (world_anchored && max(abs(p.x), abs(p.y)) > danger_edge) color = mix(color, vec3(0.40,0.13,0.21), 0.7);
 COLOR = vec4(color, 1.0);
}

