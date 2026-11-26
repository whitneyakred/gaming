class_name RodFishing
extends Node2D
signal item_caught(item_id: StringName)
signal line_broken
signal attempt_cancelled

enum State { IDLE, CASTING, WAITING, BITE, REELING }
@export_range(80.0, 700.0) var cast_range: float = 360.0
@export var minimum_cast_distance: float = 40.0
@export var bite_wait: Vector2 = Vector2(1.8, 4.5)
@export var bite_window: float = 1.25
@export var cast_seconds: float = 0.4
var state: State = State.IDLE
var fight := FishingFight.new()
var rng := RandomNumberGenerator.new()
var _world_target: Vector2
var _ship_target: Vector2
var _ship_origin: Vector2
var _cast_from_ship: bool = false
var target: Vector2:
	get:
		return _ship.to_global(_ship_target) if _cast_from_ship and is_instance_valid(_ship) else _world_target
	set(value):
		_world_target = value
var cast_origin: Vector2
var clock: float = 0.0
var wait_left: float = 0.0
var bite_left: float = 0.0
var splash_age: float = 10.0
var held: bool = false
var visual_catches: int = 0
var attempt_id: int = 0
var fight_seed: int = 0
var local_reeling: bool = false
var local_done: bool = false
var local_frame: int = 0
var local_accumulator: float = 0.0
var pending_bits: int = 0
var pending_frames: int = 0
var replay_frame: int = 0
var hook_started: int = 0
var sound: FishingAudio
var hud: FishingHUD
var _terrain: Array[IslandTerrain] = []
var _ship: Ship
var _geometry_time := -1000
var _geometry_attempt := -1
var _geometry_water := Vector2.ZERO
var _geometry_landing := Vector2.ZERO
var geometry_ms := 0.0
var pending_cast_until := 0
@onready var service: InventoryService = get_parent() as InventoryService

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 20
	rng.randomize()
	sound = FishingAudio.new()
	add_child(sound)
	var canvas := CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)
	hud = FishingHUD.new()
	hud.fishing = self
	canvas.add_child(hud)
	_ship = service.get_parent() as Ship
	_collect_terrain(service.get_parent())
	get_window().focus_exited.connect(func() -> void:
		if not NetworkSession.online:
			cancel()
		elif service.network_id == NetworkSession.local_id and not NetworkSession.dedicated:
			NetworkSession.command("cancel_fish"))

func _collect_terrain(node: Node) -> void:
	if node is IslandTerrain:
		_terrain.append(node)
	for child in node.get_children():
		_collect_terrain(child)

func rod_selected() -> bool:
	if service == null or service.hud == null:
		return false
	var index: int = service.hud.selected
	return index >= 0 and index < service.local_slots.size() and service.local_slots[index].get("id", &"") == &"fishing_rod"

func can_fish() -> bool:
	var local_drag := get_viewport().gui_is_dragging() and (not NetworkSession.online or service.network_id == NetworkSession.local_id)
	return rod_selected() and service.can_handle_items() and not service.hud.storage_open and not service.hud.grill_open and not local_drag

func is_water(point: Vector2) -> bool:
	if is_instance_valid(_ship):
		if Geometry2D.is_point_in_polygon(point, _ship.get_hull_polygon(_ship.global_position, _ship.global_rotation)):
			return false
		# The rowboat and boarding plank are solid too.
		if is_instance_valid(_ship.rowboat) and _ship.rowboat.global_position.distance_to(point) < 35:
			return false
		if Rect2(-145, -58, 85, 32).has_point(_ship.to_local(point)):
			return false
		for island in _ship.get_islands():
			if Geometry2D.is_point_in_polygon(point, island.get_coast()):
				return false
	else:
		if _terrain.is_empty():
			return false
		for terrain in _terrain:
			if terrain.contains_point(point) or terrain.is_on_cliff(point):
				return false
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		held = false

