class_name SwimWake
extends Node2D
## Local-only cosmetic samples of the already predicted/interpolated player.
## No RPCs, replicated state, physics bodies, or per-particle nodes.
@export var lifetime: float = 1.8
@export var spacing: float = 7.0
@export var maximum_samples: int = 32
var samples: Array[Dictionary] = []
var last_position: Vector2
var last_respawn: int = 0
var active := false
var remainder := 0.0
var idle_clock := 0.0
@onready var crew: CharacterBody2D = get_parent()

func _ready() -> void:
	set_as_top_level(true)
	global_transform = Transform2D.IDENTITY
	z_index = -11
	process_priority = 100
	last_position = crew.global_position

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if delta <= 0: return
	for sample in samples: sample.age += delta
	while not samples.is_empty() and samples[0].age >= lifetime: samples.pop_front()
	var at: Vector2 = crew.visual_position()
	var displacement := at - last_position
	var distance := displacement.length()
	var swimming: bool = crew.is_overboard and not crew.on_land and crew.health > 0 and not crew.island_challenge and crew.access_motion == &""
	var jumped: bool = distance > 100 or crew.respawn_serial != last_respawn
	if jumped:
		samples.clear()
		remainder = 0
		idle_clock = 0
	if swimming and active and not jumped:
		if distance > 0.05:
			var direction := displacement / distance
			var traveled := spacing - remainder
			# Spacing-based emission is stable across frame rates, bounded even in dev speed.
			while traveled <= distance:
				if samples.size() >= maximum_samples: samples.pop_front()
				samples.append({"position": last_position + direction * traveled, "side": direction.orthogonal(), "age": 0.0, "idle": false})
				traveled += spacing
			remainder = fmod(remainder + distance, spacing)
			idle_clock = 0
		else:
			idle_clock += delta
			if idle_clock >= 0.55 and samples.size() < maximum_samples:
				idle_clock = 0
				samples.append({"position": at, "side": Vector2.RIGHT, "age": 0.0, "idle": true})
	else:
		remainder = 0
		idle_clock = 0
	active = swimming
	last_position = at
	last_respawn = crew.respawn_serial
	queue_redraw()

func _draw() -> void:
	for index in samples.size():
		var sample: Dictionary = samples[index]
		var fade: float = pow(maxf(0, 1.0 - sample.age / lifetime), 1.5)
		var width: float = 7.0 + sample.age * 8.0
		var center: Vector2 = sample.position + Vector2(0, -2)
		var tint := Color(0.66, 0.77, 0.91, fade * 0.42)
		if sample.idle:
			draw_arc(center, width, 0.2, PI - 0.2, 10, tint, 1.0)
		else:
			for side in [-1.0, 1.0]:
				var point: Vector2 = (center + sample.side * width * side).snapped(Vector2(2, 2))
				if index > 0 and not samples[index - 1].idle:
					var previous: Dictionary = samples[index - 1]
					if previous.position.distance_to(sample.position) < spacing * 3:
						var start: Vector2 = previous.position + Vector2(0, -2) + previous.side * (7.0 + previous.age * 8.0) * side
						draw_line(start, point, Color(0.53, 0.69, 0.86, fade * 0.16), 2.0)
				draw_rect(Rect2(point, Vector2(3, 2)), tint)
				draw_rect(Rect2(point - sample.side * 3, Vector2(2, 2)), Color(0.48, 0.62, 0.83, fade * 0.18))
