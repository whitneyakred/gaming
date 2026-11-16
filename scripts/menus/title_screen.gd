extends Control
## Decorative ship movement in design-canvas pixels. Lettering never moves.
@export_range(0.0, 12.0) var ship_bob_height: float = 4.0
@export_range(0.1, 3.0) var ship_bob_speed: float = 0.9
@onready var logo: TextureRect = $Wordmark
@onready var logo_ship: TextureRect = $LogoShip
@onready var play_button: Button = $PlayButton
var settings: SettingsPanel
var crew_menu: CrewMenu
var _ship_rest_y: float
var _time: float = 0.0
var _starting: bool = false

func _ready() -> void:
	_ship_rest_y = logo_ship.position.y
	play_button.action = func() -> void: crew_menu.open()
	play_button.custom_minimum_size = Vector2(280, 76)
	play_button.add_theme_font_size_override("font_size", 26)
	for button in [$CustomizeButton, $SettingsButton]:
		button.custom_minimum_size = Vector2(220, 56)
	$SettingsButton.action = func() -> void: settings.open()
	$CustomizeButton.action = open_customize
	$ProfileOverlay/ProfileCard/Rows/DoneButton.action = close_customize
	settings = SettingsPanel.new()
	$ProfileOverlay/ProfileCard.add_theme_stylebox_override("panel", HarborTheme.panel())
	$ProfileOverlay/ProfileCard/Rows/PlayerName.text = NetworkSession.local_name
	$ProfileOverlay/ProfileCard/Rows/PlayerName.text_changed.connect(NetworkSession.save_player_name)
	add_child(settings)
	crew_menu = CrewMenu.new()
	add_child(crew_menu)
	crew_menu.solo_requested.connect(start_voyage)
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
	GameWindow.start_voyage_music()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func quit_game() -> void:
	GameWindow.quit_game()

func open_customize() -> void:
	$ProfileOverlay.show()
	$ProfileOverlay/ProfileCard/Rows/PlayerName.grab_focus()

func close_customize() -> void:
	$ProfileOverlay.hide()
	$CustomizeButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if $ProfileOverlay.visible and event.is_action_pressed("ui_cancel"):
		close_customize()
		get_viewport().set_input_as_handled()
