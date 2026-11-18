extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	var ship := get_tree().current_scene as Ship
	ship.set_physics_process(false)
	var helm := ship.get_node("Helm") as HelmStation
	var view := ship.get_node("SailingDemo")
	var remote := CharacterBody2D.new()
	ship.add_child(remote)
	helm.operator = remote
	view._process(0.0)
	check(not view.helm_wheel.visible, "Remote helm operator must not show local steering overlay")
	helm.operator = null
	ship.player.position = helm.position
	check(helm.try_take_control(ship.player), "Local sailor can claim helm")
	view._process(0.0)
	check(view.helm_wheel.visible, "Local helm operator sees steering overlay")
	NetworkSession.players[NetworkSession.local_id] = ship.player
	MapState.map_open = true
	check(not NetworkSession._map_blocks_movement(), "Map leaves occupied station controls enabled for network input")
	var before := ship.wheel_angle_degrees
	Input.action_press("move_right")
	helm._physics_process(0.1)
	Input.action_release("move_right")
	check(ship.wheel_angle_degrees > before and ship.player.active_station == helm, "Steering continues with map open")
	helm.release_control()
	check(NetworkSession._map_blocks_movement(), "Map still blocks walking when not using a station")
	MapState.map_open = false
	NetworkSession.players.clear()
	remote.queue_free()
	# Clients rebuild an already populated world when they receive the host seed.
	for seed_value in [71021, 71022]:
		ship.rebuild_world(seed_value)
		for island in ship.get_islands():
			var totem := island.get_node("MinigameTotem") as MinigameTotem
			var labels := totem.find_children("*", "Label", false, false)
			check(labels.size() == 1, "Rebuilt totem must have exactly one caption")
			totem.set_occupied(true)
			check(totem.caption.text.contains("Occupied") and not totem.caption.text.contains("Play challenge"), "Occupied caption replaces idle prompt")
			check(totem.global_scale.is_equal_approx(Vector2.ONE), "Rebuilt totem retains consistent scale")
	# Exercise the real online input path, including the host's release logic.
	check(NetworkSession.host_session("UI test", 24719, "", false) == OK, "Local test host starts")
	for frame in 20: await get_tree().physics_frame
	ship = NetworkSession.ship
	helm = ship.get_node("Helm") as HelmStation
	ship.player.position = helm.position
	check(helm.try_take_control(ship.player), "Online host claims helm")
	MapState.map_open = true
	before = ship.wheel_angle_degrees
	Input.action_press("move_right")
	for frame in 10: await get_tree().physics_frame
	Input.action_release("move_right")
	check(ship.player.active_station == helm and ship.wheel_angle_degrees > before, "Online map input keeps station claimed and steers")
	MapState.map_open = false
	NetworkSession.leave()
	print("Playtest UI: %d failure(s)" % failures)
	get_tree().quit(1 if failures else 0)
