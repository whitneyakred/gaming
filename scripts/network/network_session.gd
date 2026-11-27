extends Node
## Desktop ENet co-op. Only the server changes world state and awards items.
signal status_changed(message: String)
const PROTOCOL := "holy-ship-coop-24"
var crew_markers: Dictionary = {}
var loading_overlay: VoyageLoading
const INPUT_REFRESH_INTERVAL := 0.5
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
var _prediction: Array[Dictionary] = []
var _prediction_error := Vector2.ZERO
var _trim_error := 0.0
var _wheel_error := 0.0
var _motion_buffer := preload("res://scripts/network/snapshot_buffer.gd").new()
var _last_local_move := Vector2.ZERO
var _last_local_held := false
var _last_local_blocked := false
var _pagehide_callback: JavaScriptObject
var _input_batch: Array[Dictionary] = []
var _crew_buffers: Dictionary = {}
var _shared := SharedSnapshotState.new()
var _shared_sent: Dictionary = {}
var _waiting_snapshot: Dictionary = {}
var diagnostics: Node
var last_correction := 0.0
var hard_corrections := 0
var transition_resets := 0
var distance_resets := 0
var snapshot_bytes := 0
var snapshot_apply_ms := 0.0
var snapshot_build_ms := 0.0
var snapshot_gap_ms := 0
var snapshot_received_at := 0
var invalid_packets := 0
var host_frame_ms := 0.0
var _frame_peak_ms := 0.0
var _bag_cache: Dictionary = {}
var _local_selection := -1
var _selection_dirty := false
var _selection_sent_at := 0
var _local_close_until := 0
const MAX_REPLAY_FRAMES := 60
var replayed_frames := 0
var replay_ms := 0.0
var _pending_access: Dictionary = {}
var _access_retry_at := 0
var access_rejections := 0
@export_range(10, 20) var snapshot_hz: int = 15

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 50
	# Gameplay is a host/guest star, never client-to-client RPC. Avoid ENet's
	# extra peer-relay notifications (including disconnect sends to closing peers).
	if multiplayer is SceneMultiplayer: multiplayer.server_relay = false
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
	var frequency_index := arguments.find("--snapshot-hz")
	if "--settings-test" in arguments and frequency_index >= 0 and frequency_index + 1 < arguments.size():
		snapshot_hz = clampi(int(arguments[frequency_index + 1]), 10, 20)
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
	diagnostics = preload("res://scripts/network/network_diagnostics.gd").new()
	add_child(diagnostics)
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
	loading_overlay = VoyageLoading.show_loading(get_tree())
	await get_tree().process_frame
	await get_tree().process_frame
	if not online:
		if is_instance_valid(loading_overlay): loading_overlay.queue_free()
		return
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
			ship.rebuild_world(int(_restored.get("seed", ship.world_seed)),int(_restored.get("layout_version",1)))
			ship.foliage.rebuild()
			if IslandFoliage.valid(_restored.get("foliage",{})): ship.foliage.restore(_restored.get("foliage",{}),true)
			MapState.restore_discoveries(_restored.get("discovered", {}))
			VoyageState.restore_quest(_restored.get("paradise_quest", {}))
			ship.global_position = _restored.get("position", Vector2.ZERO)
			ship.global_rotation = _restored.get("rotation", 0.0)
			if not _restored.has("seed") or not _restored.has("paradise_quest"):
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
			var port_slots: Array[Dictionary] = []
			port_slots.assign(_restored.get("port_storage", []))
			VoyageState.get_ship_storage(18, 1).restore(port_slots)
			if _restored.get("version", "") not in [PROTOCOL, "holy-ship-coop-23"]:
				VoyageState.get_ship_storage(18,1).add_items(ItemDatabase.get_item(&"pickaxe"),4)
			var drops: Dictionary = VoyageState.floor_items.get("ship", {})
			drops.merge(_restored.get("drops", {}), true)
			for key in drops.keys():
				if ItemDatabase.get_item(drops[key].get("id", &"")) == null: drops.erase(key)
			for entry: Dictionary in drops.values():
				entry.erase("spawn_origin")
				entry.erase("spawn_time")
			for key: int in drops:
				dropped_id = maxi(dropped_id, key + 1)
		ship.get_node("Cooking").restore(_restored.get("grill", {}))
		ship.get_node("Cooking").seed_fuel()
		ship.get_node("IslandChallenges").restore_cooldowns(_restored.get("totem_cooldowns",{}))
		if not dedicated:
			spawn_crew(1)
	else:
		ready_for_world.rpc_id(1)
	if multiplayer.is_server():
		save_world.call_deferred()
		if is_instance_valid(loading_overlay): loading_overlay.queue_free()

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
	player.modulate = Color.WHITE
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
	_crew_buffers[id] = CrewInputBuffer.new()

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
	if online and world_ready and local_id != 1 and services.has(local_id):
		if kind == "select":
			_local_selection = clampi(int(args.get("index", 0)), 0, 3)
			services[local_id].hud.selected = _local_selection
			_selection_dirty = true
			return # Coalesce scroll-wheel bursts; the highlight already changed locally.
		_flush_local_selection(true) # Equip before a subsequent cast/use on reliable channel 0.
		var hud = services[local_id].hud
		if kind == "close" or (kind == "interact" and (hud.storage_open or hud.grill_open)):
			hud.close()
			_local_close_until = Time.get_ticks_msec() + 2000
		elif kind == "interact":
			_local_close_until = 0
	if online and local_id != 1 and services.has(local_id) and kind == "fish":
		var fishing: RodFishing = services[local_id].get_node("Fishing")
		if fishing.state == RodFishing.State.IDLE and args.get("point") is Vector2:
			# Cosmetic prediction only: casting never grants items. The host still
			# validates the target and owns bite timing and the resulting attempt.
			if fishing.cast(args.point): fishing.pending_cast_until = Time.get_ticks_msec() + 1500
		elif fishing.state == RodFishing.State.BITE:
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

