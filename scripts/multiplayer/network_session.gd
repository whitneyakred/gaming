extends Node2D
## One authoritative session: clients send controls, server sends world snapshots.
## The host plays too; other computers connect directly over the local network.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PROTOCOL := 8 # Entry-triggered pickup; all players need matching builds.
const MAX_CREW := 4
const UPDATE_INTERVAL := 1.0 / 60.0 # Match the default physics rate for smoother LAN movement.
const CREW_COLORS := [Color.WHITE, Color("80caff"), Color("ffb080"), Color("b6ff91")]
const SPAWN_POSITIONS := [Vector2(-30, 90), Vector2(30, 90), Vector2(-30, 45), Vector2(30, 45)]
@export var port: int = 9080 # Shared default; players only enter the host IP.

@onready var ship: ShipMotion = $Ship
@onready var panel: Control = $ConnectionMenu/Panel
@onready var status: Label = $ConnectionMenu/Status
@onready var leave_button: Button = $ConnectionMenu/Leave

var peer: WebSocketMultiplayerPeer
var running := false
signal session_reset
var players: Dictionary = {} # peer ID -> CharacterBody2D
var slots: Dictionary = {} # peer ID -> stable color/spawn slot
var inputs: Dictionary = {} # server-only held direction, one-shot actions and timestamps
var latest_snapshot: Dictionary = {}
var update_clock := 0.0
var connection_clock := 0.0
var pending_interact := false
var pending_cycle := false
var stations: Dictionary = {} # stable ship-relative NodePath string -> ShipStation
var station_layout := PackedStringArray()
var initial_station_states: Dictionary = {}
var initial_ship_state: Dictionary = {}

func _ready() -> void:
	# Clients communicate only with the server; crew discovery comes from snapshots.
	(multiplayer as SceneMultiplayer).server_relay = false
	# The session drives physics; this prevents every copy simulating the same boat.
	ship.set_physics_process(false)
	_discover_stations(ship)
	station_layout.sort()
	initial_ship_state = ship.capture_state()
	ship.get_node("Player").free()
	process_priority = -20 # interpolate before the following camera updates
	leave_button.pressed.connect(func(): end_session("Left session."))
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): end_session("Connection failed. Check server address and firewall."))
	multiplayer.server_disconnected.connect(func(): end_session("Server disconnected. You can join again."))
	multiplayer.peer_disconnected.connect(_peer_left)
	# Optional shortcuts for testing multiple game instances.
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--port="):
			port = clampi(arg.trim_prefix("--port=").to_int(), 1, 65535)
	if "--host" in args:
		host_game()
	else:
		for arg in args:
			if arg.begins_with("--join="):
				join_game(arg.trim_prefix("--join="))

func _discover_stations(parent: Node) -> void:
	# Static scene stations, including nested ones. Dynamic spawning is separate work.
	for child in parent.get_children():
		if child is ShipStation:
			var station := child as ShipStation
			var key := str(ship.get_path_to(station))
			station.ship = ship
			station.set_physics_process(false)
			station.set_process_unhandled_input(false)
			station.local_player = null
			stations[key] = station
			station_layout.append(key + ":" + station.get_script().resource_path)
			initial_station_states[key] = station.capture_state().duplicate(true)
		_discover_stations(child)

func _nearest_station(crew: CharacterBody2D) -> ShipStation:
	var nearest: ShipStation = null
	var distance := INF
	for candidate: ShipStation in stations.values():
		if is_instance_valid(candidate.operator) or not candidate.can_interact(crew):
			continue
		var candidate_distance := candidate.global_position.distance_squared_to(crew.global_position)
		if candidate_distance < distance:
			nearest = candidate
			distance = candidate_distance
	return nearest

func start_offline() -> void:
	end_session("")
	running = true
	panel.hide()
	leave_button.show()
	_add_player(1, 0)
	status.text = "Offline ship"

func host_game() -> void:
	if peer != null or OS.has_feature("web"):
		return
	peer = WebSocketMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		peer = null
		status.text = "Could not host on port %d: %s" % [port, error_string(error)]
		return
	multiplayer.multiplayer_peer = peer
	running = true
	panel.hide()
	leave_button.show()
	_add_player(1, 0)
	_update_status()
	print("Server listening on TCP port ", port)

func join_game(url: String) -> void:
	if peer != null:
		return
	url = url.strip_edges()
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		status.text = "Use ws://address:9080 or wss://address."
		return
	peer = WebSocketMultiplayerPeer.new()
	var error := peer.create_client(url)
	if error != OK:
		peer = null
		status.text = "Could not join: " + error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	connection_clock = 0.0
	panel.hide()
	leave_button.show()
	status.text = "Connecting..."

func _connected() -> void:
	register_crew.rpc_id(1, PROTOCOL, station_layout)
	status.text = "Connected; waiting for crew slot..."

