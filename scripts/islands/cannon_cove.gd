class_name CannonCove
extends IslandGame

## Cannon Cove: sink the target rafts with the shore cannon.
## Walk up to the cannon and press E to man it. The barrel swings back and
## forth: press E to lock the aim. Then the power bar rises and falls: press
## E to fire. The ball lands farther the more power you give it. Sink enough
## rafts and you salvage their Cannonballs. Any move key steps away from the
## cannon.
##
## Scene setup: the Cannon marker is the cannon (it fires up the screen).
## Each child of RaftLanes is a lane rafts drift along: its y position is the
## lane, and its x position is where the first raft starts.

enum Phase { IDLE, AIM, POWER, FLYING }

@export_group("Cannon")
@export var cannon_path: NodePath = ^"World/Cannon"
@export var lanes_path: NodePath = ^"World/RaftLanes"
@export var rafts_needed: int = 4
@export var reward_item_id: StringName = &"cannonball"
@export var reward_per_raft: int = 2
@export var reach: float = 46.0
## How far the barrel swings either side of straight ahead.
@export_range(10.0, 85.0) var max_aim_degrees: float = 60.0
## Full swings per second.
@export var aim_speed: float = 0.45
@export var power_speed: float = 0.8
@export var min_range: float = 120.0
@export var max_range: float = 360.0
@export var flight_seconds: float = 0.9
## A ball landing this close to a raft sinks it.
@export var hit_radius: float = 34.0

@export_group("Rafts")
@export var raft_speed_min: float = 40.0
@export var raft_speed_max: float = 75.0
## Rafts wrap around between -lane_half_width and +lane_half_width.
@export var lane_half_width: float = 440.0
@export var respawn_seconds: float = 1.5

var phase: Phase = Phase.IDLE
var sunk_count: int = 0
var aim_t: float = 0.5        # 0..1 across the swing; 0.5 = straight ahead
var power_t: float = 0.0      # 0..1
## Each raft: {pos: Vector2, speed: float, sinking: float}; sinking < 0 = afloat.
var rafts: Array[Dictionary] = []

var _cannon: Node2D
var _sea: Node2D
var _lanes: Array[Vector2] = []
var _aim_dir: float = 1.0
var _power_dir: float = 1.0
var _ball_from: Vector2
var _ball_to: Vector2
var _ball_t: float = 0.0
var _splashes: Array[Dictionary] = []   # {pos, t}
var _respawns: Array[float] = []
var _time: float = 0.0


func _setup_game() -> void:
	_cannon = get_node_or_null(cannon_path) as Node2D
	assert(_cannon != null, "CannonCove needs a Cannon marker.")
	_cannon.draw.connect(_draw_cannon)
	var lanes := get_node_or_null(lanes_path)
	assert(lanes != null, "CannonCove needs lane markers under RaftLanes.")
	for marker in lanes.get_children():
		if marker is Node2D:
			_lanes.append(marker.global_position)
			_add_raft(marker.global_position)
	_sea = Node2D.new()
	_sea.name = "Rafts"
	_sea.z_index = 5
	_sea.draw.connect(_draw_sea)
	add_child(_sea)
	# The cannon itself blocks walking.
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	body.add_child(shape)
	_cannon.add_child(body)


func _add_raft(at: Vector2) -> void:
	var speed := randf_range(raft_speed_min, raft_speed_max) * (1.0 if randf() < 0.5 else -1.0)
	rafts.append({"pos": at, "speed": speed, "sinking": -1.0})


