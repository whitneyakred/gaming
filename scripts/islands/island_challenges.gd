class_name IslandChallenges
extends Node
## Host owns per-island reservations; original minigames run in a private viewport.
## Completion is client-reported (cooperative prototype), never a bag replacement.
const TOTEM := preload("res://scenes/islands/minigame_totem.tscn")
const MAX_RUN_SECONDS := 600.0
const REWARDS := [&"coal", &"string", &"leather", &"medpack", &"rope"]
const COOLDOWN := 300.0
var locks: Dictionary = {}
var _serial: int = 0
var game: IslandGame
var _layer: CanvasLayer
var _viewport: SubViewport
var _token: int = 0
var _island_id: String = ""
var _waiting: bool = false
var arena: Sprite2D
@onready var ship: Ship = get_parent()

static func local_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and tree.get_first_node_in_group("active_island_challenge") != null

func _ready() -> void:
	process_priority = 20 # Read the avatar after its render interpolation.
	install_totems()

func install_totems() -> void:
	for island in ship.get_islands():
		if island.scene.is_empty() or island.has_node("MinigameTotem"): continue
		var totem := TOTEM.instantiate() as MinigameTotem
		island.add_child(totem)
		if island is GeneratedIsland:
			totem.global_position = island.challenge_position()
			continue
		var coast := island.get_coast()
		var center := Vector2.ZERO
		for point in coast: center += point
		if not coast.is_empty(): center /= coast.size()
		# Concave coasts can put the average at sea. Pick a central land triangle.
		if not Geometry2D.is_point_in_polygon(center, coast):
			var triangles := Geometry2D.triangulate_polygon(coast)
			var distance := INF
			for i in range(0, triangles.size(), 3):
				var candidate := (coast[triangles[i]] + coast[triangles[i + 1]] + coast[triangles[i + 2]]) / 3.0
				if candidate.distance_squared_to(center) < distance:
					distance = candidate.distance_squared_to(center)
					totem.global_position = candidate
		else:
			totem.global_position = center
		totem.global_scale = Vector2.ONE
	if is_instance_valid(ship.foliage): ship.foliage.rebuild_collision()

func crew_for(id: int) -> CharacterBody2D:
	return NetworkSession.players.get(id) if NetworkSession.online else ship.player

func service_for(id: int) -> InventoryService:
	return NetworkSession.services.get(id) if NetworkSession.online else ship.get_node("InventorySystem")

func nearest(crew: CharacterBody2D) -> WorldIsland:
	if crew == null or not crew.on_land: return null
	var best: WorldIsland
	var distance := INF
	for island in ship.get_islands():
		var totem := island.get_node_or_null("MinigameTotem") as MinigameTotem
		if totem == null: continue
		var gap := crew.global_position.distance_to(totem.global_position)
		if gap <= totem.interaction_distance and gap < distance:
			best = island
			distance = gap
	return best

func try_start(id: int, island_id: String) -> bool:
	var crew := crew_for(id)
	var island := ship.get_island(StringName(island_id))
	if crew == null or island == null or crew.health <= 0 or crew.island_challenge or crew.using_station or crew.fishing_active or crew.inventory_open: return false
	if nearest(crew) != island: return false
	if locks.has(island_id):
		service_for(id).feedback.emit("This totem is resting or in use.")
		return false
	_serial += 1
	locks[island_id] = {"player": id, "token": _serial, "seconds": 0.0}
	crew.island_challenge = true
	crew.velocity = Vector2.ZERO
	service_for(id).hud.close()
	if NetworkSession.online and id != NetworkSession.local_id:
		NetworkSession.island_begin.rpc_id(id, island_id, _serial)
	else:
		begin_local.call_deferred(island_id, _serial)
	return true

func handle(id: int, kind: String, args: Dictionary) -> void:
	if kind == "island_start":
		try_start(id, str(args.get("island", "")))
	elif kind in ["island_finish", "island_cancel"]:
		finish(id, str(args.get("island", "")), int(args.get("token", -1)), kind == "island_finish" and bool(args.get("won", false)), args.get("prizes", {}))

