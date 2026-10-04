class_name Ship
extends ShipMotion

# Sail and steer around an open map of islands. The status line names the
# nearest island and how far away it is, and a yellow arrow points to it.
# Sail into an island's yellow docking circle to anchor beside it, then walk
# to the stern and press E (the "interact" action) to row over. When you come
# back, the rowboat rows you home and you can sail to any island you like.

# Set by IslandGame (scripts/islands/island_game.gd) right before it switches back to this scene, so we know
# to play the "row back to the ship" part instead of starting fresh.
static var returning_from_island: bool = false
# Name of the WorldIsland node the ship is anchored at while you're ashore.
# Static so it survives the scene swaps to and from the island.
static var visited_island_name: StringName = &""
# Islands you've finished (won and rowed back from). They no longer count as
# "nearest island" and the arrow stops pointing at them.
static var completed_islands: Array[StringName] = []

# --- Tunable in the Inspector on the Ship node ---
@export var docking_distance: float = 90.0         # how close to the dock point anchors the ship
@export var marker_distance: float = 900.0         # docking circle shows within this range
@export var row_speed: float = 130.0               # rowboat speed, px/s
## Map pixels per "meter" shown in the status line.
@export var pixels_per_meter: float = 10.0

enum State { SAILING, DOCKING, ANCHORED, ROWING }

const MARKER_COLOR := Color(1, 0.9, 0.45)

# Route the rowboat takes from the stern to the island's dock (ship-local
# coordinates). The last point is just below the island's dock.
const ROW_PATH: Array[Vector2] = [
	Vector2(70, 300), Vector2(230, 305), Vector2(345, 262), Vector2(400, 188),
]

@onready var ocean: Ocean = $Ocean
@onready var islands_root: Node2D = $Islands
@onready var player: CharacterBody2D = $Player
@onready var rowboat: Node2D = $Rowboat
@onready var rider: Sprite2D = $Rowboat/Rider
@onready var stern_zone: Area2D = $SternZone
@onready var status_label: Label = $HUD/StatusLabel
@onready var prompt_label: Label = $HUD/PromptLabel

var _state: State = State.SAILING
var _player_at_stern: bool = false
var _rowboat_home: Vector2
var _dock_position: Vector2
var _docked_island: WorldIsland
# The island you just left. It can't re-anchor you until you sail clear.
var _leaving_island: WorldIsland
var _nearest: WorldIsland

func _ready() -> void:
	super._ready()
	# Islands stay put in world space (their positions in ship.tscn are map
	# coordinates) while the deck, stations, and player move together.
	islands_root.set_as_top_level(true)
	islands_root.global_transform = Transform2D.IDENTITY
	ocean.set_as_top_level(true)
	ocean.global_rotation = 0.0
	_rowboat_home = rowboat.position
	stern_zone.body_entered.connect(_on_stern_entered)
	stern_zone.body_exited.connect(_on_stern_exited)
	prompt_label.visible = false
	rider.visible = false

	var visited := get_island(visited_island_name)
	if returning_from_island and visited:
		returning_from_island = false
		if not completed_islands.has(visited.name):
			completed_islands.append(visited.name)
		_row_back_from_island(visited)
	else:
		returning_from_island = false
		_update_sailing_status()

func _physics_process(delta: float) -> void:
	if _state == State.SAILING:
		super._physics_process(delta)
		_nearest = get_nearest_island()
		if _leaving_island and global_position.distance_to(_leaving_island.get_dock_position()) > docking_distance * 3.0:
			_leaving_island = null
		var dock_target := _island_in_docking_range()
		if dock_target:
			_dock(dock_target)
		else:
			_update_sailing_status()
	ocean.global_position = global_position
	prompt_label.visible = _state == State.ANCHORED and _player_at_stern and not player.using_station
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _state == State.ANCHORED and _player_at_stern and not player.using_station:
		if event.is_action_pressed("interact") and not event.is_echo():
			get_viewport().set_input_as_handled()
			_row_to_island()

# --- Islands on the map --------------------------------------------------------

func get_islands() -> Array[WorldIsland]:
	var result: Array[WorldIsland] = []
	for child in islands_root.get_children():
		if child is WorldIsland:
			result.append(child)
	return result

func get_island(island_name: StringName) -> WorldIsland:
	if island_name.is_empty():
		return null
	return islands_root.get_node_or_null(NodePath(island_name)) as WorldIsland

func is_completed(island: WorldIsland) -> bool:
	return island != null and completed_islands.has(island.name)

## Nearest island you haven't finished yet (null once they're all done).
func get_nearest_island() -> WorldIsland:
	var best: WorldIsland = null
	var best_distance := INF
	for candidate in get_islands():
		if is_completed(candidate):
			continue
		var d := global_position.distance_to(candidate.get_dock_position())
		if d < best_distance:
			best = candidate
			best_distance = d
	return best