func _unhandled_input(event: InputEvent) -> void:
	if NetworkSession.online:
		if service.network_id != NetworkSession.local_id or PauseMenu.is_paused() or MapState.map_open:
			return
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT and rod_selected():
				NetworkSession.command("fish", {"point": get_canvas_transform().affine_inverse() * event.position})
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				NetworkSession.command("cancel_fish")
				get_viewport().set_input_as_handled()
		return
	if state != State.IDLE and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		cancel()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or not can_fish():
		return
	match state:
		State.IDLE: cast(get_canvas_transform().affine_inverse() * event.position)
		State.CASTING, State.WAITING:
			finish(false, "Too soon! Recast, then wait for the bobber to dip.", false)
		State.BITE:
			state = State.REELING
			fight.begin(rng.randi())
			held = true
		State.REELING: held = true
	get_viewport().set_input_as_handled()

func cast(point: Vector2) -> bool:
	if state != State.IDLE or not can_fish():
		return false
	if not is_water(point):
		service.feedback.emit("Aim the bobber at open water.")
		return false
	var origin := service.player.global_position
	var direction := (point - origin).normalized()
	var distance := minf(origin.distance_to(point), cast_range)
	point = origin + direction * distance
	# A distant click may clamp onto a shoreline: find water along the cast first.
	while distance > 4.0 and not is_water(point):
		distance -= 4.0
		point = origin + direction * distance
	if not is_water(point):
		# If the hull blocks that whole direction, use the nearest reachable water
		# to the requested bearing instead of putting a bobber on the deck.
		var found := false
		for step in range(1, 19):
			for side in [-1, 1]:
				var candidate := origin + direction.rotated(deg_to_rad(step * 10.0 * side)) * cast_range
				if is_water(candidate):
					point = candidate
					found = true
					break
			if found: break
		if not found: return false
	cast_origin = service.player.global_position + Vector2(8, -18)
	target = point
	_cast_from_ship = is_instance_valid(_ship) and not service.player.is_overboard
	if _cast_from_ship:
		_ship_target = _ship.to_local(point)
		_ship_origin = _ship.to_local(cast_origin)
	attempt_id += 1
	fight_seed = rng.randi()
	clock = 0.0
	held = false
	state = State.CASTING
	service.player.set("fishing_active", true)

	sound.play("cast")
	queue_redraw()
	return true

func begin_local_hook() -> void:
	local_reeling = true
	local_done = false
	local_frame = 0
	local_accumulator = 0
	pending_bits = 0
	pending_frames = 0
	held = true
	state = State.REELING
	fight.begin(fight_seed)

func tick_local_fight(delta: float) -> void:
	if not local_reeling or local_done: return
	if not can_fish():
		NetworkSession.command("cancel_fish")
		local_reeling = false
		return
	local_accumulator += minf(delta, 0.25)
	while local_accumulator >= 1.0 / 60.0 and not local_done:
		local_accumulator -= 1.0 / 60.0
		if held: pending_bits |= 1 << pending_frames
		pending_frames += 1
		local_frame += 1
		fight.step(1.0 / 60.0, held)
		clock += 1.0 / 60.0
		local_done = fight.caught or fight.broken
		if pending_frames >= 6 or local_done:
			NetworkSession.command("fish_steps", {"attempt": attempt_id, "first": local_frame - pending_frames, "count": pending_frames, "bits": pending_bits})
			pending_frames = 0
			pending_bits = 0
	sound.set_reeling(held and not local_done, fight.tension)
	queue_redraw()

func replay_steps(args: Dictionary) -> void:
	for key: String in ["attempt", "first", "count", "bits"]:
		if not args.get(key) is int: return
	if state != State.REELING or int(args.get("attempt", -1)) != attempt_id: return
	var count := int(args.get("count", 0))
	if int(args.get("first", -1)) != replay_frame or count < 1 or count > 12: return
	# Never accept sped-up client simulation or trust a claimed result/progress.
	if float(replay_frame + count) / 60.0 > float(Time.get_ticks_msec() - hook_started) / 1000.0 + 0.75: return
	var bits := int(args.get("bits", 0))
	for i in count:
		held = (bits & (1 << i)) != 0
		fight.step(1.0 / 60.0, held)
		replay_frame += 1
		if fight.caught:
			finish(true)
			return
		if fight.broken:
			finish(false, "Line snapped! Keep the marker in the green.")
			return

