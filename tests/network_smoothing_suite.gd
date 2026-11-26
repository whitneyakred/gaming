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
	# Correct a deliberate prediction error and replay remaining inputs. The body
	# moves immediately; the displayed player stays where it was, then eases in.
	crew.position = Vector2(-25, 90)
	crew.inventory_open = false
	crew.access_motion = &""
	crew.set_physics_process(false)
	ship.get_node("SwimAccess").set_physics_process(false)
	var fixed_start: Vector2 = crew.position
	crew.move_crew(Vector2.DOWN, 1.0 / 120.0)
	check(absf(crew.position.distance_to(fixed_start) - crew.walk_speed / 120.0) < 0.01, "Collision movement uses explicit replay delta outside physics callback")
	crew.position = fixed_start
	NetworkSession._last_snapshot = {"trim": 0.0, "wheel": 0.0}
	NetworkSession._prediction = [{"sequence": 1, "position": crew.position, "move": Vector2.ZERO, "trim": 0.0, "wheel": 0.0}, {"sequence": 2, "position": crew.position, "move": Vector2.DOWN, "trim": 0.0, "wheel": 0.0}]
	var visual_before: Vector2 = crew.visual_position()
	NetworkSession._reconcile_local({"position": Vector2(-25, 95), "ack": 1, "station": ""}, false)
	check(NetworkSession.replayed_frames == 1 and crew.position.y > 95, "Host correction re-simulates only unacknowledged movement")
	check(crew.visual_position().distance_to(visual_before) < 0.01, "Body correction preserves displayed position")
	var body_after: Vector2 = crew.position
	crew._process(0.1)
	check(crew.position == body_after and crew.presentation_offset.length() < 5.0, "Visual smoothing never nudges collision body")
	check(crew.presentation.global_position.distance_to(crew.visual_position()) < 0.01, "Rendered sailor follows visual correction offset")
	NetworkSession._reconcile_local({"position": Vector2(-25, 90), "ack": 2, "station": ""}, true)
	check(crew.presentation_offset == Vector2.ZERO, "State transitions clear visual offset")
	# A guest starts the phase before an acknowledgement, but cannot board early.
	NetworkSession.online = true
	crew.position = access.plank_end
	NetworkSession._predict_local(Vector2.ZERO, 1.0 / 60)
	check(crew.access_motion == &"jump" and not NetworkSession._pending_access.is_empty(), "Jump starts immediately at local plank trigger")
	check(NetworkSession._hold_predicted_access({"ack": -1, "access_motion": &"", "health": 15, "station": ""}), "Pre-input snapshot cannot cancel speculative traversal")
	check(not NetworkSession._hold_predicted_access({"ack": Engine.get_physics_frames(), "access_motion": &"", "health": 15, "station": ""}), "Host rejection ends speculative traversal")
	check(NetworkSession.access_rejections > 0, "Rejected traversal is diagnosed")
	crew.access_motion = &""
	crew.global_position = ship.to_global(access.ladder_water)
	NetworkSession._access_retry_at = 0
	NetworkSession._predict_local(Vector2.ZERO, 1.0 / 60)
	check(crew.access_motion == &"align", "Ladder alignment starts locally before host reply")
	check(not NetworkSession._hold_predicted_access({"access_motion": &"climb"}) and NetworkSession._pending_access.is_empty(), "Host phase confirms speculative ladder access")
	access.advance_guest_access(crew, 5.0)
	check(crew.is_overboard and crew.access_motion == &"align", "Speculative ladder never grants deck access")
	NetworkSession.online = false
	crew.set_overboard(false)
	NetworkSession._prediction.clear()
	for sequence in 70:
		NetworkSession._prediction.append({"sequence": sequence, "position": crew.position, "move": Vector2.DOWN, "trim": 0.0, "wheel": 0.0})
	NetworkSession._reconcile_local({"position": crew.position, "ack": 0, "station": ""}, false)
	check(NetworkSession.replayed_frames == 0 and NetworkSession._prediction.is_empty(), "Long outage cannot create unbounded replay work")
	for hz in [10, 15, 20]:
		var tuned := SnapshotBuffer.new()
		for serial in range(1, hz * 5):
			var packet := state(serial)
			packet.time = float(serial) / hz
			tuned.push(packet, packet.time + 0.08)
		check(absf(tuned.playback_delay - maxf(0.1, 1.5 / hz)) < 0.005, "Stable playback delay tracks %d Hz" % hz)
	for step in 101:
		var point := SnapshotBuffer.smooth_position(Vector2.ZERO, Vector2(10, -10), Vector2(900, -900), Vector2(-900, 900), 0.1, step / 100.0)
		check(point.x >= 0 and point.x <= 10 and point.y >= -10 and point.y <= 0, "Velocity interpolation never overshoots confirmed endpoints")
	for sample in 300: NetworkSession.diagnostics.record_sample()
	check(NetworkSession.diagnostics.history.size() == 240, "Diagnostic history is bounded to two minutes")
	check(not JSON.stringify(NetworkSession.diagnostics.history).contains("token"), "History contains no identity/authentication tokens")
	crew.set_physics_process(true)
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