# Any island (finished or not) whose docking circle the ship is inside,
# except the one you just rowed back from.
func _island_in_docking_range() -> WorldIsland:
	for candidate in get_islands():
		if candidate != _leaving_island \
				and global_position.distance_to(candidate.get_dock_position()) <= docking_distance:
			return candidate
	return null

func _update_sailing_status() -> void:
	var nearest := get_nearest_island()
	if nearest == null:
		_set_status("All islands explored!")
		return
	var distance := global_position.distance_to(nearest.get_dock_position())
	var meters := roundi(distance / pixels_per_meter)
	if _leaving_island and speed < 1.0:
		_set_status("Raise the sail! Next island: %s, %d m away" % [nearest.display_name, meters])
	elif distance <= marker_distance:
		_set_status("%s: sail into the yellow circle to anchor (%d m)" % [nearest.display_name, meters])
	else:
		_set_status("Nearest island: %s, %d m away" % [nearest.display_name, meters])

func _draw() -> void:
	if _state != State.SAILING:
		return
	for candidate in get_islands():
		if candidate == _leaving_island:
			continue
		var dock := candidate.get_dock_position()
		if global_position.distance_to(dock) <= marker_distance:
			draw_arc(to_local(dock), docking_distance, 0, TAU, 48, MARKER_COLOR, 3.0)
	# Arrow just off the bow side pointing at the nearest unfinished island.
	if _nearest:
		var target := to_local(_nearest.get_dock_position())
		if target.length() > marker_distance * 0.5:
			var dir := target.normalized()
			var tip := dir * 300.0
			var side := dir.orthogonal() * 12.0
			draw_colored_polygon(PackedVector2Array([tip, tip - dir * 26.0 + side, tip - dir * 26.0 - side]), MARKER_COLOR)

# --- Docking and the rowboat ---------------------------------------------------

func _stop_sailing() -> void:
	stations_enabled = false
	$Helm.release_control()
	$Sail.release_control()
	speed = 0.0
	turn_rate = 0.0
	set_sail_level(0)
	set_wheel_angle(0.0)

func _dock(target: WorldIsland) -> void:
	_state = State.DOCKING
	_docked_island = target
	_dock_position = target.get_dock_position()
	_stop_sailing()
	_set_status("Docking at %s..." % target.display_name)
	var tween := create_tween().set_parallel(true)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", _dock_position, 0.8)
	tween.tween_property(self, "global_rotation", global_rotation + wrapf(target.global_rotation - global_rotation, -PI, PI), 0.8)
	await tween.finished
	_state = State.ANCHORED
	_set_status("Anchored at %s! Head to the back of the ship." % target.display_name)

func _row_to_island() -> void:
	_state = State.ROWING
	_set_status("Rowing to %s..." % _docked_island.display_name)
	_board_rowboat()
	await _row_along(ROW_PATH)
	visited_island_name = _docked_island.name
	get_tree().change_scene_to_file(_docked_island.scene)

func _row_back_from_island(from_island: WorldIsland) -> void:
	_state = State.ROWING
	_stop_sailing()
	_docked_island = from_island
	_dock_position = from_island.get_dock_position()
	global_position = _dock_position
	global_rotation = from_island.global_rotation
	ocean.global_position = global_position
	rowboat.position = ROW_PATH[-1]
	rowboat.rotation = -PI / 2.0
	_board_rowboat()
	_set_status("Rowing back to the ship...")
	var path: Array[Vector2] = ROW_PATH.duplicate()
	path.reverse()
	path.append(_rowboat_home)
	await _row_along(path)
	# Back aboard: hang the rowboat up, put the player at the stern, set sail.
	rowboat.rotation = 0.0
	rider.visible = false
	player.position = stern_zone.position + Vector2(0, -24)
	player.visible = true
	player.leave_station(self)
	player.set_physics_process(true)
	_leaving_island = from_island
	_docked_island = null
	_state = State.SAILING
	stations_enabled = true
	_update_sailing_status()

func _board_rowboat() -> void:
	player.try_use_station(self)
	player.visible = false
	player.set_physics_process(false)
	rider.visible = true
	prompt_label.visible = false

# Moves the rowboat through each point at a steady speed, turning it to
# face where it's going. The boat is double-ended, so it never turns more
# than a quarter turn at once.
func _row_along(points: Array[Vector2]) -> void:
	for target in points:
		var dir := target - rowboat.position
		if dir.length() < 1.0:
			continue
		var turn := wrapf(dir.angle() - rowboat.rotation, -PI / 2.0, PI / 2.0)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(rowboat, "position", target, dir.length() / row_speed)
		tween.tween_property(rowboat, "rotation", rowboat.rotation + turn, 0.4)
		await tween.finished

func _set_status(text: String) -> void:
	status_label.text = text

func _on_stern_entered(body: Node2D) -> void:
	if body == player:
		_player_at_stern = true

func _on_stern_exited(body: Node2D) -> void:
	if body == player:
		_player_at_stern = false
