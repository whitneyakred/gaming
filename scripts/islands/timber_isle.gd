class_name TimberIsle
extends IslandGame

## Timber Isle: chop down trees with a timing meter.
## Walk up to a tree and press E to start chopping. A marker swings across
## the meter above you; press E when it's inside the green zone. Three good
## chops fell a tree and put Wood in your bag. A miss costs time. Walk away
## (any move key) to stop chopping. Fell enough trees, then row back.
##
## Scene setup: Marker2D children of Trees are the trees.

@export_group("Chopping")
@export var trees_path: NodePath = ^"World/Trees"
@export var trees_needed: int = 3
@export var chops_per_tree: int = 3
@export var wood_per_tree: int = 2
@export var reach: float = 46.0
## Full sweeps of the marker per second (it speeds up a little per chop).
@export var marker_speed: float = 0.7
@export var marker_speed_step: float = 0.15
## Width of the green zone, as a share of the meter.
@export_range(0.05, 0.5) var sweet_spot_width: float = 0.18
@export var miss_penalty_seconds: float = 2.0
@export var meter_width: float = 120.0

var felled_count: int = 0
var chopping_tree: int = -1

var _trees: Array[Node2D] = []
var _hits_left: Array[int] = []
var _meter_t: float = 0.0
var _meter_dir: float = 1.0
var _sweet_start: float = 0.4
var _meter: Node2D
var _shake: Dictionary[int, float] = {}


func _setup_game() -> void:
	var trees_node := get_node_or_null(trees_path)
	assert(trees_node != null, "TimberIsle needs Marker2D children under Trees.")
	for marker in trees_node.get_children():
		if marker is Node2D:
			var index := _trees.size()
			_trees.append(marker)
			_hits_left.append(chops_per_tree)
			marker.draw.connect(_draw_tree.bind(index))
			marker.queue_redraw()
			# Trunks block the player until the tree is felled.
			var body := StaticBody2D.new()
			body.name = "Trunk"
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 10.0
			shape.shape = circle
			body.add_child(shape)
			marker.add_child(body)
	trees_needed = mini(trees_needed, _trees.size())
	_meter = Node2D.new()
	_meter.name = "ChopMeter"
	_meter.z_index = 10
	_meter.visible = false
	_meter.draw.connect(_draw_meter)
	add_child(_meter)


func _game_process(delta: float) -> void:
	for index in _shake.keys():
		_shake[index] = maxf(_shake[index] - delta, 0.0)
		_trees[index].queue_redraw()

	if chopping_tree >= 0:
		var speed := marker_speed + marker_speed_step * (chops_per_tree - _hits_left[chopping_tree])
		_meter_t += _meter_dir * speed * 2.0 * delta
		if _meter_t >= 1.0:
			_meter_t = 1.0
			_meter_dir = -1.0
		elif _meter_t <= 0.0:
			_meter_t = 0.0
			_meter_dir = 1.0
		_meter.global_position = player.global_position + Vector2(-meter_width / 2.0, -64)
		_meter.queue_redraw()
		if Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO:
			_stop_chopping()
		set_prompt("Press E in the green zone!")
		return

	var nearest := _nearest_standing_tree()
	set_prompt("Press E to chop" if nearest >= 0 else "")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if chopping_tree >= 0:
		_swing()
	else:
		var tree := _nearest_standing_tree()
		if tree >= 0:
			_start_chopping(tree)


func _start_chopping(tree: int) -> void:
	chopping_tree = tree
	_meter_t = 0.0
	_meter_dir = 1.0
	_new_sweet_spot()
	if player.has_method("try_use_station"):
		player.try_use_station(self)
	_meter.visible = true


func _stop_chopping() -> void:
	chopping_tree = -1
	_meter.visible = false
	if player.has_method("leave_station"):
		player.leave_station(self)


func _swing() -> void:
	var tree := chopping_tree
	if _meter_t >= _sweet_start and _meter_t <= _sweet_start + sweet_spot_width:
		_hits_left[tree] -= 1
		_shake[tree] = 0.25
		if _hits_left[tree] <= 0:
			_fell(tree)
			return
		show_message("Chop!", 0.5)
	else:
		add_time(-miss_penalty_seconds)
		show_message("Missed! (-%ds)" % int(miss_penalty_seconds), 0.8)
	_new_sweet_spot()


func _fell(tree: int) -> void:
	_stop_chopping()
	felled_count += 1
	var trunk := _trees[tree].get_node_or_null(^"Trunk")
	if trunk:
		trunk.queue_free()
	_trees[tree].queue_redraw()
	give_item(&"wood", wood_per_tree)
	refresh_hud()
	if felled_count >= trees_needed:
		show_message("Timber! That's enough wood. Back to the rowboat!", 2.0)
	else:
		show_message("Timber!", 1.0)


func _new_sweet_spot() -> void:
	_sweet_start = randf_range(0.05, 0.95 - sweet_spot_width)


func _nearest_standing_tree() -> int:
	if player == null:
		return -1
	var best := -1
	var best_distance := reach
	for i in _trees.size():
		if _hits_left[i] <= 0:
			continue
		var distance := player.global_position.distance_to(_trees[i].global_position)
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _get_objective_text() -> String:
	if felled_count >= trees_needed:
		return "Enough wood! Head to the rowboat."
	return "Trees felled: %d / %d" % [felled_count, trees_needed]


func _is_objective_complete() -> bool:
	return felled_count >= trees_needed


func _get_incomplete_message() -> String:
	return "Chop %d trees first!" % trees_needed


func _draw_tree(index: int) -> void:
	var tree := _trees[index]
	var trunk := Color8(110, 72, 40)
	if _hits_left[index] <= 0:
		tree.draw_circle(Vector2.ZERO, 11.0, trunk)
		tree.draw_circle(Vector2.ZERO, 7.0, Color8(196, 160, 110))
		return
	var shake: float = sin(_shake.get(index, 0.0) * 80.0) * 3.0 * _shake.get(index, 0.0) * 4.0
	tree.draw_rect(Rect2(-7 + shake, -40, 14, 42), trunk)
	tree.draw_circle(Vector2(shake, -58), 30.0, Color8(52, 120, 58))
	tree.draw_circle(Vector2(-16 + shake, -46), 18.0, Color8(62, 138, 66))
	tree.draw_circle(Vector2(16 + shake, -48), 18.0, Color8(46, 108, 52))
	# Notches show how many chops it has taken.
	for i in chops_per_tree - _hits_left[index]:
		tree.draw_line(Vector2(-7 + shake, -6 - i * 6), Vector2(2 + shake, -3 - i * 6), Color8(220, 190, 140), 2.0)


func _draw_meter() -> void:
	var height := 14.0
	_meter.draw_rect(Rect2(-3, -3, meter_width + 6, height + 6), Color(0, 0, 0, 0.7))
	_meter.draw_rect(Rect2(0, 0, meter_width, height), Color8(150, 60, 50))
	_meter.draw_rect(Rect2(_sweet_start * meter_width, 0, sweet_spot_width * meter_width, height), Color8(90, 210, 90))
	var x := _meter_t * meter_width
	_meter.draw_rect(Rect2(x - 2, -6, 4, height + 12), Color.WHITE)