@rpc("any_peer", "call_remote", "reliable")
func register_crew(version: int, layout: PackedStringArray = PackedStringArray()) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		return
	if version != PROTOCOL or layout != station_layout or players.size() >= MAX_CREW:
		var reason := "Game versions or station layouts differ. Use the same build."
		if version == PROTOCOL and layout == station_layout:
			reason = "The boat is full (4 crew)."
		rejected.rpc_id(id, reason)
		return
	var slot := 0
	while slot in slots.values():
		slot += 1
	_add_player(id, slot)
	print("Crew joined: ", players.size(), "/", MAX_CREW)
	_send_snapshot() # Includes current boat/sail/station state for late joiners.
	_update_status()

@rpc("authority", "call_remote", "reliable")
func rejected(reason: String) -> void:
	end_session(reason)

func _add_player(id: int, slot: int) -> void:
	var crew := PLAYER_SCENE.instantiate() as CharacterBody2D
	crew.name = "Crew_%d" % id
	crew.set("read_local_input", false)
	# Crew share deck walls but do not block each other in narrow station spaces.
	crew.collision_layer = 2
	crew.collision_mask = 1 if multiplayer.is_server() else 0
	ship.add_child(crew)
	# Godot enables script callbacks on entering the tree; disable AFTER add_child.
	# The server calls apply_movement; clients only display received positions.
	crew.set_physics_process(false)
	crew.position = SPAWN_POSITIONS[slot]
	crew.get_node("Sprite2D").modulate = CREW_COLORS[slot]
	players[id] = crew
	slots[id] = slot
	inputs[id] = {"direction": Vector2.ZERO, "interact": false, "cycle": false,
		"received": -1.0, "last_interact": -1.0, "last_cycle": -1.0}
	$InventorySystem.add_crew(id)
	if id == multiplayer.get_unique_id():
		for station: ShipStation in stations.values():
			station.local_player = crew

func _remove_player(id: int) -> void:
	if not players.has(id):
		return
	$InventorySystem.remove_crew(id, players[id].position)
	for station: ShipStation in stations.values():
		if station.operator == players[id]:
			station.release_control()
	players[id].free()
	players.erase(id)
	slots.erase(id)
	inputs.erase(id)

func _peer_left(id: int) -> void:
	if running and multiplayer.is_server():
		_remove_player(id)
		_update_status()

func end_session(message: String) -> void:
	running = false
	if peer != null:
		peer.close()
	peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for id: int in players.keys():
		_remove_player(id)
	_reset_world()
	latest_snapshot.clear()
	pending_interact = false
	pending_cycle = false
	update_clock = 0.0
	panel.show()
	leave_button.hide()
	status.text = message

func _reset_world() -> void:
	for key: String in stations:
		var station: ShipStation = stations[key]
		station.release_control()
		station.local_player = null
		station.restore_state(initial_station_states[key].duplicate(true))
	ship.restore_state(initial_ship_state.duplicate(true), true)
	# Future world systems can clear their temporary state using this signal.
	session_reset.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not running or event.is_echo():
		return
	if event.is_action_pressed("station_interact"):
		if $InventoryHUD.handle_interact():
			get_viewport().set_input_as_handled()
			return
		pending_interact = true
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		pending_cycle = true

func _physics_process(delta: float) -> void:
	if not running:
		if peer != null:
			connection_clock += delta
			if connection_clock > 10.0:
				end_session("Connection timed out. Check the address and try again.")
		return
	# Read controls every physics tick, so pressing/releasing a key never waits for a snapshot.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not DisplayServer.window_is_focused():
		direction = Vector2.ZERO
		pending_interact = false
		pending_cycle = false
	if multiplayer.is_server():
		_accept_input(1, direction, pending_interact, pending_cycle)
		_simulate(delta)
	else:
		submit_input.rpc_id(1, direction, pending_interact, pending_cycle)
	pending_interact = false
	pending_cycle = false
	update_clock += delta
	if update_clock >= UPDATE_INTERVAL:
		update_clock = fmod(update_clock, UPDATE_INTERVAL)
		if multiplayer.is_server():
			_send_snapshot() # Send the result AFTER this tick's movement.

@rpc("any_peer", "call_remote", "reliable")
func submit_input(direction: Vector2, interact: bool, cycle: bool) -> void:
	if multiplayer.is_server():
		# Sender identity comes from the connection, never a client-supplied player ID.
		_accept_input(multiplayer.get_remote_sender_id(), direction, interact, cycle)

func _accept_input(id: int, direction: Vector2, interact: bool, cycle: bool) -> void:
	if not inputs.has(id) or not direction.is_finite():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var command: Dictionary = inputs[id]
	if now - float(command.received) < 0.01:
		return # Bound accepted message rate and movement magnitude.
	command.direction = direction.limit_length()
	command.received = now
	if interact and now - float(command.last_interact) >= 0.2:
		command.interact = true
		command.last_interact = now
	if cycle and now - float(command.last_cycle) >= 0.15:
		command.cycle = true
		command.last_cycle = now

