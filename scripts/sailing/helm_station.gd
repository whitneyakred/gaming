class_name HelmStation
extends ShipStation
## A/D turns the wheel up to 1.5 revolutions either way; releasing preserves rudder.

@export_range(1.0, 360.0) var wheel_turn_speed_degrees: float = 165.0
@export_range(0.0, 90.0) var center_assist_angle_degrees: float = 25.0
@export_range(1.0, 180.0) var center_assist_speed_degrees: float = 60.0

func _apply_controls(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var angle := ship.wheel_angle_degrees
	if not is_zero_approx(direction):
		angle += direction * wheel_turn_speed_degrees * delta
	elif absf(angle) <= center_assist_angle_degrees:
		# Help only after releasing A/D near true zero, never at a full revolution.
		angle = move_toward(angle, 0.0, center_assist_speed_degrees * delta)
	ship.set_wheel_angle(angle)
