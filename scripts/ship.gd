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
# Whether that visit was won. A game over rows you back too, but the island
# stays unfinished so you can try it again.
static var last_visit_won: bool = true
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
# Where the rowboat ties up at an island's dock, relative to the island's
# anchoring spot (dock_offset), turned to match the island.
const DOCK_LANDING := Vector2(400, 188)
# How far the rowboat keeps from an island's shore and from the ship's hull.
const ROW_SHORE_MARGIN := 40.0
const ROW_HULL_MARGIN := 30.0
# While rowing, the view follows the rowboat once it gets this close (px) to
# the edge of the screen, then eases back to the ship afterwards.
const VIEW_EDGE := 140.0
const VIEW_FOLLOW_SPEED := 5.0

@onready var ocean: Ocean = $Ocean
@onready var islands_root: Node2D = $Islands
@onready var player: CharacterBody2D = $Player
@onready var rowboat: Node2D = $Rowboat
@onready var rider: Sprite2D = $Rowboat/Rider
@onready var stern_zone: Area2D = $SternZone
@onready var status_label: Label = $HUD/StatusLabel
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var _view: Node = get_node_or_null(^"SailingDemo")

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
	# top_level also draws a node above everything else; keep the islands
	# under the ship and rowboat (but above the ocean).
	islands_root.z_index = -10
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
		if last_visit_won and not completed_islands.has(visited.name):
			completed_islands.append(visited.name)
		last_visit_won = true
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

func _process(delta: float) -> void:
	super._process(delta)
	if _view == null:
		return
	var offset: Vector2 = _view.view_offset
	var target := Vector2.ZERO
	if _state == State.ROWING:
		target = _view_offset_showing(rowboat.global_position, offset)
	_view.view_offset = offset.lerp(target, 1.0 - exp(-VIEW_FOLLOW_SPEED * delta))

# The smallest change to `current` that brings `point` inside the screen,
# VIEW_EDGE px in from the edges.
func _view_offset_showing(point: Vector2, current: Vector2) -> Vector2:
	var camera: Camera2D = _view.camera
	var half := get_viewport_rect().size / camera.zoom * 0.5 - Vector2.ONE * VIEW_EDGE
	half = half.max(Vector2.ZERO)
	var from_center := point - (global_position + current)
	var shift := Vector2(
		signf(from_center.x) * maxf(absf(from_center.x) - half.x, 0.0),
		signf(from_center.y) * maxf(absf(from_center.y) - half.y, 0.0))
	return current + shift

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

# Ship-local points from the stern to the island's dock, going around the
# island's coast and around the ship itself rather than over either.
func _rowing_route(island: WorldIsland) -> Array[Vector2]:
	var landing := Transform2D(island.global_rotation, island.get_dock_position()) * DOCK_LANDING
	var obstacles: Array[PackedVector2Array] = [island.get_coast(), get_hull_polygon(global_position, global_rotation)]
	var margins: Array[float] = [ROW_SHORE_MARGIN, ROW_HULL_MARGIN]
	var path: Array[Vector2] = [ROW_LAUNCH]
	for point in RowPlanner.find_path(to_global(ROW_LAUNCH), landing, obstacles, margins):
		path.append(to_local(point))
	return path

func _row_to_island() -> void:
	_state = State.ROWING
	_stop_sailing()
	anchored_position = global_position
	anchored_rotation = global_rotation
	_set_status("Rowing to %s..." % _docked_island.display_name)
	_board_rowboat()
	await _row_along(_rowing_route(_docked_island))
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
	var path := _rowing_route(from_island)
	path.reverse()
	rowboat.position = path.pop_front()
	rowboat.rotation = -PI / 2.0
	if _view:
		# Start the view on the rowboat at the dock, then follow it home.
		_view.view_offset = _view_offset_showing(rowboat.global_position, Vector2.ZERO)
	_board_rowboat()
	_set_status("Rowing back to the ship...")
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
	# The anchor stays down (you lowered it to go ashore); raise it to sail on.
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
		var seconds := dir.length() / row_speed
		var tween := create_tween().set_parallel(true)
		tween.tween_property(rowboat, "position", target, seconds)
		tween.tween_property(rowboat, "rotation", rowboat.rotation + turn, minf(0.4, seconds))
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
