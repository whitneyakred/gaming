extends Control
var settings: SettingsPanel
var logo: TextureRect
var play_button: Button
var _time: float = 0.0
var _starting: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ocean := Control.new()
	ocean.set_script(preload("res://scripts/menus/menu_ocean.gd"))
	add_child(ocean)
	ocean.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo = TextureRect.new()
	logo.texture = preload("res://assets/menus/holy_ship_logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(70, 82)
	logo.size = Vector2(580, 500)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	var tagline := HarborTheme.label("Sail. Scavenge. Stay afloat.", 23)
	tagline.position = Vector2(125, 600)
	tagline.size.x = 470
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(tagline)
	var card := PanelContainer.new()
	card.position = Vector2(780, 165)
	card.size = Vector2(360, 390)
	card.add_theme_stylebox_override("panel", HarborTheme.panel())
	add_child(card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	card.add_child(rows)
	rows.add_child(HarborTheme.label("THE SEA IS CALLING", 23, Color("e5c687")))
	rows.add_child(HarborTheme.label("A small ship. An open ocean.", 16, Color("aebdb7")))
	play_button = HarborTheme.button("Play  •  New voyage", start_voyage)
	play_button.name = "PlayButton"
	rows.add_child(play_button)
	rows.add_child(HarborTheme.button("Settings", func() -> void: settings.open()))
	rows.add_child(HarborTheme.button("How to play", func() -> void: settings.open(3)))
	if not OS.has_feature("web"):
		rows.add_child(HarborTheme.button("Quit", quit_game))
	var footer := HarborTheme.label("SINGLE PLAYER  /  EARLY VOYAGE", 13, Color("8ca8ac"))
	footer.position = Vector2(48, 674)
	add_child(footer)
	var hint := HarborTheme.label("F11  Fullscreen    •    Headphones welcome", 14, Color("8ca8ac"))
	hint.position = Vector2(850, 674)
	add_child(hint)
	settings = SettingsPanel.new()
	add_child(settings)
	play_button.grab_focus()
	GameWindow.start_menu_music()

func _process(delta: float) -> void:
	if GameWindow.preferences.reduced_motion:
		logo.position.y = 82
		return
	_time += delta
	logo.position.y = 82 + sin(_time * 0.9) * 4

func start_voyage() -> void:
	if _starting:
		return
	_starting = true
	play_button.disabled = true
	if OS.has_feature("web") and GameWindow.preferences.fullscreen:
		get_window().mode = Window.MODE_FULLSCREEN
	VoyageState.reset()
	MapState.reset()
	Ship.returning_from_island = false
	Ship.last_visit_won = true
	Ship.visited_island_name = &""
	Ship.completed_islands.clear()
	Ship.anchored_position = Vector2.ZERO
	Ship.anchored_rotation = 0.0
	SwimAccess.returning_by_swimming = false
	SwimAccess.shore_return = Vector2.ZERO
	var curtain := ColorRect.new()
	curtain.color = Color(0.02, 0.05, 0.08, 0)
	add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 1.0, 0.05 if GameWindow.preferences.reduced_motion else 0.3)
	await tween.finished
	GameWindow.stop_menu_music()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func quit_game() -> void:
	GameWindow.quit_game()
