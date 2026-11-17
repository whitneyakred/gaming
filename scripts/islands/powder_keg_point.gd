class_name PowderKegPoint
extends IslandGame

## Powder Keg Point: stamp out lit fuses before the kegs blow.
## Every few seconds a fuse catches on one of the powder kegs, and fuses
## catch faster as time goes on. Run over and press E next to a burning keg
## to stamp it out; each keg you save puts 1 Gunpowder in your bag. A fuse
## that burns all the way down blows its keg. Too many blasts and it's game
## over. Last until the timer runs out, then row home.
##
## Scene setup: Marker2D children of Kegs are the kegs.

@export_group("Kegs")
@export var kegs_path: NodePath = ^"World/Kegs"
@export var reward_item_id: StringName = &"gunpowder"
## Seconds a lit fuse burns before its keg blows.
@export var fuse_seconds: float = 5.0
## Seconds between new fuses when the island starts...
@export var light_interval_start: float = 3.0
## ...and when the timer is almost out.
@export var light_interval_end: float = 1.3
@export var reach: float = 48.0
@export var max_blasts: int = 3

var blasts: int = 0
var stamped_count: int = 0
var all_clear: bool = false

var _kegs: Array[Node2D] = []
var _fuse: Array[float] = []     # seconds left on the fuse; < 0 means not lit
var _blown: Array[bool] = []
var _flash: Array[float] = []    # explosion / stamp effect timer
var _next_light: float = 1.5
var _time: float = 0.0


func _setup_game() -> void:
	var kegs := get_node_or_null(kegs_path)
	assert(kegs != null, "PowderKegPoint needs Marker2D children under Kegs.")
	for marker in kegs.get_children():
		if marker is Node2D:
			var index := _kegs.size()
			_kegs.append(marker)
			_fuse.append(-1.0)
			_blown.append(false)
			_flash.append(0.0)
			marker.draw.connect(_draw_keg.bind(index))
			marker.queue_redraw()


func _game_process(delta: float) -> void:
	_time += delta
	for i in _kegs.size():
		_flash[i] = maxf(_flash[i] - delta, 0.0)
		_kegs[i].queue_redraw()
	if all_clear:
		return

	_next_light -= delta
	if _next_light <= 0.0:
		light_random_fuse()
		var progress := 1.0 - time_remaining / time_limit_seconds if has_time_limit() else 0.0
		_next_light = lerpf(light_interval_start, light_interval_end, progress)

	for i in _kegs.size():
		if _fuse[i] < 0.0:
			continue
		_fuse[i] -= delta
		if _fuse[i] <= 0.0:
			_blow(i)
			if not is_running():
				return

	set_prompt("Press E to stamp out the fuse!" if _nearest_lit_keg() >= 0 else "")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or all_clear or not event.is_action_pressed("interact") or event.is_echo():
		return
	var keg := _nearest_lit_keg()
	if keg >= 0:
		get_viewport().set_input_as_handled()
		stamp(keg)


## Lights the fuse on a random keg that isn't already lit or blown.
## Returns the keg's index, or -1 if none could be lit.
func light_random_fuse() -> int:
	var choices: Array[int] = []
	for i in _kegs.size():
		if not _blown[i] and _fuse[i] < 0.0:
			choices.append(i)
	if choices.is_empty():
		return -1
	var keg: int = choices[randi() % choices.size()]
	_fuse[keg] = fuse_seconds
	return keg


func is_lit(keg: int) -> bool:
	return _fuse[keg] >= 0.0


func stamp(keg: int) -> void:
	if _fuse[keg] < 0.0:
		return
	_fuse[keg] = -1.0
	_flash[keg] = 0.3
	stamped_count += 1
	give_item(reward_item_id, 1)
	refresh_hud()


func _blow(keg: int) -> void:
	_fuse[keg] = -1.0
	_blown[keg] = true
	_flash[keg] = 0.8
	blasts += 1
	refresh_hud()
	if blasts >= max_blasts:
		lose("Kaboom! Too many kegs blew up.")
	else:
		show_message("BOOM! A keg blew!", 1.0)


func _nearest_lit_keg() -> int:
	if player == null:
		return -1
	var best := -1
	var best_distance := reach
	for i in _kegs.size():
		if _fuse[i] < 0.0:
			continue
		var distance := player.global_position.distance_to(_kegs[i].global_position)
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _on_time_up() -> void:
	all_clear = true
	pause_timer(true)
	for i in _fuse.size():
		_fuse[i] = -1.0
	set_prompt("")
	if hud:
		hud.set_timer_visible(false)
	refresh_hud()
	show_message("The fires are out! Row back with your gunpowder.", 2.5)


func _get_objective_text() -> String:
	if all_clear:
		return "All clear! Head to the rowboat."
	return "Stamp out the fuses!   Blasts: %d / %d   Saved: %d" % [blasts, max_blasts, stamped_count]


func _is_objective_complete() -> bool:
	return all_clear


func _get_incomplete_message() -> String:
	return "Keep those kegs from blowing until time's up!"


func _draw_keg(index: int) -> void:
	var keg := _kegs[index]
	if _blown[index]:
		keg.draw_circle(Vector2(0, 4), 22.0, Color(0.1, 0.08, 0.06, 0.8))
		for i in 6:
			var dir := Vector2.from_angle(i * TAU / 6.0 + 0.4)
			keg.draw_line(dir * 8.0, dir * 20.0, Color8(110, 72, 40), 3.0)
		if _flash[index] > 0.0:
			var t := 1.0 - _flash[index] / 0.8
			keg.draw_circle(Vector2.ZERO, 20.0 + t * 60.0, Color(1.0, 0.55, 0.1, 0.7 * (1.0 - t)))
			keg.draw_circle(Vector2.ZERO, 10.0 + t * 30.0, Color(1.0, 0.9, 0.4, 0.8 * (1.0 - t)))
		return

	var wood := Color8(130, 84, 44)
	keg.draw_rect(Rect2(-14, -22, 28, 30), wood)
	keg.draw_rect(Rect2(-16, -18, 32, 4), Color8(70, 70, 76))
	keg.draw_rect(Rect2(-16, 0, 32, 4), Color8(70, 70, 76))
	keg.draw_circle(Vector2(0, -22), 3.0, Color8(30, 30, 30))

	if _fuse[index] >= 0.0:
		var left := _fuse[index] / fuse_seconds
		var tip := Vector2(6.0 + 10.0 * left, -22.0 - 14.0 * left)
		keg.draw_line(Vector2(0, -22), tip, Color8(60, 50, 40), 2.0)
		var flicker := 0.7 + 0.3 * sin(_time * 40.0 + index)
		keg.draw_circle(tip, 5.0 * flicker, Color(1.0, 0.6, 0.1))
		keg.draw_circle(tip, 2.5, Color(1.0, 1.0, 0.6))
		if _fuse[index] < 2.0:
			var pulse := 0.5 + 0.5 * sin(_time * 18.0)
			keg.draw_arc(Vector2(0, -8), 28.0, 0.0, TAU, 24, Color(1.0, 0.2, 0.1, 0.4 + 0.5 * pulse), 3.0)
	if _flash[index] > 0.0:
		keg.draw_circle(Vector2(0, -24), 12.0 * _flash[index] / 0.3, Color(0.8, 0.8, 0.8, 0.6))
