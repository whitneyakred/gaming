class_name SmugglersDen
extends IslandGame

## Smuggler's Den: sneak in, steal the loot, sneak out.
## Pirate guards walk set routes. Stay out of their yellow vision cones;
## crates block their view, so hide behind them. If a guard spots you,
## you're thrown back to the dock and lose time. Grab the loot from the chest,
## then sneak back to the rowboat: get spotted while carrying it and the
## guards take it back to the chest. Escaping with it pays 5-30 gold coins.
##
## Scene setup:
## - Each child of Guards is one guard's route; its Marker2D children are the
##   stops, walked in order and looping.
## - Marker2D children of Crates are crates (cover).
## - The Loot marker is the chest.

@export_group("Guards")
@export var routes_path: NodePath = ^"World/Guards"
@export var crates_path: NodePath = ^"World/Crates"
@export var loot_path: NodePath = ^"World/Loot"
@export var guard_speed: float = 62.0
@export var view_distance: float = 160.0
@export_range(5.0, 80.0) var view_half_angle_degrees: float = 30.0
## Seconds a guard stands looking around at each stop.
@export var pause_seconds: float = 1.1
## How long you can be in view before you're caught (a little forgiveness).
@export var spot_grace_seconds: float = 0.2
@export var spotted_penalty_seconds: float = 5.0
@export var crate_size: float = 36.0

const CRATE_LAYER: int = 4   # physics layer 3; also on layer 1 to block walking
const CONE_RAYS: int = 18

var loot_taken: bool = false
var times_spotted: int = 0

var _guards: Array[Dictionary] = []   # {node, points, target, wait, facing, sweep}
var _start_position: Vector2
var _exposure: float = 0.0
var _loot: Node2D
var _cones: Node2D
var _alarm: float = 0.0


func _setup_game() -> void:
	if player:
		_start_position = player.global_position
	_loot = get_node_or_null(loot_path) as Node2D
	if _loot:
		_loot.draw.connect(_draw_loot)
		_loot.queue_redraw()

	var crates := get_node_or_null(crates_path)
	if crates:
		for marker in crates.get_children():
			if marker is Node2D:
				marker.add_child(_make_crate())

	var routes := get_node_or_null(routes_path)
	assert(routes != null, "SmugglersDen needs route nodes under Guards.")
	for route in routes.get_children():
		var points: Array[Vector2] = []
		for stop in route.get_children():
			if stop is Node2D:
				points.append(stop.global_position)
		if points.is_empty():
			continue
		var guard := Node2D.new()
		guard.name = "Guard%d" % (_guards.size() + 1)
		var info := {"node": guard, "points": points, "target": 1 % points.size(),
				"wait": 0.0, "facing": Vector2.DOWN, "sweep": 0.0}
		guard.draw.connect(_draw_guard.bind(info))
		routes.add_child(guard)
		guard.global_position = points[0]
		_guards.append(info)

	_cones = Node2D.new()
	_cones.name = "VisionCones"
	_cones.z_index = -1
	_cones.draw.connect(_draw_cones)
	add_child(_cones)


func _game_process(delta: float) -> void:
	_alarm = maxf(_alarm - delta, 0.0)
	for info in _guards:
		_move_guard(info, delta)

	var seen := false
	for info in _guards:
		if _can_see(info, player.global_position):
			seen = true
			break
	_exposure = _exposure + delta if seen else 0.0
	if _exposure >= spot_grace_seconds:
		_spotted()

	if not loot_taken and _loot and player.global_position.distance_to(_loot.global_position) < 26.0:
		loot_taken = true
		_loot.queue_redraw()
		refresh_hud()
		show_message("You grabbed the loot! Sneak back to the rowboat.", 2.0)
	_cones.queue_redraw()


func _move_guard(info: Dictionary, delta: float) -> void:
	var guard: Node2D = info.node
	var points: Array[Vector2] = info.points
	if info.wait > 0.0:
		info.wait -= delta
		info.sweep += delta
		return
	var target: Vector2 = points[info.target]
	var to_target := target - guard.global_position
	var step := guard_speed * delta
	if to_target.length() <= step:
		guard.global_position = target
		info.target = (info.target + 1) % points.size()
		info.wait = pause_seconds if points.size() > 1 else INF
		info.sweep = 0.0
	else:
		info.facing = to_target.normalized()
		guard.global_position += info.facing * step
	guard.queue_redraw()


## The direction a guard is looking (it glances side to side while paused).
func _look_direction(info: Dictionary) -> Vector2:
	var facing: Vector2 = info.facing
	if info.wait > 0.0:
		return facing.rotated(sin(info.sweep * 2.4) * deg_to_rad(45.0))
	return facing