func _flush_local_selection(force: bool = false) -> void:
	if not _selection_dirty or _local_selection < 0: return
	var now := Time.get_ticks_msec()
	if not force and now - _selection_sent_at < 100: return
	request_command.rpc_id(1, "select", {"index": _local_selection})
	_selection_sent_at = now
	_selection_dirty = false

func _apply_hud_state(id: int, entry: Dictionary) -> void:
	var service: InventoryService = services[id]
	var selection := int(entry.selected)
	if id == local_id and _local_selection >= 0:
		# Selection is the owner's intent, not an inventory mutation. Retry if a
		# burst was rate limited, without ever flashing back to an old highlight.
		_selection_dirty = selection != _local_selection
		selection = _local_selection
	var changed: bool = service.hud.selected != selection
	service.hud.selected = selection
	service.select_chest(int(entry.get("chest_id", 0)))
	var closed: bool = not entry.chest and not entry.get("grill_open", false)
	if id == local_id and closed: _local_close_until = 0
	var closing := id == local_id and Time.get_ticks_msec() < _local_close_until
	service.hud.storage_open = entry.chest and not closing
	service.hud.grill_open = entry.get("grill_open", false) and not closing
	service.player.inventory_open = service.hud.storage_open or service.hud.grill_open
	if changed: service.hud._refresh()

@rpc("any_peer", "call_remote", "reliable", 0)
func request_command(kind: String, args: Dictionary) -> void:
	if not multiplayer.is_server() or var_to_bytes(args).size() > 2048 or not valid_command(args):
		return
	var id := multiplayer.get_remote_sender_id()
	# Replay has its own count, sequence and elapsed-time bounds. A delayed burst
	# must not lose a middle batch to the generic UI command rate limiter.
	if kind == "fish_steps" and players.has(id):
		_handle_command(id, kind, args)
		return
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
	if kind.begins_with("island_"):
		ship.get_node("IslandChallenges").handle(id, kind, args)
		return
	if player.island_challenge: return
	match kind:
		"chop":
			if args.get("point") is Vector2: ship.foliage.chop(service,args.point,int(args.get("index",-1)))
		"marker":
			if args.get("clear",false) is bool and args.get("clear",false): crew_markers.erase(id)
			elif args.get("point") is Vector2 and args.point.is_finite() and MapState.world_bounds.has_point(args.point): crew_markers[id] = args.point
			MapState.accept_markers(crew_markers)
		"medpack":
			ship.survival.medpack(id,str(args.get("action","")),int(args.get("index",-1)))
		"eat":
			if int(args.get("revision", -1)) == service.view_revision and not inputs[id].get("blocked",false):
				ship.survival.eat(id, int(args.get("index", -1)))
		"select":
			service.hud.selected = clampi(int(args.get("index", 0)), 0, 3)
		"interact":
			if ship.get_node("ParadiseJourney").interact(player): return
			var challenges := ship.get_node("IslandChallenges") as IslandChallenges
			var island := challenges.nearest(player)
			if island != null:
				challenges.try_start(id, str(island.name))
				return
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
				service.open_nearest_chest()
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
				fishing.finish(false, "", false)
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
				var data := {"service_id": service.get_instance_id(), "revision": service.view_revision, "storage": bool(args.get("storage", false)), "index": int(args.get("index", -1)), "amount": int(args.get("amount", -1))}
				service.request_drag(data, int(args.get("destination", -1)), bool(args.get("to_storage", false)))
			applying = false

@rpc("any_peer", "call_remote", "reliable", 1)
func input_frames(batch: Array) -> void:
	if not multiplayer.is_server(): return
	var id := multiplayer.get_remote_sender_id()
	if not _crew_buffers.has(id): return
	var buffer: CrewInputBuffer = _crew_buffers[id]
	if not buffer.append(batch):
		invalid_packets += 1
		if diagnostics.enabled: print("NETWORK INPUT REJECTED: ", buffer.last_rejection)
		return
	inputs[id].stamp = Time.get_ticks_msec()

func _move_input(player: CharacterBody2D, move: Vector2, delta: float) -> void:
	if player.active_station == ship.get_node("Helm"):
		ship.set_wheel_angle(ship.wheel_angle_degrees + move.x * 165.0 * delta)
	elif player.active_station == ship.get_node("Sail"):
		ship.set_sail_angle(ship.sail_angle_degrees + move.x * 34.0 * delta)
	player.move_crew(move, delta)

# The map suppresses walking, but does not release an occupied station.
func _map_blocks_movement() -> bool:
	var player: CharacterBody2D = players.get(local_id)
	return MapState.map_open and (not is_instance_valid(player) or not player.using_station)

