extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frame(sequence: int, direction := Vector2.RIGHT) -> Dictionary:
	return {"sequence": sequence, "move": direction, "held": false, "blocked": false}
func snapshot() -> Dictionary:
	return {"serial": 1, "position": Vector2.ZERO, "paradise_quest": {}, "island_locks": {}, "discovered": {}, "seed": 34, "storage": [{"id": &"coal", "quantity": 4}], "port_storage": [{}], "drops": {}, "crew": {2: {"inventory": [{"id": &"fishing_rod", "quantity": 1}], "position": Vector2.ZERO}}}
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	var buffer := CrewInputBuffer.new()
	check(not buffer.append([null]) and not buffer.append([{"sequence": "bad"}]), "Malformed input rejected without reading properties")
	check(not buffer.append([frame(1, Vector2(INF, 0))]), "Non-finite movement rejected")
	check(buffer.append([frame(10), frame(11, Vector2.LEFT)]), "Valid input batch accepted")
	var played := buffer.take(1.0 / 60)
	check(played.size() == 2 and buffer.acknowledged == 11, "Ack names the exact last simulated input")
	for i in 120: buffer.take(1.0 / 60)
	check(buffer.acknowledged == 11, "Host ticks never fabricate acknowledgements")
	check(not buffer.append([frame(11)]), "Duplicate input cannot move player twice")
	check(buffer.append([frame(400, Vector2.ZERO)]), "Idle frame gaps are safe")
	buffer.take(1.0 / 60)
	check(buffer.acknowledged == 400, "Neutral input refresh acknowledges only that frame")
	# Simulate changing input with delayed, bursty delivery and a 400 ms outage.
	buffer = CrewInputBuffer.new()
	var sent := 0
	var applied := 0
	var expected := Vector2.ZERO
	var actual := Vector2.ZERO
	for tick in 420:
		if tick < 300:
			var direction := Vector2.RIGHT if tick % 60 < 30 else Vector2.LEFT
			expected += direction
		if tick > 12 and not (tick >= 100 and tick <= 124) and tick % 6 == 0:
			var batch: Array = []
			while sent < mini(tick - 12, 300) and batch.size() < 12:
				batch.append(frame(sent, Vector2.RIGHT if sent % 60 < 30 else Vector2.LEFT))
				sent += 1
			if not batch.is_empty(): check(buffer.append(batch), "Delayed ordered batch accepted")
		for value: Dictionary in buffer.take(1.0 / 60):
			actual += value.move
			applied += 1
	check(applied == 300 and actual == expected and buffer.acknowledged == 299, "Jitter and stall preserve all movement and reversals exactly once")
	buffer = CrewInputBuffer.new()
	var flood: Array = []
	for i in 12: flood.append(frame(i))
	buffer.append(flood)
	check(buffer.take(0).size() <= 6, "Burst catch-up is capped by elapsed-time credit")
	check(not buffer.append([frame(20), frame(19)]) and buffer.received == 11, "Invalid batch is atomic")
	var sender := SharedSnapshotState.new()
	var receiver := SharedSnapshotState.new()
	var full := snapshot()
	check(sender.extract(full), "First snapshot creates reliable shared revision")
	var motion := sender.motion(full)
	check(not motion.has("storage") and not motion.crew[2].has("inventory"), "Motion packets omit unchanged storage and bags")
	check(var_to_bytes(motion).size() < var_to_bytes(full).size(), "Motion payload is smaller than the full state")
	check(receiver.expand(motion).is_empty(), "Motion cannot apply before its reliable state")
	check(receiver.accept(sender.revision, sender.current), "Receiver accepts validated reliable state")
	check(receiver.expand(motion).storage == full.storage, "Motion reconstructs complete authoritative inventory")
	full.position = Vector2(10, 0)
	check(not sender.extract(full), "Movement alone does not resend shared state")
	full.drops[1] = {"id": &"coal", "quantity": 1, "position": Vector2.ZERO, "age": 0.0}
	full.island_locks["island"] = {"player": 2, "token": 1, "seconds": 0.0}
	check(sender.extract(full), "New drops and island reservations are replicated")
	full.drops[1].age = 20.0
	full.island_locks.island.seconds = 20.0
	check(not sender.extract(full), "Host-only drop and reservation clocks do not trigger synchronization")
	full.storage[0].quantity = 3
	check(sender.extract(full), "Storage change advances shared revision")
	# Dropping any number of motion packets cannot lose a reliable inventory update.
	receiver.accept(sender.revision, sender.current)
	full.serial = 50
	check(receiver.expand(sender.motion(full)).storage[0].quantity == 3, "Latest-only motion is safe after skipped snapshots")
	check(not receiver.accept(99, {"bags": null}), "Malformed shared state rejected")
	var malformed := sender.current.duplicate(true)
	malformed["fish_returns"] = 42
	check(not receiver.accept(100,malformed), "Invalid fish return container rejected before property access")
	malformed["fish_returns"] = {"fish": {"position":Vector2.ZERO,"angle":0.0,"time":NAN,"duration":3.0}}
	check(not receiver.accept(100,malformed), "Nonfinite fish return clock rejected")
	var inventory := ShipInventory.new()
	var slots: Array[Dictionary] = [{"id": &"coal", "quantity": 4}]
	inventory.max_inv_space = 1
	inventory.restore(slots)
	var revision := inventory.revision
	for i in 30: inventory.restore(slots)
	check(inventory.revision == revision, "Unchanged inventories emit no updates or revision churn")
	slots[0].quantity = 2
	inventory.restore(slots)
	check(inventory.revision == revision + 1, "Actual inventory change publishes once")
	check(not NetworkSession.valid_snapshot({"serial": 100, "crew": [1]}), "Malformed world snapshot rejected before mutation")
	check(not NetworkSession.valid_command({"attempt": {}}) and not NetworkSession.valid_command({"point": Vector2(NAN, 0)}), "Malformed command fields rejected before conversion")
	check(not HarborPeer.valid_control({"type": "welcome", "id": 1, "identity": "test", "peers": [null]}), "Malformed peer list rejected without property access")
	check(HarborPeer.valid_control({"type": "welcome", "id": 2.0, "identity": "test", "peers": [{"id": 1.0, "identity": "host"}]}), "JSON numeric peer identifiers remain supported")
	var departing := HarborPeer.new()
	departing.identities = {2: "one", 3: "two"}
	departing.incoming = [{"peer": 2, "bytes": PackedByteArray([1])}, {"peer": 3, "bytes": PackedByteArray([2])}]
	departing.control({"type": "peer_left", "id": 2})
	check(departing.incoming.size() == 1 and departing.incoming[0].peer == 3, "Departure purges only departed peer RPCs before disconnect delivery")
	var playback := SnapshotBuffer.new()
	for i in range(1, 8):
		playback.push({"serial": i, "time": i * 0.1, "position": Vector2(i, 0)}, i * 0.1 + (0.12 if i >= 4 else 0.0))
	check(playback.playback_delay > SnapshotBuffer.DELAY and playback.playback_delay <= 0.3, "Playback adapts to arrival jitter with a bounded delay")
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	var ship := get_tree().current_scene as Ship
	ship.set_physics_process(false)
	var fishing: RodFishing = ship.get_node("InventorySystem/Fishing")
	var rod_slots: Array[Dictionary] = [{"id": &"fishing_rod", "quantity": 1}, {}, {}, {}]
	fishing.service.inventory.restore(rod_slots)
	fishing.service.hud.selected = 0
	fishing.set_process(false)
	fishing.state = RodFishing.State.CASTING
	fishing._cast_from_ship = true
	fishing._ship_target = Vector2(250, 0)
	fishing._ship_origin = Vector2(0, -18)
	fishing.clock = 0.1
	var bobber := fishing.bobber_position()
	ship.position += Vector2(20, 0)
	check(fishing.bobber_position().is_equal_approx(bobber + Vector2(20, 0)), "Guest bobber follows displayed ship between snapshots")
	fishing.tick_presentation(0.05)
	check(is_equal_approx(fishing.clock, 0.15) and fishing.state == RodFishing.State.CASTING, "Presentation advances smoothly without inventing gameplay transitions")
	fishing.fight_seed = 45
	fishing.begin_local_hook()
	var tension := fishing.fight.tension
	fishing.tick_local_fight(1.0 / 60)
	check(fishing.fight.tension > tension, "Guest tension responds before any host reply")
	fishing.cancel()
	# Exercise the real collision movement and reconciliation, not just vector sums.
	var predicted := ship.player
	predicted.set_physics_process(false)
	predicted.collision_layer = 0
	predicted.position = Vector2(-25, 75)
	var authority: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	authority.player_inventory = PlayerInventory.new()
	ship.add_child(authority)
	authority.set_physics_process(false)
	authority.collision_layer = 0
	authority.position = predicted.position
	NetworkSession.ship = ship
	NetworkSession.players[NetworkSession.local_id] = predicted
	NetworkSession._last_snapshot = {"trim": ship.sail_angle_degrees, "wheel": ship.wheel_angle_degrees}
	NetworkSession._prediction.clear()
	NetworkSession._prediction_error = Vector2.ZERO
	var pending: Array[Dictionary] = []
	buffer = CrewInputBuffer.new()
	var maximum_error := 0.0
	for tick in 240:
		await get_tree().physics_frame
		var direction := Vector2.RIGHT if tick < 80 else (Vector2.LEFT if tick < 160 else Vector2.ZERO)
		NetworkSession._predict_local(direction, 1.0 / 60)
		pending.append(frame(Engine.get_physics_frames(), direction))
		if tick % 6 == 0 and pending.size() > 12 and not (tick >= 100 and tick < 118):
			var batch: Array = []
			while pending.size() > 12 and batch.size() < 12: batch.append(pending.pop_front())
			buffer.append(batch)
		for input: Dictionary in buffer.take(1.0 / 60): authority.move_crew(input.move, 1.0 / 60)
		if tick % 6 == 0 and buffer.acknowledged >= 0:
			NetworkSession._reconcile_local({"position": authority.position, "ack": buffer.acknowledged, "station": ""}, false)
			maximum_error = maxf(maximum_error, NetworkSession.last_correction)
	check(maximum_error < 0.5, "Actual deck collisions and reversals stay aligned under delayed input playback")
	check(predicted.position.distance_to(authority.position) < 0.5, "Guest and host settle at the same stopped position")
	NetworkSession.players.clear()
	NetworkSession._prediction.clear()
	NetworkSession._last_snapshot.clear()
	print("NETWORK RESPONSIVENESS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
