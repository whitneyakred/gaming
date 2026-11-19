extends CanvasLayer
## Small survival readout alongside dev-testing's hotbar. PauseMenu owns pause UI.
const NeedIcons = preload("res://scripts/survival/need_icons.gd")
var health_icons: NeedIcons
var hunger_icons: NeedIcons
var warning: Label
var message: Label
var meals_frame: PanelContainer
var meals_panel: VBoxContainer
var food_button: Button
var effects: Control
var message_seconds: float = 0.0
var meals_signature: String = ""

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	var screen := Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects = Control.new()
	screen.add_child(effects)
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.draw.connect(_draw_effects)
	var needs := VBoxContainer.new()
	screen.add_child(needs)
	needs.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	needs.offset_left = -184
	needs.offset_right = -16
	needs.offset_top = 12
	health_icons = NeedIcons.new()
	needs.add_child(health_icons)
	hunger_icons = NeedIcons.new()
	hunger_icons.is_health = false
	needs.add_child(hunger_icons)
	food_button = _button("Meals [F]", _toggle_meals)
	needs.add_child(food_button)
	warning = _label("")
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.custom_minimum_size.x = 168
	needs.add_child(warning)
	message = _label("")
	message.position = Vector2(18, 120)
	screen.add_child(message)
	meals_frame = PanelContainer.new()
	meals_frame.position = Vector2(18, 160)
	screen.add_child(meals_frame)
	meals_panel = VBoxContainer.new()
	meals_frame.add_child(meals_panel)
	meals_frame.hide()
	VoyageSurvival.changed.connect(_refresh)
	VoyageSurvival.notice.connect(_notice)
	PauseMenu.pause_changed.connect(func(_paused: bool) -> void: _refresh())
	_refresh()

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 30
	button.pressed.connect(callback)
	return button

func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_F:
		_toggle_meals()
	else:
		return
	get_viewport().set_input_as_handled()

func _toggle_meals() -> void:
	if VoyageSurvival.dead or get_tree().paused:
		return
	var crew := get_tree().get_first_node_in_group("crew")
	if crew and crew.get("using_station"):
		_notice("Leave the station before eating.")
		return
	meals_frame.visible = not meals_frame.visible
	_rebuild_meals()

func _rebuild_meals() -> void:
	var signature := str(VoyageSurvival.meals) + str(VoyageSurvival.inventory.quantities)
	if signature == meals_signature and meals_panel.get_child_count() > 0:
		return
	meals_signature = signature
	for child in meals_panel.get_children():
		meals_panel.remove_child(child)
		child.queue_free()
	meals_panel.add_child(_label("MEALS"))
	for index in range(VoyageSurvival.meals.size()):
		var meal: Dictionary = VoyageSurvival.meals[index]
		var text := "%s (%d/3 stars)" % [meal.name, meal.stars]
		if float(meal.get("poison", 0)) > 0:
			text += " - HARMFUL"
		else:
			text += " +%d hunger / +%d health" % [meal.hunger, meal.healing]
		meals_panel.add_child(_button(text, func() -> void: VoyageSurvival.eat(index)))
	if VoyageSurvival.inventory.get_quantity(&"coconut") > 0:
		meals_panel.add_child(_button("Eat coconut (+16 hunger / +5 health)", func() -> void: VoyageSurvival.eat_coconut()))
	if VoyageSurvival.meals.is_empty():
		meals_panel.add_child(_label("Cook and collect a meal first."))

func _notice(text: String) -> void:
	message.text = text
	message_seconds = 4

func _refresh() -> void:
	health_icons.update_value(VoyageSurvival.health / VoyageSurvival.maximum_health,
		VoyageSurvival.health <= VoyageSurvival.maximum_health * VoyageSurvival.health_threshold)
	hunger_icons.update_value(VoyageSurvival.hunger / VoyageSurvival.maximum_hunger, VoyageSurvival.hunger_warning)
	var causes: Array[String] = []
	if VoyageSurvival.hunger_warning:
		causes.append("Hungry - eat soon.")
	if VoyageSurvival.health <= VoyageSurvival.maximum_health * VoyageSurvival.health_threshold:
		causes.append("Low health - eat to heal.")
	if VoyageSurvival.hunger <= 0:
		causes.append("Starving!")
	warning.text = "\n".join(causes) if not VoyageSurvival.dead else ""
	food_button.disabled = VoyageSurvival.dead
	food_button.text = "Meals %d [F]" % VoyageSurvival.meals.size()
	if get_tree().paused or VoyageSurvival.dead:
		meals_frame.hide()
	elif meals_frame.visible:
		_rebuild_meals()

func _process(delta: float) -> void:
	effects.queue_redraw()
	for activity in get_tree().get_nodes_in_group("cooking_activity"):
		activity.queue_redraw()
	if not get_tree().paused:
		message_seconds = maxf(0, message_seconds - delta)
		if message_seconds <= 0:
			message.text = ""

func _draw_effects() -> void:
	var severity: float = VoyageSurvival.fatigue
	if severity <= 0:
		return
	var area := get_viewport().get_visible_rect().size
	var tint := Color(0.15, 0.08, 0.12, severity * 0.25)
	effects.draw_rect(Rect2(0, 0, area.x, 24 + severity * 25), tint)
	effects.draw_rect(Rect2(0, area.y - 24 - severity * 25, area.x, 60), tint)
