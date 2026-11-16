extends Control
## Decorative ship movement in design-canvas pixels. Lettering never moves.
@export_range(0.0, 12.0) var ship_bob_height: float = 4.0
@export_range(0.1, 3.0) var ship_bob_speed: float = 0.9
@onready var logo: TextureRect = $Wordmark
@onready var logo_ship: TextureRect = $LogoShip
@onready var play_button: Button = $MenuCard/Rows/PlayButton
var settings: SettingsPanel
var crew_menu: CrewMenu
var _ship_rest_y: float
var _time: float = 0.0
var _starting: bool = false

func _ready() -> void:
	_ship_rest_y = logo_ship.position.y
	$MenuCard.add_theme_stylebox_override("panel", HarborTheme.panel())
	play_button.action = start_voyage
	$MenuCard/Rows/SettingsButton.action = func() -> void: settings.open()
	$MenuCard/Rows/HelpButton.action = func() -> void: settings.open(3)
	$MenuCard/Rows/QuitButton.action = quit_game
	$MenuCard/Rows/QuitButton.visible = not OS.has_feature("web")
	settings = SettingsPanel.new()
	$ProfileCard.add_theme_stylebox_override("panel", HarborTheme.panel())
	$ProfileCard/Rows/PlayerName.text = NetworkSession.local_name
	$ProfileCard/Rows/PlayerName.text_changed.connect(NetworkSession.save_player_name)
	add_child(settings)
	crew_menu = CrewMenu.new()
	add_child(crew_menu)
	var crew_button := HarborTheme.button("Sail with a crew", func() -> void: crew_menu.open())
	$MenuCard/Rows.add_child(crew_button)
	$MenuCard/Rows.move_child(crew_button, 2)
	$MenuCard.position.y = 125
	$MenuCard.size.y = 460
	if not NetworkSession.status.is_empty():
		crew_menu.open()
	play_button.grab_focus()
	GameWindow.start_menu_music()

func _process(delta: float) -> void:
	if GameWindow.preferences.reduced_motion:
		logo_ship.position.y = _ship_rest_y
		return
	_time += delta
	logo_ship.position.y = _ship_rest_y + sin(_time * ship_bob_speed) * ship_bob_height

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
