class_name FishingStation
extends Area2D

signal item_caught(item_id: StringName)
signal attempt_cancelled

enum State { IDLE, HOLDING, READY_TO_RELEASE }

@export_range(1.5, 30.0, 0.1, "suffix:s") var minimum_hold_seconds: float = 1.5
@export_range(1.5, 30.0, 0.1, "suffix:s") var maximum_hold_seconds: float = 4.0
@export_range(0.5, 10.0, 0.1, "suffix:s") var result_feedback_seconds: float = 2.0
@export var loot_ids: Array[StringName] = [&"fish_cod", &"rope"]

@onready var hold_timer: Timer = $HoldTimer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel

var state: State = State.IDLE
var is_player_in_range: bool = false
var interacting_player: CharacterBody2D
var result_feedback_time_left: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hold_timer.timeout.connect(_on_hold_timer_timeout)
	reset_attempt()

func _process(delta: float) -> void:
	if state == State.HOLDING:
		progress_bar.value = hold_timer.wait_time - hold_timer.time_left
	if result_feedback_time_left > 0.0:
		result_feedback_time_left = maxf(0.0, result_feedback_time_left - delta)
		if is_zero_approx(result_feedback_time_left) and is_player_in_range:
			update_idle_prompt()
			status_label.show()

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
	if not interacting_player_has_fishing_rod():
		status_label.text = "Fishing rod required"
		status_label.show()
		return

	if loot_ids.is_empty():
		push_warning("Fishing station has no loot IDs configured.")
		show_result("Fishing is unavailable")
		return

	if interacting_player == null or not interacting_player.try_use_station(self):
		status_label.text = "Station in use"
		status_label.show()
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
	var item_database := get_node_or_null("/root/ItemDatabase")
	if item_database == null or not item_database.has_method("get_item"):
		push_warning("Fishing station could not find ItemDatabase.")
		finish_attempt("Fishing reward unavailable")
		return
	var item: ItemData = item_database.call(&"get_item", item_id) as ItemData

	if item == null:
		push_warning("Fishing item is missing from ItemDatabase: %s" % item_id)
		finish_attempt("Fishing reward unavailable")
		return

	var player_inventory := get_interacting_player_inventory()
	if player_inventory == null:
		push_warning("Fishing station could not find the interacting player's inventory.")
		finish_attempt("Fishing inventory unavailable")
		return

	if not player_inventory.add_item(item):
		finish_attempt("Inventory is full")
		return

	item_caught.emit(item_id)
	# Release the station lock before the legacy animation helper runs. The helper
	# owns its short visual-only lock and remains outside this station's scope.
	_release_player()
	if interacting_player != null and interacting_player.has_method("play_fishing_animation"):
		interacting_player.call(&"play_fishing_animation")
	finish_attempt("Caught: %s" % item.display_name)

func cancel_attempt() -> void:
	attempt_cancelled.emit()
	finish_attempt("Fishing cancelled")

func finish_attempt(message: String) -> void:
	reset_attempt()
	_release_player()
	show_result(message)

func _release_player() -> void:
	if interacting_player != null:
		interacting_player.leave_station(self)

func show_result(message: String) -> void:
	result_feedback_time_left = result_feedback_seconds
	status_label.text = message
	status_label.show()

func reset_attempt() -> void:
	state = State.IDLE
	hold_timer.stop()
	progress_bar.hide()
	if result_feedback_time_left <= 0.0:
		status_label.hide()

func interacting_player_has_fishing_rod() -> bool:
	var player_inventory := get_interacting_player_inventory()
	return player_inventory != null and player_inventory.get_quantity(&"fishing_rod") > 0

func get_interacting_player_inventory() -> PlayerInventory:
	if interacting_player == null:
		return null

	return interacting_player.get("player_inventory") as PlayerInventory

func update_idle_prompt() -> void:
	if interacting_player_has_fishing_rod():
		status_label.text = "Hold F to fish"
	else:
		status_label.text = "Fishing rod required"

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = true
		interacting_player = body
		if state == State.IDLE:
			update_idle_prompt()
			status_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = false
		if state != State.IDLE:
			cancel_attempt()
		else:
			status_label.hide()
		interacting_player = null

func _exit_tree() -> void:
	_release_player()
