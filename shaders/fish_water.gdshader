shader_type canvas_item;
render_mode unshaded;
uniform float body_opacity : hint_range(0.0, 1.0) = 0.57;
uniform vec4 water_tint : source_color = vec4(0.12, 0.23, 0.38, 1.0);
uniform vec2 heads[24];
uniform vec2 rows[6];
varying vec4 fish;
void vertex() {
	fish = INSTANCE_CUSTOM;
}
void fragment() {
	float frame = mod(floor(fish.g * 4.0), 4.0);
	int species = int(floor(fish.r * 6.0));
	// QuadMesh V runs upward in canvas space; the source atlas runs downward.
	vec2 pixel = vec2(UV.x, 1.0-UV.y) * 320.0 + heads[species * 4 + int(frame)] - vec2(160.0, 40.0);
	vec4 starts = vec4(0.0,270.0,510.0,750.0);
	vec4 ends = vec4(270.0,510.0,750.0,1024.0);
	bool inside = pixel.x >= starts[int(frame)] && pixel.x < ends[int(frame)] && pixel.y >= rows[species].x && pixel.y < rows[species].y;
	vec4 source = texture(TEXTURE, pixel * TEXTURE_PIXEL_SIZE);
	vec3 submerged = mix(source.rgb * 0.75, water_tint.rgb, 0.38);
	COLOR = vec4(submerged, smoothstep(0.45, 0.85, source.a) * body_opacity * fish.b * float(inside));
}