func _game_process(delta: float) -> void:
	_time += delta
	_move_rafts(delta)

	match phase:
		Phase.AIM:
			aim_t += _aim_dir * aim_speed * 2.0 * delta
			if aim_t >= 1.0 or aim_t <= 0.0:
				aim_t = clampf(aim_t, 0.0, 1.0)
				_aim_dir = -_aim_dir
		Phase.POWER:
			power_t += _power_dir * power_speed * 2.0 * delta
			if power_t >= 1.0 or power_t <= 0.0:
				power_t = clampf(power_t, 0.0, 1.0)
				_power_dir = -_power_dir
		Phase.FLYING:
			_ball_t += delta / flight_seconds
			if _ball_t >= 1.0:
				_land_ball()

	if phase != Phase.IDLE and phase != Phase.FLYING:
		if Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO:
			_leave_cannon()

	match phase:
		Phase.IDLE:
			set_prompt("Press E to man the cannon" if _near_cannon() and sunk_count < rafts_needed else "")
		Phase.AIM:
			set_prompt("Press E to lock your aim")
		Phase.POWER:
			set_prompt("Press E to fire!")
		Phase.FLYING:
			set_prompt("")
	_cannon.queue_redraw()
	_sea.queue_redraw()


func _move_rafts(delta: float) -> void:
	for raft in rafts:
		var pos: Vector2 = raft["pos"]
		if float(raft["sinking"]) >= 0.0:
			raft["sinking"] = float(raft["sinking"]) + delta
			continue
		pos.x += float(raft["speed"]) * delta
		var left := _cannon.global_position.x - lane_half_width
		var right := _cannon.global_position.x + lane_half_width
		if pos.x > right:
			pos.x = left
		elif pos.x < left:
			pos.x = right
		raft["pos"] = pos
	for i in range(rafts.size() - 1, -1, -1):
		if float(rafts[i]["sinking"]) > 1.2:
			rafts.remove_at(i)
			_respawns.append(respawn_seconds)
	for i in range(_respawns.size() - 1, -1, -1):
		_respawns[i] -= delta
		if _respawns[i] <= 0.0:
			_respawns.remove_at(i)
			var lane: Vector2 = _lanes[randi() % _lanes.size()]
			var edge := lane_half_width * (1.0 if randf() < 0.5 else -1.0)
			_add_raft(Vector2(_cannon.global_position.x + edge, lane.y))
	for i in range(_splashes.size() - 1, -1, -1):
		_splashes[i]["t"] = float(_splashes[i]["t"]) + delta
		if float(_splashes[i]["t"]) > 0.7:
			_splashes.remove_at(i)


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or not event.is_action_pressed("interact") or event.is_echo():
		return
	match phase:
		Phase.IDLE:
			if _near_cannon() and sunk_count < rafts_needed:
				get_viewport().set_input_as_handled()
				man_cannon()
		Phase.AIM:
			get_viewport().set_input_as_handled()
			phase = Phase.POWER
			power_t = 0.0
			_power_dir = 1.0
		Phase.POWER:
			get_viewport().set_input_as_handled()
			fire()


func man_cannon() -> void:
	phase = Phase.AIM
	aim_t = 0.5
	_aim_dir = 1.0
	if player.has_method("try_use_station"):
		player.try_use_station(self)


## The direction the barrel points for an aim between 0 and 1.
func aim_direction(t: float) -> Vector2:
	var angle := deg_to_rad(lerpf(-max_aim_degrees, max_aim_degrees, t))
	return Vector2.UP.rotated(angle)


## Where a ball fired with this aim and power (both 0..1) comes down.
func landing_point(aim: float, power: float) -> Vector2:
	return _cannon.global_position + aim_direction(aim) * (24.0 + lerpf(min_range, max_range, power))


func fire() -> void:
	_ball_from = _barrel_tip()
	_ball_to = landing_point(aim_t, power_t)
	_ball_t = 0.0
	phase = Phase.FLYING


func _land_ball() -> void:
	_splashes.append({"pos": _ball_to, "t": 0.0})
	var hit := false
	for raft in rafts:
		if float(raft["sinking"]) < 0.0 and _ball_to.distance_to(raft["pos"]) <= hit_radius:
			raft["sinking"] = 0.0
			hit = true
			break
	if hit:
		sunk_count += 1
		give_item(reward_item_id, reward_per_raft)
		refresh_hud()
		if sunk_count >= rafts_needed:
			show_message("All targets sunk! Back to the rowboat.", 2.0)
			_leave_cannon()
			return
		show_message("Direct hit!", 0.8)
	else:
		show_message("Splash! Missed.", 0.6)
	phase = Phase.AIM


