class_name SeagullRoost
extends IslandGame

## Seagull Roost: guard the fish-drying rack from diving gulls.
## Gulls fly in from the sea toward the rack. Get next to one and press E to
## shoo it away. Each gull that reaches the rack flies off with a fish; lose
## every fish and it's game over. Hold out until the timer runs out, and the
## fish still on the rack go into your bag as Dried Fish.
##
## Scene setup: the Rack marker is the drying rack.

@export_group("Gulls")
@export var rack_path: NodePath = ^"World/Rack"
@export var reward_item_id: StringName = &"dried_fish"
@export var fish_on_rack: int = 8
@export var gull_speed: float = 70.0
## Added to the gulls' speed by the time the timer runs out.
@export var gull_speed_step: float = 35.0
## Seconds between gulls when the island starts...
@export var spawn_interval_start: float = 2.6
## ...and when the timer is almost out.
@export var spawn_interval_end: float = 1.1
## How far from the rack gulls appear.
@export var spawn_distance: float = 430.0
## How close you must be to a gull to shoo it.
@export var reach: float = 56.0
## A gull this close to the rack grabs a fish.
@export var steal_radius: float = 26.0

var fish_left: int = 0
var shooed_count: int = 0
var rack_safe: bool = false
## Each gull: {pos: Vector2, vel: Vector2, fleeing: bool, carrying: bool, flap: float}
var gulls: Array[Dictionary] = []

var _rack: Node2D
var _sky: Node2D
var _next_spawn: float = 1.2


func _setup_game() -> void:
	fish_left = fish_on_rack
	_rack = get_node_or_null(rack_path) as Node2D
	assert(_rack != null, "SeagullRoost needs a Rack marker.")
	_rack.draw.connect(_draw_rack)
	_rack.queue_redraw()
	_sky = Node2D.new()
	_sky.name = "Gulls"
	_sky.z_index = 20
	_sky.draw.connect(_draw_gulls)
	add_child(_sky)


func _game_process(delta: float) -> void:
	var progress := 1.0 - time_remaining / time_limit_seconds if has_time_limit() else 0.0
	if not rack_safe:
		_next_spawn -= delta
		if _next_spawn <= 0.0:
			spawn_gull()
			_next_spawn = lerpf(spawn_interval_start, spawn_interval_end, progress)

	var rack_at := _rack.global_position
	var speed := gull_speed + gull_speed_step * progress
	for i in range(gulls.size() - 1, -1, -1):
		var gull := gulls[i]
		var pos: Vector2 = gull["pos"]
		gull["flap"] = float(gull["flap"]) + delta * (14.0 if gull["fleeing"] else 9.0)
		if gull["fleeing"]:
			var vel: Vector2 = gull["vel"]
			pos += vel * delta
			gull["pos"] = pos
			if pos.distance_to(rack_at) > spawn_distance + 250.0:
				gulls.remove_at(i)
			continue
		var to_rack := rack_at - pos
		if to_rack.length() <= steal_radius:
			_steal(gull, to_rack)
			if not is_running():
				return
			continue
		pos += to_rack.normalized() * speed * delta
		gull["pos"] = pos

	_sky.queue_redraw()
	set_prompt("Press E to shoo the gull!" if _nearest_gull() >= 0 else "")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or not event.is_action_pressed("interact") or event.is_echo():
		return
	var gull := _nearest_gull()
	if gull >= 0:
		get_viewport().set_input_as_handled()
		shoo(gull)


## Adds a gull at a random spot on the circle around the rack (never from the
## dock side). Returns its index in `gulls`.
func spawn_gull() -> int:
	var angle := randf_range(-PI * 1.15, PI * 0.15)
	var pos := _rack.global_position + Vector2.from_angle(angle) * spawn_distance
	gulls.append({"pos": pos, "vel": Vector2.ZERO, "fleeing": false, "carrying": false, "flap": randf() * TAU})
	return gulls.size() - 1


