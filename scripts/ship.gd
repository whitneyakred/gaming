class_name Ship
extends ShipMotion

# Sail and steer around an open map of islands. There is no nearest-island
# text or arrow while voyaging: you find islands by sailing. Islands are solid:
# the hull scrapes along a shore instead of sailing over it (each island's
# Land/Coast outline). Lower the anchor (E at the anchor station) within
# anchor_island_distance of an island's shore and the ship anchors right
# there. Then walk to the stern and press E (the "interact" action) to row
# ashore, or raise the anchor again to sail on. When you come back, the
# rowboat rows you home to the ship where you left it.

# Set by IslandGame (scripts/islands/island_game.gd) right before it switches back to this scene, so we know
# to play the "row back to the ship" part instead of starting fresh.
static var returning_from_island: bool = false
# Name of the WorldIsland node the ship is anchored at while you're ashore.
# Static so it survives the scene swaps to and from the island.
static var visited_island_name: StringName = &""
# Islands you've finished (won and rowed back from). They no longer count as
# the "nearest island" (get_nearest_island()).
static var completed_islands: Array[StringName] = []
# Where the ship was anchored when you rowed ashore, so it is still there
# when you row back.
static var anchored_position: Vector2 = Vector2.ZERO
static var anchored_rotation: float = 0.0

# --- Tunable in the Inspector on the Ship node ---
## Lowering the anchor this close (px) to an island's shore lets you row ashore.
@export var anchor_island_distance: float = 500.0
@export var row_speed: float = 130.0               # rowboat speed, px/s
## Map pixels per "meter" shown in the status line.
@export var pixels_per_meter: float = 10.0

enum State { SAILING, ANCHORED, ROWING }

# Where the rowboat goes first after leaving the stern (ship-local), so it
# clears the hull before heading for shore.
const ROW_LAUNCH := Vector2(70, 300)
# The rowboat stops this far short of the coastline.
const SHORE_GAP := 24.0

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
var _docked_island: WorldIsland
# The island you just left. Anchoring near it again does nothing until you
# sail clear of it.
var _leaving_island: WorldIsland
# The island whose shore the hull last touched.
var _aground_island: WorldIsland

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
	anchor_changed.connect(_on_anchor_changed)
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
	if _state == State.SAILING or _state == State.ANCHORED:
		super._physics_process(delta)
		if _leaving_island and _distance_to_shore(_leaving_island) > anchor_island_distance:
			_leaving_island = null
		if _state == State.SAILING:
			if aground:
				_set_status("Ran aground! Steer away from the shore.")
			else:
				_update_sailing_status()
	ocean.global_position = global_position
	prompt_label.visible = _state == State.ANCHORED and _player_at_stern and not player.using_station

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

# The nearest island (finished or not) whose shore is within
# anchor_island_distance, except the one you just rowed back from.
func _island_in_anchor_range() -> WorldIsland:
	var best: WorldIsland = null
	var best_distance := anchor_island_distance
	for candidate in get_islands():
		if candidate == _leaving_island:
			continue
		var d := _distance_to_shore(candidate)
		if d <= best_distance:
			best = candidate
			best_distance = d
	return best

func _distance_to_shore(island: WorldIsland) -> float:
	return global_position.distance_to(island.get_nearest_coast_point(global_position))

# --- Keeping the hull off land -------------------------------------------------

func _is_pose_blocked(at: Vector2, angle: float) -> bool:
	if hull_outline.is_empty():
		return false
	var hull := get_hull_polygon(at, angle)
	var bounds := Rect2(hull[0], Vector2.ZERO)
	for point in hull:
		bounds = bounds.expand(point)
	for island in get_islands():
		if island.overlaps_land(hull, bounds):
			_aground_island = island
			return true
	return false

func _get_shore_normal(at: Vector2) -> Vector2:
	if _aground_island == null:
		return Vector2.ZERO
	var away := at - _aground_island.get_nearest_coast_point(at)
	return away.normalized() if away.length() > 0.01 else Vector2.ZERO

# While voyaging the status line stays empty: no nearest-island name,
# distance, or arrow. It only speaks up when the anchor is down out at sea.
# Anchoring and rowing use it for their own messages.
func _update_sailing_status() -> void:
	if anchor_deployed:
		_set_status("Anchor lowered. Press E at the anchor to sail again.")
	else:
		_set_status("")

# --- Anchoring and the rowboat -------------------------------------------------

func _stop_sailing() -> void:
	stations_enabled = false
	anchor_deployed = true
	$Helm.release_control()
	$Sail.release_control()
	speed = 0.0
	turn_rate = 0.0
	set_sail_level(0)
	set_wheel_angle(0.0)

# Lowering the anchor near an island anchors there; raising it sails on.
func _on_anchor_changed(deployed: bool) -> void:
	if deployed and _state == State.SAILING:
		var island := _island_in_anchor_range()
		if island:
			_anchor_at(island)
	elif not deployed and _state == State.ANCHORED:
		_docked_island = null
		_state = State.SAILING
		_update_sailing_status()

func _anchor_at(island: WorldIsland) -> void:
	_state = State.ANCHORED
	_docked_island = island
	_set_status("Anchored near %s! Head to the back of the ship to row ashore, or raise the anchor to sail on." % island.display_name)

# Ship-local spot just off the stretch of shore nearest the ship.
func _landing_point(island: WorldIsland) -> Vector2:
	var shore := island.get_nearest_coast_point(global_position)
	var back := global_position - shore
	if back.length() > SHORE_GAP:
		shore += back.normalized() * SHORE_GAP
	return to_local(shore)

func _row_to_island() -> void:
	_state = State.ROWING
	_stop_sailing()
	anchored_position = global_position
	anchored_rotation = global_rotation
	_set_status("Rowing to %s..." % _docked_island.display_name)
	_board_rowboat()
	var path: Array[Vector2] = [ROW_LAUNCH, _landing_point(_docked_island)]
	await _row_along(path)
	visited_island_name = _docked_island.name
	get_tree().change_scene_to_file(_docked_island.scene)

func _row_back_from_island(from_island: WorldIsland) -> void:
	_state = State.ROWING
	_stop_sailing()
	_docked_island = from_island
	global_position = anchored_position
	global_rotation = anchored_rotation
	force_update_transform()
	ocean.global_position = global_position
	rowboat.position = _landing_point(from_island)
	rowboat.rotation = -PI / 2.0
	_board_rowboat()
	_set_status("Rowing back to the ship...")
	var path: Array[Vector2] = [ROW_LAUNCH, _rowboat_home]
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
	anchor_deployed = false
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
	status_label.visible = not text.is_empty()

func _on_stern_entered(body: Node2D) -> void:
	if body == player:
		_player_at_stern = true

func _on_stern_exited(body: Node2D) -> void:
	if body == player:
		_player_at_stern = false
