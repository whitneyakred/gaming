class_name Ship
extends ShipMotion

# Sail and steer toward an island, then dock beside it. Walk to the stern and
# press E (the "interact" action) to climb into the rowboat and row over.
# When you come back from the island, the rowboat rows you home. Then
# use the sailing stations again to leave the island behind.

# Set by island.gd right before it switches back to this scene, so we know
# to play the "row back to the ship" part instead of starting fresh.
static var returning_from_island: bool = false

# --- Tunable in the Inspector on the Ship node ---
@export var travel_before_island: float = 660.0    # distance sailed before land appears
@export var island_start_distance: float = 750.0   # how far away it first appears
@export var docking_distance: float = 90.0         # distance from the docking point
@export var row_speed: float = 130.0               # rowboat speed, px/s
@export_file("*.tscn") var island_scene: String = "res://scenes/island.tscn"

enum State { SAILING, APPROACHING, DOCKING, ANCHORED, ROWING }

# Route the rowboat takes from the stern to the island's dock (ship-local
# coordinates). The last point is just below the island's dock.
const ROW_PATH: Array[Vector2] = [
	Vector2(70, 300), Vector2(230, 305), Vector2(345, 262), Vector2(400, 188),
]

@onready var ocean: Ocean = $Ocean
@onready var island: Node2D = $Island
@onready var player: CharacterBody2D = $Player
@onready var rowboat: Node2D = $Rowboat
@onready var rider: Sprite2D = $Rowboat/Rider
@onready var stern_zone: Area2D = $SternZone
@onready var status_label: Label = $HUD/StatusLabel
@onready var prompt_label: Label = $HUD/PromptLabel

var _state: State = State.SAILING
var _travel_distance: float = 0.0
var _island_anchor: Vector2
var _island_leaving: bool = false
var _player_at_stern: bool = false
var _rowboat_home: Vector2
var _dock_position: Vector2
var _dock_rotation: float = 0.0

func _ready() -> void:
	super._ready()
	_island_anchor = island.position
	# Land stays in world space while the deck, stations, and player move together.
	island.set_as_top_level(true)
	island.global_position = to_global(_island_anchor)
	ocean.set_as_top_level(true)
	ocean.global_rotation = 0.0
	_rowboat_home = rowboat.position
	stern_zone.body_entered.connect(_on_stern_entered)
	stern_zone.body_exited.connect(_on_stern_exited)
	prompt_label.visible = false
	rider.visible = false

	if returning_from_island:
		returning_from_island = false
		_row_back_from_island()
	else:
		island.visible = false
		_set_status("Raise the sail and take the helm to find an island.")

func _physics_process(delta: float) -> void:
	var previous_position := global_position
	if _state == State.SAILING or _state == State.APPROACHING:
		super._physics_process(delta)
	var distance_sailed := global_position.distance_to(previous_position)
	match _state:
		State.SAILING:
			if _island_leaving:
				if global_position.distance_to(_dock_position) > 900.0:
					island.visible = false
					_island_leaving = false
					_travel_distance = 0.0
			else:
				_travel_distance += distance_sailed
			if _travel_distance >= travel_before_island and not _island_leaving:
				_start_approach()
		State.APPROACHING:
			var remaining := global_position.distance_to(_dock_position)
			_set_status("Land ho! Sail to the docking marker (%d px)." % roundi(remaining))
			if remaining <= docking_distance:
				_dock()
	ocean.global_position = global_position
	prompt_label.visible = _state == State.ANCHORED and _player_at_stern and not player.using_station
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _state == State.ANCHORED and _player_at_stern and not player.using_station:
		if event.is_action_pressed("interact") and not event.is_echo():
			get_viewport().set_input_as_handled()
			_row_to_island()

func _start_approach() -> void:
	_state = State.APPROACHING
	island.visible = true
	_dock_rotation = global_rotation
	_dock_position = to_global(Vector2(0, -island_start_distance))
	island.global_position = _dock_position + _island_anchor.rotated(_dock_rotation)
	island.global_rotation = _dock_rotation
	_set_status("Land ho! An island!")

func _draw() -> void:
	if _state == State.APPROACHING:
		draw_arc(to_local(_dock_position), docking_distance, 0, TAU, 48, Color(1, 0.9, 0.45), 3.0)

func _stop_sailing() -> void:
	stations_enabled = false
	$Helm.release_control()
	$Sail.release_control()
	speed = 0.0
	turn_rate = 0.0
	set_sail_level(0)
	set_wheel_angle(0.0)

func _dock() -> void:
	_state = State.DOCKING
	_stop_sailing()
	_set_status("Docking...")
	var tween := create_tween().set_parallel(true)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", _dock_position, 0.8)
	tween.tween_property(self, "global_rotation", global_rotation + wrapf(_dock_rotation - global_rotation, -PI, PI), 0.8)
	await tween.finished
	_state = State.ANCHORED
	_set_status("Anchor dropped! Head to the back of the ship.")

func _row_to_island() -> void:
	_state = State.ROWING
	_set_status("Rowing to the island...")
	_board_rowboat()
	await _row_along(ROW_PATH)
	get_tree().change_scene_to_file(island_scene)

func _row_back_from_island() -> void:
	_state = State.ROWING
	_stop_sailing()
	island.visible = true
	island.global_position = to_global(_island_anchor)
	_dock_position = global_position
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
	_island_leaving = true
	_travel_distance = 0.0
	_state = State.SAILING
	stations_enabled = true
	_set_status("Back aboard! Raise the sail to leave the island.")

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
