extends Node2D
## Shared station stock for the first cooking prototype.
signal cooking_started
signal meal_ready
signal meal_collected

enum State { IDLE, PREPARING, COOKING, READY }
const COOKING_ACTIVITY: PackedScene = preload("res://scenes/galley_cooking.tscn")
var active_crew: Node2D
var prep_layer: CanvasLayer
@export_range(0.5, 30.0, 0.5) var cook_seconds: float = 4.0
@export_range(0, 99, 1) var raw_fish: int = 3
var state: State = State.IDLE
var cooked_fish: int = 0
var last_meal_stars: int = 0
var crew_nearby: Array[Node2D] = []
@onready var timer: Timer = $CookTimer
@onready var prompt: Label = $Prompt
@onready var progress: ProgressBar = $Progress

func _ready() -> void:
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	timer.timeout.connect(_finish_cooking)
	_update_display()

func _process(_delta: float) -> void:
	if state == State.COOKING:
		progress.value = 100.0 * (1.0 - timer.time_left / timer.wait_time)

func _unhandled_input(event: InputEvent) -> void:
	if not crew_nearby.is_empty() and event.is_action_pressed("interact") and not event.is_echo():
		interact()
		get_viewport().set_input_as_handled()

func interact() -> void:
	if crew_nearby.is_empty() or crew_nearby[0].get("using_station") == true:
		return
	match state:
		State.IDLE:
			if raw_fish <= 0 or crew_nearby.is_empty():
				return
			_start_preparation()
		State.READY:
			cooked_fish += 1
			state = State.IDLE
			meal_collected.emit()
	_update_display()

func _start_preparation() -> void:
	active_crew = crew_nearby[0]
	if not active_crew.try_use_station(self):
		active_crew = null
		return
	state = State.PREPARING
	prep_layer = CanvasLayer.new()
	prep_layer.layer = 20
	add_child(prep_layer)
	var activity := COOKING_ACTIVITY.instantiate()
	activity.completed.connect(_on_preparation_completed)
	activity.cancelled.connect(_on_preparation_cancelled)
	prep_layer.add_child(activity)

func _release_crew() -> void:
	if is_instance_valid(active_crew):
		active_crew.leave_station(self)
	active_crew = null
	if is_instance_valid(prep_layer):
		prep_layer.queue_free()

func _on_preparation_completed(stars: int) -> void:
	last_meal_stars = stars
	_release_crew()
	raw_fish -= 1
	cooking_started.emit()
	_finish_cooking()

func _on_preparation_cancelled() -> void:
	_release_crew()
	state = State.IDLE
	_update_display()

func _exit_tree() -> void:
	if is_instance_valid(active_crew):
		active_crew.leave_station(self)

func _finish_cooking() -> void:
	state = State.READY
	meal_ready.emit()
	_update_display()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("crew") and not crew_nearby.has(body):
		crew_nearby.append(body)
		_update_display()

func _on_body_exited(body: Node2D) -> void:
	crew_nearby.erase(body)
	_update_display()

func _update_display() -> void:
	progress.visible = state == State.COOKING
	prompt.visible = not crew_nearby.is_empty()
	var stock := "Raw: %d | Collected: %d" % [raw_fish, cooked_fish]
	match state:
		State.IDLE:
			prompt.text = ("E: Make potato + fish stew" if raw_fish > 0 else "No raw fish left") + "\n" + stock
		State.PREPARING:
			prompt.text = "Making stew..."
		State.COOKING:
			prompt.text = "Cooking...\n" + stock
		State.READY:
			prompt.text = "E: Collect stew (%d/3 stars)\n" % last_meal_stars + stock
	$ReadyIndicator.visible = state == State.READY