func _leave_cannon() -> void:
	phase = Phase.IDLE
	if player.has_method("leave_station"):
		player.leave_station(self)


func _barrel_tip() -> Vector2:
	return _cannon.global_position + aim_direction(aim_t) * 24.0


func _near_cannon() -> bool:
	return player != null and player.global_position.distance_to(_cannon.global_position) <= reach


func _get_objective_text() -> String:
	if sunk_count >= rafts_needed:
		return "Targets sunk! Head to the rowboat."
	return "Rafts sunk: %d / %d" % [sunk_count, rafts_needed]


func _is_objective_complete() -> bool:
	return sunk_count >= rafts_needed


func _get_incomplete_message() -> String:
	return "Sink %d rafts first!" % rafts_needed


func _draw_cannon() -> void:
	var dir := aim_direction(aim_t)
	_cannon.draw_circle(Vector2(-12, 8), 7.0, Color8(90, 60, 35))
	_cannon.draw_circle(Vector2(12, 8), 7.0, Color8(90, 60, 35))
	_cannon.draw_line(Vector2.ZERO, dir * 28.0, Color8(40, 40, 46), 12.0)
	_cannon.draw_circle(Vector2.ZERO, 11.0, Color8(55, 55, 62))
	if phase == Phase.AIM or phase == Phase.POWER:
		# Dotted aim line, longer with more power.
		var length := lerpf(min_range, max_range, power_t if phase == Phase.POWER else 0.5)
		var steps := int(length / 18.0)
		for i in steps:
			_cannon.draw_circle(dir * (30.0 + i * 18.0), 2.0, Color(1, 1, 1, 0.7))
	if phase == Phase.POWER:
		var bar := Rect2(Vector2(30, -40), Vector2(12, 60))
		_cannon.draw_rect(bar.grow(3.0), Color(0, 0, 0, 0.7))
		_cannon.draw_rect(bar, Color8(70, 70, 70))
		var filled := bar.size.y * power_t
		_cannon.draw_rect(Rect2(bar.position.x, bar.end.y - filled, bar.size.x, filled), Color8(240, 160, 50))


func _draw_sea() -> void:
	for raft in rafts:
		var pos: Vector2 = raft["pos"]
		var sinking: float = raft["sinking"]
		var alpha := 1.0 if sinking < 0.0 else clampf(1.0 - sinking / 1.2, 0.0, 1.0)
		var bob := sin(_time * 3.0 + pos.x * 0.05) * 2.0
		var at := pos + Vector2(0, bob + maxf(sinking, 0.0) * 10.0)
		_sea.draw_rect(Rect2(at + Vector2(-26, -12), Vector2(52, 24)), Color(0.55, 0.38, 0.2, alpha))
		for i in 4:
			_sea.draw_line(at + Vector2(-26 + i * 13, -12), at + Vector2(-26 + i * 13, 12), Color(0.35, 0.22, 0.1, alpha), 2.0)
		# Target painted on the sail.
		_sea.draw_line(at, at + Vector2(0, -34), Color(0.3, 0.2, 0.1, alpha), 3.0)
		_sea.draw_circle(at + Vector2(0, -26), 10.0, Color(1, 1, 1, alpha))
		_sea.draw_circle(at + Vector2(0, -26), 6.5, Color(0.85, 0.15, 0.1, alpha))
		_sea.draw_circle(at + Vector2(0, -26), 3.0, Color(1, 1, 1, alpha))
	for splash in _splashes:
		var pos: Vector2 = splash["pos"]
		var t: float = splash["t"]
		_sea.draw_arc(pos, 8.0 + t * 40.0, 0.0, TAU, 20, Color(1, 1, 1, 1.0 - t / 0.7), 3.0)
	if phase == Phase.FLYING:
		var at := _ball_from.lerp(_ball_to, _ball_t)
		var height := sin(_ball_t * PI) * 90.0
		_sea.draw_circle(at, 6.0, Color(0, 0, 0, 0.25))
		_sea.draw_circle(at + Vector2(0, -height), 7.0, Color8(30, 30, 34))
