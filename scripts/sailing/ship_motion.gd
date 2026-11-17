class_name ShipMotion
extends Node2D
## Owns ship movement and local wind. Stations submit commands; no input is read here.

signal sail_changed()
signal anchor_changed(deployed: bool)

@export_range(0.0, 500.0) var maximum_speed: float = 110.0
## Minimum fraction of each sail level's speed, even in calm air or a headwind.
@export_range(0.0, 1.0, 0.05) var minimum_sailing_factor: float = 0.25
@export_range(0.1, 200.0) var acceleration: float = 22.0
@export_range(0.1, 200.0) var deceleration: float = 30.0
@export_range(1.0, 300.0) var anchor_braking: float = 65.0
@export_range(0.1, 3.0) var maximum_wheel_turns: float = 1.5
## Radians per second, matching the reference project's gradual rudder steering.
@export_range(0.01, 1.0) var maximum_turn_rate: float = 0.16
@export_range(0.01, 1.0) var turn_acceleration: float = 0.07
## Direction the wind blows TOWARD; length is strength, clamped to 0..1.
@export var wind_velocity: Vector2 = Vector2(0.6, -0.8)
@export_group("Changing Wind")
@export var changing_wind_enabled: bool = true
## Time between new targets varies from 75% to 125% of this interval.
@export_range(0.1, 60.0, 0.1, "suffix:s") var wind_change_interval: float = 20.0
## Larger values make the wind settle toward its new direction faster.
@export_range(0.01, 5.0, 0.01) var wind_response: float = 0.10
@export_group("Collision")
## The hull's outline in ship-local coordinates (bow pointing up). The ship
## can't move or turn so that this overlaps land (see _is_pose_blocked).
## Leave empty for a ship that ignores land.
@export var hull_outline: PackedVector2Array = PackedVector2Array()
## Share of speed kept while grazing along a shore.
@export_range(0.0, 1.0) var shore_slide_factor: float = 0.6
## How fast (radians per second) the hull swings to run alongside the shore
## after it touches land.
@export_range(0.0, 3.0) var graze_turn_rate: float = 0.6
## How strongly the hull is nudged back out to sea while grazing (share of speed).
@export_range(0.0, 1.0) var shore_push: float = 0.15

var _wind_change_left: float = 0.0
var _target_wind_angle: float = 0.0
var _wind_random := RandomNumberGenerator.new()

var speed: float = 0.0
var sail_level: int = 0
var sail_angle_degrees: float = 0.0
var wheel_angle_degrees: float = 0.0
var turn_rate: float = 0.0
var stations_enabled: bool = true
## True on frames when the hull pressed against land instead of moving freely.
var aground: bool = false
var anchor_deployed: bool = false:
	set(value):
		if anchor_deployed == value:
			return
		anchor_deployed = value
		if value:
			turn_rate = 0.0
		anchor_changed.emit(value)

func _ready() -> void:
	# Move the shared parent before crew perform their own walking/collision step.
	process_physics_priority = -10
	_target_wind_angle = wind_velocity.angle()
	_wind_change_left = _next_wind_interval()

func _process(delta: float) -> void:
	# Separate from movement so anchored/docking ships still experience wind shifts.
	if not changing_wind_enabled:
		_target_wind_angle = wind_velocity.angle()
		_wind_change_left = 0.0
		return
	_wind_change_left -= delta
	if _wind_change_left <= 0.0:
		_wind_change_left = _next_wind_interval()
		# Every direction on the full circle is eligible, independent of current wind.
		_target_wind_angle = _wind_random.randf_range(-PI, PI)
	var angle := lerp_angle(wind_velocity.angle(), _target_wind_angle, 1.0 - exp(-wind_response * delta))
	# Change direction only; preserve configured strength, including completely calm air.
	wind_velocity = Vector2.from_angle(angle) * wind_velocity.length()

func _next_wind_interval() -> float:
	return maxf(0.1, wind_change_interval) * _wind_random.randf_range(0.75, 1.25)

func set_wheel_angle(degrees: float) -> void:
	var limit := maximum_wheel_turns * 360.0
	wheel_angle_degrees = clampf(degrees, -limit, limit)

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

## The hull outline placed at a position and rotation, in global coordinates.
func get_hull_polygon(at: Vector2, angle: float) -> PackedVector2Array:
	return Transform2D(angle, at) * hull_outline

