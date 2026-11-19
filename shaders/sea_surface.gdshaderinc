uniform sampler2D ocean_texture : source_color, filter_nearest, repeat_enable;
uniform float ocean_time = 0.0;
vec3 sea(vec2 position) {
 vec2 p = floor(position / 2.0) * 2.0;
 vec2 drift = vec2(sin(p.y * 0.009 + ocean_time * 0.35), cos(p.x * 0.008 - ocean_time * 0.27)) * 5.0;
 vec2 uv = (p + drift + vec2(ocean_time * 1.8, ocean_time * 0.6)) / 768.0;
 // Mirroring makes the non-tileable painted texture continuous at every boundary.
 uv = 1.0 - abs(mod(uv, 2.0) - 1.0);
 vec3 base = texture(ocean_texture, uv).rgb;
 float swell = sin(p.x * 0.012 + p.y * 0.019 - ocean_time * 0.65);
 return base + vec3(0.028, 0.038, 0.045) * swell;
}
