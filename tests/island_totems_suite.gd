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
	check(ship.get_islands().size() == 30, "All 30 world islands exist")
	for island in ship.get_islands():
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
	check(bag.get_quantity(&"coconut") == before + 2, "Win transfers earned prizes")
	manager.finish(1, str(island.name), token, true, {"coconut": 2})
	check(bag.get_quantity(&"coconut") == before + 2, "Duplicate completion cannot award twice")
	check(manager.try_start(1, str(island.name)), "Replay allowed")
	await frames()
	manager.game.give_item(&"coconut", 4)
	manager.game.lose_delay_seconds = 0.01
	manager.game.lose("Test timeout")
	await get_tree().create_timer(0.1).timeout
	check(bag.get_quantity(&"coconut") == before + 2 and manager.locks.is_empty(), "Loss keeps gear and releases lock")
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
	check(drops.values().any(func(entry): return entry.id == &"coconut" and entry.quantity == 2 and entry.world), "Full-bag prizes remain ashore")
	player.global_position = Vector2.ZERO
	player.update_land(false)
	check(not manager.try_start(1, str(island.name)), "Remote start rejected")
	print("ISLAND TOTEMS: ", checks, " checks, ", failures, " failures")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)

