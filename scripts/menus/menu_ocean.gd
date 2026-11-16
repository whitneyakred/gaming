extends Control
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not GameWindow.preferences.reduced_motion:
		_time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142f40"))
	for row in 22:
		for column in 32:
			var phase := float(row * 17 + column * 31)
			var point := Vector2(column * 48 + sin(_time * 0.22 + phase) * 9, row * 38 + sin(phase) * 10)
			var color := Color("426477")
			color.a = 0.2 + 0.12 * sin(_time * 0.3 + phase)
			draw_line(point, point + Vector2(9 + posmod(row + column, 4) * 3, 0), color, 2)
	# Expanding elliptical ripples follow the decorative ship's bobbing cycle.
	var title := get_parent()
	var origin: Vector2 = title.logo_ship.position + Vector2(title.logo_ship.size.x * 0.5, title.logo_ship.size.y * 0.83)
	for ring in 4:
		var phase := fposmod(_time * title.ship_bob_speed / TAU + float(ring) / 4.0, 1.0)
		var radius := lerpf(70.0, 270.0, phase)
		var opacity := sin(phase * PI) * 0.22
		var points := PackedVector2Array()
		for i in 97:
			var angle := float(i) / 96.0 * TAU
			points.append(origin + Vector2(cos(angle) * radius, sin(angle) * radius * 0.12))
		draw_polyline(points, Color(0.48, 0.76, 0.82, opacity), 1.5, true)