func _can_see(info: Dictionary, point: Vector2) -> bool:
	var guard: Node2D = info.node
	var offset := point - guard.global_position
	if offset.length() > view_distance:
		return false
	if absf(_look_direction(info).angle_to(offset)) > deg_to_rad(view_half_angle_degrees):
		return false
	return not _blocked(guard.global_position, point)


func _blocked(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, CRATE_LAYER)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _spotted() -> void:
	_exposure = 0.0
	_alarm = 0.6
	times_spotted += 1
	player.global_position = _start_position
	player.velocity = Vector2.ZERO
	add_time(-spotted_penalty_seconds)
	if loot_taken:
		# Caught carrying it: the guards put the loot back in the chest.
		loot_taken = false
		if _loot:
			_loot.queue_redraw()
		refresh_hud()
		show_message("Spotted! The guards took the loot back. (-%ds)" % int(spotted_penalty_seconds), 1.8)
	else:
		show_message("Spotted! Back to the dock. (-%ds)" % int(spotted_penalty_seconds), 1.4)


## Reaching the rowboat with the loot pays out the coins.
func try_escape() -> void:
	if not is_running() or not loot_taken:
		super.try_escape()
		return
	var coins := give_treasure()
	var payout := "%d coins collected!" % coins if coins > 0 \
			else "Your bag is full! The coins stay behind."
	win("You escaped with the smugglers' loot!\n" + payout)


func _make_crate() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Crate"
	body.collision_layer = 1 | CRATE_LAYER
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2.ONE * crate_size
	shape.shape = box
	body.add_child(shape)
	body.draw.connect(func() -> void:
		var half := crate_size / 2.0
		body.draw_rect(Rect2(-half, -half, crate_size, crate_size), Color8(150, 104, 58))
		body.draw_rect(Rect2(-half, -half, crate_size, crate_size), Color8(90, 60, 30), false, 3.0)
		body.draw_line(Vector2(-half, -half), Vector2(half, half), Color8(90, 60, 30), 3.0)
		body.draw_line(Vector2(half, -half), Vector2(-half, half), Color8(90, 60, 30), 3.0))
	return body


func _get_objective_text() -> String:
	if loot_taken:
		return "Loot taken! Sneak back to the rowboat."
	return "Steal the loot without being seen   (spotted: %d)" % times_spotted


func _is_objective_complete() -> bool:
	return loot_taken


func _get_incomplete_message() -> String:
	return "You haven't stolen the loot yet!"


func _draw_cones() -> void:
	var color := Color(1.0, 0.25, 0.2, 0.35) if _alarm > 0.0 else Color(1.0, 0.92, 0.4, 0.28)
	var half_angle := deg_to_rad(view_half_angle_degrees)
	for info in _guards:
		var origin: Vector2 = (info.node as Node2D).global_position
		var look := _look_direction(info)
		var points := PackedVector2Array([origin - _cones.global_position])
		for i in CONE_RAYS + 1:
			var direction := look.rotated(lerpf(-half_angle, half_angle, float(i) / CONE_RAYS))
			var end := origin + direction * view_distance
			var hit := get_world_2d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters2D.create(origin, end, CRATE_LAYER))
			if not hit.is_empty():
				end = hit.position
			points.append(end - _cones.global_position)
		_cones.draw_colored_polygon(points, color)


func _draw_guard(info: Dictionary) -> void:
	var guard: Node2D = info.node
	var look := _look_direction(info)
	guard.draw_circle(Vector2(0, 2), 11.0, Color(0, 0, 0, 0.25))
	guard.draw_circle(Vector2.ZERO, 10.0, Color8(60, 60, 80))
	guard.draw_circle(look * 4.0, 6.0, Color8(230, 190, 150))
	# Red bandana.
	guard.draw_arc(look * 4.0, 6.0, look.angle() + PI * 0.5, look.angle() + PI * 1.5, 8, Color8(200, 40, 40), 4.0)


func _draw_loot() -> void:
	var wood := Color8(130, 80, 35)
	_loot.draw_rect(Rect2(-16, -12, 32, 20), wood)
	if loot_taken:
		_loot.draw_rect(Rect2(-17, -26, 34, 8), wood.darkened(0.3))
	else:
		_loot.draw_rect(Rect2(-17, -18, 34, 8), wood.darkened(0.3))
		_loot.draw_rect(Rect2(-4, -12, 8, 8), Color8(250, 210, 60))
