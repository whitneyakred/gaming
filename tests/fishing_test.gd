extends Node
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func click(point: Vector2, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/" + name + ".png")
func run() -> void:
	get_tree().create_timer(30).timeout.connect(func() -> void: get_tree().quit(1))
	GameWindow.set_preference("fullscreen", false)
	GameWindow.set_preference("pause_unfocused", false)
	GameWindow.set_preference("window_size", 1)
	get_window().size = Vector2i(1280, 720)
	VoyageState.reset()
	for seed_value in 30:
		var fight := FishingFight.new()
		fight.begin(seed_value)
		for frame in 2000:
			fight.step(1.0 / 60, fight.tension < fight.green_center)
			if fight.caught or fight.broken:
				break
		check(fight.caught and not fight.broken, "Tracking the green wins randomized fight %d" % seed_value)
	for held in [true, false]:
		var fight := FishingFight.new()
		fight.begin(14)
		fight.step(8, held)
		check(fight.broken and not fight.caught, "Constant hold/release breaks line: %s" % held)
	var a := FishingFight.new()
	var b := FishingFight.new()
	a.begin(45)
	b.begin(45)
	a.step(0.5, true)
	for i in 30:
		b.step(1.0 / 60, true)
	check(is_equal_approx(a.tension, b.tension) and is_equal_approx(a.danger, b.danger), "Tension model behaves consistently across frame sizes")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var service: InventoryService = main.get_node("Ship/InventorySystem")
	var fishing: RodFishing = service.get_node("Fishing")
	fishing.set_process(false)
	var source := service.player.global_position
	var water := source + Vector2(230, 0)
	check(not fishing.cast(source), "Cannot cast onto deck")
	check(fishing.cast(source + Vector2(900, 0)), "Distant water click casts successfully")
	check(source.distance_to(fishing.target) <= fishing.cast_range + 0.1, "Distant cast stays within rod range")
	check(fishing.is_water(fishing.target), "Clamped bobber lands in water")
	fishing.cancel()
	check(fishing.is_water(water), "Nearby ocean recognized as water")
	for waiting in [false, true]:
		fishing.cast(water)
		if waiting:
			fishing.advance(0.5, false)
		var early := InputEventMouseButton.new()
		early.button_index = MOUSE_BUTTON_LEFT
		early.pressed = true
		fishing._unhandled_input(early)
		check(fishing.state == RodFishing.State.IDLE and not service.player.fishing_active, "Early click requires a fresh cast (waiting=%s)" % waiting)
	service.hud.selected = 1
	check(not fishing.cast(water), "Spyglass cannot cast a fishing line")
	service.hud.selected = 0
	click(get_viewport().get_canvas_transform() * water)
	await get_tree().process_frame
	check(fishing.state == RodFishing.State.CASTING, "World click routes to selected rod")
	check(fishing.target.distance_to(water) < 1, "Bobber targets mouse world position")
	check(service.player.fishing_active, "Casting holds the player's stance")
	fishing.advance(0.2, false)
	await capture("fishing-cast")
	fishing.advance(0.3, false)
	check(fishing.state == RodFishing.State.WAITING, "Cast lands and waits for random bite")
	check(fishing.wait_left >= 1.8 and fishing.wait_left <= 4.5, "Bite delay stays within configured range")
	await get_tree().process_frame
	await capture("fishing-waiting")
	click(Vector2(900, 300), false)
	fishing.advance(5, false)
	check(fishing.state == RodFishing.State.BITE, "Bobber signals bite")
	click(Vector2(900, 300))
	await get_tree().process_frame
	check(fishing.state == RodFishing.State.REELING and fishing.held, "Second click hooks fish")
	click(Vector2(640, 680), false)
	await get_tree().process_frame
	check(not fishing.held, "Release over hotbar eases tension")
	fishing.advance(0.2, true)
	await get_tree().process_frame
	await capture("fishing-reel")
	var saved_progress := fishing.fight.progress
	fishing.fight.progress = 0.85
	fishing.queue_redraw()
	await get_tree().process_frame
	await capture("fishing-reel-hull-edge")
	fishing.fight.progress = saved_progress
	var before: int = service.inventory.get_quantity(&"fish_cod") + service.inventory.get_quantity(&"rope")
	for i in 2000:
		fishing.advance(1.0 / 60, fishing.fight.tension < fishing.fight.green_center)
		if fishing.state == RodFishing.State.IDLE:
			break
	check(service.inventory.get_quantity(&"fish_cod") + service.inventory.get_quantity(&"rope") == before + 1, "Successful minigame grants exactly one catch")
	fishing.finish(true)
	check(service.inventory.get_quantity(&"fish_cod") + service.inventory.get_quantity(&"rope") == before + 1, "Completed cast cannot pay twice")
	check(not service.player.fishing_active, "Catch releases player's movement")
	fishing.cast(water)
	fishing.advance(1, false)
	fishing.advance(5, false)
	fishing.advance(3, false)
	check(fishing.state == RodFishing.State.IDLE, "Missed bite resets attempt")
	fishing.cast(water)
	service.hud.storage_open = true
	fishing._process(0)
	check(fishing.state == RodFishing.State.IDLE, "Opening storage cancels fishing")
	service.hud.close()
	fishing.cast(water)
	MapState.map_open = true
	fishing._process(0)
	check(fishing.state == RodFishing.State.IDLE, "Map cancels fishing")
	MapState.map_open = false
	fishing.cast(water)
	service.hud.selected = 1
	fishing._process(0)
	check(fishing.state == RodFishing.State.IDLE, "Switching tools cancels cast")
	service.hud.selected = 0
	fishing.cast(water)
	get_tree().paused = true
	fishing._process(0)
	check(fishing.state == RodFishing.State.IDLE and not service.player.fishing_active, "Pausing safely cancels fishing")
	get_tree().paused = false
	# Reeling may approach the gunwale, but never enter the deck, even while turning.
	var ship := main.get_node("Ship") as Node2D
	var ship_pose := ship.global_transform
	check(fishing.cast(water), "Moving-ship regression cast starts")
	fishing.state = RodFishing.State.REELING
	fishing.fight.begin(27)
	var local_target := ship.to_local(fishing.target)
	ship.global_position += Vector2(2400, 1700)
	ship.global_rotation += 0.7
	check(fishing.target.distance_to(ship.to_global(local_target)) < 0.01, "Cast follows ship translation and rotation")
	for progress in [0.0, 0.5, 0.85, 0.99, 1.0]:
		fishing.fight.progress = progress
		for phase in [0.0, 0.7, 1.8]:
			fishing.clock = phase
			check(fishing._water_clear(fishing.bobber_position()), "Bobber and its wobble remain outside hull at %s" % progress)
	fishing.fight.begin(27)
	var catches_before: int = service.inventory.get_quantity(&"fish_cod") + service.inventory.get_quantity(&"rope") + service.drops.size()
	for i in 2000:
		ship.global_position += Vector2(1.5, -0.6)
		ship.global_rotation += 0.0005
		fishing._process(0)
		fishing.advance(1.0 / 60, fishing.fight.tension < fishing.fight.green_center)
		if fishing.state == RodFishing.State.IDLE:
			break
	var catches_after: int = service.inventory.get_quantity(&"fish_cod") + service.inventory.get_quantity(&"rope") + service.drops.size()
	check(catches_after == catches_before + 1, "Full minigame awards catch after sailing far beyond original cast range")
	ship.global_transform = ship_pose
	service.inventory.clear()
	service.inventory.try_add(&"fishing_rod")
	service.inventory.try_add(&"spyglass")
	service.inventory.try_add(&"wood", 30)
	service.inventory.try_add(&"coconut", 20)
	fishing.cast(water)
	fishing.finish(true)
	check(service.drops.size() == 1, "Full inventory drops catch safely at player's feet")
	for kind in fishing.sound.sounds:
		check(fishing.sound.sounds[kind].data.size() > 100, "Synthesized audio exists: " + kind)
	main.queue_free()
	await get_tree().process_frame
	var island: Node = load("res://scenes/islands/cannon_cove.tscn").instantiate()
	add_child(island)
	await get_tree().process_frame
	await get_tree().process_frame
	var island_service: InventoryService = island.get_node("InventorySystem")
	var island_fishing: RodFishing = island_service.get_node("Fishing")
	check(not island_fishing.is_water(island_service.player.global_position), "Island ground cannot receive bobber")
	check(island_fishing.is_water(Vector2(1100, 0)), "Water outside island shoreline recognized")
	island.queue_free()
	await get_tree().process_frame
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.2).timeout
	print("FISHING: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
