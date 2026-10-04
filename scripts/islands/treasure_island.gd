class_name TreasureIsland
extends IslandGame

## Hot/cold treasure hunt.
## The treasure is buried under one of the Marker2D children of TreasureSpots
## (picked at random each run). The objective line tells the player how hot
## or cold they are. Press E (the "interact" action) to dig. A wrong dig
## costs time. Once the treasure is dug up, get back to the rowboat.

@export_group("Treasure")
## How close (in pixels) a dig must be to the treasure to find it.
@export var dig_radius: float = 40.0
## Seconds taken off the clock for digging in the wrong place.
@export var miss_penalty_seconds: float = 3.0
## Minimum time between digs, so holding E doesn't spam holes.
@export var dig_cooldown_seconds: float = 0.5
@export var spots_path: NodePath = ^"TreasureSpots"
@export var dig_marks_path: NodePath = ^"DigMarks"

# [farther than this distance -> use this label and color]. Checked top-down.
const HEAT_LEVELS: Array = [
	[480.0, "Freezing", Color(0.45, 0.65, 1.0)],
	[320.0, "Cold", Color(0.6, 0.8, 1.0)],
	[200.0, "Cool", Color(0.8, 0.92, 1.0)],
	[110.0, "Warm", Color(1.0, 0.85, 0.35)],
	[50.0, "Hot!", Color(1.0, 0.55, 0.2)],
	[0.0, "BURNING HOT!", Color(1.0, 0.3, 0.15)],
]
const FOUND_COLOR := Color(1.0, 0.85, 0.2)

var treasure_position: Vector2 = Vector2.ZERO
var treasure_found: bool = false

var _heat_index: int = -1
var _dig_cooldown: float = 0.0
var _dig_marks: Node2D


func _setup_game() -> void:
	_dig_marks = get_node_or_null(dig_marks_path) as Node2D
	var spots: Array = []
	var spots_node := get_node_or_null(spots_path)
	if spots_node:
		spots = spots_node.get_children().filter(func(n: Node) -> bool: return n is Node2D)
	assert(not spots.is_empty(), "TreasureIsland needs Marker2D children under TreasureSpots.")
	if not spots.is_empty():
		treasure_position = (spots.pick_random() as Node2D).global_position
	_update_heat()


func _game_process(delta: float) -> void:
	_dig_cooldown = maxf(_dig_cooldown - delta, 0.0)
	if not treasure_found:
		_update_heat()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_running():
		dig()


## Digs at the player's feet.
func dig() -> void:
	if treasure_found or _dig_cooldown > 0.0 or player == null:
		return
	_dig_cooldown = dig_cooldown_seconds
	var spot := player.global_position
	_add_dig_mark(spot)

	var distance := spot.distance_to(treasure_position)
	if distance <= dig_radius:
		_on_treasure_found()
	else:
		add_time(-miss_penalty_seconds)
		var hint := "So close! Try right next to here." if distance < dig_radius * 2.5 else "Nothing here..."
		show_message("%s  (-%ds)" % [hint, int(miss_penalty_seconds)], 1.2)


func _on_treasure_found() -> void:
	treasure_found = true
	_spawn_chest(treasure_position)
	if hud:
		hud.set_objective_color(FOUND_COLOR)
	refresh_hud()
	show_message("You found the treasure! Back to the rowboat!", 2.0)


func _get_objective_text() -> String:
	if treasure_found:
		return "Treasure found! Head to the rowboat."
	if _heat_index < 0:
		return ""
	return "Treasure: %s   (E to dig)" % HEAT_LEVELS[_heat_index][1]


func _is_objective_complete() -> bool:
	return treasure_found


func _update_heat() -> void:
	if player == null:
		return
	var distance := player.global_position.distance_to(treasure_position)
	var index := HEAT_LEVELS.size() - 1
	for i in HEAT_LEVELS.size():
		if distance > HEAT_LEVELS[i][0]:
			index = i
			break
	if index == _heat_index:
		return
	_heat_index = index
	if hud:
		hud.set_objective_color(HEAT_LEVELS[index][2])
	refresh_hud()


# --- Placeholder visuals (swap for real sprites later) ----------------------

func _add_dig_mark(at: Vector2) -> void:
	var hole := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		points.append(Vector2(cos(a) * 11.0, sin(a) * 6.0))
	hole.polygon = points
	hole.color = Color(0.36, 0.25, 0.17, 0.85)
	hole.position = at
	(_dig_marks if _dig_marks else self).add_child(hole)


func _spawn_chest(at: Vector2) -> void:
	var chest := Node2D.new()
	chest.position = at
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-14, -18), Vector2(14, -18), Vector2(14, 0), Vector2(-14, 0)])
	base.color = Color(0.55, 0.33, 0.14)
	var lid := Polygon2D.new()
	lid.polygon = PackedVector2Array([Vector2(-15, -26), Vector2(15, -26), Vector2(14, -18), Vector2(-14, -18)])
	lid.color = Color(0.42, 0.24, 0.1)
	var gold := Polygon2D.new()
	gold.polygon = PackedVector2Array([Vector2(-3, -21), Vector2(3, -21), Vector2(3, -13), Vector2(-3, -13)])
	gold.color = FOUND_COLOR
	chest.add_child(base)
	chest.add_child(lid)
	chest.add_child(gold)
	var world := get_node_or_null(^"World")
	(world if world else self).add_child(chest)
