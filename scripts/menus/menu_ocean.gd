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
	# Restrained chart rings and compass ticks, drawn without external textures.
	var origin := Vector2(330, 330)
	for radius in [220, 290, 360]:
		draw_arc(origin, radius, 0, TAU, 96, Color(0.6, 0.7, 0.65, 0.07), 1)
	for i in 32:
		var direction := Vector2.from_angle(i * TAU / 32)
		draw_line(origin + direction * 288, origin + direction * (302 if i % 4 == 0 else 295), Color(0.8, 0.7, 0.45, 0.15), 2)
