extends CanvasLayer
signal pause_changed(is_paused: bool)
const PAUSE_ACTION: StringName = &"pause"
var _screen: Control
var _resume_button: Button
var _settings: SettingsPanel
var _confirm: ConfirmationDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = Control.new()
	_screen.name = "Screen"
	add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.07, 0.8)
	_screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.add_theme_stylebox_override("panel", HarborTheme.panel())
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	panel.add_child(rows)
	rows.add_child(HarborTheme.label("A MOMENT AT ANCHOR", 25))
	rows.add_child(HarborTheme.label("Solo pauses here. Online crews keep sailing.", 17, Color("aebdb7")))
	_resume_button = HarborTheme.button("Resume voyage", resume)
	_resume_button.name = "ResumeButton"
	rows.add_child(_resume_button)
	rows.add_child(HarborTheme.button("Settings", func() -> void: _settings.open()))
	rows.add_child(HarborTheme.button("Return to title", _ask_return))
	rows.add_child(HarborTheme.label("P / Esc  Resume", 14, Color("aebdb7")))
	_settings = SettingsPanel.new()
	_screen.add_child(_settings)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "End this voyage?"
	_confirm.dialog_text = "Returning to the title ends this voyage.\nYour inventory, chest and island progress are not saved."
	_confirm.ok_button_text = "End voyage"
	_confirm.confirmed.connect(return_to_title)
	add_child(_confirm)
	_screen.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _settings.visible or _confirm.visible:
		return
	if not event.is_action_pressed(PAUSE_ACTION) and not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene == null or scene.is_in_group("title_screen"):
		return
	get_viewport().set_input_as_handled()
	GameWindow.play_ui("back")
	if is_paused():
		resume()
	else:
		pause()

func _input(event: InputEvent) -> void:
	if _screen.visible and not _settings.visible and not _confirm.visible:
		HarborTheme.trap_focus(_screen, event)

func pause() -> void:
	var scene := get_tree().current_scene
	if is_paused() or scene == null or scene.is_in_group("title_screen"):
		return
	get_tree().paused = not NetworkSession.online
	GameWindow.start_menu_music()
	_screen.show()
	_resume_button.grab_focus()
	pause_changed.emit(true)

func resume() -> void:
	if not is_paused():
		return
	_settings.hide()
	_confirm.hide()
	get_tree().paused = false
	GameWindow.stop_menu_music()
	_screen.hide()
	pause_changed.emit(false)

func is_paused() -> bool:
	return _screen.visible

func _ask_return() -> void:
	if NetworkSession.online:
		_confirm.dialog_text = "Leave this crew? The host saves the voyage. If you are hosting, everyone disconnects."
	else:
		_confirm.dialog_text = "End the solo voyage? Solo progress is not saved."
	_confirm.popup_centered(Vector2i(500, 180))

func return_to_title() -> void:
	if NetworkSession.online:
		NetworkSession.leave()
		return
	resume()
	GameWindow.save_preferences()
	get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
