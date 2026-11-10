class_name BeeHiveHill
extends IslandGame

## Bee Hive Hill: grab the honey and outrun the bees.
## Press E at a hive to take its honey. That wakes the bees, and after a
## moment they come after you, faster than you can run. Duck behind one of
## the island's trees and they lose track of you and fly home; they also give
## up after a while. Get stung too many times and it's game over. Take honey
## from every hive, then row home.
##
## Scene setup: Marker2D children of Hives are the hives. The hiding spots
## are the painted trees: the Trees markers inside the Terrain instance
## (scenes/islands/island_art.tscn), one at the foot of each trunk.

@export_group("Hives")
@export var hives_path: NodePath = ^"World/Hives"
@export var trees_path: NodePath = ^"Terrain/Trees"
@export var reward_item_id: StringName = &"honey"
@export var reach: float = 44.0
## Standing this close to a tree's trunk hides you from the bees.
@export var hide_radius: float = 24.0

@export_group("Bees")
@export var bee_speed: float = 172.0
## Seconds the bees buzz at the hive before they chase.
@export var wake_seconds: float = 0.7
## Seconds the bees chase before giving up.
@export var chase_seconds: float = 7.0
@export var sting_radius: float = 18.0
@export var sting_penalty_seconds: float = 4.0
@export var max_stings: int = 3

var robbed: Array[bool] = []
var honey_count: int = 0
var stings: int = 0
## Each swarm: {pos: Vector2, home: Vector2, wake: float, chase: float, returning: bool}
var swarms: Array[Dictionary] = []

var _hives: Array[Node2D] = []
var _trees: Array[Node2D] = []
var _bees: Node2D
var _time: float = 0.0


func _setup_game() -> void:
	var hives := get_node_or_null(hives_path)
	assert(hives != null, "BeeHiveHill needs Marker2D children under Hives.")
	for marker in hives.get_children():
		if marker is Node2D:
			var index := _hives.size()
			_hives.append(marker)
			robbed.append(false)
			marker.draw.connect(_draw_hive.bind(index))
			marker.queue_redraw()
	var trees := get_node_or_null(trees_path)
	assert(trees != null, "BeeHiveHill needs tree markers (Terrain/Trees) to hide behind.")
	if trees:
		for marker in trees.get_children():
			if marker is Node2D:
				_trees.append(marker)
	_bees = Node2D.new()
	_bees.name = "Bees"
	_bees.z_index = 20
	_bees.draw.connect(_draw_bees)
	add_child(_bees)


func _game_process(delta: float) -> void:
	_time += delta
	_bees.queue_redraw()
	for hive in _hives:
		hive.queue_redraw()
	if player == null:
		return
	var hidden := is_hidden()
	for i in range(swarms.size() - 1, -1, -1):
		var swarm := swarms[i]
		var pos: Vector2 = swarm["pos"]
		var home: Vector2 = swarm["home"]
		if swarm["returning"]:
			pos = pos.move_toward(home, bee_speed * 0.6 * delta)
			swarm["pos"] = pos
			if pos.distance_to(home) < 2.0:
				swarms.remove_at(i)
			continue
		if float(swarm["wake"]) > 0.0:
			swarm["wake"] = float(swarm["wake"]) - delta
			continue
		swarm["chase"] = float(swarm["chase"]) - delta
		if hidden or float(swarm["chase"]) <= 0.0:
			swarm["returning"] = true
			if hidden:
				show_message("The bees lost you behind the tree.", 1.0)
			continue
		pos = pos.move_toward(player.global_position, bee_speed * delta)
		swarm["pos"] = pos
		if pos.distance_to(player.global_position) <= sting_radius:
			_sting(swarm)
			if not is_running():
				return
	set_prompt("Press E to take the honey" if _nearest_full_hive() >= 0 else "")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or not event.is_action_pressed("interact") or event.is_echo():
		return
	var hive := _nearest_full_hive()
	if hive >= 0:
		get_viewport().set_input_as_handled()
		take_honey(hive)


