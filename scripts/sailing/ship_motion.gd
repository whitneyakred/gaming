class_name ShipMotion
extends Node2D
## Owns movement only. Stations submit commands; this script never reads input.

signal sail_changed()

@export_range(0.0, 500.0) var maximum_speed: float = 110.0
@export_range(0.1, 200.0) var acceleration: float = 22.0
@export_range(0.1, 200.0) var deceleration: float = 30.0
@export_range(1.0, 300.0) var anchor_braking: float = 65.0
@export_range(0.1, 3.0) var maximum_wheel_turns: float = 1.5
## Radians per second, matching the reference project's gradual rudder steering.
@export_range(0.01, 1.0) var maximum_turn_rate: float = 0.16
@export_range(0.01, 1.0) var turn_acceleration: float = 0.07
## Direction the wind blows TOWARD; length is strength, clamped to 0..1.
@export var wind_velocity: Vector2 = Vector2(0.6, -0.8)

var speed: float = 0.0
var sail_level: int = 0
var sail_angle_degrees: float = 0.0
var wheel_angle_degrees: float = 0.0
var turn_rate: float = 0.0
var anchor_deployed: bool = false

func _ready() -> void:
	# Move the shared parent before crew perform their own walking/collision step.
	process_physics_priority = -10

func set_wheel_angle(degrees: float) -> void:
	var limit := maximum_wheel_turns * 360.0
	wheel_angle_degrees = clampf(degrees, -limit, limit)

# Movement/weather state is owned here; each station captures its own controls.
func capture_state() -> Dictionary:
	return {"position": position, "rotation": rotation, "speed": speed,
		"turn_rate": turn_rate, "wind": wind_velocity}

func restore_state(state: Dictionary, restore_transform: bool = false) -> void:
	speed = state.speed
	turn_rate = state.turn_rate
	wind_velocity = state.wind
	if restore_transform:
		position = state.position
		rotation = state.rotation

func set_sail_level(level: int) -> void:
	var bounded_level := clampi(level, 0, 3)
	if sail_level != bounded_level:
		sail_level = bounded_level
		sail_changed.emit()

func set_sail_angle(degrees: float) -> void:
	var bounded_angle := clampf(degrees, -60.0, 60.0)
	if not is_equal_approx(sail_angle_degrees, bounded_angle):
		sail_angle_degrees = bounded_angle
		sail_changed.emit()

func get_target_speed() -> float:
	if anchor_deployed:
		return 0.0
	var sail_direction := Vector2.UP.rotated(global_rotation + deg_to_rad(sail_angle_degrees))
	var strength := clampf(wind_velocity.length(), 0.0, 1.0)
	# The cloth billows along sail_direction. Only wind pushing that way fills it.
	# No artificial propulsion in calm air or with wind on the wrong side.
	var alignment := clampf(sail_direction.dot(wind_velocity.normalized()), 0.0, 1.0)
	var wind_factor := strength * alignment * alignment
	return maximum_speed * (float(sail_level) / 3.0) * wind_factor

func _physics_process(delta: float) -> void:
	simulate_movement(delta)

func simulate_movement(delta: float) -> void:
	# Wheel displacement sets rudder strength. Centering the wheel eases out of a turn.
	var rudder := wheel_angle_degrees / (maximum_wheel_turns * 360.0)
	var steerage := clampf(speed / 100.0, 0.08, 1.0)
	turn_rate = move_toward(turn_rate, rudder * maximum_turn_rate * steerage, turn_acceleration * delta)
	if anchor_deployed:
		turn_rate = 0.0
	global_rotation += turn_rate * delta
	var target_speed := get_target_speed()
	var rate := acceleration if target_speed > speed else deceleration
	if anchor_deployed:
		rate = anchor_braking
	speed = move_toward(speed, target_speed, rate * delta)
	global_position += Vector2.UP.rotated(global_rotation) * speed * delta
	# Deck and crew inherit the same transform. Do not also add ship velocity to crew.
	force_update_transform()
	for child in get_children():
		if child is CollisionObject2D:
			(child as CollisionObject2D).force_update_transform()
