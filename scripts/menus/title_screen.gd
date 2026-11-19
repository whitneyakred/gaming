extends Control
## Each generated sprite is independent; the screenshot is never rendered.
const DESIGN_SIZE := Vector2(956, 531)
const WRECK := preload("res://assets/menus/title_wreck_wood.png")
const PROPS := preload("res://assets/menus/title_props.png")


@onready var logo: TextureRect = $Composition/Wordmark
@onready var logo_ship: TextureRect = $Composition/LogoShip
@onready var play_button: Button = $Composition/PlayButton
var settings: SettingsPanel
var crew_menu: CrewMenu
var _ship_rest_y: float
var _time: float = 0.0
var _starting: bool = false
var _floaters: Array[Dictionary] = []

func _ready() -> void:
	theme = HarborTheme.menu_theme()
	$ProfileOverlay/ProfileCard/Rows/Portrait.texture = preload("res://assets/player/characters/viking/appearance.tres").portrait()
	_ship_rest_y = logo_ship.position.y
	logo.texture = HarborTheme.trimmed(logo.texture)
	var wood := AtlasTexture.new()
	wood.atlas = WRECK
	wood.region = Rect2(205, 35, 540, 1460)
	logo_ship.texture = wood
	logo_ship.position = Vector2(366, 18)
	logo_ship.size = Vector2(216, 476)
	_ship_rest_y = logo_ship.position.y
	var flooded := ShaderMaterial.new()
	flooded.shader = preload("res://shaders/wreck_waterline.gdshader")
	flooded.set_shader_parameter("ocean_texture", preload("res://assets/menus/title_ocean.png"))
	logo_ship.material = flooded
	play_button.action = func() -> void: crew_menu.open()
	$Composition/SettingsButton.action = func() -> void: settings.open()
	$Composition/CustomizeButton.action = open_customize
	$ProfileOverlay/ProfileCard/Rows/DoneButton.action = close_customize
	$ProfileOverlay/ProfileCard.add_theme_stylebox_override("panel", HarborTheme.panel())
	$ProfileOverlay/ProfileCard/Rows/PlayerName.text = NetworkSession.local_name
	$ProfileOverlay/ProfileCard/Rows/PlayerName.text_changed.connect(NetworkSession.save_player_name)
	settings = SettingsPanel.new()
	add_child(settings)
	crew_menu = CrewMenu.new()
	add_child(crew_menu)
	crew_menu.solo_requested.connect(start_voyage)
	_build_floaters()
	resized.connect(_layout)
	_layout()
	if not NetworkSession.status.is_empty(): crew_menu.open()
	else: play_button.grab_focus()
	GameWindow.start_menu_music()

func _layout() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	$Composition.scale = Vector2.ONE * factor
	$Composition.position = (size - DESIGN_SIZE * factor) * 0.5

func _floater(texture: Texture2D, at: Vector2, dimensions: Vector2, angle: float, index: int, swimming: bool = false) -> void:
	var node := TextureRect.new()
	node.texture = texture
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = at - dimensions * 0.5
	node.size = dimensions
	node.pivot_offset = dimensions * 0.5
	node.rotation = angle
	$Composition/Props.add_child(node)
	_floaters.append({"node": node, "rest": node.position, "angle": angle, "phase": float(index) * 1.71, "swimming": swimming})

func _build_floaters() -> void:
	for i in 5:
		var shark := Node2D.new()
		shark.set_script(preload("res://scripts/menus/title_shark.gd"))
		shark.index = i
		$Composition/Props.add_child(shark)
	var cells: Array[AtlasTexture] = []
	var half := Vector2(PROPS.get_size()) * 0.5
	for i in 4:
		var cell := AtlasTexture.new()
		cell.atlas = PROPS
		cell.region = Rect2(Vector2(i % 2, i / 2) * half, half)
		cells.append(cell)
	var props := [[0,352,74,43], [0,602,450,44], [1,901,78,44], [1,654,171,34], [1,923,309,34], [1,365,395,38], [1,381,505,32], [1,628,376,34], [2,343,211,34], [2,793,329,35], [3,617,212,48], [3,636,267,39], [3,612,308,36], [3,779,498,47], [3,352,450,38], [3,367,149,38]]
	for i in props.size():
		var p: Array = props[i]
		_floater(cells[p[0]], Vector2(p[1], p[2]), Vector2.ONE * float(p[3]) * 1.38, float(i % 3 - 1) * 0.2, i + 7)

func _process(delta: float) -> void:
	var reduced: bool = GameWindow.preferences.reduced_motion
	if not reduced: _time += delta
	logo_ship.position.y = _ship_rest_y
	logo_ship.material.set_shader_parameter("ocean_time", 0.0 if reduced else _time)
	for floater in _floaters:
		var node: TextureRect = floater.node
		var drift := Vector2.ZERO
		var turn := 0.0
		if not reduced:
			var t: float = _time * (0.23 if floater.swimming else 0.5) + floater.phase
			drift = Vector2(sin(t) * (14.0 if floater.swimming else 2.5), cos(t * 0.8) * (19.0 if floater.swimming else 2.0))
			turn = sin(t * 0.6) * (0.16 if floater.swimming else 0.06)
		node.position = floater.rest + drift
		node.rotation = floater.angle + turn

func start_voyage() -> void:
	if _starting: return
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
	curtain.color = Color(0.12, 0.13, 0.25, 0)
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
	HarborTheme.reveal($ProfileOverlay)
	$ProfileOverlay/ProfileCard/Rows/PlayerName.grab_focus()

func close_customize() -> void:
	$ProfileOverlay.hide()
	$Composition/CustomizeButton.grab_focus()

func _input(event: InputEvent) -> void:
	if $ProfileOverlay.visible: HarborTheme.trap_focus($ProfileOverlay, event)

func _unhandled_input(event: InputEvent) -> void:
	if $ProfileOverlay.visible and event.is_action_pressed("ui_cancel"):
		GameWindow.play_ui("back")
		close_customize()
		get_viewport().set_input_as_handled()