func _simulate(delta: float) -> void:
	if players.is_empty():
		return
	ship.simulate_movement(delta)
	var now := Time.get_ticks_msec() / 1000.0
	for id: int in players:
		var crew: CharacterBody2D = players[id]
		var command: Dictionary = inputs[id]
		var fresh := now - float(command.received) < 0.5
		var direction: Vector2 = command.direction if fresh else Vector2.ZERO
		if not fresh:
			command.interact = false
			command.cycle = false
		var station := crew.get("active_station") as ShipStation
		if station != null and station.global_position.distance_to(crew.global_position) > maxf(station.release_distance, station.interaction_distance):
			station.release_control()
			station = null
		if command.interact:
			if station != null:
				station.release_control()
			else:
				var candidate := _nearest_station(crew)
				if candidate != null:
					candidate.try_take_control(crew)
			# Do not interpret the same packet as both entering a station and cycling it.
			command.cycle = false
		station = crew.get("active_station") as ShipStation
		if station != null:
			station.apply_controls(direction, command.cycle, delta)
		else:
			crew.call("apply_movement", direction)
		command.interact = false
		command.cycle = false

	$InventorySystem.collect_nearby(delta)

func _send_snapshot() -> void:
	var crew_state: Dictionary = {}
	for id: int in players:
		crew_state[id] = {"position": players[id].position, "slot": slots[id]}
	var station_states: Dictionary = {}
	for key: String in stations:
		var station: ShipStation = stations[key]
		station_states[key] = {"operator": _operator_id(station), "state": station.capture_state()}
	var state := {"ship": ship.capture_state(), "crew": crew_state, "stations": station_states}
	for id: int in players:
		if id == 1 or id not in multiplayer.get_peers():
			continue
		var connection := peer.get_peer(id)
		# Skip closing sockets and drop replaceable snapshots for a slow client.
		if connection.get_ready_state() == WebSocketPeer.STATE_OPEN and connection.get_current_outbound_buffered_amount() < 16384:
			receive_snapshot.rpc_id(id, state)

func _operator_id(station: ShipStation) -> int:
	for id: int in players:
		if players[id] == station.operator:
			return id
	return 0

@rpc("authority", "call_remote", "reliable")
func receive_snapshot(state: Dictionary) -> void:
	if multiplayer.is_server():
		return
	var first := latest_snapshot.is_empty()
	latest_snapshot = state
	for id: int in players.keys():
		if not state.crew.has(id):
			_remove_player(id)
	for id: int in state.crew:
		if not players.has(id):
			_add_player(id, state.crew[id].slot)
			players[id].position = state.crew[id].position
	# Release old assignments first so transfers cannot clear a newly assigned station.
	for key: String in stations:
		var station: ShipStation = stations[key]
		var next_operator: CharacterBody2D = players.get(state.stations[key].operator)
		if station.operator != next_operator:
			station.set_network_operator(null)
	for key: String in stations:
		var station: ShipStation = stations[key]
		station.set_network_operator(players.get(state.stations[key].operator))
		station.restore_state(state.stations[key].state)
	ship.restore_state(state.ship, first)
	# Our own character uses the newest confirmed position immediately. Only other
	# crew are interpolated: smoothing our own input adds another noticeable delay.
	var local_id := multiplayer.get_unique_id()
	if players.has(local_id):
		players[local_id].position = state.crew[local_id].position
	running = true
	_update_status()

func _process(delta: float) -> void:
	if not running or multiplayer.is_server() or latest_snapshot.is_empty():
		return
	# Interpolate crew in boat-local coordinates, avoiding double movement/jitter.
	var weight := 1.0 - exp(-20.0 * delta)
	ship.position = ship.position.lerp(latest_snapshot.ship.position, weight)
	ship.rotation = lerp_angle(ship.rotation, latest_snapshot.ship.rotation, weight)
	for id: int in players:
		if id == multiplayer.get_unique_id():
			continue
		players[id].position = players[id].position.lerp(latest_snapshot.crew[id].position, weight)

func _update_status() -> void:
	var id := multiplayer.get_unique_id()
	var role := "Host" if multiplayer.is_server() else "Client"
	var you := "" if not slots.has(id) else " - you are crew %d" % (int(slots[id]) + 1)
	status.text = "%s - %d/4 crew%s" % [role, players.size(), you]

	if multiplayer.is_server() and peer != null:
		var addresses := PackedStringArray()
		for address in IP.get_local_addresses():
			if address.is_valid_ip_address() and ":" not in address and not address.begins_with("127.") and not address.begins_with("169.254."):
				addresses.append(address)
		status.text += " | LAN IP: " + ", ".join(addresses)