## Override to stop the ship sailing through things: return true when the
## hull at this position and rotation would overlap land.
func _is_pose_blocked(_at: Vector2, _angle: float) -> bool:
	return false

## Override with the direction pointing away from the shore the ship touched
## (used to slide along it). ZERO means "just stop".
func _get_shore_normal(_at: Vector2) -> Vector2:
	return Vector2.ZERO

func get_target_speed() -> float:
	if anchor_deployed:
		return 0.0
	var sail_direction := Vector2.UP.rotated(global_rotation + deg_to_rad(sail_angle_degrees))
	var strength := clampf(wind_velocity.length(), 0.0, 1.0)
	# Deployed sails provide gentle forward motion; favorable wind adds speed.
	var alignment := clampf(sail_direction.dot(wind_velocity.normalized()), 0.0, 1.0)
	var wind_factor := strength * alignment * alignment
	return maximum_speed * (float(sail_level) / 3.0) * lerpf(minimum_sailing_factor, 1.0, wind_factor)

func _physics_process(delta: float) -> void:
	# Wheel displacement sets rudder strength. Centering the wheel eases out of a turn.
	var rudder := wheel_angle_degrees / (maximum_wheel_turns * 360.0)
	var steerage := clampf(speed / 100.0, 0.08, 1.0)
	turn_rate = move_toward(turn_rate, rudder * maximum_turn_rate * steerage, turn_acceleration * delta)
	if anchor_deployed:
		turn_rate = 0.0
	var old_position := global_position
	var old_rotation := global_rotation
	var new_rotation := old_rotation + turn_rate * delta
	var target_speed := get_target_speed()
	var rate := acceleration if target_speed > speed else deceleration
	if anchor_deployed:
		rate = anchor_braking
	speed = move_toward(speed, target_speed, rate * delta)
	var step := Vector2.UP.rotated(new_rotation) * speed * delta
	var new_position := old_position + step
	aground = false
	if _is_pose_blocked(new_position, new_rotation):
		aground = true
		var normal := _get_shore_normal(old_position)
		if normal == Vector2.ZERO:
			# No shore to slide along: just stop.
			new_position = old_position
			new_rotation = old_rotation
			turn_rate = 0.0
		else:
			var graze := _graze_pose(old_position, old_rotation, new_rotation, normal, rudder, delta)
			new_position = graze.origin
			new_rotation = graze.get_rotation()
	global_rotation = new_rotation
	global_position = new_position
	# Deck and crew inherit the same transform. Do not also add ship velocity to crew.
	force_update_transform()
	for child in get_children():
		if child is CollisionObject2D:
			(child as CollisionObject2D).force_update_transform()

## Where the hull goes this frame when it touches land: instead of sticking,
## it grazes along the shore. It slides toward the side the wheel is turned
## (or, with the wheel centred, the side the bow already leans to), swings
## round to run alongside the coast, and is nudged a little back out to sea.
## Speed is kept, so steering away or sailing on along the coast both work.
func _graze_pose(old_position: Vector2, old_rotation: float, wanted_rotation: float, normal: Vector2, rudder: float, delta: float) -> Transform2D:
	var heading := Vector2.UP.rotated(wanted_rotation)
	var starboard := heading.rotated(PI / 2.0)
	var steer := heading + starboard * clampf(rudder * 3.0, -1.0, 1.0)
	var along := normal.orthogonal()
	if along.dot(steer) < 0.0:
		along = -along
	# Heading that runs parallel to the shore in the chosen direction.
	var along_rotation := along.angle() + PI / 2.0
	var graze_rotation := rotate_toward(wanted_rotation, along_rotation, graze_turn_rate * delta)
	var move := (along * shore_slide_factor + normal * shore_push) * speed * delta
	# Try the graze; if the hull still touches, push it a little further out
	# from the shore, then fall back to keeping the old heading.
	for push: float in [0.0, 2.0, 5.0, 10.0, 20.0]:
		for angle: float in [graze_rotation, old_rotation]:
			for offset: Vector2 in [move, Vector2.ZERO]:
				var spot := old_position + offset + normal * push
				if not _is_pose_blocked(spot, angle):
					return Transform2D(angle, spot)
	return Transform2D(old_rotation, old_position)
