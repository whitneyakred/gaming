extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
var using_station: bool:
	get:
		return is_instance_valid(active_station)

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null

func try_use_station(station: Node) -> bool:
	if not is_instance_valid(station) or using_station or not is_physics_processing():
		return false
	active_station = station
	velocity = Vector2.ZERO
	return true

func leave_station(station: Node) -> void:
	if active_station == station:
		active_station = null

func _physics_process(_delta: float) -> void:
	if using_station:
		velocity = Vector2.ZERO
		return
	# Read WASD / arrow keys; diagonal movement stays the same speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()