func shoo(index: int) -> void:
	var gull := gulls[index]
	var pos: Vector2 = gull["pos"]
	var away := (pos - player.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	gull["fleeing"] = true
	gull["vel"] = away * 260.0
	shooed_count += 1
	show_message("Shoo!", 0.4)


func _steal(gull: Dictionary, to_rack: Vector2) -> void:
	fish_left -= 1
	gull["fleeing"] = true
	gull["carrying"] = true
	gull["vel"] = -to_rack.normalized() * 150.0 if to_rack != Vector2.ZERO else Vector2.UP * 150.0
	_rack.queue_redraw()
	refresh_hud()
	if fish_left <= 0:
		lose("The gulls took every fish!")
	else:
		show_message("A gull snatched a fish!", 1.0)


func _nearest_gull() -> int:
	if player == null:
		return -1
	var best := -1
	var best_distance := reach
	for i in gulls.size():
		if gulls[i]["fleeing"]:
			continue
		var distance := player.global_position.distance_to(gulls[i]["pos"])
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _on_time_up() -> void:
	rack_safe = true
	pause_timer(true)
	for gull in gulls:
		if not gull["fleeing"]:
			var pos: Vector2 = gull["pos"]
			gull["fleeing"] = true
			gull["vel"] = (pos - _rack.global_position).normalized() * 200.0
	set_prompt("")
	if hud:
		hud.set_timer_visible(false)
	give_item(reward_item_id, fish_left)
	fish_left = 0
	_rack.queue_redraw()
	refresh_hud()
	show_message("The gulls gave up! You packed the dried fish.", 2.5)


func _get_objective_text() -> String:
	if rack_safe:
		return "The gulls gave up! Head to the rowboat."
	return "Guard the fish!   Fish on the rack: %d / %d" % [fish_left, fish_on_rack]


func _is_objective_complete() -> bool:
	return rack_safe


func _get_incomplete_message() -> String:
	return "Guard the rack until the gulls give up!"


func _draw_rack() -> void:
	var wood := Color8(120, 80, 45)
	_rack.draw_rect(Rect2(-60, -40, 6, 46), wood)
	_rack.draw_rect(Rect2(54, -40, 6, 46), wood)
	_rack.draw_line(Vector2(-60, -36), Vector2(60, -36), Color8(170, 140, 90), 3.0)
	for i in fish_left:
		var x := -48.0 + i * (96.0 / maxf(fish_on_rack - 1, 1))
		_rack.draw_line(Vector2(x, -36), Vector2(x, -30), Color8(170, 140, 90), 1.0)
		_rack.draw_set_transform(Vector2(x, -22), 0.0, Vector2(0.55, 1.0))
		_rack.draw_circle(Vector2.ZERO, 8.0, Color8(196, 150, 96))
		_rack.draw_set_transform(Vector2.ZERO)
		_rack.draw_colored_polygon(PackedVector2Array([Vector2(x, -15), Vector2(x - 5, -9), Vector2(x + 5, -9)]), Color8(170, 120, 70))


func _draw_gulls() -> void:
	for gull in gulls:
		var pos: Vector2 = gull["pos"]
		var flap := sin(float(gull["flap"])) * 7.0
		var body := Color(0.96, 0.96, 0.96)
		var wing := Color(0.75, 0.78, 0.82)
		_sky.draw_circle(pos + Vector2(4, 22), 7.0, Color(0, 0, 0, 0.18))
		_sky.draw_line(pos, pos + Vector2(-18, -6 - flap), wing, 4.0)
		_sky.draw_line(pos, pos + Vector2(18, -6 - flap), wing, 4.0)
		_sky.draw_circle(pos, 7.0, body)
		_sky.draw_circle(pos + Vector2(0, -6), 4.5, body)
		_sky.draw_line(pos + Vector2(0, -9), pos + Vector2(0, -14), Color(1.0, 0.75, 0.1), 2.5)
		if gull["carrying"]:
			_sky.draw_circle(pos + Vector2(0, 9), 4.0, Color8(196, 150, 96))
