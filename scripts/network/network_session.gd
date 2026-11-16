extends Node
## Desktop ENet co-op. Only the server changes world state and awards items.
signal status_changed(message: String)
const PROTOCOL := "holy-ship-coop-9"
const DEFAULT_PORT := 24567
const MAX_CREW := 4
var online: bool = false
var internet: bool = false
var _snapshot_parts: Dictionary = {}
var dedicated: bool = false
var world_ready: bool = false
var applying: bool = false
var local_id: int = 1
var port: int = DEFAULT_PORT
var status: String = ""
var ship: Node2D
var players: Dictionary = {}
var services: Dictionary = {}
var identities: Dictionary = {}
var inputs: Dictionary = {}
var accounts: Dictionary = {}
var password: String = ""
var local_name: String = "Sailor"
var local_token: String = ""
var crew_title: String = "The Wandering Ship"
var profile_path: String = "user://crew_identity.cfg"
var discovery: Node
var dropped_id: int = 1
var _send_clock: float = 0.0
var _input_clock: float = 0.0
var _save_clock: float = 0.0
var _connect_clock: float = 0.0
var _pending: Dictionary = {}
var _rate: Dictionary = {}
var _last_snapshot: Dictionary = {}
var _restored: Dictionary = {}
var _snapshot_serial: int = 0
var _received_serial: int = -1
var _badge: Label
var _prediction: Array[Dictionary] = []
var _prediction_error := Vector2.ZERO
var _last_local_move := Vector2.ZERO
var _pagehide_callback: JavaScriptObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 50
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func() -> void: leave("Could not connect to the voyage. Refresh the crew list and try again."))
	multiplayer.server_disconnected.connect(func() -> void: leave("The host disconnected. Your crew session has ended."))
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.peer_connected.connect(func(id: int) -> void:
		if online and local_id == 1:
			_pending[id] = Time.get_ticks_msec())
	var config := ConfigFile.new()
	var path := "user://crew_identity.cfg"
	var arguments := OS.get_cmdline_user_args()
	var profile_index := arguments.find("--crew-profile")
	if profile_index >= 0 and profile_index + 1 < arguments.size():
		path = "user://crew_identity_%s.cfg" % arguments[profile_index + 1].sha256_text().left(16)
	if "--settings-test" in OS.get_cmdline_user_args():
		path = "res://.godot/crew-identity-%s.cfg" % OS.get_process_id()
	config.load(path)
	if OS.has_feature("web"):
		var stored: Variant = JavaScriptBridge.eval("(() => {try {return localStorage.getItem('holyShip.identity') || '';} catch(e) {return '';}})()")
		if stored is String and stored.length() == 48: config.set_value("crew", "token", stored)
	profile_path = path
	local_name = clean_name(str(config.get_value("crew", "name", "Sailor")))
	local_token = str(config.get_value("crew", "token", ""))
	if local_token.length() < 32:
		local_token = Crypto.new().generate_random_bytes(24).hex_encode()
		config.set_value("crew", "token", local_token)
		config.save(path)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try {localStorage.setItem('holyShip.identity', " + JSON.stringify(local_token) + ");} catch(e) {}")
		_pagehide_callback = JavaScriptBridge.create_callback(func(_args: Array): save_world())
		JavaScriptBridge.get_interface("window").addEventListener("pagehide", _pagehide_callback)
	discovery = preload("res://scripts/network/crew_discovery.gd").new()
	add_child(discovery)
	_start_cli.call_deferred()

func save_player_name(value: String) -> void:
	local_name = clean_name(value)
	var config := ConfigFile.new()
	config.load(profile_path)
	config.set_value("crew", "name", local_name)
	config.set_value("crew", "token", local_token)
	config.save(profile_path)

func set_status(message: String) -> void:
	status = message
	status_changed.emit(message)

func host_session(name_text: String, port_number: int, secret: String = "", resume_world: bool = true) -> Error:
	if OS.has_feature("web"):
		set_status("Co-op currently requires the desktop build. Browser solo play is available.")
		return ERR_UNAVAILABLE
	if online:
		return ERR_ALREADY_IN_USE
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port_number, MAX_CREW + 4, 3)
	if error != OK:
		set_status("Cannot host on UDP port %d (error %d)." % [port_number, error])
		return error
	multiplayer.multiplayer_peer = peer
	port = port_number
	local_name = clean_name(name_text)
	start_host_peer(peer, secret, resume_world, false)
	return OK

func start_host_peer(peer: MultiplayerPeer, secret: String, resume_world: bool, via_internet: bool) -> void:
	multiplayer.multiplayer_peer = peer
	internet = via_internet
	online = true
	local_id = 1
	password = secret.left(64)
	accounts.clear()
	_restored.clear()
	if resume_world:
		load_world()
	if not dedicated:
		var identity := local_token
		if internet:
			var user_id: String = peer.get_peer_user_id(1) if peer is HarborPeer else EOSGRuntime.local_product_user_id
			identity = user_id.sha256_text().left(48)
		identities[1] = {"name": local_name, "token": identity}
	set_status("Your voyage is open. Friends can find it in Browse crews.")
	load_game.call_deferred()

