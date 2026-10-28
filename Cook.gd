extends Node2D
## Reusable station: owns participation, not player supplies or health.
signal cooking_started
signal meal_ready
signal meal_collected

enum State { IDLE, SELECTING, PREPARING, READY }
const COOKING_ACTIVITY: PackedScene = preload("res://scenes/galley_cooking.tscn")
var active_crew: Node2D
var prep_layer: CanvasLayer
var state: State = State.IDLE
var crew_nearby: Array[Node2D] = []
var selected_fish: int = 0
var selected_potato: int = 0
var reserved_recipe: Dictionary = {}
var selection_label: Label
var start_button: Button
@onready var prompt: Label = $Prompt
@onready var progress: ProgressBar = $Progress

func _ready() -> void:
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	VoyageSurvival.changed.connect(_update_display)
	VoyageSurvival.died.connect(cancel_for_death)
	_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not crew_nearby.is_empty():
		if state == State.IDLE or state == State.READY:
			interact()
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") and state == State.SELECTING:
		_cancel()
		get_viewport().set_input_as_handled()

func interact() -> void:
	if VoyageSurvival.dead or get_tree().paused or crew_nearby.is_empty() or crew_nearby[0].get("using_station"):
		return
	if not VoyageSurvival.ready_meal.is_empty():
		if VoyageSurvival.take_meal():
			meal_collected.emit()
		else:
			VoyageSurvival.notice.emit("Meal tray full — eat a meal first.")
		_update_display()
		return
	_start_selection()

func _start_selection() -> void:
	active_crew = crew_nearby[0]
	if not active_crew.try_use_station(self):
		active_crew = null
		return
	state = State.SELECTING
	selected_fish = 0
	selected_potato = 0
	prep_layer = CanvasLayer.new()
	prep_layer.layer = 20
	add_child(prep_layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prep_layer.add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -235
	panel.offset_right = 235
	panel.offset_top = -190
	panel.offset_bottom = 190
	screen.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "GALLEY • TRY A COMBINATION"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	selection_label = Label.new()
	column.add_child(selection_label)
	_add_button(column, "+ Fish", func() -> void: _select(true))
	_add_button(column, "+ Potato", func() -> void: _select(false))
	_add_button(column, "Clear ingredients", func() -> void:
		selected_fish = 0
		selected_potato = 0
		_update_selection())
	start_button = _add_button(column, "Prepare", _start_preparation)
	_add_button(column, "Leave / Escape", _cancel)
	_update_selection()
	_update_display()

func _add_button(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _select(fish: bool) -> void:
	if selected_fish + selected_potato >= 3:
		return
	var stock: PlayerInventory = VoyageSurvival.inventory
	if fish and selected_fish < stock.get_quantity(&"fish_cod"):
		selected_fish += 1
	elif not fish and selected_potato < stock.get_quantity(&"potato"):
		selected_potato += 1
	_update_selection()

func _update_selection() -> void:
	if not is_instance_valid(selection_label):
		return
	selection_label.text = "Owned: %d fish • %d potatoes
Selected: %d fish + %d potatoes (max 3)
No water needed. Stars measure technique, not safety." % [
		VoyageSurvival.inventory.get_quantity(&"fish_cod"), VoyageSurvival.inventory.get_quantity(&"potato"),
		selected_fish, selected_potato]
	start_button.disabled = selected_fish + selected_potato == 0

func _start_preparation() -> void:
	if state != State.SELECTING or VoyageSurvival.dead:
		return
	reserved_recipe = FoodRecipes.resolve(selected_fish, selected_potato)
	if reserved_recipe.is_empty():
		return
	if not _has_inputs():
		VoyageSurvival.notice.emit("Not enough ingredients.")
		return
	# Inputs remain owned but locked by station participation; nothing is lost on cancellation.
	prep_layer.queue_free()
	prep_layer = CanvasLayer.new()
	prep_layer.layer = 20
	add_child(prep_layer)
	var activity := COOKING_ACTIVITY.instantiate()
	activity.use_potato = selected_potato > 0
	activity.use_fish = selected_fish > 0
	activity.completed.connect(_on_preparation_completed)
	activity.cancelled.connect(_cancel)
	prep_layer.add_child(activity)
	state = State.PREPARING
	cooking_started.emit()
	_update_display()

func _has_inputs() -> bool:
	return VoyageSurvival.inventory.get_quantity(&"fish_cod") >= selected_fish and VoyageSurvival.inventory.get_quantity(&"potato") >= selected_potato

func _on_preparation_completed(stars: int) -> void:
	if state != State.PREPARING or VoyageSurvival.dead:
		return
	if not _has_inputs():
		VoyageSurvival.notice.emit("Ingredients changed — batch cancelled without spending supplies.")
		_cancel()
		return
	if selected_fish > 0:
		VoyageSurvival.inventory.remove_item(&"fish_cod", selected_fish)
	if selected_potato > 0:
		VoyageSurvival.inventory.remove_item(&"potato", selected_potato)
	VoyageSurvival.ready_meal = FoodRecipes.prepare(reserved_recipe, stars)
	VoyageSurvival.discovered_recipes[reserved_recipe.id] = reserved_recipe.name
	VoyageSurvival.notice.emit("Discovered: %s • %d stars%s" % [reserved_recipe.name, stars,
		" • POISONOUS" if float(VoyageSurvival.ready_meal.poison) > 0 else ""])
	_release_crew()
	state = State.READY
	meal_ready.emit()
	VoyageSurvival.changed.emit()
	_update_display()

func _release_crew() -> void:
	if is_instance_valid(active_crew):
		active_crew.leave_station(self)
	active_crew = null
	if is_instance_valid(prep_layer):
		prep_layer.queue_free()
	prep_layer = null
	reserved_recipe.clear()

func _cancel() -> void:
	_release_crew()
	state = State.IDLE
	_update_display()

func cancel_for_death() -> void:
	_cancel()

func _exit_tree() -> void:
	_release_crew()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("crew") and not crew_nearby.has(body):
		crew_nearby.append(body)
		_update_display()

func _on_body_exited(body: Node2D) -> void:
	crew_nearby.erase(body)
	_update_display()

func _update_display() -> void:
	if not is_node_ready():
		return
	progress.hide()
	prompt.visible = not crew_nearby.is_empty() and state != State.SELECTING and state != State.PREPARING and not VoyageSurvival.dead
	var ready: Dictionary = VoyageSurvival.ready_meal
	if not ready.is_empty():
		state = State.READY
		prompt.text = "E: Collect %s (%d/3 stars)" % [ready.name, ready.stars]
	else:
		if state == State.READY:
			state = State.IDLE
		prompt.text = "E: Cook with your ingredients
Fish: %d | Potatoes: %d" % [
			VoyageSurvival.inventory.get_quantity(&"fish_cod"), VoyageSurvival.inventory.get_quantity(&"potato")]
	$ReadyIndicator.visible = not ready.is_empty()
