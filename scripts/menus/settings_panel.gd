class_name SettingsPanel
extends Control
signal closed
var _tabs: TabContainer
var _back: Button
var _previous_focus: Control
var _toggles: Dictionary = {}
var _sizes: OptionButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.05, 0.88)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(760, 596)
	box.add_theme_stylebox_override("panel", HarborTheme.panel())
	center.add_child(box)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	box.add_child(rows)
	rows.add_child(HarborTheme.label("SHIP'S SETTINGS", 30))
	rows.add_child(HarborTheme.label("Make yourself at home. Changes are saved automatically.", 16, Color("aebdb7")))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 18)
	rows.add_child(_tabs)
	_build_tabs()
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	rows.add_child(actions)
	var defaults := HarborTheme.button("Restore defaults", _restore)
	defaults.custom_minimum_size.x = 280
	actions.add_child(defaults)
	_back = HarborTheme.button("Back", close)
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_back)
	hide()
	GameWindow.preferences_changed.connect(_sync_controls)

func _page(title: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = title
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	_tabs.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)
	return rows

func _build_tabs() -> void:
	_toggles.clear()
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	var display := _page("Display")
	_toggle(display, "Fullscreen", "fullscreen")
	var row := HBoxContainer.new()
	display.add_child(row)
	var caption := HarborTheme.label("Windowed size")
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var sizes := OptionButton.new()
	_sizes = sizes
	sizes.custom_minimum_size = Vector2(220, 40)
	for text in ["960 × 540", "1280 × 720", "1600 × 900"]:
		sizes.add_item(text)
	sizes.selected = GameWindow.preferences.window_size
	sizes.disabled = OS.has_feature("web")
	sizes.item_selected.connect(func(index: int) -> void: GameWindow.set_preference("window_size", index))
	row.add_child(sizes)
	if not OS.has_feature("web"):
		_toggle(display, "VSync", "vsync")
	else:
		display.add_child(HarborTheme.label("Display refresh is managed by your browser.", 16))
	display.add_child(HarborTheme.label("A consistent 16:9 view on every screen.\nBlack bars preserve the picture on wider or taller displays.\nF11 toggles fullscreen. Windowed size applies in windowed mode.", 15, Color("aebdb7")))
	var audio := _page("Audio")
	for key in ["master", "music", "effects"]:
		_volume(audio, key)
	_toggle(audio, "Mute while the game is unfocused", "mute_unfocused")
	var comfort := _page("Comfort")
	_toggle(comfort, "Reduced menu motion", "reduced_motion")
	_toggle(comfort, "Pause when switching to another app", "pause_unfocused")
	comfort.add_child(HarborTheme.label("Reduced motion removes button scaling and decorative menu motion.\nFocus pause leaves your voyage paused until you resume.\nThese preferences apply to this device.", 15, Color("aebdb7")))
	var controls := _page("Controls")
	for pair in [["WASD / Arrow keys", "Walk or swim"], ["E / Space", "Use chest / station"], ["Left mouse", "Rod: cast / hook / reel; Spyglass: hold to scout"], ["Sail / Helm", "W/S sail level; A/D trim or steer"], ["1–4 / Mouse wheel", "Select hotbar slot"], ["Drag / Shift-click", "Move or drop a stack / transfer to chest"], ["M", "Map (C clears destination while open)"], ["P", "Pause / resume"], ["Esc", "Close the current panel or pause"], ["F11", "Fullscreen / windowed"]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 24)
		controls.add_child(line)
		var key := HarborTheme.label(pair[0], 16, Color("dfbc78"))
		key.custom_minimum_size.x = 215
		line.add_child(key)
		line.add_child(HarborTheme.label(pair[1], 16))

func _toggle(parent: Control, text: String, key: String) -> void:
	var button := CheckButton.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 18)
	button.button_pressed = GameWindow.preferences[key]
	_toggles[key] = button
	button.toggled.connect(func(value: bool) -> void:
		GameWindow.play_ui()
		GameWindow.set_preference(key, value))
	parent.add_child(button)

func _sync_controls() -> void:
	for key: String in _toggles:
		_toggles[key].set_pressed_no_signal(GameWindow.preferences[key])
	_sizes.select(GameWindow.preferences.window_size)

func _volume(parent: Control, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var caption := HarborTheme.label(key.capitalize(), 18)
	caption.custom_minimum_size.x = 95
	row.add_child(caption)
	var slider := HSlider.new()
	slider.name = key.capitalize() + "Volume"
	slider.custom_minimum_size = Vector2(320, 40)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundf(GameWindow.preferences[key] * 100)
	row.add_child(slider)
	var amount := HarborTheme.label("%d%%" % slider.value)
	amount.custom_minimum_size.x = 55
	row.add_child(amount)
	slider.value_changed.connect(func(value: float) -> void:
		amount.text = "%d%%" % value
		GameWindow.set_preference(key, value / 100.0))
	slider.drag_ended.connect(func(_changed: bool) -> void: GameWindow.play_ui())

func open(tab: int = 0) -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	_build_tabs()
	_tabs.current_tab = tab
	show()
	_back.grab_focus()

func close() -> void:
	GameWindow.save_preferences()
	hide()
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	closed.emit()

func _restore() -> void:
	GameWindow.reset_preferences()
	_build_tabs()
	_back.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and HarborTheme.trap_focus(self, event):
		return
	if visible and event.is_action_pressed("ui_cancel"):
		GameWindow.play_ui("back")
		close()
		get_viewport().set_input_as_handled()
