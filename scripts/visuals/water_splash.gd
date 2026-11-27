extends Node2D
## One short-lived draw node: fixed droplet count, no textures or physics particles.
const LIFETIME := 0.75
var age: float = 0.0

func _ready() -> void:
	add_to_group("water_splashes")
	set_as_top_level(true)
	global_rotation = 0.0
	z_index = -1

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var t := age / LIFETIME
	var fade := 1.0 - t
	# Two expanding broken elliptical foam rings.
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.48))
	for ring in 2:
		var radius := 5.0 + t * 25.0 + ring * 5.0
		for segment in 6:
			var start := segment * TAU / 6.0 + ring * 0.25
			draw_arc(Vector2.ZERO, radius, start, start + 0.65, 5, Color(0.65, 0.89, 1.0, fade * (0.8 - ring * 0.25)), 2.0)
	draw_set_transform(Vector2.ZERO)
	for index in 12:
		var angle := index * TAU / 12.0
		var spread := Vector2(cos(angle), sin(angle) * 0.45)
		var point := spread * (5.0 + t * (22.0 + (index % 3) * 4.0))
		point.y -= sin(t * PI) * (10.0 + (index % 4) * 3.0)
		point = point.snapped(Vector2(2, 2))
		var width := 3.0 if index % 2 == 0 else 2.0
		draw_rect(Rect2(point, Vector2(width, width + 1)), Color(0.78, 0.94, 1, fade))
