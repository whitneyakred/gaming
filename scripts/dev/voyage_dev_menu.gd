extends CanvasLayer
## Optional local/host testing tools. The Ship Inspector switch gates UI and actions.
@onready var ship: Ship = get_parent()
var panel: VBoxContainer
var options: VBoxContainer
var status: Label
var buttons: Array[Button] = []
var speed_buttons: Dictionary = {}
var normal_speeds: Dictionary = {}
const SPEED_MULTIPLIER := 8.0

func _ready() -> void:
	layer = 12
	panel = VBoxContainer.new()
	panel.position = Vector2(12, 12)
	panel.add_theme_constant_override("separation", 3)
	add_child(panel)
	var toggle := Button.new()
	toggle.text = "Dev tools"
	toggle.custom_minimum_size = Vector2(180, 30)
	toggle.focus_mode = Control.FOCUS_NONE
	panel.add_child(toggle)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation", 3)
	panel.add_child(options)
	toggle.pressed.connect(func() -> void: options.visible = not options.visible)
	for entry in [["Nearest island", "nearest"], ["Paradise", "Paradise"], ["Bronze key", "Key_bronze"], ["Silver key", "Key_silver"], ["Gold key", "Key_gold"], ["Random island", "random"]]:
		var button := Button.new()
		button.text = "TP · " + str(entry[0])
		button.custom_minimum_size = Vector2(180, 28)
		button.add_theme_font_size_override("font_size", 14)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(teleport.bind(str(entry[1])))
		options.add_child(button)
		buttons.append(button)
	for property in ["walk_speed", "swim_speed"]:
		normal_speeds[property] = ship.player.get(property)
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(180, 28)
		button.add_theme_font_size_override("font_size", 14)
		speed_buttons[property] = button
		button.toggled.connect(set_speed_boost.bind(property))
		options.add_child(button)
		buttons.append(button)
		update_speed_label(property, false)
	status = Label.new()
	status.custom_minimum_size.x = 180
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	options.add_child(status)
	_process(0)

func available() -> bool:
	return ship.developer_tools_enabled and (not NetworkSession.online or multiplayer.is_server()) and ship._state != Ship.State.ROWING and not IslandChallenges.local_active() and ship.player.health > 0 and not PauseMenu.is_paused() and not MapState.map_open

func _process(_delta: float) -> void:
	if not ship.developer_tools_enabled:
		for property in speed_buttons:
			if speed_buttons[property].button_pressed: set_speed_boost(false, property)
	panel.visible = ship.developer_tools_enabled and not MapState.map_open and not IslandChallenges.local_active()
	for button in buttons: button.disabled = not available()

func set_speed_boost(enabled: bool, property: String) -> void:
	if not normal_speeds.has(property): return
	if enabled and not available():
		speed_buttons[property].set_pressed_no_signal(false)
		return
	ship.player.set(property, float(normal_speeds[property]) * (SPEED_MULTIPLIER if enabled else 1.0))
	speed_buttons[property].set_pressed_no_signal(enabled)
	update_speed_label(property, enabled)

func update_speed_label(property: String, enabled: bool) -> void:
	var title := "Super walk" if property == "walk_speed" else "Super swim"
	speed_buttons[property].text = title + (" · ON (8x)" if enabled else " · OFF")

func teleport(target: String) -> bool:
	if not available(): return false
	var islands := ship.get_islands()
	var island: WorldIsland
	if target == "random":
		island = islands.pick_random()
	elif target == "nearest":
		var distance := INF
		for candidate in islands:
			var gap := candidate.get_nearest_coast_point(ship.global_position).distance_to(ship.global_position)
			if gap < distance:
				distance = gap
				island = candidate
	else:
		island = ship.get_island(StringName(target))
	if island == null: return false
	var landing := safe_arrival(island)
	if not landing.is_finite():
		status.text = "No safe water beside this island."
		return false
	# Bring everyone aboard, including a sailor currently swimming or ashore.
	var crew := ship.survival.crew()
	for id in crew:
		if crew[id].island_challenge:
			status.text = "Leave island challenges first."
			return false
	for id in crew:
		ship.survival.stop_actions(id)
		var player: CharacterBody2D = crew[id]
		player.set_overboard(false)
		player.update_land(false)
		player.position = Vector2(0, 70)
		player.velocity = Vector2.ZERO
		player.swim_time = 0
		player.danger_time = 0
		player.respawn_serial += 1
	ship.global_position = landing
	ship.global_rotation = 0
	ship.speed = 0
	ship.turn_rate = 0
	ship.set_sail_level(0)
	ship.set_wheel_angle(0)
	ship._leaving_island = null
	ship._aground_island = null
	ship.aground = false
	ship._anchor_at(island)
	ship.anchor_deployed = true
	ship.stations_enabled = true
	ship.survival.ship_danger = 0
	if ship._view != null:
		ship._view.view_offset = Vector2.ZERO
		ship._view._focus_offset = Vector2.ZERO
		ship._view.camera.global_position = landing
		ship._view.camera.reset_smoothing()
	MapState.discover_island(str(island.name), island.display_name, island.global_position)
	MapState.update_player_position(landing)
	status.text = "Arrived: " + island.display_name
	if NetworkSession.online: NetworkSession.save_world()
	return true

func safe_arrival(island: WorldIsland) -> Vector2:
	# Start south of the coast; search around it if another island blocks the hull.
	# Full hull collision checks avoid teleporting into land, even on large islands.
	for margin in [230.0, 330.0, 430.0]:
		for step in 32:
			var direction := Vector2.DOWN.rotated(step * TAU / 32.0)
			var shore := island.get_nearest_coast_point(island.global_position + direction * 5000)
			var candidate: Vector2 = shore + direction * float(margin)
			if not WorldLayout.danger(candidate) and not ship._is_pose_blocked(candidate, 0): return candidate
	return Vector2.INF
