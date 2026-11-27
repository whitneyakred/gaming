extends Node
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func frames(count: int = 3) -> void:
	for i in count: await get_tree().physics_frame

func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await frames(8)
	var ship := get_tree().current_scene as Ship
	var manager := ship.get_node("IslandChallenges") as IslandChallenges
	var player := ship.player
	var bag: PlayerInventory = player.player_inventory
	var seen := {}
	check(ship.get_islands().size() == 34, "30 ordinary islands plus four quest islands exist")
	for island in ship.get_islands():
		if island is QuestIsland: continue
		var totem := island.get_node("MinigameTotem") as MinigameTotem
		check(Geometry2D.is_point_in_polygon(totem.global_position, island.get_coast()), "Totem is on land: " + str(island.name))
		if seen.has(island.scene): continue
		seen[island.scene] = true
		player.set_overboard(true)
		player.global_position = totem.global_position
		player.update_land(true)
		var before := bag.capture()
		if seen.size() == 1:
			var event := InputEventAction.new()
			event.action = "interact"
			event.pressed = true
			get_viewport().push_input(event)
			await frames()
			event = InputEventAction.new()
			event.action = "interact"
			get_viewport().push_input(event)
			check(manager.locks.has(str(island.name)), "Interact input starts island totem")
		else:
			check(manager.try_start(1, str(island.name)), "Starts " + island.scene)
		await frames()
		check(is_instance_valid(manager.game), "Original game loaded")
		if not is_instance_valid(manager.game):
			get_tree().quit(1)
			return
		if "--capture" in OS.get_cmdline_user_args() and seen.size() == 1:
			await get_tree().create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/totem-challenge.png")
		check(manager.game.get_inventory() != bag, "Challenge bag is isolated")
		manager.game.give_item(&"gold_coin", 5)
		check(manager.game.get_inventory().get_quantity(&"gold_coin") == 5 and bag.get_quantity(&"gold_coin") == 0, "Objective tokens stay private")
		check(manager.arena.global_position == totem.global_position and manager._viewport.transparent_bg, "Gameplay is placed over the real clearing")
		check(manager.game.get_node_or_null("Ocean") == null and manager.game.get_node("Terrain").clearing, "Legacy ocean and island art removed")
		check(manager.game.hud.get_parent() == manager._layer, "Instructions remain screen sized")
		check(not player.presentation.visible, "World avatar does not overlap puzzle avatar")
		var leave_button: Button = manager._layer.get_node("LeaveChallenge")
		check(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(leave_button.get_global_rect()), "Leave button stays visible")
		check(not manager.try_start(1, str(island.name)), "Double start is rejected")
		if manager.game is TimberIsle:
			var timber := manager.game as TimberIsle
			timber.player.global_position = timber._trees[0].global_position
			var event := InputEventAction.new()
			event.action = "interact"
			event.pressed = true
			get_viewport().push_input(event)
			await frames()
			event = InputEventAction.new()
			event.action = "interact"
			get_viewport().push_input(event)
			check(timber.chopping_tree == 0, "Interact routes to original minigame, not world")
		var position_before := player.global_position
		Input.action_press("move_right")
		await frames(4)
		Input.action_release("move_right")
		check(player.global_position == position_before, "Challenge input never moves world player")
		leave_button.pressed.emit()
		await frames()
		check(not IslandChallenges.local_active() and manager.locks.is_empty(), "Cancel releases reservation")
		check(player.presentation.visible and not ship._view.challenge_center.is_finite(), "Cancel restores avatar and camera")
		check(bag.capture() == before, "Cancel preserves real gear")
		check(get_tree().current_scene == ship and player.global_position == position_before, "Same world and return position")
		if "--capture" in OS.get_cmdline_user_args() and seen.size() == 1:
			var camera := Camera2D.new()
			ship.add_child(camera)
			camera.global_position = totem.global_position
			camera.make_current()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/totem-world.png")
			camera.queue_free()
	check(seen.size() == 19, "All 19 existing minigames available")
	# Each scene's existing objective predicate must trigger completion without
	# crossing an exit. Puzzle-solving rules are exercised by island_minigames.
	for scene in seen:
		var arena_island: WorldIsland = ship.get_islands().filter(func(i): return i.scene == scene)[0]
		player.global_position = arena_island.get_node("MinigameTotem").global_position+Vector2(40,0)
		player.update_land(true)
		check(manager.try_start(1,str(arena_island.name)),"Auto-completion starts: "+scene)
		await frames()
		var challenge := manager.game
		challenge.win_delay_seconds = 0.01
		complete_objective(challenge)
		await get_tree().create_timer(0.1).timeout
		check(not is_instance_valid(manager.game) and manager.locks.get(str(arena_island.name),{}).get("player",-1) == 0,"Objective finishes automatically: "+scene)
		manager.locks.erase(str(arena_island.name))
	manager.service_for(1).drops.clear()
	var island := ship.get_islands()[0]
	player.global_position = island.get_node("MinigameTotem").global_position
	player.update_land(true)
	check(manager.try_start(1, str(island.name)), "Reward attempt starts")
	await frames()
	var token := manager._token
	var before := bag.get_quantity(&"coconut")
	manager.game.give_item(&"coconut", 2)
	manager.game.win_delay_seconds = 0.01
	manager.game.win()
	await get_tree().create_timer(0.1).timeout
	var won_drops: Dictionary = manager.service_for(1).drops
	check(bag.get_quantity(&"coconut") == before and won_drops.size()==2, "Win spawns two supplies instead of minigame loot")
	if "--capture" in OS.get_cmdline_user_args():
		var camera := Camera2D.new()
		ship.add_child(camera)
		camera.global_position = player.global_position
		camera.make_current()
		await get_tree().create_timer(0.85).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/totem-rewards.png")
		camera.queue_free()
	var rewards := won_drops.values()
	check(rewards[0].id != rewards[1].id and rewards.all(func(entry): return entry.id in IslandChallenges.REWARDS and entry.quantity >= 1 and entry.quantity <= 3 and (entry.id != &"medpack" or entry.quantity == 1)),"Rewards are distinct and bounded")
	manager.finish(1, str(island.name), token, true, {"coconut": 2})
	check(won_drops.size()==2, "Duplicate completion cannot award twice")
	check(not manager.try_start(1,str(island.name)), "Success starts shared cooldown")
	var saved_cooldowns := manager.capture_cooldowns()
	manager.locks.clear()
	manager.restore_cooldowns(saved_cooldowns)
	check(manager.locks.has(str(island.name)) and manager.locks[str(island.name)].until > ship.ocean_fish.shared_time()+290.0,"Successful cooldown survives save and restore")
	manager.locks[str(island.name)].until = ship.ocean_fish.shared_time()-1.0
	await get_tree().process_frame
	await get_tree().process_frame
	player.global_position = island.get_node("MinigameTotem").global_position
	player.update_land(true)
	check(manager.try_start(1, str(island.name)), "Replay allowed")
	await frames()
	manager.game.give_item(&"coconut", 4)
	manager.game.lose_delay_seconds = 0.01
	manager.game.lose("Test timeout")
	await get_tree().create_timer(0.1).timeout
	check(bag.get_quantity(&"coconut") == before and manager.locks.is_empty(), "Loss keeps gear and releases lock")
	# Rejected result packets must not release another player's reservation.
	check(manager.try_start(1, str(island.name)), "Validation attempt starts")
	await frames()
	token = manager._token
	manager.finish(2, str(island.name), token, true, {"coconut": 20})
	manager.finish(1, str(island.name), token + 1, true, {"coconut": 20})
	check(manager.locks.has(str(island.name)), "Wrong player and stale token cannot finish")
	manager.locks[str(island.name)].seconds = IslandChallenges.MAX_RUN_SECONDS
	await frames()
	check(manager.locks.is_empty() and not IslandChallenges.local_active(), "Expired reservation closes challenge")
	# A full bag leaves rewards in the existing world pickup system.
	bag.restore([])
	for item_id in [&"fishing_rod", &"spyglass", &"rope", &"coal"]:
		var item := ItemDatabase.get_item(item_id)
		bag.add_items(item, item.max_stack)
	check(manager.try_start(1, str(island.name)), "Full bag can still play")
	await frames()
	manager.game.give_item(&"coconut", 2)
	manager._finished_local(true)
	await frames()
	var drops: Dictionary = manager.service_for(1).drops
	check(drops.values().any(func(entry): return entry.id in IslandChallenges.REWARDS and entry.world), "Full-bag prizes remain ashore")
	player.global_position = Vector2.ZERO
	player.update_land(false)
	check(not manager.try_start(1, str(island.name)), "Remote start rejected")
	print("ISLAND TOTEMS: ", checks, " checks, ", failures, " failures")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)

func complete_objective(game: IslandGame) -> void:
	if game is CollectIsland: game.collected_count = game.total_count
	elif game is TreasureIsland: game.treasure_found = true
	elif game is CrabCove: game.penned_count = game.crabs.size()
	elif game is CoconutSquall: game.storm_over = true
	elif game is TikiTotems: game.phase = TikiTotems.Phase.DONE
	elif game is TimberIsle: game.felled_count = game.trees_needed
	elif game is SkullRock: game.idol_taken = true
	elif game is SmugglersDen: game.loot_taken = true
	elif game is OvergrownIsle: game.compass_found = true
	elif game is ParrotPoint: game.orders_done = game.orders_needed
	elif game is PowderKegPoint: game.all_clear = true
	elif game is SeagullRoost: game.rack_safe = true
	elif game is TurtleBeach: game.rewarded = true
	elif game is QuicksandFlats: game.chest_found = true
	elif game is FireflyHollow: game.jar_filled = true
	elif game is CannonCove: game.sunk_count = game.rafts_needed
	elif game is MosquitoMarsh: game.lit_count = game._torches.size()
	elif game is SlipperyRocks: game.chest_opened = true
	elif game is BeeHiveHill: game.honey_count = game._hives.size()