func take_honey(index: int) -> void:
	if robbed[index]:
		return
	robbed[index] = true
	honey_count += 1
	give_item(reward_item_id, 1)
	var home := _hives[index].global_position
	swarms.append({"pos": home, "home": home, "wake": wake_seconds, "chase": chase_seconds, "returning": false})
	refresh_hud()
	if honey_count >= _hives.size():
		show_message("That's all the honey! Run for the rowboat!", 2.0)
	else:
		show_message("Bzzz... the bees are waking up. Run!", 1.2)


## True while the player is hiding behind a tree.
func is_hidden() -> bool:
	return _hiding_tree() >= 0


## The index of the tree the player is hiding behind, or -1.
func _hiding_tree() -> int:
	if player == null:
		return -1
	for i in _trees.size():
		if player.global_position.distance_to(_trees[i].global_position) <= hide_radius:
			return i
	return -1


func _sting(swarm: Dictionary) -> void:
	stings += 1
	swarm["returning"] = true
	refresh_hud()
	if stings >= max_stings:
		lose("Stung too many times!")
		return
	add_time(-sting_penalty_seconds)
	show_message("Ouch! Stung! (-%ds)" % int(sting_penalty_seconds), 1.0)


func _nearest_full_hive() -> int:
	var best := -1
	var best_distance := reach
	for i in _hives.size():
		if robbed[i]:
			continue
		var distance := player.global_position.distance_to(_hives[i].global_position)
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _get_objective_text() -> String:
	if honey_count >= _hives.size():
		return "All the honey's yours! Head to the rowboat."
	return "Honey: %d / %d   Stings: %d / %d" % [honey_count, _hives.size(), stings, max_stings]


func _is_objective_complete() -> bool:
	return honey_count >= _hives.size()


func _get_incomplete_message() -> String:
	return "Take honey from every hive first!"


func _draw_hive(index: int) -> void:
	var hive := _hives[index]
	hive.draw_rect(Rect2(-3, -6, 6, 20), Color8(100, 66, 36))
	var gold := Color8(230, 180, 60) if not robbed[index] else Color8(170, 140, 80)
	for i in 4:
		var w := 22.0 - absf(i - 1.5) * 5.0
		hive.draw_rect(Rect2(-w / 2.0, -38 + i * 8, w, 8), gold if i % 2 == 0 else gold.darkened(0.25))
	hive.draw_circle(Vector2(0, -16), 3.5, Color8(40, 30, 20))
	if not robbed[index]:
		for i in 3:
			var at := Vector2.from_angle(_time * 3.0 + i * 2.1) * 18.0 + Vector2(0, -24)
			hive.draw_circle(at, 2.0, Color8(40, 30, 10))


func _draw_bees() -> void:
	# While you hide, leaves cover you so it looks like you're behind the tree.
	var tree := _hiding_tree()
	if tree >= 0:
		var at := _trees[tree].global_position
		var leaves := Color8(58, 120, 56)
		_bees.draw_circle(at + Vector2(0, -24), 22.0, Color(leaves, 0.7))
		_bees.draw_circle(at + Vector2(-12, -14), 13.0, Color(leaves.lightened(0.1), 0.7))
		_bees.draw_circle(at + Vector2(12, -14), 13.0, Color(leaves.darkened(0.1), 0.7))
	for swarm in swarms:
		var pos: Vector2 = swarm["pos"]
		var waking := float(swarm["wake"]) > 0.0
		for i in 9:
			var angle := i * 2.4 + _time * (8.0 if not waking else 4.0)
			var at := pos + Vector2.from_angle(angle) * (6.0 + (i % 3) * 4.0)
			_bees.draw_circle(at, 2.5, Color8(240, 200, 40))
			_bees.draw_line(at + Vector2(-1.5, 0), at + Vector2(1.5, 0), Color8(30, 25, 10), 1.5)
