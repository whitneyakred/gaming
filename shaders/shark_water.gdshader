shader_type canvas_item;

// Atlas-space dorsal fin mask: no screen reads, extra textures or render passes.
uniform vec2 fin_tip;
uniform vec2 fin_base;
uniform float body_opacity : hint_range(0.0, 1.0) = 0.48;
uniform vec4 water_tint : source_color = vec4(0.12, 0.24, 0.38, 1.0);
varying vec4 vertex_modulate;

void vertex() {
 vertex_modulate = COLOR;
}

void fragment() {
 vec4 source = texture(TEXTURE, UV);
 vec2 p = UV / TEXTURE_PIXEL_SIZE;
 vec2 axis = fin_base - fin_tip;
 float along = dot(p - fin_tip, axis) / dot(axis, axis);
 float across = abs((p.x-fin_tip.x)*axis.y-(p.y-fin_tip.y)*axis.x) / length(axis);
 float width = mix(2.0, 12.0, clamp(along * 2.0, 0.0, 1.0));
 width *= 1.0 - smoothstep(0.65, 1.05, along);
 float fin = (1.0-smoothstep(width-1.0, width+1.0, across)) * smoothstep(-0.03, 0.03, along) * (1.0-smoothstep(0.94, 1.02, along));
 vec3 submerged = mix(source.rgb * 0.65, water_tint.rgb, 0.35);
 COLOR = vec4(mix(submerged, source.rgb, fin), smoothstep(0.55, 0.85, source.a) * mix(body_opacity, 1.0, fin)) * vertex_modulate;
}
