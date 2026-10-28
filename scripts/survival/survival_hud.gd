extends CanvasLayer
## Read-only presentation plus explicit consume/pause/restart commands.
const NeedIcons = preload("res://scripts/survival/need_icons.gd")
var health_icons: NeedIcons
var hunger_icons: NeedIcons
var motion_button: Button
var warning: Label
var message: Label
var meals_panel: VBoxContainer
var meals_frame: PanelContainer
var pause_panel: VBoxContainer
var pause_title: Label
var resume_button: Button
var effects: Control
var message_seconds: float = 0.0
var food_button: Button
var meals_signature: String = ""

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	effects = Control.new()
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.draw.connect(_draw_effects)
	root.add_child(effects)
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 18
	panel.offset_right = -18
	panel.offset_top = 12
	panel.offset_bottom = 60
	_style_panel(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	health_icons = NeedIcons.new()
	row.add_child(health_icons)
	hunger_icons = NeedIcons.new()
	hunger_icons.is_health = false
	row.add_child(hunger_icons)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(space)
	food_button = _button("Meals [F]", _toggle_meals)
	row.add_child(food_button)
	var pause_button := _button("II", _toggle_pause)
	pause_button.custom_minimum_size.x = 42
	pause_button.tooltip_text = "Pause [P]"
	row.add_child(pause_button)
	warning = _label("", 15)
	warning.position = Vector2(18, 68)
	warning.custom_minimum_size.x = 245
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(warning)
	meals_frame = PanelContainer.new()
	meals_frame.position = Vector2(18, 112)
	_style_panel(meals_frame)
	root.add_child(meals_frame)
	meals_panel = VBoxContainer.new()
	meals_panel.add_theme_constant_override("separation", 6)
	meals_frame.add_child(meals_panel)
	meals_frame.hide()
	message = _label("", 18)
	message.position = Vector2(18, 115)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message)
	var shade := PanelContainer.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shade.offset_left = -180
	shade.offset_right = 180
	shade.offset_top = -100
	shade.offset_bottom = 100
	shade.custom_minimum_size = Vector2(360, 200)
	_style_panel(shade)
	root.add_child(shade)
	pause_panel = VBoxContainer.new()
	shade.add_child(pause_panel)
	pause_title = _label("Paused", 28)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_panel.add_child(pause_title)
	resume_button = _button("Resume", _toggle_pause)
	pause_panel.add_child(resume_button)
	motion_button = _button("Motion: Full [M]", _toggle_motion)
	pause_panel.add_child(motion_button)
	pause_panel.add_child(_button("Start new voyage", func() -> void: VoyageSurvival.restart()))
	shade.hide()
	VoyageSurvival.changed.connect(_refresh)
	VoyageSurvival.notice.connect(_notice)
	get_tree().scene_changed.connect(_layout_scene)
	_refresh()