func _unhandled_input(event: InputEvent) -> void:
	if IslandChallenges.local_active(): return
	if not online or not world_ready or PauseMenu.is_paused() or _map_blocks_movement():
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
	if multiplayer.multiplayer_peer is HarborPeer and not multiplayer.is_server():
		var packed := (multiplayer.multiplayer_peer as HarborPeer).take_world_snapshot()
		if not packed.is_empty(): world_snapshot(packed)
	if players.has(local_id) and not dedicated:
		var blocked: bool = PauseMenu.is_paused() or _map_blocks_movement() or not DisplayServer.window_is_focused()
		if DisplayServer.get_name() == "headless" or "--settings-test" in OS.get_cmdline_user_args():
			blocked = PauseMenu.is_paused() or _map_blocks_movement()
		blocked = blocked or IslandChallenges.local_active()
		var move := Vector2.ZERO if blocked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var held: bool = not blocked and not MapState.map_open and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if multiplayer.is_server():
			inputs[local_id].merge({"move": move, "held": held, "blocked": blocked, "stamp": Time.get_ticks_msec()}, true)
		else:
			_flush_local_selection()
			_input_clock += delta
			_predict_local(move, delta)
			# Stationary frames need no simulation. Keep just the newest neutral frame.
			if move == Vector2.ZERO and _last_local_move == Vector2.ZERO and not _input_batch.is_empty() and _input_batch.back().move == Vector2.ZERO:
				_input_batch.clear()
			_input_batch.append({"sequence": Engine.get_physics_frames(), "move": move, "held": held, "blocked": blocked})
			if input_needs_send(move, held, blocked) or _input_batch.size() >= 6:
				_input_clock = 0
				input_frames.rpc_id(1, _input_batch)
				_input_batch.clear()
			_last_local_move = move
			_last_local_held = held
			_last_local_blocked = blocked
	if not multiplayer.is_server():
		if services.has(local_id): services[local_id].get_node("Fishing").tick_local_fight(delta)
		_interpolate(delta)
		for id: int in services: services[id].get_node("Fishing").tick_presentation(delta)
		return
	for id: int in players:
		var player: CharacterBody2D = players[id]
		var service: InventoryService = services[id]
		var data: Dictionary = inputs[id]
		var playback: Array[Dictionary] = []
		if id != local_id:
			playback = (_crew_buffers[id] as CrewInputBuffer).take(delta)
			if not playback.is_empty():
				data.merge(playback.back(), true)
				data["ack"] = playback.back().sequence
		var blocked: bool = data.blocked or Time.get_ticks_msec() - int(data.stamp) > 1500
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
		if id == local_id:
			_move_input(player, move, delta)
		else:
			var before_visual: Vector2 = player.visual_position()
			var before_position: Vector2 = player.position
			player.velocity = Vector2.ZERO
			for frame: Dictionary in playback:
				_move_input(player, Vector2.ZERO if blocked or frame.blocked else frame.move, 1.0 / Engine.physics_ticks_per_second)
			if player.position != before_position:
				player.smooth_remote_motion(before_visual, float(playback.size()) / Engine.physics_ticks_per_second)
		player.get_node("CrewName").rotation = -player.global_rotation
		ship.get_node("SwimAccess").update_crew(player)
		if fishing.state != RodFishing.State.IDLE:
			if not fishing.can_fish():
				fishing.cancel()
			else:
				fishing.held = data.held and not blocked
				if id != 1 and fishing.state == RodFishing.State.REELING:
					fishing.clock += delta
					fishing.update_catch_visual(delta)
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
	var snapshot_interval := 1.0 / clampi(snapshot_hz, 10, 20)
	if _send_clock >= snapshot_interval:
		_send_clock = minf(_send_clock - snapshot_interval, snapshot_interval)
		_send_snapshot()
	if _save_clock >= 20:
		_save_clock = 0
		save_world()
	for id: int in _pending.keys():
		if Time.get_ticks_msec() - int(_pending[id]) > 15000:
			multiplayer.multiplayer_peer.disconnect_peer(id)

func input_needs_send(move: Vector2, held: bool, blocked: bool) -> bool:
	# Changes (including mouse release and focus loss) are never held for a timer.
	return _input_clock >= INPUT_REFRESH_INTERVAL or move != _last_local_move or held != _last_local_held or blocked != _last_local_blocked

