extends Node
## The island minigame checks. Started by tests/island_minigames.gd (it has to
## load after the autoloads, so it isn't run directly).

var failures: int = 0
var current_test: String = ""

const ISLANDS: Array[String] = [
	"res://scenes/island.tscn",
	"res://scenes/islands/treasure_island.tscn",
	"res://scenes/islands/crab_cove.tscn",
	"res://scenes/islands/coconut_squall.tscn",
	"res://scenes/islands/tiki_totems.tscn",
	"res://scenes/islands/timber_isle.tscn",
	"res://scenes/islands/skull_rock.tscn",
	"res://scenes/islands/smugglers_den.tscn",
	"res://scenes/islands/overgrown_isle.tscn",
	"res://scenes/islands/parrot_point.tscn",
	"res://scenes/islands/powder_keg_point.tscn",
	"res://scenes/islands/seagull_roost.tscn",
	"res://scenes/islands/turtle_beach.tscn",
	"res://scenes/islands/quicksand_flats.tscn",
	"res://scenes/islands/firefly_hollow.tscn",
	"res://scenes/islands/cannon_cove.tscn",
	"res://scenes/islands/mosquito_marsh.tscn",
	"res://scenes/islands/slippery_rocks.tscn",
	"res://scenes/islands/bee_hive_hill.tscn",
]


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("[%s] %s" % [current_test, message])


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().physics_frame
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	Input.parse_input_event(event)
	await get_tree().physics_frame


func _release_moves() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)


## Walks the player toward `target` with the real move keys. Returns true
## when it got within `tolerance` px. From the dock it first goes straight up
## the stairs, since the cliffs either side block a diagonal path.
func _walk_to(player: Node2D, target: Vector2, max_seconds: float = 8.0, tolerance: float = 6.0) -> bool:
	var top := _top_of_stairs()
	if player.global_position.y > top.y + 4.0 and target.y < top.y:
		await _walk_direct(player, Vector2(player.global_position.x, top.y), max_seconds * 0.5, 4.0)
	return await _walk_direct(player, target, max_seconds, tolerance)


## Where the dock stairs come out on top of the cliffs, on the current island.
func _top_of_stairs() -> Vector2:
	var scene := get_tree().current_scene
	if scene.scene_file_path == "res://scenes/island.tscn":
		return Vector2(0, 172)   # Coconut Island has its own, smaller art
	var terrain := scene.get_node_or_null(^"Terrain") as Node2D
	if terrain:
		return terrain.to_global(Vector2(0, 236))
	return Vector2(0, 236)   # Treasure Island: same art, drawn without Terrain


func _walk_direct(player: Node2D, target: Vector2, max_seconds: float, tolerance: float) -> bool:
	var elapsed := 0.0
	while elapsed < max_seconds:
		var offset := target - player.global_position
		if offset.length() <= tolerance:
			break
		_release_moves()
		if absf(offset.x) > tolerance * 0.5:
			Input.action_press("move_right" if offset.x > 0 else "move_left")
		if absf(offset.y) > tolerance * 0.5:
			Input.action_press("move_down" if offset.y > 0 else "move_up")
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()  # already scaled by time_scale
	_release_moves()
	await get_tree().physics_frame
	return player.global_position.distance_to(target) <= tolerance


func _load(path: String) -> IslandGame:
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await _frames(2)
	return get_tree().current_scene as IslandGame


func _inventory() -> PlayerInventory:
	return VoyageState.get_inventory(&"player_1")


