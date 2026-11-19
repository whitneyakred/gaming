shader_type canvas_item;
void fragment() { vec4 c = texture(TEXTURE, UV); COLOR = vec4(c.rgb, smoothstep(0.55, 0.85, c.a)); }
