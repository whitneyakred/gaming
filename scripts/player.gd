extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null

# Standalone scenes read the keyboard. Networked crew only receive server movement.
var read_local_input: bool = true

func try_use_station(station: Node) -> bool:
	if not is_instance_valid(station) or is_instance_valid(active_station):
		return false
	active_station = station
	velocity = Vector2.ZERO
	return true

func leave_station(station: Node) -> void:
	if active_station == station:
		active_station = null

func _physics_process(_delta: float) -> void:
	if read_local_input:
		apply_movement(Input.get_vector("move_left", "move_right", "move_up", "move_down"))

# Called by the server for networked crew; standalone scenes still read local input above.
func apply_movement(direction: Vector2) -> void:
	if is_instance_valid(active_station):
		velocity = Vector2.ZERO
		return
	# Clamp input so diagonal movement (or a network request) cannot exceed walk speed.
	velocity = direction.limit_length() * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()