func finish(id: int, island_id: String, token: int, won: bool, prizes: Variant) -> void:
	var reservation: Dictionary = locks.get(island_id, {})
	if reservation.get("player", -1) != id or reservation.get("token", -1) != token: return
	var island := ship.get_island(StringName(island_id))
	var crew := crew_for(id)
	# Release first: duplicate result packets cannot grant a second reward.
	locks.erase(island_id)
	if crew != null: crew.island_challenge = false
	if won and crew != null and crew.health > 0 and island != null:
		var pool: Array = REWARDS.duplicate()
		pool.shuffle()
		var service := service_for(id)
		var origin: Vector2 = island.get_node("MinigameTotem").global_position
		for i in 2:
			var item: StringName = pool[i]
			var amount := 1 if item == &"medpack" else randi_range(1,3)
			var drop_id := NetworkSession.dropped_id if NetworkSession.online else service.next_drop_id
			service._spawn_drop({"id":item,"quantity":amount},origin+Vector2(-54 if i==0 else 54,0))
			service.drops[drop_id]["world"] = true
			service.drops[drop_id]["spawn_origin"] = origin
			service.drops[drop_id]["spawn_time"] = ship.ocean_fish.shared_time()
		locks[island_id] = {"player":0,"token":token,"seconds":0.0,"until":ship.ocean_fish.shared_time()+COOLDOWN}
		service.feedback.emit("Totem complete!")
	if NetworkSession.online and id != NetworkSession.local_id and id in multiplayer.get_peers():
		NetworkSession.island_end.rpc_id(id, token)
	else:
		close_local.call_deferred(token)

func capture_cooldowns() -> Dictionary:
	var saved := {}
	for id in locks:
		if locks[id].get("player",-1) == 0:
			saved[id] = Time.get_unix_time_from_system()+maxf(0,float(locks[id].until)-ship.ocean_fish.shared_time())
	return saved

func restore_cooldowns(saved: Variant) -> void:
	if not saved is Dictionary: return
	for id in saved:
		if not id is String or not saved[id] is float or not is_finite(saved[id]): continue
		var seconds := clampf(saved[id]-Time.get_unix_time_from_system(),0,COOLDOWN)
		if seconds > 0 and ship.get_island(StringName(id)) != null:
			locks[id] = {"player":0,"token":0,"seconds":0.0,"until":ship.ocean_fish.shared_time()+seconds}

func release_player(id: int) -> void:
	for island_id in locks.keys():
		if int(locks[island_id].player) == id:
			finish(id, island_id, locks[island_id].token, false, {})

func _process(delta: float) -> void:
	if not NetworkSession.online or multiplayer.is_server():
		for island_id in locks.keys():
			var reservation: Dictionary = locks[island_id]
			if reservation.get("player",0) == 0:
				if ship.ocean_fish.shared_time() >= float(reservation.get("until",0.0)): locks.erase(island_id)
				continue
			reservation.seconds += delta
			var crew := crew_for(reservation.player)
			if crew == null or crew.health <= 0 or reservation.seconds >= MAX_RUN_SECONDS:
				finish(reservation.player, island_id, reservation.token, false, {})
	for island in ship.get_islands():
		var totem := island.get_node_or_null("MinigameTotem") as MinigameTotem
		if totem != null:
			var reservation: Dictionary = locks.get(str(island.name),{})
			totem.set_cooldown(maxf(0,float(reservation.get("until",0.0))-ship.ocean_fish.shared_time()))
		if totem != null and totem.occupied != locks.has(str(island.name)):
			totem.set_occupied(locks.has(str(island.name)))
	if is_instance_valid(game):
		game.process_mode = Node.PROCESS_MODE_DISABLED if PauseMenu.is_paused() or _waiting else Node.PROCESS_MODE_INHERIT
		if is_instance_valid(game.player):
			ship._view.challenge_center = arena.to_global(game.player.visual_position())

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game) or PauseMenu.is_paused(): return
	if event.is_action("pause") or event.is_action("ui_cancel"): return
	if event is InputEventKey or event is InputEventAction:
		if not _waiting: _viewport.push_input(event, true)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if NetworkSession.online or local_active() or PauseMenu.is_paused() or MapState.map_open: return
	if event.is_action_pressed("interact") and not event.is_echo():
		var island := nearest(ship.player)
		if island != null:
			try_start(1, str(island.name))
			get_viewport().set_input_as_handled()

