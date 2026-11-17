shader_type canvas_item;
#include "res://shaders/sea_surface.gdshaderinc"
void fragment() {
 vec4 wood = texture(TEXTURE, UV);
 // Reject only the faint generation halo; retain the solid pixel silhouette.
 float alpha = smoothstep(0.55, 0.85, wood.a);
 float line = 0.80 - UV.x * 0.23 + sin(UV.x * 30.0 + ocean_time * 0.8) * 0.012 + sin(ocean_time * 0.45) * 0.012;
 float depth = smoothstep(line - 0.025, line + 0.13, UV.y);
 vec3 water = sea(FRAGCOORD.xy);
 vec3 color = mix(wood.rgb, mix(wood.rgb * vec3(0.48,0.60,0.87), water, 0.66), depth);
 float edge = 1.0 - smoothstep(0.001, 0.004, abs(UV.y - line + sin(UV.x * 240.0) * 0.003));
 vec2 step_uv = TEXTURE_PIXEL_SIZE * 4.0;
 float nearby = max(max(texture(TEXTURE, UV + vec2(step_uv.x,0)).a, texture(TEXTURE, UV - vec2(step_uv.x,0)).a), max(texture(TEXTURE, UV + vec2(0,step_uv.y)).a, texture(TEXTURE, UV - vec2(0,step_uv.y)).a));
 float rim = max(0.0, smoothstep(0.7,0.9,nearby) - alpha) * smoothstep(line - 0.13,line,UV.y);
 float froth = step(0.15, sin(UV.y * 370.0 + UV.x * 270.0 + ocean_time * 1.4));
 float broken = step(0.15, sin(UV.x * 115.0 + ocean_time * 1.2));
 color = mix(color, vec3(0.79,0.89,0.94), edge * broken * 0.65);
 color = mix(color, vec3(0.70,0.85,0.94), rim * froth);
 COLOR = vec4(color, max(alpha, rim * froth * 0.7));
}

