class_name MosquitoMarsh
extends IslandGame

## Mosquito Marsh: light every torch while a mosquito swarm hunts you.
## Stand at an unlit torch and hold E to light it; moving stops the
## lighting. The swarm follows you around the marsh, a little slower than you
## walk. Lit torches give off smoke the swarm won't fly into, so each torch
## you light makes the marsh safer. Every bite costs time, and too many bites
## drive you off the island. Light them all to keep a Torch for the voyage.
##
## Scene setup: Marker2D children of Torches are the torches; the SwarmStart
## marker is where the swarm waits.

@export_group("Torches")
@export var torches_path: NodePath = ^"World/Torches"
@export var swarm_start_path: NodePath = ^"World/SwarmStart"
@export var reward_item_id: StringName = &"torch"
@export var reach: float = 44.0
## Seconds of holding E to light a torch.
@export var light_seconds: float = 1.2
## The swarm won't fly this close to a lit torch.
@export var smoke_radius: float = 95.0

@export_group("Swarm")
@export var swarm_speed: float = 108.0
## Seconds before the swarm notices you.
@export var swarm_wake_seconds: float = 2.5
@export var bite_radius: float = 22.0
@export var bite_penalty_seconds: float = 3.0
@export var max_bites: int = 4
## After a bite the swarm backs off for this long.
@export var bite_stun_seconds: float = 1.2

var lit: Array[bool] = []
var lit_count: int = 0
var bites: int = 0
var swarm_position: Vector2
var light_progress: float = 0.0

var _torches: Array[Node2D] = []
var _swarm: Node2D
var _swarm_wait: float = 0.0
var _lighting: int = -1
var _time: float = 0.0


func _setup_game() -> void:
	var torches := get_node_or_null(torches_path)
	assert(torches != null, "MosquitoMarsh needs Marker2D children under Torches.")
	for marker in torches.get_children():
		if marker is Node2D:
			var index := _torches.size()
			_torches.append(marker)
			lit.append(false)
			marker.draw.connect(_draw_torch.bind(index))
			marker.queue_redraw()
	var start := get_node_or_null(swarm_start_path) as Node2D
	swarm_position = start.global_position if start else Vector2(0, -200)
	_swarm_wait = swarm_wake_seconds
	_swarm = Node2D.new()
	_swarm.name = "Swarm"
	_swarm.z_index = 20
	_swarm.draw.connect(_draw_swarm)
	add_child(_swarm)


func _game_process(delta: float) -> void:
	_time += delta
	for torch in _torches:
		torch.queue_redraw()
	_swarm.queue_redraw()
	if player == null:
		return
	_update_lighting(delta)
	if all_lit():
		return
	_move_swarm(delta)


func _update_lighting(delta: float) -> void:
	var torch := _nearest_unlit_torch()
	var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO
	if torch < 0 or all_lit():
		_lighting = -1
		light_progress = 0.0
		set_prompt("")
		return
	if Input.is_action_pressed("interact") and not moving:
		if torch != _lighting:
			_lighting = torch
			light_progress = 0.0
		light_progress += delta
		set_prompt("Lighting... keep holding E")
		if light_progress >= light_seconds:
			light_torch(torch)
	else:
		_lighting = -1
		light_progress = 0.0
		set_prompt("Hold E to light the torch")


func light_torch(index: int) -> void:
	if lit[index]:
		return
	lit[index] = true
	lit_count += 1
	_lighting = -1
	light_progress = 0.0
	refresh_hud()
	if all_lit():
		set_prompt("")
		give_item(reward_item_id, 1)
		show_message("Every torch is lit! The swarm scatters. Back to the rowboat!", 2.5)
	else:
		show_message("Torch lit!", 0.7)


func all_lit() -> bool:
	return lit_count >= _torches.size()


func _move_swarm(delta: float) -> void:
	if _swarm_wait > 0.0:
		_swarm_wait -= delta
		return
	var target := player.global_position
	swarm_position = swarm_position.move_toward(target, swarm_speed * delta)
	# Smoke pushes the swarm back out.
	for i in _torches.size():
		if not lit[i]:
			continue
		var center := _torches[i].global_position
		var offset := swarm_position - center
		if offset.length() < smoke_radius:
			if offset == Vector2.ZERO:
				offset = Vector2.UP
			swarm_position = center + offset.normalized() * smoke_radius
	if swarm_position.distance_to(player.global_position) <= bite_radius:
		_bite()


func _bite() -> void:
	bites += 1
	_swarm_wait = bite_stun_seconds
	var away := (swarm_position - player.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	swarm_position = player.global_position + away * 140.0
	refresh_hud()
	if bites >= max_bites:
		lose("The mosquitoes drove you off the island!")
		return
	add_time(-bite_penalty_seconds)
	show_message("Ouch! Bitten! (-%ds)" % int(bite_penalty_seconds), 1.0)


func _nearest_unlit_torch() -> int:
	var best := -1
	var best_distance := reach
	for i in _torches.size():
		if lit[i]:
			continue
		var distance := player.global_position.distance_to(_torches[i].global_position)
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _get_objective_text() -> String:
	if all_lit():
		return "All torches lit! Head to the rowboat."
	return "Torches lit: %d / %d   Bites: %d / %d" % [lit_count, _torches.size(), bites, max_bites]


func _is_objective_complete() -> bool:
	return all_lit()


func _get_incomplete_message() -> String:
	return "Light every torch first!"


func _draw_torch(index: int) -> void:
	var torch := _torches[index]
	torch.draw_rect(Rect2(-3, -30, 6, 34), Color8(100, 66, 36))
	torch.draw_rect(Rect2(-6, -36, 12, 8), Color8(70, 50, 30))
	if lit[index]:
		var flicker := 0.8 + 0.2 * sin(_time * 22.0 + index)
		torch.draw_circle(Vector2(0, -44), 9.0 * flicker, Color(1.0, 0.5, 0.1, 0.9))
		torch.draw_circle(Vector2(0, -46), 5.0 * flicker, Color(1.0, 0.9, 0.4))
		# Smoke ring shows the safe zone.
		var drift := fposmod(_time * 0.4 + index * 0.3, 1.0)
		torch.draw_arc(Vector2.ZERO, smoke_radius * (0.85 + 0.15 * drift), 0.0, TAU, 40, Color(0.85, 0.85, 0.85, 0.35 * (1.0 - drift)), 3.0)
		torch.draw_circle(Vector2(0, -60 - drift * 30.0), 6.0 + drift * 8.0, Color(0.8, 0.8, 0.8, 0.3 * (1.0 - drift)))
	elif index == _lighting:
		var share := clampf(light_progress / light_seconds, 0.0, 1.0)
		torch.draw_arc(Vector2(0, -44), 12.0, -PI / 2.0, -PI / 2.0 + TAU * share, 24, Color(1.0, 0.7, 0.2), 3.0)


func _draw_swarm() -> void:
	if all_lit():
		return
	var calm := _swarm_wait > 0.0
	for i in 16:
		var angle := i * 2.4 + _time * (3.0 + i % 3)
		var radius := 6.0 + (i % 5) * 3.0 + sin(_time * 9.0 + i) * 3.0
		var at := swarm_position + Vector2.from_angle(angle) * radius
		_swarm.draw_circle(at, 1.8, Color(0.1, 0.1, 0.1, 0.5 if calm else 0.9))
	_swarm.draw_circle(swarm_position, 20.0, Color(0.2, 0.2, 0.2, 0.12))
