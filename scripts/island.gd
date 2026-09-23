extends Node2D

# --- Tunable in the Inspector on the Island node ---
@export var time_limit_seconds: float = 30.0

@onready var coconut_label: Label = $CanvasLayer/CoconutLabel
@onready var time_label: Label = $CanvasLayer/TimeLabel
@onready var pirate_ship_icon: Polygon2D = $CanvasLayer/PirateTrack/PirateShipIcon
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var player: CharacterBody2D = $World/Player

# How far the pirate ship icon travels across the track, in pixels.
# PirateTrack is 280px wide (island.tscn); the icon's tip sits 8px ahead
# of its own position, so 272 puts the tip exactly on the right edge
# when time runs out.
const TRACK_DISTANCE: float = 272.0

var _collected_count: int = 0
var _total_count: int = 0
var _time_remaining: float = 0.0
var _run_ended: bool = false

func _ready() -> void:
	# Every Coconut instance in this scene is placed in the "coconuts" group
	# (see island.tscn), so this works no matter how many are scattered here.
	var coconuts := get_tree().get_nodes_in_group("coconuts")
	_total_count = coconuts.size()
	for coconut in coconuts:
		coconut.collected.connect(_on_coconut_collected)

	_time_remaining = time_limit_seconds
	message_label.visible = false
	_update_coconut_label()
	_update_time_label()

func _process(delta: float) -> void:
	if _run_ended:
		return

	_time_remaining = max(_time_remaining - delta, 0.0)
	_update_time_label()
	_update_pirate_ship_position()

	if _time_remaining <= 0.0:
		_lose("The pirate ship reached the island!")

func _on_coconut_collected() -> void:
	_collected_count += 1
	_update_coconut_label()

func _update_coconut_label() -> void:
	coconut_label.text = "Coconuts: %d / %d" % [_collected_count, _total_count]

func _update_time_label() -> void:
	time_label.text = "Time left: %ds" % int(ceil(_time_remaining))

func _update_pirate_ship_position() -> void:
	var progress: float = 1.0 - (_time_remaining / time_limit_seconds)
	pirate_ship_icon.position.x = lerp(0.0, TRACK_DISTANCE, progress)

# Called by scripts/rowboat.gd when the player steps into the rowboat.
func try_escape() -> void:
	if _run_ended:
		return

	if _collected_count < _total_count:
		message_label.visible = true
		message_label.text = "Grab all the coconuts first!"
		await get_tree().create_timer(1.5).timeout
		if not _run_ended:
			message_label.visible = false
		return

	_win()

func _win() -> void:
	_run_ended = true
	message_label.visible = true
	message_label.text = "You made it back with all the coconuts!"
	if player:
		player.set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	# Tell the ship scene to play the "row back to the ship" sequence.
	Ship.returning_from_island = true
	get_tree().change_scene_to_file("res://scenes/ship.tscn")

func _lose(reason: String) -> void:
	_run_ended = true
	message_label.visible = true
	message_label.text = reason + " Game Over!"
	if player:
		player.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
