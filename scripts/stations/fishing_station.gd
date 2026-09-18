class_name FishingStation
extends Area2D

signal item_caught(item_id: StringName)
signal attempt_cancelled

enum State { IDLE, HOLDING, READY_TO_RELEASE }

@export_range(1.5, 30.0, 0.1, "suffix:s") var minimum_hold_seconds: float = 1.5
@export_range(1.5, 30.0, 0.1, "suffix:s") var maximum_hold_seconds: float = 4.0
@export var loot_ids: Array[StringName] = [&"fish_cod", &"rope"]

@onready var hold_timer: Timer = $HoldTimer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel

var state: State = State.IDLE
var is_player_in_range: bool = false
var interacting_player: CharacterBody2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hold_timer.timeout.connect(_on_hold_timer_timeout)
	reset_attempt()

func _process(_delta: float) -> void:
	if state == State.HOLDING:
		progress_bar.value = hold_timer.wait_time - hold_timer.time_left

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_in_range:
		return

	if event.is_action_pressed("fish") and state == State.IDLE:
		start_attempt()
	elif event.is_action_released("fish"):
		if state == State.HOLDING:
			cancel_attempt()
		elif state == State.READY_TO_RELEASE:
			complete_attempt()

func start_attempt() -> void:
	if loot_ids.is_empty():
		push_warning("Fishing station has no loot IDs configured.")
		return

	var hold_duration := randf_range(minimum_hold_seconds, maximum_hold_seconds)
	hold_timer.start(hold_duration)
	progress_bar.max_value = hold_duration
	progress_bar.value = 0.0
	progress_bar.show()
	status_label.text = "Hold E..."
	status_label.show()
	state = State.HOLDING

func _on_hold_timer_timeout() -> void:
	state = State.READY_TO_RELEASE
	progress_bar.hide()
	status_label.text = "Release!"

func complete_attempt() -> void:
	var item_id: StringName = loot_ids.pick_random()
	var item: ItemData = ItemDatabase.get_item(item_id)

	if item == null:
		push_warning("Fishing item is missing from ItemDatabase: %s" % item_id)
		reset_attempt()
		return

	print("Caught: %s" % item.display_name)
	item_caught.emit(item_id)
	if interacting_player != null and interacting_player.has_method("play_fishing_animation"):
		interacting_player.call(&"play_fishing_animation")
	reset_attempt()

func cancel_attempt() -> void:
	attempt_cancelled.emit()
	reset_attempt()

func reset_attempt() -> void:
	state = State.IDLE
	hold_timer.stop()
	progress_bar.hide()
	status_label.hide()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = true
		interacting_player = body
		if state == State.IDLE:
			status_label.text = "Hold E to fish"
			status_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = false
		interacting_player = null
		if state != State.IDLE:
			cancel_attempt()
		else:
			status_label.hide()
