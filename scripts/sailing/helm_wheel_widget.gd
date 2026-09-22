class_name HelmWheelWidget
extends Control

const WHEEL_TEXTURE: Texture2D = preload("res://assets/sailing/steering_wheel.png")
var wheel_angle := 0.0

func set_helm_state(active: bool, angle_degrees: float) -> void:
	visible = active
	wheel_angle = deg_to_rad(angle_degrees)
	queue_redraw()

func _draw() -> void:
	# The reference ring is part of the PNG and rotates with the entire wheel.
	var center := Vector2(size.x * 0.5, 96.0)
	draw_set_transform(center, wheel_angle)
	draw_texture_rect(WHEEL_TEXTURE, Rect2(-88.0, -88.0, 176.0, 176.0), false)
	draw_set_transform(Vector2.ZERO)
	var turns := rad_to_deg(wheel_angle) / 360.0
	var readout := "Centered" if is_zero_approx(wheel_angle) else "%s %.2f turns" % ["Left" if turns < 0.0 else "Right", absf(turns)]
	draw_string(ThemeDB.fallback_font, Vector2(12.0, 202.0), readout,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 24.0, 16, Color("f4e4b2"))


