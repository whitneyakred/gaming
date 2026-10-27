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
## when it got within `tolerance` px.
func _walk_to(player: Node2D, target: Vector2, max_seconds: float = 8.0, tolerance: float = 6.0) -> bool:
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
	_check(ship.get_islands().size() == 10, "All ten islands must be on the map")
	_check(not ship.status_label.visible, "No nearest-island text while sailing")
	for island in ship.get_islands():
		_check(ResourceLoader.exists(island.scene), "%s must point at a real scene" % island.name)