func _run() -> void:
	Engine.time_scale = 4.0
	get_tree().create_timer(600.0).timeout.connect(func() -> void:
		push_error("Island test timed out")
		get_tree().quit(1))

	await _test_every_island_loads()
	await _test_cliffs()
	await _test_coconut_island()
	await _test_treasure_island()
	await _test_crab_cove()
	await _test_coconut_squall()
	await _test_tiki_totems()
	await _test_timber_isle()
	await _test_skull_rock()
	await _test_smugglers_den()
	await _test_overgrown_isle()
	await _test_parrot_point()
	await _test_powder_keg_point()
	await _test_seagull_roost()
	await _test_turtle_beach()
	await _test_quicksand_flats()
	await _test_firefly_hollow()
	await _test_cannon_cove()
	await _test_mosquito_marsh()
	await _test_slippery_rocks()
	await _test_bee_hive_hill()
	await _test_game_over_rows_back()
	await _test_inventory_survives_ship()

	print("Island minigames: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _test_every_island_loads() -> void:
	for path in ISLANDS:
		current_test = path.get_file()
		var game := await _load(path)
		_check(game != null, "Scene root must be an IslandGame")
		if game == null:
			continue
		_check(game.player != null and game.hud != null, "Player and HUD must be found")
		_check(game.is_running(), "The run must start")
		var terrain := game.get_node_or_null(^"Terrain") as IslandTerrain
		if terrain:
			_check(terrain.contains_point(game.player.global_position), "Player must start on land")
		game.try_escape()
		await _frames(2)
		_check(game.is_running(), "The rowboat must refuse to leave before the task is done")
		_check(game.hud.bag_label.visible and game.hud.bag_label.text.begins_with("Bag:"), "The HUD must show the bag")
		# Walking straight down the dock reaches the rowboat.
		var rowboat := game.get_node(^"Rowboat") as Area2D
		await _walk_to(game.player, rowboat.global_position, 6.0, 10.0)
		_check(rowboat.overlaps_body(game.player), "Player must be able to walk to the rowboat")
		_check(game.is_running(), "Reaching the rowboat early must not end the run")
		await _wait(0.3)


## Every island's cliffs are solid: you can't walk off the top of one, and
## the dock stairs still lead up.
func _test_cliffs() -> void:
	for path in ISLANDS:
		current_test = "cliffs on %s" % path.get_file()
		var game := await _load(path)
		var cliffs := game.find_child("Cliffs", true, false)
		_check((cliffs is StaticBody2D) and cliffs.get_child_count() >= 3, "The island must have cliffs")
		if not (cliffs is StaticBody2D):
			continue
		var top := _top_of_stairs()
		_check(await _walk_to(game.player, top + Vector2(0, -20), 6.0, 8.0), "The dock stairs must lead up the cliffs")
	# Walking off the cliff on the right of the stairs is blocked.
	current_test = "cliff edge"
	var edge_game := await _load("res://scenes/islands/crab_cove.tscn")
	var terrain := edge_game.get_node(^"Terrain") as IslandTerrain
	var above := terrain.to_global(Vector2(40, 235))
	var below := terrain.to_global(Vector2(40, 295))
	_check(terrain.contains_point(above) and terrain.contains_point(below), "Both sides of the cliff must be land")
	_check(terrain.is_on_cliff(terrain.to_global(Vector2(40, 277))), "The cliff face must not count as land")
	edge_game.player.global_position = above
	await _frames(2)
	await _walk_direct(edge_game.player, below, 2.0, 6.0)
	_check(edge_game.player.global_position.y < below.y - 20.0, "Walking off the cliff must be blocked")


func _test_coconut_island() -> void:
	current_test = "coconut island"
	var game := await _load("res://scenes/island.tscn") as CollectIsland
	var before := _inventory().get_quantity(&"coconut")
	var coconut: Node2D = null
	for candidate in get_tree().get_nodes_in_group("coconuts"):
		if coconut == null or game.player.global_position.distance_to(candidate.global_position) < game.player.global_position.distance_to(coconut.global_position):
			coconut = candidate
	await _walk_to(game.player, coconut.global_position, 10.0, 4.0)
	await _frames(3)
	_check(_inventory().get_quantity(&"coconut") == before + 1, "A picked-up coconut must go into the inventory")
	_check(game.collected_count == 1, "The coconut must count toward the objective")


func _test_treasure_island() -> void:
	current_test = "treasure island"
	var game := await _load("res://scenes/islands/treasure_island.tscn") as TreasureIsland
	var before := _inventory().get_quantity(&"gold_coin")
	game.player.global_position = game.treasure_position
	await _frames(1)
	game.dig()
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(game.treasure_found, "Digging on the treasure must find it")
	_check(gained >= 5 and gained <= 30, "Treasure must give 5-30 coins (got %d)" % gained)
	_check(game.hud.message_label.text.contains("%d coins collected!" % gained), "A coins pop-up must show")


func _test_crab_cove() -> void:
	current_test = "crab cove"
	var game := await _load("res://scenes/islands/crab_cove.tscn") as CrabCove
	_check(game.crabs.size() == 6, "Six crabs must spawn")
	# Crabs must flee from the player.
	var crab := game.crabs[0]
	var start := crab.global_position
	game.player.global_position = start + Vector2(40, 0)
	await _wait(0.4)
	_check(crab.global_position.x < start.x - 10.0, "A crab must run away from the player")
	var before := _inventory().get_quantity(&"crab_meat")
	for c in game.crabs:
		c.global_position = game.get_pen_rect().get_center()
		await _frames(2)
	_check(game.penned_count == 6 and game._is_objective_complete(), "Crabs inside the pen must count as penned")
	_check(_inventory().get_quantity(&"crab_meat") == before + 6, "Each penned crab must give crab meat")


func _test_coconut_squall() -> void:
	current_test = "coconut squall"
	var game := await _load("res://scenes/islands/coconut_squall.tscn") as CoconutSquall
	# Stop random coconuts so the checks below are deterministic.
	game._spawn_timer = INF
	game._falling.clear()
	game.keep_chance = 0.0
	game._land(game.player.global_position)
	_check(game.hits == 1, "A coconut landing on the player must hit")
	game._land(game.player.global_position)
	_check(game.hits == 1, "Just after a hit the player must be briefly safe")
	await _wait(2.0)
	_check(game.is_running(), "One hit must not lose")
	game.keep_chance = 1.0
	var spot := game.player.global_position + Vector2(0, -80)
	game._land(spot)
	await _frames(3)
	var before := _inventory().get_quantity(&"coconut")
	await _walk_to(game.player, spot, 4.0, 4.0)
	await _frames(3)
	_check(_inventory().get_quantity(&"coconut") == before + 1, "A whole fallen coconut must go into the inventory")
	game.time_remaining = 0.01
	await _frames(3)
	_check(game.storm_over and game.is_running(), "When time is up the storm must end, not the run")
	_check(game._is_objective_complete(), "Surviving must complete the island")


func _test_tiki_totems() -> void:
	current_test = "tiki totems"
	var game := await _load("res://scenes/islands/tiki_totems.tscn") as TikiTotems
	var before := _inventory().get_quantity(&"gold_coin")
	var safe := game.player.global_position
	for round_number in game.round_lengths.size():
		for wait in 200:
			if game.phase == TikiTotems.Phase.INPUT:
				break
			await get_tree().physics_frame
		_check(game.phase == TikiTotems.Phase.INPUT, "Pattern must finish playing (round %d)" % round_number)
		for tile in game.sequence.duplicate():
			game.player.global_position = safe
			await _frames(2)
			game.player.global_position = game._tiles[tile].global_position
			await _frames(2)
		game.player.global_position = safe
		await _frames(2)
	_check(game.phase == TikiTotems.Phase.DONE, "Getting every round right must win")
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(gained >= 5 and gained <= 30, "Tiki treasure must give 5-30 coins (got %d)" % gained)


func _test_timber_isle() -> void:
	current_test = "timber isle"
	var game := await _load("res://scenes/islands/timber_isle.tscn") as TimberIsle
	var before := _inventory().get_quantity(&"wood")
	for tree in 3:
		var target: Vector2 = game._trees[tree].global_position + Vector2(0, 24)
		var reached := await _walk_to(game.player, target, 10.0, 8.0)
		_check(reached, "Must be able to walk to tree %d" % tree)
		await _press("interact")
		_check(game.chopping_tree == tree, "E next to a tree must start chopping")
		# A miss costs time.
		var time_before := game.time_remaining
		game._meter_t = clampf(game._sweet_start - 0.1, 0.0, 1.0) if game._sweet_start > 0.15 else 0.99
		game._meter_dir = 0.0
		await _press("interact")
		_check(game.time_remaining < time_before - 1.0, "A miss must cost time")
		for chop in game.chops_per_tree:
			game._meter_t = game._sweet_start + game.sweet_spot_width / 2.0
			await _press("interact")
	_check(game.felled_count == 3 and game._is_objective_complete(), "Three felled trees must complete the island")
	_check(_inventory().get_quantity(&"wood") == before + 6, "Each tree must give 2 wood")


func _test_skull_rock() -> void:
	current_test = "skull rock"
	var game := await _load("res://scenes/islands/skull_rock.tscn") as SkullRock
	await _frames(2)
	var cell := func(c: int, r: int) -> Vector2: return game._cell_center(Vector2i(c, r))
	var entrance: Vector2 = cell.call(3, 4) + Vector2(0, 80)
	_check(await _walk_to(game.player, entrance, 10.0), "Must reach the courtyard entrance")
	# Solution: (2,2) left then up; (4,3) up, left, up; (5,3) up twice.
	# Each push: stand behind the boulder, then hold the key toward it.
	var pushes := [
		[Vector2i(4, 4), "move_up"],    # (4,3) -> (4,2)
		[Vector2i(3, 2), "move_left"],  # (2,2) -> (1,2)
		[Vector2i(1, 3), "move_up"],    # (1,2) -> (1,1)
		[Vector2i(5, 2), "move_left"],  # (4,2) -> (3,2)
		[Vector2i(3, 3), "move_up"],    # (3,2) -> (3,1)
		[Vector2i(5, 4), "move_up"],    # (5,3) -> (5,2)
		[Vector2i(5, 3), "move_up"],    # (5,2) -> (5,1)
	]
	var here := Vector2i(3, 4)
	_check(await _walk_to(game.player, cell.call(3, 4), 4.0), "Must step into the courtyard")
	for push in pushes:
		var stand: Vector2i = push[0]
		var ok := true
		for step in _grid_path(here, stand, game):
			ok = ok and await _walk_to(game.player, cell.call(step.x, step.y), 4.0, 5.0)
		here = stand
		_check(ok, "Must reach push spot %s" % stand)
		Input.action_press(push[1])
		await _wait(0.45)
		Input.action_release(push[1])
		await _wait(0.25)
	_check(game.gate_open, "Covering every plate must open the gate (boulders at %s)" % [game._boulder_cells])
	var before := _inventory().get_quantity(&"gold_coin")
	var reached := true
	for step in _grid_path(here, Vector2i(3, 0), game):
		reached = reached and await _walk_to(game.player, cell.call(step.x, step.y), 4.0, 5.0)
	reached = reached and await _walk_to(game.player, game._idol_position(), 6.0, 10.0)
	await _frames(2)
	_check(reached and game.idol_taken, "The idol must be reachable once the gate is open")
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(gained >= 5 and gained <= 30, "The idol must give 5-30 coins (got %d)" % gained)
	# Reset puts boulders back.
	var game2 := await _load("res://scenes/islands/skull_rock.tscn") as SkullRock
	await _frames(2)
	game2._push(0, Vector2i.LEFT)
	await _wait(0.3)
	game2._reset_boulders()
	_check(game2._boulder_cells == game2.boulder_cells, "Reset must put the boulders back")


## Shortest walk between two courtyard cells that doesn't touch a boulder.
func _grid_path(from: Vector2i, to: Vector2i, game: SkullRock) -> Array[Vector2i]:
	var came: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			break
		for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + step
			if next.x < 0 or next.y < 0 or next.x >= game.columns or next.y >= game.rows:
				continue
			if came.has(next) or game._boulder_cells.has(next):
				continue
			came[next] = cell
			queue.append(next)
	var path: Array[Vector2i] = []
	if not came.has(to):
		return path
	var at := to
	while at != from:
		path.push_front(at)
		at = came[at]
	return path


func _test_smugglers_den() -> void:
	current_test = "smugglers den"
	var game := await _load("res://scenes/islands/smugglers_den.tscn") as SmugglersDen
	_check(game._guards.size() == 3, "Three guards must patrol")
	var guard: Dictionary = game._guards[0]
	var guard_node: Node2D = guard.node
	var time_before := game.time_remaining
	game.player.global_position = guard_node.global_position + game._look_direction(guard) * 60.0
	await _wait(0.5)
	_check(game.times_spotted >= 1, "Standing in a guard's view must get you spotted")
	_check(game.player.global_position.distance_to(game._start_position) < 40.0, "Being spotted must send you back to the dock")
	_check(game.time_remaining < time_before - 3.0, "Being spotted must cost time")
	# A crate between guard and player blocks the view.
	var crate := game.get_node(^"World/Crates/Crate1") as Node2D
	_check(game._blocked(crate.global_position + Vector2(-60, 0), crate.global_position + Vector2(60, 0)), "Crates must block line of sight")
	var before := _inventory().get_quantity(&"gold_coin")
	for info in game._guards:
		info.wait = INF   # freeze guards facing away
		info.facing = Vector2.UP
	game.player.global_position = game._loot.global_position
	await _frames(3)
	_check(game.loot_taken, "Reaching the chest must take the loot")
	_check(_inventory().get_quantity(&"gold_coin") == before, "No coins until you escape with the loot")
	# Caught on the way out: the loot goes back in the chest.
	game._spotted()
	_check(not game.loot_taken, "Being spotted with the loot must return it to the chest")
	_check(game.player.global_position.distance_to(game._start_position) < 40.0, "Being spotted with the loot must send you back to the dock")
	game.try_escape()
	await _frames(2)
	_check(game.is_running(), "The rowboat must refuse to leave without the loot")
	# Take it again and reach the rowboat unseen.
	game.player.global_position = game._loot.global_position
	await _frames(3)
	_check(game.loot_taken, "The loot must be takeable again")
	game.win_delay_seconds = 0.0
	game.try_escape()
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(not game.is_running() and gained >= 5 and gained <= 30, "Escaping with the loot must win and give 5-30 coins (got %d)" % gained)
	await get_tree().scene_changed
	Ship.returning_from_island = false


func _test_overgrown_isle() -> void:
	current_test = "overgrown isle"
	var game := await _load("res://scenes/islands/overgrown_isle.tscn") as OvergrownIsle
	var entrance := game._cell_center(Vector2i(floori(game.columns / 2.0), game.rows - 1))
	var reached := await _walk_to(game.player, entrance + Vector2(0, game.cell_size), 8.0)
	reached = reached and await _walk_to(game.player, entrance, 3.0)
	_check(reached, "The maze entrance must be open from the beach")
	await _wait(1.0)
	_check(game._strength > 0.8, "It must be dark inside the maze")
	_check(game._compass_cell != Vector2i(floori(game.columns / 2.0), game.rows - 1), "The compass must not be at the entrance")
	game.player.global_position = game._cell_center(game._compass_cell)
	await _frames(3)
	_check(game.compass_found and _inventory().get_quantity(&"compass") == 1, "The compass must go into the inventory")


func _test_parrot_point() -> void:
	current_test = "parrot point"
	var game := await _load("res://scenes/islands/parrot_point.tscn") as ParrotPoint
	var inventory := _inventory()
	# Wrong delivery: nothing it wants.
	for fruit in [&"mango", &"banana", &"papaya"]:
		inventory.remove_item(fruit, inventory.get_quantity(fruit))
	await _walk_to(game.player, game._parrot.global_position + Vector2(0, 30), 8.0)
	var time_before := game.time_remaining
	await _press("interact")
	_check(game.time_remaining < time_before - 3.0, "Handing over nothing it wants must cost time")
	var water_before := inventory.get_quantity(&"fresh_water")
	for n in game.orders_needed:
		for fruit in game.order.keys():
			var bush: FruitBush = null
			for b in game._bushes:
				if b.fruit_id == fruit:
					bush = b
			_check(await _walk_to(game.player, bush.global_position + Vector2(0, 30), 10.0), "Must reach the %s bush" % fruit)
			for i in game.order[fruit]:
				await _press("interact")
		await _walk_to(game.player, game._parrot.global_position + Vector2(0, 30), 10.0)
		await _press("interact")
	_check(game.orders_done == game.orders_needed and game._is_objective_complete(), "Filling every order must complete the island")
	_check(inventory.get_quantity(&"fresh_water") == water_before + 2, "The parrot must reward fresh water")


## The voyage bag only holds 12 kinds of item, and the islands give out more
## kinds than that. Empty it (keeping coins, coconuts and the rod) so each
## island's reward has room.
func _make_room() -> void:
	var bag := _inventory()
	for item in bag.inventory.duplicate():
		if item.id not in [&"gold_coin", &"coconut", &"fishing_rod"]:
			bag.remove_item(item.id, bag.get_quantity(item.id))


func _test_powder_keg_point() -> void:
	current_test = "powder keg point"
	var game := await _load("res://scenes/islands/powder_keg_point.tscn") as PowderKegPoint
	_make_room()
	game._next_light = INF   # no random fuses during the checks
	var keg := game.light_random_fuse()
	_check(keg >= 0 and game.is_lit(keg), "A fuse must catch on a keg")
	var before := _inventory().get_quantity(&"gunpowder")
	game.player.global_position = game._kegs[keg].global_position + Vector2(0, 30)
	await _frames(2)
	await _press("interact")
	_check(not game.is_lit(keg) and game.stamped_count == 1, "E next to a burning keg must stamp it out")
	_check(_inventory().get_quantity(&"gunpowder") == before + 1, "A saved keg must give gunpowder")
	game.player.global_position = Vector2(0, 250)
	game.fuse_seconds = 0.1
	keg = game.light_random_fuse()
	await _wait(0.4)
	_check(game.blasts == 1 and game.is_running(), "A fuse that burns down must blow its keg, but one blast must not lose")
	game.time_remaining = 0.01
	await _frames(3)
	_check(game.all_clear and game.is_running() and game._is_objective_complete(), "Lasting until time's up must complete the island")


func _test_seagull_roost() -> void:
	current_test = "seagull roost"
	var game := await _load("res://scenes/islands/seagull_roost.tscn") as SeagullRoost
	_make_room()
	game._next_spawn = INF
	var gull := game.spawn_gull()
	game.player.global_position = game.gulls[gull]["pos"]
	await _frames(1)
	await _press("interact")
	_check(game.shooed_count == 1 and game.gulls[gull]["fleeing"], "E next to a gull must shoo it")
	var thief := game.spawn_gull()
	game.gulls[thief]["pos"] = game._rack.global_position
	await _frames(2)
	_check(game.fish_left == game.fish_on_rack - 1, "A gull reaching the rack must take a fish")
	_check(game.is_running(), "Losing one fish must not lose")
	var left := game.fish_left
	var before := _inventory().get_quantity(&"dried_fish")
	game.time_remaining = 0.01
	await _frames(3)
	_check(game.rack_safe and game._is_objective_complete(), "Lasting until time's up must complete the island")
	_check(_inventory().get_quantity(&"dried_fish") == before + left, "The fish left on the rack must go into the bag")


func _test_turtle_beach() -> void:
	current_test = "turtle beach"
	var game := await _load("res://scenes/islands/turtle_beach.tscn") as TurtleBeach
	_make_room()
	game._next_hatch = INF
	game._next_crab = INF
	_check(game.hatch() == 0 and game.turtles.size() == 1, "A hatchling must hatch")
	var crab := game.spawn_crab()
	game.crabs[crab]["pos"] = game.player.global_position + Vector2(10, 0)
	await _frames(2)
	_check(game.crabs[crab]["fleeing"], "Walking into a crab must chase it off")
	var hunter := game.spawn_crab()
	game.crabs[hunter]["pos"] = game.turtles[0]["pos"]
	await _frames(2)
	_check(game.lost_count == 1 and game.turtles.is_empty(), "A crab reaching a hatchling must snatch it")
	var before := _inventory().get_quantity(&"gold_coin")
	for i in game.turtles_needed:
		var turtle := game.hatch()
		game.turtles[turtle]["pos"] = game.turtles[turtle]["target"]
		await _frames(2)
	_check(game.saved_count == game.turtles_needed and game._is_objective_complete(), "Enough hatchlings in the sea must complete the island")
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(gained >= 5 and gained <= 30, "Turtle Beach must give 5-30 coins (got %d)" % gained)


func _test_quicksand_flats() -> void:
	current_test = "quicksand flats"
	var game := await _load("res://scenes/islands/quicksand_flats.tscn") as QuicksandFlats
	_make_room()
	_check(game.path[0].y == game.rows - 1 and game.path.back().y == 0, "The safe path must run from the bottom row to the top row")
	for i in range(1, game.path.size()):
		var step: Vector2i = game.path[i] - game.path[i - 1]
		_check(absi(step.x) + absi(step.y) == 1, "Each step of the safe path must be to a neighbouring square")
	var sand := Vector2i(-1, -1)
	for c in game.columns:
		if not game.is_firm(Vector2i(c, game.rows - 1)):
			sand = Vector2i(c, game.rows - 1)
	var time_before := game.time_remaining
	game.player.global_position = game.cell_center(sand)
	await _frames(2)
	_check(game.sink_count == 1, "Stepping on quicksand must sink you")
	_check(game.player.global_position.distance_to(game.entry_point()) < 10.0, "Sinking must send you back to the edge")
	_check(game.time_remaining < time_before - 2.0, "Sinking must cost time")
	var before := _inventory().get_quantity(&"gold_coin")
	for cell in game.path:
		game.player.global_position = game.cell_center(cell)
		await _frames(1)
	_check(game.chest_found and game.sink_count == 1, "Following the safe path must reach the chest without sinking")
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(gained >= 5 and gained <= 30, "The chest must give 5-30 coins (got %d)" % gained)


func _test_firefly_hollow() -> void:
	current_test = "firefly hollow"
	var game := await _load("res://scenes/islands/firefly_hollow.tscn") as FireflyHollow
	_make_room()
	_check(game.fireflies.size() == game.firefly_count, "Every firefly must spawn")
	_check(game._darkness != null, "The hollow must be dark")
	for fly in game.fireflies:
		fly["lit"] = false
		fly["timer"] = 1000.0
	game.player.global_position = game.fireflies[0]["pos"]
	_check(not game.swing_net() and game.caught_count == 0, "A dark firefly must slip away")
	var before := _inventory().get_quantity(&"glow_jar")
	for i in game.fireflies_needed:
		game.fireflies[0]["lit"] = true
		game.player.global_position = game.fireflies[0]["pos"]
		_check(game.swing_net(), "A glowing firefly must be caught")
	_check(game.jar_filled and game._is_objective_complete(), "Catching enough fireflies must complete the island")
	_check(_inventory().get_quantity(&"glow_jar") == before + 1, "A full jar must go into the bag")


func _test_cannon_cove() -> void:
	current_test = "cannon cove"
	var game := await _load("res://scenes/islands/cannon_cove.tscn") as CannonCove
	_make_room()
	_check(await _walk_to(game.player, game._cannon.global_position + Vector2(0, 36), 10.0, 8.0), "Must reach the cannon")
	await _press("interact")
	_check(game.phase == CannonCove.Phase.AIM, "E at the cannon must start aiming")
	await _press("interact")
	_check(game.phase == CannonCove.Phase.POWER, "E while aiming must lock the aim")
	game._power_dir = 0.0
	game.power_t = 0.5
	await _press("interact")
	_check(game.phase == CannonCove.Phase.FLYING, "E on the power bar must fire")
	# Park a raft where the ball comes down.
	game.rafts[0]["pos"] = game._ball_to
	game.rafts[0]["speed"] = 0.0
	var before := _inventory().get_quantity(&"cannonball")
	await _wait(game.flight_seconds + 0.3)
	_check(game.sunk_count == 1 and game.phase == CannonCove.Phase.AIM, "A ball landing on a raft must sink it")
	_check(_inventory().get_quantity(&"cannonball") == before + game.reward_per_raft, "A sunk raft must give cannonballs")
	game.aim_t = 0.0
	game.power_t = 1.0
	game.fire()
	await _wait(game.flight_seconds + 0.3)
	_check(game.sunk_count == 1, "A ball landing in open water must miss")
	for i in game.rafts_needed - 1:
		game._aim_dir = 0.0
		game.aim_t = 0.5
		game.power_t = 0.5
		var spot := game.landing_point(0.5, 0.5)
		game._add_raft(spot)
		var parked: Dictionary = game.rafts.back()
		parked["speed"] = 0.0
		game.fire()
		await _wait(game.flight_seconds + 0.3)
	_check(game._is_objective_complete() and game.phase == CannonCove.Phase.IDLE, "Sinking enough rafts must complete the island")
	_check(not game.player.get("using_station"), "Finishing must step you away from the cannon")


func _test_mosquito_marsh() -> void:
	current_test = "mosquito marsh"
	var game := await _load("res://scenes/islands/mosquito_marsh.tscn") as MosquitoMarsh
	_make_room()
	game._swarm_wait = INF
	game.player.global_position = game._torches[0].global_position + Vector2(0, 20)
	await _frames(2)
	Input.action_press("interact")
	await _wait(game.light_seconds * 0.5)
	_check(not game.lit[0] and game.light_progress > 0.0, "Holding E must take a moment to light the torch")
	await _wait(game.light_seconds)
	Input.action_release("interact")
	_check(game.lit[0], "Holding E at a torch must light it")
	game.player.global_position = Vector2(0, 220)
	game.swarm_position = game.player.global_position + Vector2(10, 0)
	game._swarm_wait = 0.0
	var time_before := game.time_remaining
	await _frames(2)
	_check(game.bites == 1 and game.is_running(), "The swarm reaching you must bite")
	_check(game.time_remaining < time_before - 2.0, "A bite must cost time")
	# The swarm can't fly into a lit torch's smoke.
	game._swarm_wait = 0.0
	game.player.global_position = game._torches[0].global_position
	game.swarm_position = game._torches[0].global_position + Vector2(game.smoke_radius + 30.0, 0)
	await _frames(4)
	_check(game.swarm_position.distance_to(game._torches[0].global_position) >= game.smoke_radius - 1.0, "Smoke must keep the swarm away")
	var before := _inventory().get_quantity(&"torch")
	for i in game.lit.size():
		game.light_torch(i)
	_check(game._is_objective_complete(), "Lighting every torch must complete the island")
	_check(_inventory().get_quantity(&"torch") == before + 1, "A torch must go into the bag")


func _test_slippery_rocks() -> void:
	current_test = "slippery rocks"
	var game := await _load("res://scenes/islands/slippery_rocks.tscn") as SlipperyRocks
	_make_room()
	_check(await _walk_to(game.player, game.cell_center(game.mat_cell()) + Vector2(0, 16), 8.0, 8.0), "The mat must be reachable from the dock")
	await _press("interact")
	_check(game.on_shelf and game.player.get("using_station"), "E at the mat must step onto the rocks")
	await _press("move_up")
	await _wait(0.6)
	_check(game.player_cell == Vector2i(game.mat_cell().x, 0), "Sliding up must carry you to the far edge")
	var time_before := game.time_remaining
	await _press("interact")
	_check(game.player_cell == game.mat_cell() and game.moves == 0, "E on the rocks must start over from the mat")
	_check(game.time_remaining < time_before - 1.0, "Starting over must cost time")
	var before := _inventory().get_quantity(&"gold_coin")
	for move in ["move_up", "move_right", "move_down", "move_right", "move_down", "move_left", "move_up"]:
		await _press(move)
		await _wait(0.6)
	_check(game.chest_opened and game.moves == game.par_moves, "The default layout must be solvable in par")
	_check(not game.on_shelf and not game.player.get("using_station"), "Opening the chest must step you off the rocks")
	var gained := _inventory().get_quantity(&"gold_coin") - before
	_check(gained >= 5 and gained <= 30, "The chest must give 5-30 coins (got %d)" % gained)


func _test_bee_hive_hill() -> void:
	current_test = "bee hive hill"
	var game := await _load("res://scenes/islands/bee_hive_hill.tscn") as BeeHiveHill
	_make_room()
	var before := _inventory().get_quantity(&"honey")
	game.player.global_position = game._hives[0].global_position + Vector2(0, 30)
	await _frames(2)
	await _press("interact")
	_check(game.robbed[0] and game.swarms.size() == 1, "E at a hive must take the honey and wake the bees")
	_check(_inventory().get_quantity(&"honey") == before + 1, "Honey must go into the bag")
	_check(game._trees.size() >= 10, "The island's painted trees must be the hiding spots")
	game.player.global_position = game._trees[0].global_position
	await _wait(game.wake_seconds + 0.3)
	_check(game.stings == 0 and (game.swarms.is_empty() or game.swarms[0]["returning"]), "Hiding behind a tree must lose the bees")
	game.player.global_position = Vector2(0, 220)
	game.take_honey(1)
	var swarm: Dictionary = game.swarms.back()
	swarm["wake"] = 0.0
	swarm["pos"] = game.player.global_position
	var time_before := game.time_remaining
	await _frames(2)
	_check(game.stings == 1 and game.is_running(), "Bees reaching you must sting")
	_check(game.time_remaining < time_before - 3.0, "A sting must cost time")
	for i in range(2, game.robbed.size()):
		game.take_honey(i)
	game.swarms.clear()
	_check(game._is_objective_complete(), "Honey from every hive must complete the island")
	_check(_inventory().get_quantity(&"honey") == before + game.robbed.size(), "Every hive must give honey")

func _test_game_over_rows_back() -> void:
	current_test = "game over"
	var game := await _load("res://scenes/island.tscn")
	var coins := _inventory().get_quantity(&"gold_coin")
	var coconuts := _inventory().get_quantity(&"coconut")
	game.give_item(&"coconut", 2)
	game.give_item(&"gold_coin", 3)
	_check(_inventory().get_quantity(&"coconut") == coconuts + 2, "Pickups must go into the bag during the run")
	game.lose_delay_seconds = 0.0
	game.lose("Test loss.")
	_check(_inventory().get_quantity(&"coconut") == coconuts and _inventory().get_quantity(&"gold_coin") == coins,
		"A game over must take back everything picked up on the island")
	await get_tree().scene_changed
	_check(get_tree().current_scene is Ship, "A game over must row back to the ship")
	Ship.returning_from_island = false
	Ship.last_visit_won = true
	await _frames(2)


func _test_inventory_survives_ship() -> void:
	current_test = "inventory across scenes"
	var coins := _inventory().get_quantity(&"gold_coin")
	_check(coins > 0, "Coins collected earlier must still be in the inventory")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await _frames(2)
	var ship := get_tree().current_scene.get_node("Ship") as Ship
	var inventory := ship.player.get("player_inventory") as PlayerInventory
	_check(inventory == _inventory(), "The ship's player must use the voyage inventory")
	_check(inventory.get_quantity(&"gold_coin") == coins, "Island coins must still be there on the ship")
	_check(ship.get_islands().size() == 19, "All nineteen islands must be on the map")
	_check(not ship.status_label.visible, "No nearest-island text while sailing")
	for island in ship.get_islands():
		_check(ResourceLoader.exists(island.scene), "%s must point at a real scene" % island.name)