func join_session(address: String, port_number: int, name_text: String, secret: String = "") -> Error:
	if OS.has_feature("web") or online:
		return ERR_UNAVAILABLE
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port_number, 3)
	if error != OK:
		set_status("Cannot start connection (error %d)." % error)
		return error
	local_name = clean_name(name_text)
	port = port_number
	start_client_peer(peer, secret, false)
	return OK

func start_client_peer(peer: MultiplayerPeer, secret: String, via_internet: bool) -> void:
	internet = via_internet
	online = true
	password = secret.left(64)
	_connect_clock = 0
	multiplayer.multiplayer_peer = peer
	set_status("Connecting…")

func _drop_rejected(id: int) -> void:
	await get_tree().create_timer(0.4).timeout
	if online and local_id == 1 and not identities.has(id) and id in multiplayer.get_peers():
		multiplayer.multiplayer_peer.disconnect_peer(id)

func clean_name(value: String) -> String:
	var result := value.strip_edges().replace("\n", " ").replace("\r", " ").left(24)
	return "Sailor" if result.is_empty() else result

func _connected() -> void:
	local_id = multiplayer.get_unique_id()
	hello.rpc_id(1, PROTOCOL, local_name, local_token, password)

@rpc("any_peer", "call_remote", "reliable", 0)
func hello(version: String, crew_name: String, token: String, secret: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if identities.has(id):
		return
	if internet:
		var authenticated: String = multiplayer.multiplayer_peer.call("get_peer_user_id", id)
		if authenticated.is_empty(): return
		token = authenticated.sha256_text().left(48)
	var reason := ""
	if version != PROTOCOL:
		reason = "Different game version. Everyone must use the same build."
	elif secret != password:
		reason = "Incorrect session password."
	elif identities.size() >= MAX_CREW:
		reason = "This crew is full (4 players)."
	elif token.length() != 48 or not token.is_valid_hex_number():
		reason = "Invalid crew identity."
	for entry in identities.values():
		if entry.token == token:
			reason = "This crew identity is already connected. Use a separate game profile."
	if not reason.is_empty():
		rejected.rpc_id(id, reason)
		_drop_rejected(id)
		return
	identities[id] = {"name": clean_name(crew_name), "token": token}
	_pending[id] = Time.get_ticks_msec()
	welcome.rpc_id(id)

@rpc("authority", "call_remote", "reliable", 0)
func rejected(reason: String) -> void:
	leave(reason)

@rpc("authority", "call_remote", "reliable", 0)
func welcome() -> void:
	set_status("Joining the voyage…")
	load_game.call_deferred()

func load_game() -> void:
	VoyageState.reset()
	MapState.reset()
	Ship.returning_from_island = false
	SwimAccess.returning_by_swimming = false
	PauseMenu.resume()
	GameWindow.start_voyage_music()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	ship = get_tree().current_scene.get_node("Ship")
	world_ready = true
	ship.get_node("Player").hide()
	ship.get_node("Player").collision_layer = 0
	ship.get_node("InventorySystem/InventoryHUD").hide()
	_disable_local_systems(ship)
	var galley := ShipStation.new()
	galley.name = "Galley"
	galley.position = ship.get_node("Cooking").position
	galley.ship = ship
	ship.add_child(galley)
	galley.set_physics_process(false)
	galley.set_process_unhandled_input(false)
	if multiplayer.is_server():
		if not _restored.is_empty():
			ship.rebuild_world(int(_restored.get("seed", ship.world_seed)))
			MapState.discovered_islands = _restored.get("discovered", {})
			ship.global_position = _restored.get("position", Vector2.ZERO)
			ship.global_rotation = _restored.get("rotation", 0.0)
			if not _restored.has("seed"):
				var hull: PackedVector2Array = ship.get_hull_polygon(ship.global_position, ship.global_rotation)
				var bounds := Rect2(hull[0], Vector2.ZERO)
				for point in hull: bounds = bounds.expand(point)
				for island in ship.get_islands():
					if island.overlaps_land(hull, bounds): ship.global_position = Vector2.ZERO; break
				if WorldLayout.danger(ship.global_position): ship.global_position = Vector2.ZERO
			ship.anchor_deployed = true
			var slots: Array[Dictionary] = []
			slots.assign(_restored.get("storage", []))
			VoyageState.get_ship_storage().restore(slots)
			var drops: Dictionary = VoyageState.floor_items.get("ship", {})
			drops.merge(_restored.get("drops", {}), true)
			for key: int in drops:
				dropped_id = maxi(dropped_id, key + 1)
		ship.get_node("Cooking").restore(_restored.get("grill", {}))
		ship.get_node("Cooking").seed_fuel()
		if not dedicated:
			spawn_crew(1)
	else:
		ready_for_world.rpc_id(1)
	var hud := CanvasLayer.new()
	ship.add_child(hud)
	hud.layer = 15
	_badge = Label.new()
	_badge.position = Vector2(18, 16)
	_badge.add_theme_font_size_override("font_size", 14)
	_badge.add_theme_color_override("font_outline_color", Color("102531"))
	_badge.add_theme_constant_override("outline_size", 4)
	hud.add_child(_badge)
	if multiplayer.is_server(): save_world.call_deferred()
	_badge.text = "Sailing together • " + ("Captain" if multiplayer.is_server() else "Crew")

func _disable_local_systems(node: Node) -> void:
	if node is ShipStation:
		node.set_physics_process(false)
		node.set_process_unhandled_input(false)
	if node.name == "Cooking":
		node.set_process_unhandled_input(false)
	for child in node.get_children():
		_disable_local_systems(child)

@rpc("any_peer", "call_remote", "reliable", 0)
func ready_for_world() -> void:
	var id := multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and identities.has(id) and world_ready and not players.has(id):
		spawn_crew(id)
		_pending.erase(id)
		_send_snapshot()

func spawn_crew(id: int) -> void:
	if players.has(id):
		return
	var player: CharacterBody2D
	var service: InventoryService
	if id == 1:
		player = ship.get_node("Player")
		service = ship.get_node("InventorySystem")
	else:
		player = load("res://scenes/player.tscn").instantiate()
		player.name = "Crew_%d" % id
		var bag := PlayerInventory.new()
		bag.player_id = StringName("peer_%d" % id)
		player.player_inventory = bag
		ship.add_child(player)
		service = load("res://scenes/inventory/inventory_system.tscn").instantiate()
		service.name = "CrewInventory_%d" % id
		service.player_path = NodePath("../" + player.name)
		ship.add_child(service)
	players[id] = player
	services[id] = service
	service.network_id = id
	player.position = Vector2(-25 + (players.size() - 1) * 15, 75)
	player.show()
	player.collision_layer = 0 # Crew do not shove each other through the deck boundary.
	var label := Label.new()
	label.name = "CrewName"
	label.text = identities.get(id, {}).get("name", "Sailor")
	label.position = Vector2(-50, -42)
	label.size.x = 100
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	player.add_child(label)
	player.modulate = [Color.WHITE, Color("c1e4ff"), Color("ffdab8"), Color("d2f4be")][posmod(players.size() - 1, 4)]
	var local := id == local_id and not dedicated
	service.hud.visible = local
	service.hud.set_process(local)
	service.hud.set_process_unhandled_input(local)
	service.get_node("DeckItems").visible = local
	service.get_node("DeckItems").set_process(local)
	service.get_node("Spyglass").set_process(local)
	service.get_node("Spyglass").set_process_input(local)
	service.get_node("Spyglass").set_process_unhandled_input(local)
	var fishing: RodFishing = service.get_node("Fishing")
	fishing.set_process(false)
	fishing.set_process_input(local)
	fishing.set_process_unhandled_input(local)
	fishing.hud.set_process(local)
	fishing.hud.visible = false
	if not local:
		fishing.sound.voice.volume_db = -80
		fishing.sound.reel.volume_db = -80
	service.feedback.connect(func(message: String) -> void:
		if multiplayer.is_server() and id != local_id and identities.has(id):
			feedback.rpc_id(id, message))
	if multiplayer.is_server():
		var account: Dictionary = accounts.get(identities[id].token, {})
		player.health = clampi(int(account.get("health",15)),0,15)
		player.hunger = clampi(int(account.get("hunger",15)),0,15)
		player.hunger_clock = clampf(float(account.get("hunger_clock",0)),0,1)
		if account.has("inventory"):
			var slots: Array[Dictionary] = []
			slots.assign(account.inventory)
			service.inventory.restore(slots)
			VoyageState._starter_granted[service.inventory.player_id] = true
		else:
			VoyageState.grant_starter(service.inventory)
	if local:
		ship.player = player
		for station_name in ["Helm", "Sail", "Anchor", "Galley"]:
			ship.get_node(station_name).local_player = player
	inputs[id] = {"move": Vector2.ZERO, "held": false, "blocked": false, "stamp": Time.get_ticks_msec()}

@rpc("authority", "call_remote", "reliable", 0)
func feedback(message: String) -> void:
	if services.has(local_id):
		services[local_id].feedback.emit(message)
		var fishing: RodFishing = services[local_id].get_node("Fishing")
		if message.begins_with("Caught "):
			fishing.sound.play("catch")
			players[local_id].play_fishing_animation()
		elif message.begins_with("Line snapped"):
			fishing.sound.play("snap")

func command(kind: String, args: Dictionary = {}) -> void:
	if online and local_id != 1 and services.has(local_id) and kind == "fish":
		var fishing: RodFishing = services[local_id].get_node("Fishing")
		if fishing.state == RodFishing.State.BITE:
			args["attempt"] = fishing.attempt_id
			fishing.begin_local_hook()
		elif fishing.local_reeling:
			fishing.held = true
			return
	if not online or not world_ready:
		return
	if multiplayer.is_server():
		_handle_command(local_id, kind, args)
	else:
		request_command.rpc_id(1, kind, args)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_command(kind: String, args: Dictionary) -> void:
	if not multiplayer.is_server() or var_to_bytes(args).size() > 2048:
		return
	var id := multiplayer.get_remote_sender_id()
	if not _allow_command(id):
		return
	_handle_command(id, kind, args)

func _allow_command(id: int) -> bool:
	if not players.has(id):
		return false
	var now := Time.get_ticks_msec()
	var bucket: Dictionary = _rate.get(id, {"time": now, "count": 0})
	if now - int(bucket.time) > 1000:
		bucket = {"time": now, "count": 0}
	bucket.count += 1
	_rate[id] = bucket
	return bucket.count <= 40

func _handle_command(id: int, kind: String, args: Dictionary) -> void:
	if not players.has(id):
		return
	var player: CharacterBody2D = players[id]
	var service: InventoryService = services[id]
	var fishing: RodFishing = service.get_node("Fishing")
	if kind == "respawn":
		if player.health <= 0: ship.survival.respawn(id)
		return
	if player.health <= 0: return
	match kind:
		"eat":
			if int(args.get("revision", -1)) == service.view_revision and not inputs[id].get("blocked",false):
				ship.survival.eat(id, int(args.get("index", -1)))
		"select":
			service.hud.selected = clampi(int(args.get("index", 0)), 0, 3)
		"interact":
			if player.using_station:
				player.active_station.release_control()
				return
			if player.fishing_active:
				fishing.cancel()
				return
			if service.hud.storage_open or service.hud.grill_open:
				service.hud.close()
				return
			if service.grill_is_nearest():
				service.hud.grill_open = true
				player.inventory_open = true
				return
			if service.chest_is_nearest():
				service.hud.storage_open = true
				player.inventory_open = true
				return
			var nearest: ShipStation
			var distance := INF
			for node in ship.get_children():
				if node is ShipStation and node.can_interact(player) and node.global_position.distance_to(player.global_position) < distance:
					nearest = node
					distance = node.global_position.distance_to(player.global_position)
			if nearest != null:
				if not nearest.try_take_control(player):
					service.feedback.emit("That station is occupied.")

		"grill":
			ship.get_node("Cooking").handle(service, args)
		"close": service.hud.close()
		"sail_step":
			if player.active_station == ship.get_node("Sail"):
				ship.set_sail_level((ship.sail_level + 1) % 4)
		"fish_steps":
			if id != 1 and fishing.can_fish(): fishing.replay_steps(args)
		"fish":
			if inputs[id].get("blocked", false) or not fishing.can_fish():
				return
			if fishing.state == RodFishing.State.IDLE:
				var point: Variant = args.get("point")
				if point is Vector2 and point.is_finite():
					fishing.cast(point)
			elif fishing.state in [RodFishing.State.CASTING, RodFishing.State.WAITING]:
				fishing.finish(false, "Too soon! Recast and wait for a bite.", false)
			elif fishing.state == RodFishing.State.BITE:
				if id != 1 and int(args.get("attempt", -1)) != fishing.attempt_id: return
				fishing.replay_frame = 0
				fishing.hook_started = Time.get_ticks_msec()
				fishing.state = RodFishing.State.REELING
				fishing.fight.begin(fishing.fight_seed)
			inputs[id].held = true
		"cancel_fish": fishing.cancel()
		"transfer", "drag":
			if int(args.get("revision", -1)) != service.view_revision:
				service.feedback.emit("Items changed. Try again.")
				return
			applying = true
			if kind == "transfer":
				service.request(str(args.get("action", "")), int(args.get("index", -1)))
			else:
				var data := {"service_id": service.get_instance_id(), "revision": service.view_revision, "storage": bool(args.get("storage", false)), "index": int(args.get("index", -1))}
				service.request_drag(data, int(args.get("destination", -1)), bool(args.get("to_storage", false)))
			applying = false

@rpc("any_peer", "call_remote", "unreliable", 1)
func input_frame(direction: Vector2, held: bool, blocked: bool, sequence: int) -> void:
	if not multiplayer.is_server() or not direction.is_finite():
		return
	var id := multiplayer.get_remote_sender_id()
	if inputs.has(id) and sequence > int(inputs[id].get("sequence", -1)):
		inputs[id]["sequence"] = sequence
		inputs[id].merge({"move": direction.limit_length(), "held": held, "blocked": blocked, "stamp": Time.get_ticks_msec()}, true)

func _unhandled_input(event: InputEvent) -> void:
	if not online or not world_ready or PauseMenu.is_paused() or MapState.map_open:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		command("interact")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		if not event.is_echo():
			command("sail_step")

func _physics_process(delta: float) -> void:
	if not online:
		return
	if not world_ready:
		_connect_clock += delta
		if _connect_clock > 20:
			leave("Connection timed out.")
		return
	if players.has(local_id) and not dedicated:
		var blocked: bool = PauseMenu.is_paused() or MapState.map_open or not DisplayServer.window_is_focused()
		if DisplayServer.get_name() == "headless" or "--settings-test" in OS.get_cmdline_user_args():
			blocked = PauseMenu.is_paused() or MapState.map_open
		var move := Vector2.ZERO if blocked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var held: bool = not blocked and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if multiplayer.is_server():
			inputs[local_id].merge({"move": move, "held": held, "blocked": blocked, "stamp": Time.get_ticks_msec()}, true)
		else:
			_input_clock += delta
			_predict_local(move, delta)
			if _input_clock >= 0.05 or move != _last_local_move:
				_input_clock = 0
				input_frame.rpc_id(1, move, held, blocked, Engine.get_physics_frames())
			_last_local_move = move
	if not multiplayer.is_server():
		if services.has(local_id): services[local_id].get_node("Fishing").tick_local_fight(delta)
		_interpolate(delta)
		return
	for id: int in players:
		var player: CharacterBody2D = players[id]
		var service: InventoryService = services[id]
		var data: Dictionary = inputs[id]
		var blocked: bool = data.blocked or Time.get_ticks_msec() - int(data.stamp) > 750
		var move: Vector2 = Vector2.ZERO if blocked else data.move
		var fishing: RodFishing = service.get_node("Fishing")
		if blocked:
			fishing.cancel()
			service.hud.close()
			if player.using_station:
				player.active_station.release_control()
		if service.hud.storage_open and not service.near_storage():
			service.hud.close()
		if service.hud.grill_open and not ship.get_node("Cooking").near(service):
			service.hud.close()
		player.inventory_open = service.hud.storage_open or service.hud.grill_open
		if player.active_station == ship.get_node("Helm"):
			ship.set_wheel_angle(ship.wheel_angle_degrees + move.x * 165 * delta)
		elif player.active_station == ship.get_node("Sail"):
			ship.set_sail_angle(ship.sail_angle_degrees + move.x * 34 * delta)
		player.move_crew(move, delta)
		player.get_node("CrewName").rotation = -player.global_rotation
		ship.get_node("SwimAccess").update_crew(player)
		if fishing.state != RodFishing.State.IDLE:
			if not fishing.can_fish():
				fishing.cancel()
			else:
				fishing.held = data.held and not blocked
				if id != 1 and fishing.state == RodFishing.State.REELING:
					fishing.clock += delta
					fishing.queue_redraw()
					if Time.get_ticks_msec() - fishing.hook_started > 45000: fishing.cancel()
				else:
					var before := fishing.state
					fishing.advance(delta, fishing.held)
					if id != 1 and before != RodFishing.State.BITE and fishing.state == RodFishing.State.BITE:
						fishing.bite_left += 0.75 # Transport grace; local display stays responsive.
		service.server_pickups()
	_send_clock += delta
	_save_clock += delta
	if _send_clock >= 0.05:
		_send_clock = 0
		_send_snapshot()
	if _save_clock >= 20:
		_save_clock = 0
		save_world()
	for id: int in _pending.keys():
		if Time.get_ticks_msec() - int(_pending[id]) > 15000:
			multiplayer.multiplayer_peer.disconnect_peer(id)

func _send_snapshot() -> void:
	if not world_ready:
		return
	var crew := {}
	for id: int in players:
		var player: CharacterBody2D = players[id]
		var service: InventoryService = services[id]
		var fishing: RodFishing = service.get_node("Fishing")
		crew[id] = {"eat": player.eat_serial, "health": player.health, "hunger": player.hunger, "hurt": player.hurt_serial, "respawn": player.respawn_serial, "danger": player.danger_time, "ack": inputs[id].get("sequence", -1), "name": identities[id].name, "position": player.position, "outside": player.is_overboard, "land": player.on_land,
			"station": str(player.active_station.name) if player.using_station else "", "inventory": service.inventory.capture(),
			"selected": service.hud.selected, "chest": service.hud.storage_open, "grill_open": service.hud.grill_open, "revision": service.view_revision,
			"fish": {"attempt": fishing.attempt_id, "seed": fishing.fight_seed, "state": int(fishing.state), "target": fishing.target, "origin": fishing.cast_origin, "clock": fishing.clock,
				"progress": fishing.fight.progress, "tension": fishing.fight.tension, "green": fishing.fight.green_center,
				"width": fishing.fight.green_width, "danger": fishing.fight.danger, "held": fishing.held, "catches": fishing.visual_catches}}
	_snapshot_serial += 1
	var data := {"serial": _snapshot_serial, "position": ship.global_position, "rotation": ship.global_rotation, "wind": ship.wind_velocity,
		"sail": ship.sail_level, "trim": ship.sail_angle_degrees, "wheel": ship.wheel_angle_degrees, "anchor": ship.anchor_deployed,
		"discovered": MapState.discovered_islands, "seed": ship.world_seed, "survival": ship.survival.capture(), "crew": crew, "grill": ship.get_node("Cooking").capture(), "storage": VoyageState.get_ship_storage().capture(), "drops": VoyageState.floor_items.get("ship", {})}
	var packed := var_to_bytes(data).compress(FileAccess.COMPRESSION_GZIP)
	for id: int in identities:
		if id != 1 and players.has(id):
			if multiplayer.multiplayer_peer is HarborPeer and packed.size() < 64000:
				world_snapshot.rpc_id(id, packed)
			elif internet or "--snapshot-chunks" in OS.get_cmdline_user_args():
				var count := ceili(packed.size() / 850.0)
				for part in count:
					snapshot_part.rpc_id(id, _snapshot_serial, part, count, packed.slice(part * 850, (part + 1) * 850))
			elif packed.size() > 1100:
				large_snapshot.rpc_id(id, packed)
			else:
				world_snapshot.rpc_id(id, packed)

@rpc("authority", "call_remote", "unreliable", 2)
func world_snapshot(packed: PackedByteArray) -> void:
	var bytes := packed.decompress_dynamic(1048576, FileAccess.COMPRESSION_GZIP)
	var decoded: Variant = bytes_to_var(bytes)
	if decoded is Dictionary:
		apply_snapshot(decoded)

@rpc("authority", "call_remote", "unreliable", 2)
func snapshot_part(serial: int, index: int, count: int, bytes: PackedByteArray) -> void:
	if serial <= _received_serial or count < 1 or count > 128 or index < 0 or index >= count or bytes.size() > 850: return
	for old in _snapshot_parts.keys():
		if old < serial - 4: _snapshot_parts.erase(old)
	if not _snapshot_parts.has(serial): _snapshot_parts[serial] = {}
	_snapshot_parts[serial][index] = bytes
	if _snapshot_parts[serial].size() != count: return
	var packed := PackedByteArray()
	for part in count:
		if not _snapshot_parts[serial].has(part): return
		packed.append_array(_snapshot_parts[serial][part])
	_snapshot_parts.erase(serial)
	world_snapshot(packed)

@rpc("authority", "call_remote", "reliable", 2)
func large_snapshot(packed: PackedByteArray) -> void:
	world_snapshot(packed)

func apply_snapshot(data: Dictionary) -> void:
	if int(data.get("serial", -1)) <= _received_serial:
		return
	_received_serial = data.serial
	if not world_ready or multiplayer.is_server():
		return
	ship.rebuild_world(int(data.get("seed", ship.world_seed)))
	ship.survival.restore(data.get("survival", {}))
	var known_before := MapState.discovered_islands.size()
	MapState.discovered_islands.merge(data.get("discovered", {}), true)
	if known_before != MapState.discovered_islands.size(): MapState.changed.emit()
	_last_snapshot = data
	ship.get_node("Cooking").restore(data.get("grill", {}))
	for id: int in data.crew:
		if not players.has(id):
			identities[id] = {"name": data.crew[id].name}
			spawn_crew(id)
	for id: int in players.keys():
		if not data.crew.has(id):
			_remove_crew(id)
	var storage: Array[Dictionary] = []
	storage.assign(data.storage)
	VoyageState.get_ship_storage().restore(storage)
	var drops: Dictionary = VoyageState.floor_items.get("ship", {})
	drops.clear()
	drops.merge(data.drops, true)
	ship.wind_velocity = data.wind
	ship.set_sail_level(data.sail)
	ship.anchor_deployed = data.anchor
	for station_name in ["Helm", "Sail", "Anchor", "Galley"]:
		ship.get_node(station_name).operator = null
	for id: int in data.crew:
		var entry: Dictionary = data.crew[id]
		var player: CharacterBody2D = players[id]
		var service: InventoryService = services[id]
		var respawned: bool = player.respawn_serial != int(entry.get("respawn", 0))
		player.eat_serial = entry.get("eat", 0)
		player.health = entry.get("health", 15)
		player.hunger = entry.get("hunger", 15)
		player.hurt_serial = entry.get("hurt", 0)
		player.respawn_serial = entry.get("respawn", 0)
		player.danger_time = entry.get("danger", 0.0)
		var transition: bool = respawned or player.is_overboard != entry.outside or (str(player.active_station.name) if player.using_station else "") != entry.station
		player.set_overboard(entry.outside)
		player.update_land(entry.land)
		player.active_station = ship.get_node_or_null(NodePath(entry.station)) if entry.station != "" else null
		if player.using_station:
			player.active_station.operator = player
		var slots: Array[Dictionary] = []
		slots.assign(entry.inventory)
		service.inventory.restore(slots)
		service.hud.selected = entry.selected
		service.hud.storage_open = entry.chest
		service.hud.grill_open = entry.get("grill_open", false)
		player.inventory_open = entry.chest or service.hud.grill_open
		service.view_revision = entry.revision
		service.hud._refresh()
		var fishing: RodFishing = service.get_node("Fishing")
		var previous: int = fishing.state
		var fish: Dictionary = entry.fish
		if id != local_id and fishing.visual_catches != fish.catches and previous != RodFishing.State.IDLE:
			player.play_fishing_animation()
		var predicted := id == local_id and fishing.local_reeling and fishing.attempt_id == int(fish.attempt) and int(fish.state) != RodFishing.State.IDLE
		if not predicted:
			if id == local_id and fishing.local_reeling and int(fish.state) == RodFishing.State.IDLE:
				fishing.sound.play("catch" if int(fish.catches) > fishing.visual_catches else "snap")
			fishing.local_reeling = false
			fishing.local_done = false
			fishing.state = fish.state
			fishing.clock = fish.clock
			fishing.held = fish.held
			fishing.fight.progress = fish.progress
			fishing.fight.tension = fish.tension
			fishing.fight.green_center = fish.green
			fishing.fight.green_width = fish.width
			fishing.fight.danger = fish.danger
		fishing.visual_catches = fish.catches
		fishing.attempt_id = fish.attempt
		fishing.fight_seed = fish.seed
		fishing._cast_from_ship = false
		fishing.target = fish.target
		fishing.cast_origin = fish.origin
		player.fishing_active = fishing.state != 0
		if id == local_id:
			_reconcile_local(entry, transition)
			if not predicted:
				if previous != fish.state:
					if fish.state == RodFishing.State.CASTING: fishing.sound.play("cast")
					elif fish.state == RodFishing.State.WAITING: fishing.sound.play("splash")
					elif fish.state == RodFishing.State.BITE: fishing.sound.play("bite")
				fishing.sound.set_reeling(false)
		fishing.queue_redraw()

func _interpolate(delta: float) -> void:
	if _last_snapshot.is_empty():
		return
	var weight := 1.0 - exp(-18 * delta)
	ship.global_position = ship.global_position.lerp(_last_snapshot.position, weight) if ship.global_position.distance_to(_last_snapshot.position) < 500 else _last_snapshot.position
	ship.global_rotation = lerp_angle(ship.global_rotation, _last_snapshot.rotation, weight)
	MapState.update_player_position(ship.global_position)
	var local_player: Node = players.get(local_id)
	var station := str(local_player.active_station.name) if is_instance_valid(local_player) and local_player.using_station else ""
	# Interpolate remote controls instead of stepping them at snapshot frequency.
	if station != "Sail": ship.set_sail_angle(lerpf(ship.sail_angle_degrees, _last_snapshot.trim, weight))
	if station != "Helm": ship.set_wheel_angle(lerpf(ship.wheel_angle_degrees, _last_snapshot.wheel, weight))
	for id: int in players:
		if _last_snapshot.crew.has(id):
			var player: Node2D = players[id]
			var target: Vector2 = _last_snapshot.crew[id].position
			if id != local_id:
				player.position = player.position.lerp(target, weight) if player.position.distance_to(target) < 150 else target
			player.get_node("CrewName").rotation = -player.global_rotation

func _predict_local(move: Vector2, delta: float) -> void:
	var player: CharacterBody2D = players[local_id]
	var correction := _prediction_error * (1.0 - exp(-12.0 * delta))
	player.position += correction
	_prediction_error -= correction
	for frame: Dictionary in _prediction:
		frame.position += correction
	player.move_crew(move, delta)
	if player.active_station == ship.get_node("Sail"):
		ship.set_sail_angle(ship.sail_angle_degrees + move.x * 34.0 * delta)
	elif player.active_station == ship.get_node("Helm"):
		ship.set_wheel_angle(ship.wheel_angle_degrees + move.x * 165.0 * delta)
	_prediction.append({"sequence": Engine.get_physics_frames(), "position": player.position, "trim": ship.sail_angle_degrees, "wheel": ship.wheel_angle_degrees})
	if _prediction.size() > 120: _prediction.pop_front()

func _reconcile_local(entry: Dictionary, transition: bool) -> void:
	var player: CharacterBody2D = players[local_id]
	if transition or _prediction.is_empty() or player.position.distance_to(entry.position) > 150:
		player.position = entry.position
		_prediction.clear()
		_prediction_error = Vector2.ZERO
		ship.set_sail_angle(_last_snapshot.trim)
		ship.set_wheel_angle(_last_snapshot.wheel)
		return
	var ack := int(entry.get("ack", -1))
	var acknowledged: Dictionary = {}
	while not _prediction.is_empty() and int(_prediction[0].sequence) <= ack:
		acknowledged = _prediction.pop_front()
	if acknowledged.is_empty(): return
	_prediction_error = Vector2(entry.position) - Vector2(acknowledged.position)
	# Preserve controls applied since the acknowledged input, correcting only drift.
	if entry.station == "Sail":
		var error := float(_last_snapshot.trim) - float(acknowledged.trim)
		ship.set_sail_angle(ship.sail_angle_degrees + error * 0.25)
		for frame: Dictionary in _prediction: frame.trim += error * 0.25
	elif entry.station == "Helm":
		var error := float(_last_snapshot.wheel) - float(acknowledged.wheel)
		ship.set_wheel_angle(ship.wheel_angle_degrees + error * 0.25)
		for frame: Dictionary in _prediction: frame.wheel += error * 0.25

func _peer_left(id: int) -> void:
	if not online or not multiplayer.is_server():
		return
	_remember(id)
	_remove_crew(id)
	identities.erase(id)
	_pending.erase(id)
	_rate.erase(id)
	save_world()

func _remember(id: int) -> void:
	if identities.has(id) and services.has(id):
		accounts[identities[id].token] = {"name": identities[id].name, "inventory": services[id].inventory.capture(), "health": players[id].health, "hunger": players[id].hunger, "hunger_clock": players[id].hunger_clock}

func _remove_crew(id: int) -> void:
	if not players.has(id):
		return
	var player: CharacterBody2D = players[id]
	if player.using_station:
		player.active_station.release_control()
	services[id].queue_free()
	player.queue_free()
	players.erase(id)
	services.erase(id)
	inputs.erase(id)

func save_path() -> String:
	return VoyageSaves.path(VoyageSaves.selected)

func save_world() -> void:
	if not online or local_id != 1 or not world_ready or not is_instance_valid(ship):
		return
	for id: int in players:
		_remember(id)
	var data := {"discovered": MapState.discovered_islands, "seed": ship.world_seed, "version": PROTOCOL, "title": crew_title, "position": ship.global_position, "rotation": ship.global_rotation,
		"grill": ship.get_node("Cooking").capture(), "storage": VoyageState.get_ship_storage().capture(), "drops": VoyageState.floor_items.get("ship", {}), "accounts": accounts}
	if not VoyageSaves.store(data):
		set_status(VoyageSaves.last_error)
		if services.has(local_id): services[local_id].feedback.emit(VoyageSaves.last_error)

func load_world() -> void:
	var data := VoyageSaves.world(VoyageSaves.selected)
	if data.get("version") in [PROTOCOL, "holy-ship-coop-8", "holy-ship-coop-7", "holy-ship-coop-6", "holy-ship-coop-5", "holy-ship-coop-4", "holy-ship-coop-3", "holy-ship-coop-2", "holy-ship-coop-1"]:
		_restored = data
		accounts = data.get("accounts", {})

func leave(message: String = "") -> void:
	save_world()
	if internet:
		HarborService.leave()
	elif online:
		multiplayer.multiplayer_peer.close()
	if internet:
		EOSGRuntime.leave_lobby()
	internet = false
	_snapshot_parts.clear()
	online = false
	world_ready = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	services.clear()
	identities.clear()
	inputs.clear()
	_pending.clear()
	_rate.clear()
	_last_snapshot.clear()
	_prediction.clear()
	_prediction_error = Vector2.ZERO
	_last_local_move = Vector2.ZERO
	_received_serial = -1
	_connect_clock = 0
	local_id = 1
	PauseMenu.resume()
	set_status(message)
	if not dedicated:
		get_tree().change_scene_to_file.call_deferred("res://scenes/menus/title_screen.tscn")

func _exit_tree() -> void:
	save_world()
	if online: multiplayer.multiplayer_peer.close()

func _start_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		dedicated = true
		var port_number := DEFAULT_PORT
		var index := args.find("--port")
		if index >= 0 and index + 1 < args.size(): port_number = int(args[index + 1])
		var secret := OS.get_environment("HOLY_SHIP_PASSWORD")
		host_session("Server", port_number, secret, not "--new-world" in args)
