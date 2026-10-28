class_name IslandCrab
extends CharacterBody2D

## A beach crab for Crab Cove. It wanders on its own and scuttles away from
## `threat` (the player) when they come close, which is what lets you herd it.
## Drawn in code as a placeholder.

@export var wander_speed: float = 35.0
@export var flee_speed: float = 125.0
## The crab starts running when the player is closer than this.
@export var flee_radius: float = 120.0
@export var color: Color = Color8(214, 86, 52)

var threat: Node2D
var penned: bool = false

var _wander_direction: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Crabs live on layer 2 so they never block the player; they still bump
	# into the island's edge (layer 1).
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	_time = randf() * 10.0


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if penned:
		velocity = Vector2.ZERO
		return

	var away := Vector2.ZERO
	if is_instance_valid(threat):
		away = global_position - threat.global_position

	if away != Vector2.ZERO and away.length() < flee_radius:
		# Run away, zig-zagging sideways like a crab. Closer = faster.
		var urgency := 1.0 - away.length() / flee_radius * 0.5
		var direction := away.normalized().rotated(sin(_time * 7.0) * 0.45)
		velocity = direction * flee_speed * urgency
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(0.8, 2.2)
			_wander_direction = Vector2.ZERO if randf() < 0.35 else Vector2.from_angle(randf() * TAU)
		velocity = _wander_direction * wander_speed

	move_and_slide()
	# Pinned against the shore: slip sideways instead of sticking forever.
	if is_on_wall() and velocity.length() > 0.0:
		var normal := get_wall_normal()
		velocity = normal.orthogonal() * signf(normal.orthogonal().dot(velocity) + 0.01) * flee_speed * 0.6
		move_and_slide()


func _draw() -> void:
	var leg_wiggle := sin(_time * (14.0 if velocity.length() > 1.0 else 2.0)) * 2.0
	var leg_color := color.darkened(0.3)
	for side in [-1.0, 1.0]:
		for i in 3:
			var start := Vector2(side * 6.0, -2.0 + i * 3.0)
			var end := Vector2(side * 13.0, -4.0 + i * 4.0 + (leg_wiggle if i % 2 == 0 else -leg_wiggle))
			draw_line(start, end, leg_color, 2.0)
		# Claws.
		draw_circle(Vector2(side * 9.0, -9.0), 3.5, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, 9.0, color)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(-3, -5), 1.6, Color.BLACK)
	draw_circle(Vector2(3, -5), 1.6, Color.BLACK)
