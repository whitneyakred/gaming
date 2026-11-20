class_name SwimAccess
extends Node2D
## Continuous deck / sea / island travel. No island scene changes.
static var returning_by_swimming: bool = false
static var shore_return: Vector2 = Vector2.ZERO
@export var plank_end: Vector2 = Vector2(-116, -42)
@export var water_entry: Vector2 = Vector2(-145, -42)
@export var ladder_water: Vector2 = Vector2(-88, 12)
@export var ladder_lip: Vector2 = Vector2(-88, -34)
@export var ladder_top: Vector2 = Vector2(-45, -34)
@export_range(0.2, 1.5) var jump_seconds: float = 0.55
@export_range(0.1, 0.8) var dunk_seconds: float = 0.24
@export_range(0.1, 0.8) var surface_seconds: float = 0.24
@export_range(0.1, 0.5) var align_seconds: float = 0.16
@export_range(0.3, 2.0) var climb_seconds: float = 0.8
@export_range(0.1, 0.8) var step_seconds: float = 0.3
@onready var ship: Ship = get_parent()

func _physics_process(_delta: float) -> void:
	if not NetworkSession.online:
		update_crew(ship.player)

func update_crew(crew: CharacterBody2D) -> void:
	if crew.access_motion != &"":
		_advance_access(crew, get_physics_process_delta_time())
		return
	if crew.island_challenge: return
	if crew.health <= 0: return
	if not crew.is_overboard:
		if not crew.using_station and not crew.inventory_open and crew.position.distance_to(plank_end) < 14:
			_begin_access(crew, &"jump")
		return
	if crew.global_position.distance_to(ship.to_global(ladder_water)) < 20:
		_begin_access(crew, &"align")
		return
	var land := false
	for island in ship.get_islands():
		if Geometry2D.is_point_in_polygon(crew.global_position, island.get_coast()):
			land = true
			break
	crew.update_land(land)

func restore_swimmer() -> void:
	returning_by_swimming = false
	ship.player.set_overboard(true)
	ship.player.global_position = shore_return

func _begin_access(crew: CharacterBody2D, kind: StringName) -> void:
	crew.access_start = ship.to_local(crew.global_position)
	crew.access_progress = 0.0
	crew.access_motion = kind
	crew.velocity = Vector2.ZERO
	crew.set_overboard(true)
	crew.update_land(false)

func _advance_access(crew: CharacterBody2D, delta: float) -> void:
	if crew.health <= 0 or crew.island_challenge:
		crew.access_motion = &""
		return
	# Consume overshoot so slow frames don't stretch the sequence or skip impact.
	var remaining := maxf(0.0, delta)
	while remaining > 0.0 and crew.access_motion != &"":
		var duration := _phase_seconds(crew.access_motion)
		var advance := minf(remaining, (1.0 - crew.access_progress) * duration)
		crew.access_progress = minf(1.0, crew.access_progress + advance / duration)
		remaining -= advance
		_place_access(crew)
		if crew.access_progress < 0.99999: break
		_finish_phase(crew)
	if crew.idle_sprite is CrewSprite: crew.idle_sprite.refresh(0)

func _phase_seconds(phase: StringName) -> float:
	match phase:
		&"jump": return jump_seconds
		&"dunk": return dunk_seconds
		&"surface": return surface_seconds
		&"align": return align_seconds
		&"climb": return climb_seconds
		_: return step_seconds

## Guests animate only the host-confirmed phase. Never complete boarding, trigger
## a splash, or unlock movement speculatively when snapshots stop arriving.
func advance_guest_access(crew: CharacterBody2D, delta: float) -> void:
	crew.access_progress = minf(1.0, crew.access_progress + maxf(delta, 0.0) / _phase_seconds(crew.access_motion))
	_place_access(crew)

func sync_guest_access(crew: CharacterBody2D, entry: Dictionary, host_transform: Transform2D) -> void:
	var progress := clampf(float(entry.get("access_progress", 0.0)), 0.0, 1.0)
	var t := progress
	var target: Vector2
	match crew.access_motion:
		&"jump":
			target = water_entry
			t = clampf((t - 0.15) / 0.85, 0.0, 1.0)
		&"align": target = ladder_water
		&"climb": target = ladder_lip
		&"step_on": target = ladder_top
		_:
			crew.position = entry.position
			return
	# Recover the phase origin from its authoritative point on the path. Use the
	# host transform, not the delayed rendered ship, then follow the rendered ship.
	var point: Vector2 = host_transform.affine_inverse() * Vector2(entry.position)
	crew.access_start = (point - target * t) / (1.0 - t) if t < 0.999 else target
	_place_access(crew)

func _place_access(crew: CharacterBody2D) -> void:
	var t: float = crew.access_progress
	var target: Vector2
	match crew.access_motion:
		&"jump":
			target = water_entry
			t = clampf((t - 0.15) / 0.85, 0, 1) # Brief crouch before takeoff.
		&"align": target = ladder_water
		&"climb": target = ladder_lip
		&"step_on": target = ladder_top
		_: return # Dunk/surface remain at the world-space splash, not on the ship.
	crew.global_position = ship.to_global(crew.access_start.lerp(target, t))

func _finish_phase(crew: CharacterBody2D) -> void:
	match crew.access_motion:
		&"jump":
			var splash := preload("res://scripts/visuals/water_splash.gd").new()
			ship.add_child(splash)
			splash.global_position = crew.global_position
			crew.access_motion = &"dunk"
		&"dunk": crew.access_motion = &"surface"
		&"surface": crew.access_motion = &""
		&"align": crew.access_motion = &"climb"
		&"climb": crew.access_motion = &"step_on"
		&"step_on":
			crew.set_overboard(false)
			crew.position = ladder_top
	crew.access_start = ship.to_local(crew.global_position)
	crew.access_progress = 0.0