func _layout_scene() -> void:
	# Keep the existing navigation text below the slim HUD, without changing sailing.
	var scene := get_tree().current_scene
	if scene == null:
		return
	var status := scene.get_node_or_null("Ship/HUD/StatusLabel") as Label
	if status == null:
		status = scene.get_node_or_null("HUD/StatusLabel") as Label
	if status:
		status.offset_top = 72
		status.offset_bottom = 108

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#292923")
	style.border_color = Color("#997c51")
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 3
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#efdfbc"))
	label.add_theme_color_override("font_shadow_color", Color("#181a18"))
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.add_theme_color_override("font_color", Color("#efdfbc"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#38392e")
	normal.border_color = Color("#766746")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#4a4938")
	hover.border_color = Color("#c5a26b")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#24271f")
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(callback)
	return button

func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_P:
			_toggle_pause()
		KEY_F:
			_toggle_meals()
		KEY_M:
			_toggle_motion()
		_:
			return
	get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if VoyageSurvival.dead:
		return
	get_tree().paused = not get_tree().paused
	_refresh()

func _toggle_motion() -> void:
	VoyageSurvival.reduced_motion = not VoyageSurvival.reduced_motion
	motion_button.text = "Motion: Reduced [M]" if VoyageSurvival.reduced_motion else "Motion: Full [M]"

func _toggle_meals() -> void:
	if VoyageSurvival.dead or get_tree().paused:
		return
	# Eating cannot interrupt an active station and duplicate its recipe inputs.
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
	meals_panel.add_child(_label("FOOD & SUPPLIES", 18))
	meals_panel.add_child(_label("Fish: %d | Potatoes: %d | Coconuts: %d | Rope: %d" % [
		VoyageSurvival.inventory.get_quantity(&"fish_cod"), VoyageSurvival.inventory.get_quantity(&"potato"),
		VoyageSurvival.inventory.get_quantity(&"coconut"), VoyageSurvival.inventory.get_quantity(&"rope")], 16))
	if VoyageSurvival.inventory.get_quantity(&"rope") > 0:
		meals_panel.add_child(_button("Discard one rope", func() -> void: VoyageSurvival.discard_rope()))
	for index in range(VoyageSurvival.meals.size()):
		var meal: Dictionary = VoyageSurvival.meals[index]
		var text := "%s (%d★)" % [meal.name, meal.stars]
		if float(meal.get("poison", 0)) > 0:
			text += " — HARMFUL"
		else:
			text += "  +%d hunger / +%d health" % [meal.hunger, meal.healing]
		meals_panel.add_child(_button(text, func() -> void: VoyageSurvival.eat(index)))
	if VoyageSurvival.inventory.get_quantity(&"coconut") > 0:
		meals_panel.add_child(_button("Eat coconut (+16 hunger / +5 health)", func() -> void: VoyageSurvival.eat_coconut()))
	if VoyageSurvival.meals.is_empty():
		meals_panel.add_child(_label("Cook and collect a meal first.", 16))

func _notice(text: String) -> void:
	message.text = text
	message_seconds = 4.0

func _refresh() -> void:
	health_icons.update_value(VoyageSurvival.health / VoyageSurvival.maximum_health,
		VoyageSurvival.health <= VoyageSurvival.maximum_health * VoyageSurvival.health_threshold)
	hunger_icons.update_value(VoyageSurvival.hunger / VoyageSurvival.maximum_hunger, VoyageSurvival.hunger_warning)
	var causes: Array[String] = []
	if VoyageSurvival.hunger_warning:
		causes.append("Hungry — cook or eat soon.")
	if VoyageSurvival.health <= VoyageSurvival.maximum_health * VoyageSurvival.health_threshold:
		causes.append("Low health — eat a healing meal.")
	if VoyageSurvival.hunger <= 0:
		causes.append("STARVING — losing health!")
	warning.text = "\n".join(causes) if not causes.is_empty() else ""
	if VoyageSurvival.dead:
		warning.text = "This voyage has ended."
	warning.visible = not warning.text.is_empty()
	food_button.disabled = VoyageSurvival.dead
	food_button.text = "Meals %d [F]" % VoyageSurvival.meals.size()
	pause_panel.get_parent().visible = get_tree().paused or VoyageSurvival.dead
	pause_title.text = "Game over — you died" if VoyageSurvival.dead else "Paused"
	resume_button.visible = not VoyageSurvival.dead
	if VoyageSurvival.dead or get_tree().paused:
		meals_frame.hide()
	elif meals_frame.visible:
		_rebuild_meals()

func _process(delta: float) -> void:
	effects.queue_redraw()
	# Cooking draw transforms animate during pause, but its simulation/input does not.
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
	var size := get_viewport().get_visible_rect().size
	var pulse := 0.9 + 0.1 * sin(VoyageSurvival.visual_time * 2.0)
	var tint := Color(0.15, 0.08, 0.12, severity * 0.3 * pulse)
	effects.draw_rect(Rect2(0, 0, size.x, 32 + severity * 34), tint)
	effects.draw_rect(Rect2(0, size.y - 32 - severity * 34, size.x, 70), tint)
	effects.draw_rect(Rect2(0, 0, 18 + severity * 25, size.y), tint)
	effects.draw_rect(Rect2(size.x - 18 - severity * 25, 0, 50, size.y), tint)
