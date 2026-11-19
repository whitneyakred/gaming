class_name FishAtlas
extends RefCounted
## Nose registration and safe crop rows for the generated source artwork.
## Keep the original PNG intact; normalize frame alignment at sampling time.
const TEXTURE := preload("res://assets/fish/fish_swim.png")
const HEADS := [Vector2(152.27,40),Vector2(391.44,38),Vector2(631.55,40),Vector2(871.56,38),
	Vector2(149.72,288),Vector2(389.59,288),Vector2(630.71,288),Vector2(871.09,288),
	Vector2(150.15,516),Vector2(390.85,516),Vector2(630.92,516),Vector2(872.07,516),
	Vector2(148.54,783),Vector2(388.72,783),Vector2(630.11,783),Vector2(869.98,783),
	Vector2(150.82,1014),Vector2(390.94,1014),Vector2(631.08,1014),Vector2(871.45,1014),
	Vector2(150.19,1260),Vector2(391.19,1260),Vector2(629.45,1260),Vector2(871.61,1260)]
const ROWS := [Vector2(0,256),Vector2(256,500),Vector2(500,760),Vector2(760,1000),Vector2(1000,1230),Vector2(1230,1536)]

static func material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("res://shaders/fish_water.gdshader")
	result.set_shader_parameter("heads", PackedVector2Array(HEADS))
	result.set_shader_parameter("rows", PackedVector2Array(ROWS))
	return result