func begin_local(island_id: String, token: int) -> void:
	if is_instance_valid(game): return
	var island := ship.get_island(StringName(island_id))
	if island == null: return
	_island_id = island_id
	_token = token
	_waiting = false
	add_to_group("active_island_challenge")
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 1040)
	_viewport.transparent_bg = true
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	_layer.add_child(_viewport)
	arena = Sprite2D.new()
	arena.texture = _viewport.get_texture()
	arena.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ship.add_child(arena)
	arena.set_as_top_level(true)
	arena.global_position = island.get_node("MinigameTotem").global_position
	arena.scale = Vector2.ONE
	arena.z_index = 31
	ship._view.challenge_center = arena.global_position
	game = load(island.scene).instantiate() as IslandGame
	game.embedded = true
	game.win_delay_seconds = 0.35
	if game is CollectIsland:
		_viewport.size = Vector2i(720, 640)
		for child in game.get_node("World").get_children():
			if child is Sprite2D:
				child.texture = IslandFoliage.icon(3 if String(child.name).begins_with("Palm") else 0)
				child.region_enabled = false
				child.hframes = 1
				child.vframes = 1
				child.scale = Vector2.ONE * (90.0 / child.texture.get_width())
				child.centered = false
				child.offset = -child.texture.get_size()*Vector2(0.5,0.94)
				add_trunk(game.get_node("World"),child.position)
	# Invisible cover from the old painted island must become visible props.
	if game is BeeHiveHill:
		for marker in game.get_node("Terrain/Trees").get_children():
			var tree := Sprite2D.new()
			tree.texture = IslandFoliage.icon(0)
			tree.scale = Vector2.ONE * (110.0 / tree.texture.get_width())
			tree.centered = false
			tree.offset = -tree.texture.get_size()*Vector2(0.5,0.94)
			marker.add_child(tree)
			add_trunk(marker,Vector2.ZERO)
	var exit_area := game.get_node_or_null("Rowboat")
	if exit_area != null:
		game.remove_child(exit_area)
		exit_area.queue_free()
	var terrain := game.get_node_or_null("Terrain") as IslandTerrain
	if terrain == null:
		# Coconut and treasure predate IslandTerrain and embed their scenery.
		for path in ["Sprite2D", "IslandBoundary", "Cliffs", "TreeTrunks", "World/Trees", "Camera2D"]:
			var legacy := game.get_node_or_null(path)
			if legacy != null:
				legacy.get_parent().remove_child(legacy)
				legacy.queue_free()
		terrain = IslandTerrain.new()
		terrain.name = "Terrain"
		game.add_child(terrain)
	if terrain != null:
		terrain.clearing = true
		if game is CollectIsland: terrain.clearing_half_size = Vector2(320,280)
		terrain.scale = Vector2.ONE
	var ocean := game.get_node_or_null("Ocean")
	if ocean != null:
		game.remove_child(ocean)
		ocean.queue_free()
	var avatar := game.get_node(game.player_path) as CharacterBody2D
	for child in avatar.get_children():
		if child is Camera2D: child.enabled = false
	avatar.minigame_avatar = true
	avatar.player_inventory = PlayerInventory.new()
	avatar.player_inventory.max_inv_space = 32
	game.embedded_finished.connect(_finished_local)
	_viewport.add_child(game)
	var camera := Camera2D.new()
	_viewport.add_child(camera)
	camera.make_current()
	if game.hud != null: game.hud.reparent(_layer)
	ship.player.presentation.visible = false
	island.get_node("MinigameTotem").hide()
	var back := Button.new()
	back.name = "LeaveChallenge"
	back.text = "Leave"
	back.theme = HarborTheme.menu_theme()
	back.pressed.connect(func() -> void: _finished_local(false))
	_layer.add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -300
	back.offset_top = 16
	back.offset_right = -20
	back.offset_bottom = 54

func _finished_local(won: bool) -> void:
	if _waiting or not is_instance_valid(game): return
	_waiting = true
	var prizes := {}
	if NetworkSession.online:
		NetworkSession.command("island_finish", {"island": _island_id, "token": _token, "won": won, "prizes": prizes})
	else:
		finish(1, _island_id, _token, won, prizes)

func add_trunk(parent: Node, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	body.add_child(shape)
	parent.add_child(body)

func close_local(token: int) -> void:
	if token != _token: return
	remove_from_group("active_island_challenge")
	if is_instance_valid(arena): arena.queue_free()
	ship._view.challenge_center = Vector2.INF
	ship.player.presentation.visible = true
	var island := ship.get_island(StringName(_island_id))
	if island != null: island.get_node("MinigameTotem").show()
	if is_instance_valid(_layer):
		_layer.queue_free()
	game = null
	_waiting = false
