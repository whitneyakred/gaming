class_name HelmWheelWidget
extends Control

var wheel_angle := 0.0
var maximum_angle_degrees := 540.0

func set_helm_state(active: bool, angle_degrees: float) -> void:
	visible = active
	wheel_angle = deg_to_rad(angle_degrees)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 96.0)
	draw_set_transform(center, wheel_angle)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	draw_texture_rect(preload("res://assets/props/helm_wheel_pixel.tres"), Rect2(-80, -80, 160, 160), false)
	draw_set_transform(Vector2.ZERO)
	# Fixed pointer makes the marked spoke legible while the wheel rotates.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-5, -91), center + Vector2(5, -91), center + Vector2(0, -83)]), Color("e8dcc3"))
	# Signed rudder fill grows outward from neutral toward the steering direction.
	var amount := clampf(wheel_angle / deg_to_rad(maximum_angle_degrees), -1.0, 1.0)
	var bar := Rect2(20, 190, size.x - 40, 12)
	draw_rect(bar.grow(2), Color("594737"))
	draw_rect(bar, Color("252632"))
	var midpoint := bar.get_center().x
	var width := absf(amount) * bar.size.x * 0.5
	draw_rect(Rect2(midpoint - width if amount < 0 else midpoint, bar.position.y, width, bar.size.y), Color("e4bb62"))
	draw_line(Vector2(midpoint, 186), Vector2(midpoint, 206), Color("f4e4b2"), 2)
