extends Node

var failures: int = 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _settle(view: Node) -> void:
	for frame in range(120):
		view._process(1.0 / 60.0)

func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	await get_tree().process_frame
	var ship := get_tree().current_scene.get_node("Ship") as Ship
	var player := ship.player
	var view := ship.get_node("SailingDemo")
	var camera := ship.get_node("Camera2D") as Camera2D
	view.set_process(false)
	var normal := camera.zoom
	for name in ["Helm", "Sail"]:
		var station := ship.get_node(name) as ShipStation
		player.position = station.position
		_check(station.try_take_control(player), "Station must accept interaction")
		view._process(0.016)
		_check(camera.zoom.x > normal.x and camera.zoom.x < normal.x * view.station_zoom_multiplier, "Zoom must ease in")
		_settle(view)
		var expected_zoom: float = view.helm_zoom_multiplier if name == "Helm" else view.station_zoom_multiplier
		_check(absf(camera.zoom.x - normal.x * expected_zoom) < 0.001, "Helm must use its own smaller zoom")
		var expected_center := ship.global_position if name == "Helm" else station.global_position
		_check(camera.global_position.distance_to(expected_center) < 0.1, "Helm must keep ship framing; other stations must be centered")
		_check(absf(view.vignette.modulate.a - view.station_vignette_opacity) < 0.001, "Station vignette must fade in")
		station.release_control()
		_settle(view)
		_check(camera.zoom.distance_to(normal) < 0.001, "Leaving must restore original zoom")
		_check(view.vignette.modulate.a < 0.001, "Leaving must fade out the vignette")
		_check(camera.global_position.distance_to(ship.global_position) < 0.1, "Leaving must restore ship framing")
	var cooking := ship.get_node("Cooking")
	cooking.crew_nearby.append(player)
	cooking._update_display()
	_check(not cooking.prompt.visible, "Cooking proximity prompt must stay hidden")
	cooking.interact()
	_settle(view)
	_check(camera.global_position.distance_to(cooking.global_position) < 0.1, "Cooking must focus camera")
	cooking._on_preparation_cancelled()
	_settle(view)
	_check(camera.zoom.distance_to(normal) < 0.001, "Cancelling cooking must restore camera")
	var fishing := ship.get_node("InventorySystem/Fishing")
	player.position = Vector2(0, 60)
	_check(fishing.cast(player.global_position + Vector2(230, 0)), "Rod must cast into nearby water")
	_settle(view)
	_check(player.fishing_active and not player.using_station, "Fishing holds stance without claiming station camera")
	_check(camera.zoom.distance_to(normal) < 0.001, "Fishing preserves camera framing for mouse aim")
	fishing.cancel()
	_check(not player.fishing_active, "Cancelling fishing releases stance")
	print("Station camera integration: %d failure(s)" % failures)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if failures == 0 else 1)
