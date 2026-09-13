extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0

func _physics_process(_delta: float) -> void:
	# Read WASD / arrow keys; diagonal movement stays the same speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()
