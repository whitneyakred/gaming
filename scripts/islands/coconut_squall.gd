class_name CoconutSquall
extends IslandGame

## Coconut Squall: a storm shakes coconuts loose from the palms.
## A shadow grows where each one will land; step out of it before it hits.
## Three bonks and you're knocked out (lose). Survive until the squall passes
## (the timer runs out), then walk back to the rowboat.
## Some coconuts land in one piece. Walk over them to put them in your bag,
## during or after the storm.

@export_group("Squall")
@export var max_hits: int = 3
@export var terrain_path: NodePath = ^"Terrain"
## Seconds between coconuts at the start and at the end of the storm.
@export var start_interval: float = 0.85
@export var end_interval: float = 0.35
## How long the shadow shows before the coconut lands.
@export var warning_seconds: float = 1.0
@export var hit_radius: float = 20.0
## Share of coconuts aimed near the player (the rest fall anywhere).
@export_range(0.0, 1.0) var aimed_share: float = 0.55
## Chance that a landed coconut stays whole and can be picked up.
@export_range(0.0, 1.0) var keep_chance: float = 0.3
@export var pickup_scene: PackedScene = preload("res://scenes/coconut.tscn")
## Seconds you can't be hit again after a bonk.
@export var invulnerable_seconds: float = 1.0

var hits: int = 0
var storm_over: bool = false

var _spawn_timer: float = 0.5
var _invulnerable: float = 0.0
var _terrain: IslandTerrain
var _falling: Array[Dictionary] = []   # {pos, t}
var _effects: Node2D
var _pickups: Node2D


func _setup_game() -> void:
	_terrain = get_node_or_null(terrain_path) as IslandTerrain
	_effects = Node2D.new()
	_effects.name = "FallingCoconuts"
	_effects.z_index = 5
	_effects.draw.connect(_draw_falling)
	add_child(_effects)
	_pickups = get_node_or_null(^"World") as Node2D


func _game_process(delta: float) -> void:
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if player and _invulnerable > 0.0:
		player.modulate.a = 0.4 if int(_invulnerable * 12.0) % 2 == 0 else 1.0
	elif player:
		player.modulate.a = 1.0

	if not storm_over:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var progress := 1.0 - time_remaining / time_limit_seconds if has_time_limit() else 0.0
			_spawn_timer = lerpf(start_interval, end_interval, progress)
			_spawn_coconut()

	for i in range(_falling.size() - 1, -1, -1):
		var c := _falling[i]
		c.t += delta
		if c.t >= warning_seconds:
			_falling.remove_at(i)
			_land(c.pos)
	_effects.queue_redraw()


func _spawn_coconut() -> void:
	var target: Vector2
	if player and randf() < aimed_share:
		# Aim a little ahead of where the player is heading.
		target = player.global_position + player.velocity * 0.35 + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 45.0)
		if _terrain and not _terrain.contains_point(target):
			target = player.global_position
	elif _terrain:
		target = _terrain.random_point(25.0)
	else:
		target = player.global_position
	_falling.append({"pos": target, "t": 0.0})


func _land(at: Vector2) -> void:
	if player and _invulnerable <= 0.0 and player.global_position.distance_to(at) <= hit_radius:
		hits += 1
		_invulnerable = invulnerable_seconds
		refresh_hud()
		if hits >= max_hits:
			lose("Bonk! You were knocked out by coconuts.")
			return
		show_message("Bonk! (%d / %d)" % [hits, max_hits], 0.8)
		return
	if randf() < keep_chance and pickup_scene and _pickups and (_terrain == null or _terrain.contains_point(at)):
		var pickup := pickup_scene.instantiate() as Node2D
		pickup.position = _pickups.to_local(at)
		_pickups.add_child.call_deferred(pickup)


func _on_time_up() -> void:
	storm_over = true
	pause_timer(true)
	_falling.clear()
	if hud:
		hud.set_timer_visible(false)
	refresh_hud()
	show_message("The squall has passed! Grab any coconuts and row back.", 2.5)


func _get_objective_text() -> String:
	if storm_over:
		return "Storm over! Head to the rowboat."
	var hearts := ""
	for i in max_hits:
		hearts += "O " if i < max_hits - hits else "x "
	return "Dodge the coconuts!   Health: %s" % hearts.strip_edges()


func _is_objective_complete() -> bool:
	return storm_over


func _get_incomplete_message() -> String:
	return "Wait out the storm first!"


func _draw_falling() -> void:
	for c in _falling:
		var k: float = clampf(c.t / warning_seconds, 0.0, 1.0)
		var at: Vector2 = c.pos - _effects.global_position
		_effects.draw_set_transform(at, 0.0, Vector2(1.0, 0.55))
		_effects.draw_circle(Vector2.ZERO, lerpf(6.0, hit_radius, k), Color(0, 0, 0, 0.18 + 0.27 * k))
		_effects.draw_set_transform(Vector2.ZERO)
		# The coconut itself, dropping in from above.
		var height := (1.0 - k) * 260.0
		_effects.draw_circle(at - Vector2(0, height), 9.0, Color8(92, 51, 23))
