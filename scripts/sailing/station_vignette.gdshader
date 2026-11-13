shader_type canvas_item;
render_mode unshaded;

void fragment() {
	// Leave the center clear and softly darken the screen edges.
	float radius = length((UV - vec2(0.5)) * 2.0);
	float edge = smoothstep(0.45, 1.25, radius);
	COLOR = vec4(0.0, 0.0, 0.0, edge * COLOR.a);
}
