class_name Ship
extends Node2D

# The ship sails on its own. After a while an island drifts into view and
# the ship drops anchor beside it. Walk to the back (stern) of the ship and
# press E (the "interact" action) to climb into the rowboat and row over.
# When you come back from the island, the rowboat rows you home and the
# ship sets sail again, leaving the island behind.

# Set by island.gd right before it switches back to this scene, so we know
# to play the "row back to the ship" part instead of starting fresh.
static var returning_from_island: bool = false

# --- Tunable in the Inspector on the Ship node ---
@export var sail_speed: float = 110.0              # water scroll speed, px/s
@export var sail_time_before_island: float = 6.0   # seconds of open sea first
@export var island_start_distance: float = 750.0   # how far away it first appears
@export var slow_down_distance: float = 320.0      # starts easing to a stop here
@export var row_speed: float = 130.0               # rowboat speed, px/s
@export_file("*.tscn") var island_scene: String = "res://scenes/island.tscn"

enum State { SAILING, APPROACHING, ANCHORED, ROWING }

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
var _speed: float = 0.0
var _sail_timer: float = 0.0
var _island_anchor: Vector2
var _island_leaving: bool = false
var _player_at_stern: bool = false
var _rowboat_home: Vector2

func _ready() -> void:
	# Loaded directly with change_scene_to_file() (coming back from the
	# island) there's no Main camera above us, so bring our own.
	if get_tree().current_scene == self:
		add_child(Camera2D.new())

	_island_anchor = island.position
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
		_speed = sail_speed
		_set_status("Sailing the open sea...")

func _process(delta: float) -> void:
	match _state:
		State.SAILING:
			_speed = move_toward(_speed, sail_speed, sail_speed * 0.5 * delta)
			if _island_leaving:
				island.position.y += _speed * delta
				if island.position.y > _island_anchor.y + 900.0:
					island.visible = false
					_island_leaving = false
			_sail_timer += delta
			if _sail_timer >= sail_time_before_island and not _island_leaving:
				_start_approach()
		State.APPROACHING:
			var remaining := _island_anchor.y - island.position.y
			# Ease to a stop so the island ends up exactly beside the ship.
			var ease_speed := sqrt(2.0 * (sail_speed * sail_speed / (2.0 * slow_down_distance)) * remaining)
			_speed = clamp(ease_speed, 10.0, sail_speed)
			island.position.y += min(_speed * delta, remaining)
			if remaining <= 0.5:
				island.position = _island_anchor
				_speed = 0.0
				_state = State.ANCHORED
				_set_status("Anchor dropped! Head to the back of the ship.")
		State.ANCHORED:
			if _player_at_stern and Input.is_action_just_pressed("interact"):
				_row_to_island()
		State.ROWING:
			pass

	ocean.scroll_speed = _speed
	prompt_label.visible = _state == State.ANCHORED and _player_at_stern

func _start_approach() -> void:
	_state = State.APPROACHING
	island.visible = true
	island.position = _island_anchor - Vector2(0, island_start_distance)
	_set_status("Land ho! An island!")

func _row_to_island() -> void:
	_state = State.ROWING
	_set_status("Rowing to the island...")
	_board_rowboat()
	await _row_along(ROW_PATH)
	get_tree().change_scene_to_file(island_scene)

func _row_back_from_island() -> void:
	_state = State.ROWING
	_speed = 0.0
	island.visible = true
	island.position = _island_anchor
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
	player.set_physics_process(true)
	_island_leaving = true
	_sail_timer = 0.0
	_state = State.SAILING
	_set_status("Setting sail!")

func _board_rowboat() -> void:
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