func _send_snapshot() -> void:
	if not world_ready or players.size() <= (0 if dedicated else 1):
		return
	var build_started := Time.get_ticks_usec()
	var crew := {}
	for id: int in players:
		var player: CharacterBody2D = players[id]
		var service: InventoryService = services[id]
		var fishing: RodFishing = service.get_node("Fishing")
		crew[id] = {"chop":player.chop_serial,"chop_direction":player.chop_direction,"island_challenge": player.island_challenge, "heal":player.heal_serial,"splash":player.splash_serial,"splash_position":player.splash_position,"eat": player.eat_serial, "health": player.health, "hunger": player.hunger, "hurt": player.hurt_serial, "respawn": player.respawn_serial, "danger": player.danger_time, "ack": inputs[id].get("ack", inputs[id].get("sequence", -1)), "name": identities[id].name, "position": player.position, "outside": player.is_overboard, "land": player.on_land,
			"station": str(player.active_station.name) if player.using_station else "", "inventory": _capture_bag(service.inventory),
			"access_motion": player.access_motion, "access_progress": player.access_progress,
			"selected": service.hud.selected, "chest": service.hud.storage_open, "chest_id": service.active_chest_id, "grill_open": service.hud.grill_open, "revision": service.view_revision, "pickup_serial": service.pickup_serial, "drop_serial": service.drop_serial,
			"fish": {"catch_length":fishing.catch_length,"catch_angle":fishing.catch_angle,"catch_phase":fishing.catch_phase,"catch_speed":fishing.catch_speed,"catch_id": fishing.catch_id, "catch_species": fishing.catch_species, "catch_position": fishing.catch_position, "attached": fishing._cast_from_ship, "ship_target": fishing._ship_target, "ship_origin": fishing._ship_origin, "replay": fishing.replay_frame, "attempt": fishing.attempt_id, "seed": fishing.fight_seed, "state": int(fishing.state), "target": fishing.target, "origin": fishing.cast_origin, "clock": fishing.clock,
				"progress": fishing.fight.progress, "tension": fishing.fight.tension, "green": fishing.fight.green_center,
				"width": fishing.fight.green_width, "danger": fishing.fight.danger, "held": fishing.held, "catches": fishing.visual_catches}}
	_snapshot_serial += 1
	var data := {"serial": _snapshot_serial, "time": Time.get_ticks_msec() / 1000.0, "position": ship.global_position, "rotation": ship.global_rotation, "wind": ship.wind_velocity,
		"sail": ship.sail_level, "trim": ship.sail_angle_degrees, "wheel": ship.wheel_angle_degrees, "anchor": ship.anchor_deployed,
		"foliage":ship.foliage.changes,"markers": crew_markers.duplicate(), "fish_taken": ship.ocean_fish.taken.duplicate(), "fish_returns":ship.ocean_fish.returns.duplicate(true), "paradise_quest": VoyageState.quest_data(), "island_locks": ship.get_node("IslandChallenges").locks, "discovered": MapState.discovered_islands, "layout_version":ship.layout_version,"seed": ship.world_seed, "survival": ship.survival.capture(), "crew": crew, "grill": ship.get_node("Cooking").capture(), "storage": _capture_bag(VoyageState.get_ship_storage()), "port_storage": _capture_bag(VoyageState.get_ship_storage(18, 1)), "drops": VoyageState.floor_items.get("ship", {})}
	data["host_frame_ms"] = _frame_peak_ms
	_frame_peak_ms = 0.0
	_shared.extract(data)
	var shared_packet := PackedByteArray()
	for id: int in players:
		if id == 1 or _shared_sent.get(id, 0) == _shared.revision: continue
		if shared_packet.is_empty(): shared_packet = var_to_bytes(_shared.current).compress(FileAccess.COMPRESSION_GZIP)
		shared_state.rpc_id(id, _shared.revision, shared_packet)
		_shared_sent[id] = _shared.revision
	var packed := var_to_bytes(_shared.motion(data)).compress(FileAccess.COMPRESSION_GZIP)
	snapshot_bytes = packed.size()
	snapshot_build_ms = (Time.get_ticks_usec() - build_started) / 1000.0
	diagnostics.record_event("snapshot_sent", {"serial": _snapshot_serial, "host_time": data.time, "build_ms": snapshot_build_ms, "bytes": snapshot_bytes})
	if multiplayer.multiplayer_peer is HarborPeer and _pending.is_empty() and packed.size() < 64000:
		# One upload per crew; the relay fans it out. Pending peers must finish
		# the scene handshake before receiving RPCs for the gameplay scene.
		(multiplayer.multiplayer_peer as HarborPeer).send_world_snapshot(packed)
		return
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
	var started := Time.get_ticks_usec()
	var bytes := packed.decompress_dynamic(1048576, FileAccess.COMPRESSION_GZIP)
	var decoded: Variant = bytes_to_var(bytes)
	if decoded is Dictionary:
		if not decoded.get("serial") is int or int(decoded.serial) <= _received_serial: return
		var expanded := _shared.expand(decoded)
		if expanded.is_empty():
			_waiting_snapshot = decoded
			return
		apply_snapshot(expanded)
		snapshot_bytes = packed.size()
		snapshot_apply_ms = (Time.get_ticks_usec() - started) / 1000.0
	else: invalid_packets += 1

@rpc("authority", "call_remote", "reliable", 2)
func shared_state(revision: int, packed: PackedByteArray) -> void:
	if multiplayer.is_server() or packed.size() > 65536: return
	var decoded: Variant = bytes_to_var(packed.decompress_dynamic(1048576, FileAccess.COMPRESSION_GZIP))
	if not decoded is Dictionary or not _shared.accept(revision, decoded):
		invalid_packets += 1
		return
	if not _waiting_snapshot.is_empty():
		var expanded := _shared.expand(_waiting_snapshot)
		if not expanded.is_empty():
			_waiting_snapshot.clear()
			apply_snapshot(expanded)

