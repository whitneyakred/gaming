extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func state(serial: int) -> Dictionary:
	return {"serial": serial, "time": serial * 0.1, "position": Vector2(serial * 10, 0), "rotation": 0.0, "trim": 0.0, "wheel": 0.0, "crew": {}}
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	for fps: int in [30, 60, 144]:
		var buffer := SnapshotBuffer.new()
		var next := 1
		var previous := 0.0
		var biggest_step := 0.0
		for tick in fps * 5:
			var time := float(tick) / fps
			# Uneven delivery with fixed latency; host timing stays regular.
			while next <= 45 and time >= next * 0.1 + 0.08 + (0.045 if next % 3 == 0 else 0.0):
				buffer.push(state(next))
				next += 1
			var visual := buffer.sample(1.0 / fps)
			if visual.is_empty(): continue
			var x: float = visual.position.x
			if tick > fps: biggest_step = maxf(biggest_step, absf(x - previous))
			check(x >= previous, "Buffered motion must not reverse under jitter")
			previous = x
		check(biggest_step < 120.0 / fps, "Jitter does not create packet-sized jumps at %d FPS" % fps)
		for tick in fps: buffer.sample(1.0 / fps)
		check(buffer.sample(0).position == state(45).position, "Outage holds latest host position, never runs through land")
		buffer.push(state(44))
		check(buffer.frames.back().state.serial == 45, "Stale packets ignored")
		var teleport := state(46)
		teleport.position = Vector2(9000, 0)
		buffer.push(teleport)
		check(buffer.sample(0).position == teleport.position, "Teleport resets playback")
		buffer.clear()
		check(buffer.sample(0).is_empty(), "Reconnect clears buffer")
	var angles := SnapshotBuffer.new()
	var first := state(1)
	first.rotation = deg_to_rad(179)
	first.trim = 179.0
	first.crew = {2: {"position": Vector2.ZERO, "outside": false, "station": "", "respawn": 0}}
	var second := state(2)
	second.rotation = deg_to_rad(-179)
	second.trim = -179.0
	second.crew = {2: {"position": Vector2(100, 0), "outside": true, "station": "", "respawn": 0}}
	angles.push(first)
	angles.push(second)
	angles.cursor = 0.15
	var middle := angles.sample(0)
	check(absf(middle.rotation) > 3.0 and absf(middle.trim) > 170, "Angles cross wrap boundary by shortest route")
	check(middle.crew[2].position == second.crew[2].position, "Boarding transition does not blend coordinate spaces")
	for serial in range(3, 100): angles.push(state(serial))
	check(angles.frames.size() <= SnapshotBuffer.LIMIT, "Packet bursts retain bounded memory")
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	var ship := get_tree().current_scene as Ship
	ship.set_physics_process(false)
	NetworkSession.ship = ship
	NetworkSession.players[NetworkSession.local_id] = ship.player
	var service := ship.get_node("InventorySystem") as InventoryService
	NetworkSession.services[NetworkSession.local_id] = service
	var hud_state := {"selected": 0, "chest": true, "grill_open": false}
	NetworkSession._local_selection = 3
	service.hud.selected = 3
	NetworkSession._apply_hud_state(NetworkSession.local_id, hud_state)
	check(service.hud.selected == 3 and NetworkSession._selection_dirty, "Old snapshot cannot undo local hotbar selection; mismatch schedules retry")
	hud_state.selected = 3
	NetworkSession._apply_hud_state(NetworkSession.local_id, hud_state)
	check(not NetworkSession._selection_dirty, "Matching host selection stops retries")
	NetworkSession._local_close_until = Time.get_ticks_msec() + 2000
	NetworkSession._apply_hud_state(NetworkSession.local_id, hud_state)
	check(not service.hud.storage_open and not ship.player.inventory_open, "Stale open snapshot cannot reopen locally closed panel")
	hud_state.chest = false
	NetworkSession._apply_hud_state(NetworkSession.local_id, hud_state)
	check(NetworkSession._local_close_until == 0, "Host close confirmation clears temporary protection")
	NetworkSession._local_selection = -1
	hud_state.selected = 1
	NetworkSession._apply_hud_state(NetworkSession.local_id, hud_state)
	check(service.hud.selected == 1, "Initial restored selection still comes from host")
	NetworkSession.services.clear()
	var access := ship.get_node("SwimAccess") as SwimAccess
	var crew := ship.player
	for phase: StringName in [&"jump", &"align", &"climb", &"step_on", &"dunk", &"surface"]:
		crew.set_overboard(true)
		crew.access_motion = phase
		crew.access_progress = 0.25
		crew.access_start = access.plank_end if phase == &"jump" else access.ladder_water
		access._place_access(crew)
		var authoritative := crew.position
		var entry := {"position": authoritative, "access_progress": 0.25}
		access.sync_guest_access(crew, entry, ship.global_transform)
		check(crew.position.distance_to(authoritative) < 0.01, "Guest phase starts at host position: %s" % phase)
		var before_progress: float = crew.access_progress
		access.advance_guest_access(crew, 1.0 / 60.0)
		check(crew.access_progress > before_progress, "Guest animation advances between packets: %s" % phase)
		var advanced: float = crew.access_progress
		access.sync_guest_access(crew, entry, ship.global_transform)
		check(crew.access_progress == advanced, "Snapshot does not rewind visual progress: %s" % phase)
		access.advance_guest_access(crew, 5.0)
		check(crew.access_progress == 1.0 and crew.access_motion == phase and crew.is_overboard, "Outage cannot speculatively finish phase/board: %s" % phase)
	crew.set_overboard(false)
	var helm := ship.get_node("Helm") as HelmStation
	ship.player.position = helm.position
	helm.try_take_control(ship.player)
	NetworkSession._last_snapshot = {"trim": 0.0, "wheel": 40.0}
	ship.set_wheel_angle(100.0)
	NetworkSession._prediction = [{"sequence": 1, "position": ship.player.position, "trim": 0.0, "wheel": 80.0}]
	NetworkSession._reconcile_local({"position": ship.player.position, "ack": 1, "station": "Helm"}, false)
	check(ship.wheel_angle_degrees == 100.0, "Snapshot must not instantly jump local wheel")
	NetworkSession._predict_local(Vector2.RIGHT, 1.0 / 60.0)
	check(absf(ship.wheel_angle_degrees - 100.0) < 6.0, "Local correction is spread across frames")
	NetworkSession._wheel_error = 0
	var before := ship.wheel_angle_degrees
	NetworkSession._predict_local(Vector2.RIGHT, 1.0 / 60.0)
	check(ship.wheel_angle_degrees > before, "Held helm responds without waiting for network")
	helm.release_control()
	var sail := ship.get_node("Sail") as SailStation
	ship.player.position = sail.position
	sail.try_take_control(ship.player)
	ship.set_sail_angle(100.0)
	NetworkSession._last_snapshot.trim = 40.0
	NetworkSession._prediction = [{"sequence": 2, "position": ship.player.position, "trim": 80.0, "wheel": 0.0}]
	NetworkSession._reconcile_local({"position": ship.player.position, "ack": 2, "station": "Sail"}, false)
	check(ship.sail_angle_degrees == 100.0, "Snapshot must not instantly jump local sail trim")
	NetworkSession._predict_local(Vector2.RIGHT, 1.0 / 60.0)
	check(absf(ship.sail_angle_degrees - 100.0) < 6.0, "Sail correction is spread across frames")
	NetworkSession.players.clear()
	NetworkSession._last_snapshot.clear()
	NetworkSession._prediction.clear()
	print("Network smoothing: %d failure(s)" % failures)
	get_tree().quit(1 if failures else 0)