func tick_presentation(delta: float) -> void:
	# Guests animate every frame, independently of the snapshot rate. Never
	# advance authoritative bite timers or award a catch from presentation.
	if state == State.IDLE: return
	if not local_reeling: clock += delta
	splash_age += delta
	queue_redraw()

func _process(delta: float) -> void:
	if state == State.IDLE:
		return
	if not can_fish():
		cancel()
		return
	advance(delta, held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	queue_redraw()

func advance(delta: float, pulling: bool) -> void:
	queue_redraw()
	clock += delta
	splash_age += delta
	match state:
		State.CASTING:
			if clock >= cast_seconds:
				state = State.WAITING
				wait_left = rng.randf_range(bite_wait.x, bite_wait.y)
				splash_age = 0.0
				sound.play("splash")
		State.WAITING:
			wait_left -= delta
			if wait_left <= 0:
				state = State.BITE
				bite_left = bite_window
				splash_age = 0.0
				sound.play("bite")
		State.BITE:
			bite_left -= delta
			if bite_left <= 0:
				finish(false, "Missed the bite! Click again when the bobber dips.", false)
		State.REELING:
			fight.step(delta, pulling)
			sound.set_reeling(pulling, fight.tension)
			if fight.caught:
				finish(true)
			elif fight.broken:
				finish(false, "Line snapped! " + ("Ease off the reel." if fight.tension > fight.green_center else "Keep some tension on the line."))

func finish(success: bool, message: String = "", snapped: bool = true) -> void:
	if state == State.IDLE:
		return
	state = State.IDLE
	held = false
	service.player.set("fishing_active", false)
	sound.set_reeling(false)
	if success:
		visual_catches += 1
		var item_id: StringName = &"fish_cod" if rng.randf() < 0.9 else &"rope"
		var item := ItemDatabase.get_item(item_id)
		if not service.inventory.try_add(item_id):
			service._spawn_drop({"id": item_id, "quantity": 1}, service.player.position)
			service.publish()
			message = "Caught %s! Bag full — dropped at your feet." % item.display_name
		else:
			message = "Caught %s!" % item.display_name
		sound.play("catch")
		item_caught.emit(item_id)
		service.player.play_fishing_animation()
	elif snapped:
		sound.play("snap")
		line_broken.emit()
	else:
		attempt_cancelled.emit()
	service.feedback.emit(message)
	hud.hide()
	queue_redraw()

func cancel() -> void:
	if state != State.IDLE:
		finish(false, "Cast reeled back in.", false)

func status_text() -> String:
	match state:
		State.CASTING: return "CASTING…"
		State.WAITING: return "WAITING FOR A BITE…"
		State.BITE: return "BITE!  Click and hold to hook it!"
		State.REELING: return "KEEP THE MARKER IN THE GREEN" if fight.danger < 0.6 else "CAREFUL — THE LINE IS STRAINING!"
	return ""

## Find the first bank/hull edge along the retrieve, staying on the water side.
func _water_clear(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(10, 0), Vector2(-10, 0), Vector2(0, 10), Vector2(0, -10)]:
		if not is_water(point + offset):
			return false
	return true

func _safe_water_target() -> Vector2:
	var point := target
	if _water_clear(point):
		return point
	# A moving ship can bring the original side of the cast near a shoreline.
	# Reposition in nearby water rather than forfeiting an otherwise valid catch.
	for radius in range(16, 513, 16):
		for i in 16:
			var candidate := point + Vector2.from_angle(i * TAU / 16) * radius
			if _water_clear(candidate):
				return candidate
	return point

func _stop_at_water_edge(from: Vector2, toward: Vector2) -> Vector2:
	var steps := maxi(1, ceili(from.distance_to(toward) / 4.0))
	var last := from
	for i in range(1, steps + 1):
		var point := from.lerp(toward, float(i) / steps)
		if not _water_clear(point):
			break
		last = point
	return last

func bobber_position() -> Vector2:
	if state == State.CASTING:
		var t := clampf(clock / cast_seconds, 0.0, 1.0)
		var launch := _ship.to_global(_ship_origin) if _cast_from_ship and is_instance_valid(_ship) else cast_origin
		return launch.lerp(target, t) + Vector2(0, -sin(t * PI) * 65)
	# Shore intersection searches used to run for every angler on every draw.
	# Cache endpoints at 10 Hz, keeping them ship-relative between checks.
	var now := Time.get_ticks_msec()
	if now - _geometry_time >= 100 or _geometry_attempt != attempt_id:
		var started := Time.get_ticks_usec()
		var safe := _safe_water_target()
		var landing := _stop_at_water_edge(safe, service.player.global_position)
		_geometry_water = _ship.to_local(safe) if _cast_from_ship else safe
		_geometry_landing = _ship.to_local(landing) if _cast_from_ship else landing
		_geometry_time = now
		_geometry_attempt = attempt_id
		geometry_ms = (Time.get_ticks_usec() - started) / 1000.0
	var water := _ship.to_global(_geometry_water) if _cast_from_ship else _geometry_water
	var bobber := water
	if state == State.REELING:
		var landing := _ship.to_global(_geometry_landing) if _cast_from_ship else _geometry_landing
		bobber = water.lerp(landing, fight.progress)
	var motion := Vector2(0, sin(clock * (13.0 if state == State.BITE else 3.4)) * (4.0 if state == State.BITE else 2.0))
	if state == State.REELING:
		motion.x = sin(clock * 9.0) * 5
	return _stop_at_water_edge(bobber, bobber + motion)

func _draw() -> void:
	if state == State.IDLE or not is_instance_valid(service.player):
		return
	if not get_viewport_rect().grow(cast_range + 80).has_point(get_canvas_transform() * service.player.global_position): return
	var origin: Vector2 = service.player.visual_position() + Vector2(8, -18)
	var bobber := bobber_position()
	var start := to_local(origin)
	var end := to_local(bobber)
	var direction := (end - start).normalized()
	draw_line(to_local(service.player.visual_position()), start + direction * 14, Color("cfad73"), 3)
	start += direction * 14
	var line := PackedVector2Array()
	var sag := 4.0 if state == State.REELING and held else 18.0
	for i in 21:
		var t := float(i) / 20
		line.append(start.lerp(end, t) + Vector2(0, sin(t * PI) * sag))
	draw_polyline(line, Color("e4dfbd"), 1.3, true)
	if state != State.CASTING:
		for i in 2:
			var radius := 7.0 + fmod(clock * 10 + i * 10, 22.0)
			draw_arc(end, radius, 0, TAU, 24, Color(0.6, 0.85, 0.9, 0.24), 1.0)
		if splash_age < 0.65:
			for i in 8:
				var ray := Vector2.from_angle(i * TAU / 8)
				draw_circle(end + ray * splash_age * 42, 2, Color(0.7, 0.92, 1, 1.0 - splash_age / 0.65))
	draw_circle(end + Vector2(0, 3), 5, Color("102a36"))
	draw_rect(Rect2(end - Vector2(3, 5), Vector2(6, 5)), Color("f6e6c4"))
	draw_rect(Rect2(end - Vector2(3, 0), Vector2(6, 4)), Color("d95e4c"))
	draw_line(end - Vector2(0, 5), end - Vector2(0, 10), Color("f6e6c4"), 1)

func _exit_tree() -> void:
	if is_instance_valid(service.player):
		service.player.set("fishing_active", false)
