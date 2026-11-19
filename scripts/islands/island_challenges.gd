class_name IslandChallenges
extends Node
## Host owns per-island reservations; original minigames run in a private viewport.
## Completion is client-reported (cooperative prototype), never a bag replacement.
const TOTEM := preload("res://scenes/islands/minigame_totem.tscn")
const MAX_RUN_SECONDS := 600.0
# Maximum accepted prizes per attempt, scoped to the original scene.
const PRIZES := {
	"island": {"coconut": 20}, "treasure_island": {"gold_coin": 30},
	"crab_cove": {"crab_meat": 12}, "coconut_squall": {"coconut": 100},
	"tiki_totems": {"gold_coin": 30}, "timber_isle": {"wood": 6},
	"skull_rock": {"gold_coin": 30}, "smugglers_den": {"gold_coin": 30},
	"overgrown_isle": {"compass": 1},
	"parrot_point": {"mango": 100, "banana": 100, "papaya": 100, "fresh_water": 2},
	"powder_keg_point": {"gunpowder": 100}, "seagull_roost": {"dried_fish": 8},
	"turtle_beach": {"gold_coin": 30}, "quicksand_flats": {"gold_coin": 30},
	"firefly_hollow": {"glow_jar": 6}, "cannon_cove": {"cannonball": 8},
	"mosquito_marsh": {"torch": 5}, "slippery_rocks": {"gold_coin": 30},
	"bee_hive_hill": {"honey": 4},
}
var locks: Dictionary = {}
var _serial: int = 0
var game: IslandGame
var _layer: CanvasLayer
var _viewport: SubViewport
var _token: int = 0
var _island_id: String = ""
var _waiting: bool = false
@onready var ship: Ship = get_parent()

static func local_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and tree.get_first_node_in_group("active_island_challenge") != null

func _ready() -> void:
	install_totems()

func install_totems() -> void:
	for island in ship.get_islands():
		if island.scene.is_empty() or island.has_node("MinigameTotem"): continue
		var totem := TOTEM.instantiate() as MinigameTotem
		island.add_child(totem)
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
		service_for(id).feedback.emit("This island's challenge is occupied. Wait for your turn.")
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
	if won and crew != null and crew.health > 0 and island != null and prizes is Dictionary:
		var limits: Dictionary = PRIZES.get(island.scene.get_file().get_basename(), {})
		var bag: PlayerInventory = crew.player_inventory
		var overflow := false
		for item_id in limits:
			if not prizes.get(item_id, 0) is int: continue
			var amount := clampi(int(prizes.get(item_id, 0)), 0, int(limits[item_id]))
			if amount == 0: continue
			var added := bag.add_items(ItemDatabase.get_item(StringName(item_id)), amount)
			if added < amount:
				# Keep prizes that don't fit as ordinary pickups beside the totem.
				service_for(id)._spawn_drop({"id": StringName(item_id), "quantity": amount - added}, crew.position)
				overflow = true
		service_for(id).feedback.emit("Challenge won! Extra prizes are beside the totem." if overflow else "Challenge won! Prizes added to your bag.")
	if NetworkSession.online and id != NetworkSession.local_id and id in multiplayer.get_peers():
		NetworkSession.island_end.rpc_id(id, token)
	else:
		close_local.call_deferred(token)

func release_player(id: int) -> void:
	for island_id in locks.keys():
		if int(locks[island_id].player) == id:
			finish(id, island_id, locks[island_id].token, false, {})

func _process(delta: float) -> void:
	if not NetworkSession.online or multiplayer.is_server():
		for island_id in locks.keys():
			var reservation: Dictionary = locks[island_id]
			reservation.seconds += delta
			var crew := crew_for(reservation.player)
			if crew == null or crew.health <= 0 or reservation.seconds >= MAX_RUN_SECONDS:
				finish(reservation.player, island_id, reservation.token, false, {})
	for island in ship.get_islands():
		var totem := island.get_node_or_null("MinigameTotem") as MinigameTotem
		if totem != null and totem.occupied != locks.has(str(island.name)):
			totem.set_occupied(locks.has(str(island.name)))
	if is_instance_valid(game):
		game.process_mode = Node.PROCESS_MODE_DISABLED if PauseMenu.is_paused() or _waiting else Node.PROCESS_MODE_INHERIT
		_viewport.size = Vector2i(get_viewport().get_visible_rect().size)

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
	_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	_layer.add_child(_viewport)
	var picture := TextureRect.new()
	picture.texture = _viewport.get_texture()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game = load(island.scene).instantiate() as IslandGame
	game.embedded = true
	var avatar := game.get_node(game.player_path) as CharacterBody2D
	avatar.minigame_avatar = true
	avatar.player_inventory = PlayerInventory.new()
	avatar.player_inventory.max_inv_space = 32
	game.embedded_finished.connect(_finished_local)
	_viewport.add_child(game)
	var back := Button.new()
	back.name = "LeaveChallenge"
	back.text = "Leave challenge (no prizes)"
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
	if won:
		for item_id in game.get_inventory().quantities:
			prizes[str(item_id)] = game.get_inventory().get_quantity(item_id)
	if NetworkSession.online:
		NetworkSession.command("island_finish", {"island": _island_id, "token": _token, "won": won, "prizes": prizes})
	else:
		finish(1, _island_id, _token, won, prizes)

func close_local(token: int) -> void:
	if token != _token: return
	remove_from_group("active_island_challenge")
	if is_instance_valid(_layer):
		_layer.queue_free()
	game = null
	_waiting = false
