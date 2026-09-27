class_name HelmWheelWidget
extends Control

var wheel_angle := 0.0

func set_helm_state(active: bool, angle_degrees: float) -> void:
	visible = active
	wheel_angle = deg_to_rad(angle_degrees)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 96.0)
	draw_set_transform(center, wheel_angle)
	# Chunky wood spokes use the same muted palette as the main ship sprite.
	var rim := PackedVector2Array()
	for index in range(17):
		var direction := Vector2.UP.rotated(TAU * float(index) / 16.0)
		rim.append((direction * 58.0 / 2.0).round() * 2.0)
	draw_polyline(rim, Color("594737"), 12.0)
	draw_polyline(rim, Color("ac9272"), 6.0)
	for index in range(8):
		var direction := Vector2.UP.rotated(TAU * float(index) / 8.0)
		draw_line(Vector2.ZERO, direction * 76, Color("594737"), 10.0)
		draw_line(direction * 8, direction * 74, Color("c4ab86"), 4.0)
	draw_rect(Rect2(-10, -10, 20, 20), Color("594737"))
	draw_rect(Rect2(-6, -6, 12, 12), Color("c4ab86"))
	draw_rect(Rect2(-4, -80, 8, 10), Color("f4e4b2"))
	draw_set_transform(Vector2.ZERO)
	var turns := rad_to_deg(wheel_angle) / 360.0
	var readout := "Centered" if is_zero_approx(wheel_angle) else "%s %.2f turns" % ["Left" if turns < 0.0 else "Right", absf(turns)]
	draw_string(ThemeDB.fallback_font, Vector2(12.0, 202.0), readout,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 24.0, 16, Color("f4e4b2"))