@rpc("any_peer", "call_remote", "unreliable", 1)
func diagnostic_ping(stamp: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and players.has(id) and _allow_command(id): diagnostic_pong.rpc_id(id, stamp)

@rpc("authority", "call_remote", "unreliable", 1)
func diagnostic_pong(stamp: int) -> void:
	diagnostics.accept_ping_reply(stamp)

static func _fields(data: Dictionary, types: Dictionary) -> bool:
	for key: String in types:
		if not data.has(key) or typeof(data[key]) != types[key]: return false
		if data[key] is float and not is_finite(data[key]): return false
		if data[key] is Vector2 and not data[key].is_finite(): return false
	return true

static func _optional_fields(data: Dictionary, types: Dictionary) -> bool:
	for key: String in types:
		if data.has(key) and not _fields(data, {key: types[key]}): return false
	return true

static func valid_command(args: Dictionary) -> bool:
	return _optional_fields(args, {"clear": TYPE_BOOL, "stars": TYPE_INT, "index": TYPE_INT, "revision": TYPE_INT, "destination": TYPE_INT, "amount": TYPE_INT, "key": TYPE_INT, "attempt": TYPE_INT, "first": TYPE_INT, "count": TYPE_INT, "bits": TYPE_INT, "token": TYPE_INT, "point": TYPE_VECTOR2, "action": TYPE_STRING, "island": TYPE_STRING, "storage": TYPE_BOOL, "to_storage": TYPE_BOOL, "won": TYPE_BOOL, "prizes": TYPE_DICTIONARY})

func _capture_bag(bag: ShipInventory) -> Array[Dictionary]:
	var id := bag.get_instance_id()
	if not _bag_cache.has(id) or _bag_cache[id].revision != bag.revision:
		_bag_cache[id] = {"revision": bag.revision, "slots": bag.capture()}
	return _bag_cache[id].slots

static func valid_snapshot(data: Dictionary) -> bool:
	if not _fields(data, {"serial": TYPE_INT, "time": TYPE_FLOAT, "position": TYPE_VECTOR2, "rotation": TYPE_FLOAT, "wind": TYPE_VECTOR2, "trim": TYPE_FLOAT, "wheel": TYPE_FLOAT, "sail": TYPE_INT, "anchor": TYPE_BOOL, "crew": TYPE_DICTIONARY, "grill": TYPE_DICTIONARY, "survival": TYPE_DICTIONARY}): return false
	if data.crew.size() > MAX_CREW: return false
	for key: String in SharedSnapshotState.KEYS:
		if not data.has(key): return false
	var shared := {}
	for key: String in SharedSnapshotState.KEYS: shared[key] = data[key]
	shared["bags"] = {}
	if not SharedSnapshotState.valid(shared): return false
	if not _optional_fields(data, {"host_frame_ms": TYPE_FLOAT}): return false
	if not _fields(data.grill, {"fish": TYPE_ARRAY, "fuel": TYPE_DICTIONARY, "remaining": TYPE_FLOAT, "capacity": TYPE_FLOAT, "next_id": TYPE_INT, "starter": TYPE_BOOL}): return false
	if not _optional_fields(data.grill, {"active": TYPE_INT, "token": TYPE_INT, "stars": TYPE_INT}): return false
	if data.grill.fish.size() > 64 or not SharedSnapshotState.valid_slots([data.grill.fuel]): return false
	for fish: Variant in data.grill.fish:
		if not fish is Dictionary or not _fields(fish, {"key": TYPE_INT, "point": TYPE_VECTOR2, "progress": TYPE_FLOAT}): return false
	if not _fields(data.survival, {"sharks": TYPE_ARRAY, "danger": TYPE_FLOAT, "sink": TYPE_INT, "wreck": TYPE_VECTOR2, "wreck_rotation": TYPE_FLOAT}): return false
	if data.survival.sharks.size() > 32: return false
	for shark: Variant in data.survival.sharks:
		if not shark is Dictionary or not _fields(shark, {"position": TYPE_VECTOR2, "angle": TYPE_FLOAT, "size": TYPE_FLOAT, "alpha": TYPE_FLOAT, "active": TYPE_BOOL}): return false
	for id: Variant in data.crew:
		if not id is int or not data.crew[id] is Dictionary: return false
		var entry: Dictionary = data.crew[id]
		if not _fields(entry, {"name": TYPE_STRING, "position": TYPE_VECTOR2, "outside": TYPE_BOOL, "land": TYPE_BOOL, "station": TYPE_STRING, "selected": TYPE_INT, "chest": TYPE_BOOL, "revision": TYPE_INT, "fish": TYPE_DICTIONARY}): return false
		if entry.station not in ["", "Helm", "Sail", "Anchor", "Galley"] or not SharedSnapshotState.valid_slots(entry.get("inventory")): return false
		if not _optional_fields(entry, {"chop":TYPE_INT,"chop_direction":TYPE_VECTOR2,"heal":TYPE_INT,"splash":TYPE_INT,"splash_position":TYPE_VECTOR2,"ack": TYPE_INT, "health": TYPE_INT, "hunger": TYPE_INT, "eat": TYPE_INT, "hurt": TYPE_INT, "respawn": TYPE_INT, "danger": TYPE_FLOAT, "island_challenge": TYPE_BOOL, "access_motion": TYPE_STRING_NAME, "access_progress": TYPE_FLOAT, "chest_id": TYPE_INT, "grill_open": TYPE_BOOL, "pickup_serial": TYPE_INT, "drop_serial": TYPE_INT}): return false
		if not _fields(entry.fish, {"attempt": TYPE_INT, "seed": TYPE_INT, "state": TYPE_INT, "target": TYPE_VECTOR2, "origin": TYPE_VECTOR2, "clock": TYPE_FLOAT, "progress": TYPE_FLOAT, "tension": TYPE_FLOAT, "green": TYPE_FLOAT, "width": TYPE_FLOAT, "danger": TYPE_FLOAT, "held": TYPE_BOOL, "catches": TYPE_INT}): return false
		if not _optional_fields(entry.fish, {"catch_length":TYPE_FLOAT,"catch_angle":TYPE_FLOAT,"catch_phase":TYPE_FLOAT,"catch_speed":TYPE_FLOAT,"catch_id": TYPE_STRING, "catch_species": TYPE_INT, "catch_position": TYPE_VECTOR2}): return false
		if str(entry.fish.get("catch_id", "")).length() > 80 or int(entry.fish.get("catch_species", 0)) not in range(6): return false
		if entry.fish.state < 0 or entry.fish.state > RodFishing.State.REELING: return false
		if not _optional_fields(entry.fish, {"attached": TYPE_BOOL, "ship_target": TYPE_VECTOR2, "ship_origin": TYPE_VECTOR2, "replay": TYPE_INT}): return false
	return true

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
	if not valid_snapshot(data):
		invalid_packets += 1
		return
	if int(data.get("serial", -1)) <= _received_serial:
		return
	_received_serial = data.serial
	if not world_ready or multiplayer.is_server():
		return
	var now := Time.get_ticks_msec()
	if snapshot_received_at > 0: snapshot_gap_ms = now - snapshot_received_at
	snapshot_received_at = now
	diagnostics.record_event("snapshot_received", {"serial": data.serial, "host_time": data.time, "gap_ms": snapshot_gap_ms, "ack": data.crew.get(local_id, {}).get("ack", -1)})
	host_frame_ms = float(data.get("host_frame_ms", 0.0))
	if int(data.get("seed", ship.world_seed)) != ship.world_seed or data.layout_version != ship.layout_version:
		_motion_buffer.clear()
	ship.rebuild_world(int(data.get("seed", ship.world_seed)),int(data.layout_version))
	ship.foliage.rebuild()
	ship.foliage.restore(data.get("foliage",{}))
	# Fish locations are reconstructed from the existing seed and host timestamp.
	# Sprite animation, fading and rendering remain local; no per-fish packets.
	MapState.accept_markers(data.markers)
	ship.ocean_fish.taken = data.fish_taken.duplicate()
	ship.ocean_fish.returns = data.fish_returns.duplicate(true)
	if is_instance_valid(ship.ocean_fish): ship.ocean_fish.synchronize(float(data.get("time", 0.0)))
	ship.survival.restore(data.get("survival", {}))
	VoyageState.restore_quest(data.get("paradise_quest", {}))
	ship.get_node("IslandChallenges").locks = data.get("island_locks", {})
	var known_before := MapState.discovered_islands.size()
	MapState.discovered_islands.merge(data.get("discovered", {}), true)
	if known_before != MapState.discovered_islands.size(): MapState.changed.emit()
	if is_instance_valid(loading_overlay): loading_overlay.queue_free()
	_last_snapshot = data
	_motion_buffer.push(data)
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
	var port_slots: Array[Dictionary] = []
	port_slots.assign(data.get("port_storage", []))
	VoyageState.get_ship_storage(18, 1).restore(port_slots)
	var drops: Dictionary = VoyageState.floor_items.get("ship", {})
	if drops != data.drops:
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
		player.heal_serial = entry.get("heal",0)
		player.chop_serial = entry.get("chop",0)
		player.chop_direction = entry.get("chop_direction",Vector2.RIGHT)
		var splash_seen := player.has_meta("splash_seen")
		player.set_meta("splash_seen",true)
		if player.splash_serial != int(entry.get("splash",0)):
			player.splash_serial = entry.get("splash",0)
			if splash_seen and entry.get("splash_position") is Vector2:
				var splash := preload("res://scripts/visuals/water_splash.gd").new()
				ship.add_child(splash)
				splash.global_position = entry.splash_position
		player.island_challenge = entry.get("island_challenge", false)
		player.health = entry.get("health", 15)
		player.hunger = entry.get("hunger", 15)
		player.hurt_serial = entry.get("hurt", 0)
		player.respawn_serial = entry.get("respawn", 0)
		player.danger_time = entry.get("danger", 0.0)
		var transition: bool = respawned or player.is_overboard != entry.outside or player.on_land != entry.land or (str(player.active_station.name) if player.using_station else "") != entry.station
		var previous_access: StringName = player.access_motion
		var previous_progress: float = player.access_progress
		var hold_access := id == local_id and not respawned and _hold_predicted_access(entry)
		if respawned and id == local_id: _pending_access.clear()
		if not hold_access:
			player.set_overboard(entry.outside)
			player.access_motion = StringName(entry.get("access_motion", ""))
			player.access_progress = clampf(float(entry.get("access_progress", 0.0)), 0.0, 1.0)
		if id == local_id and not respawned and player.access_motion != &"" and player.access_motion == previous_access:
			player.access_progress = maxf(player.access_progress, previous_progress)
		player.update_land(entry.land)
		player.active_station = ship.get_node_or_null(NodePath(entry.station)) if entry.station != "" else null
		if player.using_station:
			player.active_station.operator = player
		var slots: Array[Dictionary] = []
		slots.assign(entry.inventory)
		service.inventory.restore(slots)
		_apply_hud_state(id, entry)
		service.view_revision = entry.revision
		var new_pickups: int = entry.get("pickup_serial", 0)
		if id == local_id and new_pickups > service.pickup_serial: GameWindow.play_ui("pickup")
		service.pickup_serial = new_pickups
		var new_drops: int = entry.get("drop_serial", 0)
		if id == local_id and new_drops > service.drop_serial: GameWindow.play_ui("drop")
		service.drop_serial = new_drops
		var fishing: RodFishing = service.get_node("Fishing")
		var previous: int = fishing.state
		var fish: Dictionary = entry.fish
		if id == local_id and fishing.pending_cast_until > Time.get_ticks_msec() and fish.attempt < fishing.attempt_id:
			_reconcile_local(entry, transition)
			continue
		fishing.pending_cast_until = 0
		if id != local_id and fishing.visual_catches != fish.catches and previous != RodFishing.State.IDLE:
			player.play_fishing_animation()
		var predicted := id == local_id and fishing.local_reeling and fishing.attempt_id == int(fish.attempt) and int(fish.state) != RodFishing.State.IDLE
		if not predicted:
			if id == local_id and fishing.local_reeling and int(fish.state) == RodFishing.State.IDLE:
				fishing.sound.play("catch" if int(fish.catches) > fishing.visual_catches else "snap")
			fishing.local_reeling = false
			fishing.local_done = false
			fishing.state = fish.state
			# Visual clocks advance between snapshots; only phase/attempt changes reset.
			if previous != fish.state or fishing.attempt_id != fish.attempt: fishing.clock = fish.clock
			fishing.held = fish.held
			fishing.fight.progress = fish.progress
			fishing.fight.tension = fish.tension
			fishing.fight.green_center = fish.green
			fishing.fight.green_width = fish.width
			fishing.fight.danger = fish.danger
		fishing.catch_id = fish.get("catch_id", "")
		fishing.catch_species = fish.get("catch_species", 0)
		fishing.catch_length = clampf(fish.get("catch_length",30.0),10.0,80.0)
		fishing.catch_angle = fish.get("catch_angle",0.0)
		fishing.catch_phase = fish.get("catch_phase",0.0)
		fishing.catch_speed = fish.get("catch_speed",30.0)
		fishing.catch_position = fish.get("catch_position", Vector2.ZERO)
		fishing.visual_catches = fish.catches
		fishing.attempt_id = fish.attempt
		fishing.fight_seed = fish.seed
		fishing._cast_from_ship = fish.get("attached", false)
		fishing._ship_target = fish.get("ship_target", Vector2.ZERO)
		fishing._ship_origin = fish.get("ship_origin", Vector2.ZERO)
		fishing.replay_frame = fish.get("replay", 0)
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
	var visual: Dictionary = _motion_buffer.sample(delta)
	if visual.is_empty(): return
	var weight := 1.0 - exp(-18 * delta)
	ship.global_position = visual.position
	ship.global_rotation = visual.rotation
	MapState.update_player_position(ship.global_position)
	var local_player: Node = players.get(local_id)
	var station := str(local_player.active_station.name) if is_instance_valid(local_player) and local_player.using_station else ""
	# Interpolate remote controls instead of stepping them at snapshot frequency.
	if station != "Sail": ship.set_sail_angle(rad_to_deg(lerp_angle(deg_to_rad(ship.sail_angle_degrees), deg_to_rad(visual.trim), weight)))
	if station != "Helm": ship.set_wheel_angle(lerpf(ship.wheel_angle_degrees, visual.wheel, weight))
	for id: int in players:
		if visual.crew.has(id):
			var player: Node2D = players[id]
			var target: Vector2 = visual.crew[id].position
			if id != local_id:
				var rendered: Dictionary = visual.crew[id]
				var current: Dictionary = _last_snapshot.crew[id]
				if rendered.get("outside") != current.get("outside") or rendered.get("station") != current.get("station") or rendered.get("respawn") != current.get("respawn"):
					target = current.position
				player.position = target
			player.get_node("CrewName").rotation = -player.global_rotation

func _predict_local(move: Vector2, delta: float) -> void:
	var player: CharacterBody2D = players[local_id]
	if player.access_motion != &"":
		ship.get_node("SwimAccess").advance_guest_access(player, delta)
		return
	if player.active_station != ship.get_node("Sail"): _trim_error = 0.0
	if player.active_station != ship.get_node("Helm"): _wheel_error = 0.0
	var control_weight := 1.0 - exp(-8.0 * delta)
	var trim_correction := _trim_error * control_weight
	var wheel_correction := _wheel_error * control_weight
	_trim_error -= trim_correction
	_wheel_error -= wheel_correction
	ship.set_sail_angle(ship.sail_angle_degrees + trim_correction)
	ship.set_wheel_angle(ship.wheel_angle_degrees + wheel_correction)
	for frame: Dictionary in _prediction:
		frame.trim += trim_correction
		frame.wheel += wheel_correction
	player.move_crew(move, delta)
	if player.active_station == ship.get_node("Sail"):
		ship.set_sail_angle(ship.sail_angle_degrees + move.x * 34.0 * delta)
	elif player.active_station == ship.get_node("Helm"):
		ship.set_wheel_angle(ship.wheel_angle_degrees + move.x * 165.0 * delta)
	_prediction.append({"sequence": Engine.get_physics_frames(), "move": move, "position": player.position, "trim": ship.sail_angle_degrees, "wheel": ship.wheel_angle_degrees})
	if _prediction.size() > 120: _prediction.pop_front()
	if online and Time.get_ticks_msec() >= _access_retry_at:
		var access: SwimAccess = ship.get_node("SwimAccess")
		var phase := access.candidate_phase(player)
		if phase != &"":
			_pending_access = {"phase": phase, "sequence": Engine.get_physics_frames(), "until": Time.get_ticks_msec() + 1500}
			access._begin_access(player, phase)

func _hold_predicted_access(entry: Dictionary) -> bool:
	if _pending_access.is_empty(): return false
	if entry.get("access_motion", &"") != &"":
		_pending_access.clear()
		return false
	if int(entry.get("health", 15)) > 0 and not entry.get("island_challenge", false) and entry.get("station", "") == "" and int(entry.get("ack", -1)) < int(_pending_access.sequence) and Time.get_ticks_msec() < int(_pending_access.until):
		return true
	_pending_access.clear()
	_access_retry_at = Time.get_ticks_msec() + 500
	access_rejections += 1
	return false

func _reconcile_local(entry: Dictionary, transition: bool) -> void:
	var player: CharacterBody2D = players[local_id]
	replayed_frames = 0
	if not _pending_access.is_empty(): return
	if player.access_motion != &"":
		_prediction.clear()
		_prediction_error = Vector2.ZERO
		_trim_error = 0.0
		_wheel_error = 0.0
		ship.get_node("SwimAccess").sync_guest_access(player, entry, Transform2D(float(_last_snapshot.rotation), Vector2(_last_snapshot.position)))
		return
	if transition or _prediction.is_empty() or player.position.distance_to(entry.position) > 150:
		if not _prediction.is_empty():
			hard_corrections += 1
			if transition: transition_resets += 1
			else: distance_resets += 1
		player.position = entry.position
		player.presentation_offset = Vector2.ZERO
		_prediction.clear()
		_prediction_error = Vector2.ZERO
		_trim_error = 0.0
		_wheel_error = 0.0
		ship.set_sail_angle(_last_snapshot.trim)
		ship.set_wheel_angle(_last_snapshot.wheel)
		return
	var ack := int(entry.get("ack", -1))
	var acknowledged: Dictionary = {}
	while not _prediction.is_empty() and int(_prediction[0].sequence) <= ack:
		acknowledged = _prediction.pop_front()
	if acknowledged.is_empty(): return
	var started := Time.get_ticks_usec()
	var previous_visual: Vector2 = player.visual_position()
	var previous_position := player.position
	player.position = entry.position
	replayed_frames = 0
	# Re-run only movement, never pickups, damage, sounds, or traversal events.
	# Large outages are bounded; do not spend an unbounded frame catching up.
	if _prediction.size() <= MAX_REPLAY_FRAMES:
		for frame: Dictionary in _prediction:
			player.move_crew(frame.get("move", Vector2.ZERO), 1.0 / Engine.physics_ticks_per_second)
			frame.position = player.position
			replayed_frames += 1
	else:
		_prediction.clear()
		distance_resets += 1
		hard_corrections += 1
	player.smooth_correction(previous_visual)
	last_correction = previous_position.distance_to(player.position)
	_prediction_error = Vector2.ZERO
	replay_ms = (Time.get_ticks_usec() - started) / 1000.0
	# Preserve controls applied since the acknowledged input, correcting only drift.
	if entry.station == "Sail":
		var error := wrapf(float(_last_snapshot.trim) - float(acknowledged.trim), -180.0, 180.0)
		_trim_error = error
	elif entry.station == "Helm":
		var error := float(_last_snapshot.wheel) - float(acknowledged.wheel)
		_wheel_error = error

func _peer_left(id: int) -> void:
	if not online or not multiplayer.is_server():
		return
	ship.survival.medical.erase(id)
	ship.get_node("Cooking").release_for(id)
	crew_markers.erase(id)
	MapState.accept_markers(crew_markers)
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
	if is_instance_valid(ship) and ship.has_node("IslandChallenges") and multiplayer.is_server():
		ship.get_node("IslandChallenges").release_player(id)
	if not players.has(id):
		return
	var player: CharacterBody2D = players[id]
	if player.using_station:
		player.active_station.release_control()
	services[id].queue_free()
	_bag_cache.erase(services[id].inventory.get_instance_id())
	player.queue_free()
	players.erase(id)
	services.erase(id)
	inputs.erase(id)
	_crew_buffers.erase(id)
	_shared_sent.erase(id)

func save_path() -> String:
	return VoyageSaves.path(VoyageSaves.selected)

func save_world() -> void:
	if not online or local_id != 1 or not world_ready or not is_instance_valid(ship):
		return
	for id: int in players:
		_remember(id)
	var data := {"foliage":ship.foliage.capture_save(),"totem_cooldowns":ship.get_node("IslandChallenges").capture_cooldowns(), "paradise_quest": VoyageState.quest_data(), "discovered": MapState.discovered_islands, "layout_version":ship.layout_version,"seed": ship.world_seed, "version": PROTOCOL, "title": crew_title, "position": ship.global_position, "rotation": ship.global_rotation,
		"grill": ship.get_node("Cooking").capture(), "storage": VoyageState.get_ship_storage().capture(), "port_storage": VoyageState.get_ship_storage(18, 1).capture(), "drops": VoyageState.floor_items.get("ship", {}), "accounts": accounts}
	if not VoyageSaves.store(data):
		set_status(VoyageSaves.last_error)
		if services.has(local_id): services[local_id].feedback.emit(VoyageSaves.last_error)

func load_world() -> void:
	var data := VoyageSaves.world(VoyageSaves.selected)
	if data.get("version") in [PROTOCOL, "holy-ship-coop-23", "holy-ship-coop-22", "holy-ship-coop-21", "holy-ship-coop-20", "holy-ship-coop-19", "holy-ship-coop-18", "holy-ship-coop-17", "holy-ship-coop-16", "holy-ship-coop-15", "holy-ship-coop-14", "holy-ship-coop-13", "holy-ship-coop-11", "holy-ship-coop-8", "holy-ship-coop-7", "holy-ship-coop-6", "holy-ship-coop-5", "holy-ship-coop-4", "holy-ship-coop-3", "holy-ship-coop-2", "holy-ship-coop-1"]:
		_restored = data
		accounts = data.get("accounts", {})

func leave(message: String = "") -> void:
	if is_instance_valid(loading_overlay): loading_overlay.queue_free()
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
	crew_markers.clear()
	players.clear()
	services.clear()
	identities.clear()
	inputs.clear()
	_crew_buffers.clear()
	_input_batch.clear()
	_shared = SharedSnapshotState.new()
	_shared_sent.clear()
	_bag_cache.clear()
	_local_selection = -1
	_selection_dirty = false
	_selection_sent_at = 0
	_local_close_until = 0
	_pending_access.clear()
	_access_retry_at = 0
	access_rejections = 0
	replayed_frames = 0
	replay_ms = 0.0
	_waiting_snapshot.clear()
	snapshot_received_at = 0
	last_correction = 0.0
	hard_corrections = 0
	transition_resets = 0
	distance_resets = 0
	invalid_packets = 0
	_pending.clear()
	_rate.clear()
	_last_snapshot.clear()
	_motion_buffer.clear()
	_trim_error = 0.0
	_wheel_error = 0.0
	_prediction.clear()
	_prediction_error = Vector2.ZERO
	_last_local_move = Vector2.ZERO
	_last_local_held = false
	_last_local_blocked = false
	_input_clock = 0.0
	_send_clock = 0.0
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

@rpc("authority", "call_remote", "reliable", 0)
func island_begin(island_id: String, token: int) -> void:
	if world_ready and is_instance_valid(ship):
		ship.get_node("IslandChallenges").begin_local(island_id, token)

@rpc("authority", "call_remote", "reliable", 0)
func island_end(token: int) -> void:
	if world_ready and is_instance_valid(ship):
		ship.get_node("IslandChallenges").close_local(token)
