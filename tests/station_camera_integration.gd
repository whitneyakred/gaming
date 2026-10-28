extends SceneTree

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _settle(view: Node) -> void:
	for frame in range(120):
		view._process(1.0 / 60.0)

func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
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
	var fishing := ship.get_node("FishingStation")
	fishing._on_body_entered(player)
	_check(not fishing.status_label.visible, "Fishing proximity prompt must stay hidden")
	fishing.start_attempt()
	_check(player.active_station == fishing, "Fishing must claim station focus")
	_settle(view)
	_check(camera.global_position.distance_to(fishing.global_position) < 0.1, "Fishing must focus camera")
	fishing.cancel_attempt()
	_settle(view)
	_check(not player.using_station and camera.zoom.distance_to(normal) < 0.001, "Cancelling fishing must release focus")
	fishing.start_attempt()
	fishing._on_hold_timer_timeout()
	fishing.complete_attempt()
	_settle(view)
	_check(not player.using_station and camera.zoom.distance_to(normal) < 0.001, "Completing fishing must release focus")
	print("Station camera integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
