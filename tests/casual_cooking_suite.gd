extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	for activity in get_tree().get_nodes_in_group("cooking_activity"): activity.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/cooking-validation/" + label + ".png")
func run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	var ship = get_tree().current_scene.get_node("Ship")
	var service = ship.get_node("InventorySystem")
	var bench = ship.get_node("Crafting")
	service.player.position = bench.position + Vector2(0, 25)
	service.hud.crafting_open = true
	service.inventory.clear()
	var first = VoyageState.get_ship_storage()
	var second = VoyageState.get_ship_storage(18, 1)
	first.restore([{"id": &"wood", "quantity": 2}, {"id": &"rope", "quantity": 1}])
	second.restore([{"id": &"wood", "quantity": 1}, {"id": &"string", "quantity": 1}])
	service.hud.crafting_panel.select_recipe("fishing_rod")
	check(not service.hud.crafting_panel.craft_button.disabled, "Recipe preview includes both ship chests")
	check(bench.craft(service, "fishing_rod", service.view_revision), "Craft from split chest materials")
	check(service.inventory.get_quantity(&"fishing_rod") == 1 and CraftingStation.available(service, &"wood") == 0, "Shared ingredients consumed exactly once")
	check(not bench.craft(service, "fishing_rod", service.view_revision), "Next sailor cannot reuse spent materials")
	first.restore([{"id": &"wood", "quantity": 3}])
	second.restore([{"id": &"stone", "quantity": 3}])
	var full_bag: Array[Dictionary] = [{"id": &"spyglass", "quantity": 1},{"id": &"spyglass", "quantity": 1},{"id": &"spyglass", "quantity": 1},{"id": &"spyglass", "quantity": 1}]
	service.inventory.restore(full_bag)
	var a = first.capture()
	var b = second.capture()
	check(not bench.craft(service, "axe", service.view_revision), "Full bag rejects crafted item")
	check(first.capture() == a and second.capture() == b, "Failed craft rolls back both chests")
	service.inventory.clear()
	service.inventory.try_add(&"wood", 1)
	check(bench.craft(service, "axe", service.view_revision), "Bag and chests combine materials")
	check(service.inventory.get_quantity(&"wood") == 0 and CraftingStation.available(service, &"wood") == 1, "Bag materials used before shared stock")
	service.hud.close()
	var activity = load("res://scenes/galley_cooking.tscn").instantiate()
	service.hud.add_child(activity)
	activity.set_process(false)
	await capture("chop")
	activity._process(600)
	check(activity.stage == activity.Stage.FISH, "Long idle never times out")
	activity._press(Vector2(0, 250))
	activity._release(Vector2(0, 470))
	check(activity.cuts == 0, "Missed slice is retryable")
	for i in 3:
		var x = activity._cut_x()
		activity._press(Vector2(x, 230))
		activity._move(Vector2(x, 350))
		check(activity.knife_direction.is_equal_approx(Vector2.DOWN), "Knife points down along the cut")
		if i == 0:
			activity.pointer = Vector2(x, 350)
			await capture("knife")
		activity._release(Vector2(x, 470))
	check(activity.stage == activity.Stage.ADD_FISH and activity.pieces.size() == 4, "Three cuts create four fish pieces")
	await capture("pot")
	activity._press(activity.pieces[0])
	activity._move(Vector2(20, 20))
	activity._release(Vector2(20, 20))
	check(activity.pieces.size() == 4, "Missed drop never loses food")
	while not activity.pieces.is_empty():
		activity._press(activity.pieces[0])
		activity._move(activity.POT_CENTER)
		activity._release(activity.POT_CENTER)
	check(activity.stage == activity.Stage.HEAT, "All pieces go into pot before heat")
	activity._process(600)
	check(activity.temperature == 0, "Stove waits for deliberate ignition")
	activity._press(Vector2(350, 520))
	activity._release(Vector2(350, 520))
	activity._process(4)
	await capture("simmer")
	activity._process(4)
	check(activity.stage == activity.Stage.SKEWER and activity.pieces.size() == 4, "Cooked pieces can be removed from pot")
	var pot_interior := Rect2(activity.POT_CENTER + Vector2(-80, -104), Vector2(160, 92))
	for point in activity.pieces:
		check(pot_interior.encloses(Rect2(point - activity.POT_PIECE_SIZE * 0.5, activity.POT_PIECE_SIZE)), "Every cooked piece fits inside the pot rim")
	await capture("skewer")
	while not activity.pieces.is_empty():
		activity._press(activity.pieces[0])
		activity._move(activity.SKEWER_CENTER)
		activity._release(activity.SKEWER_CENTER)
	check(activity.stage == activity.Stage.DONE and activity.threaded == 4, "Four pieces finish one kabob")
	await capture("kabob")
	check(ItemDatabase.get_item(&"dried_fish").display_name == "Fish Kabob", "Legacy cooked fish saves retain new kabob name")
	activity.queue_free()
	var grill = ship.get_node("Cooking")
	service.player.position = grill.position + Vector2(-25, 12)
	service.hud.grill_open = true
	service.inventory.clear()
	service.inventory.try_add(&"fish_cod")
	grill.handle(service, {"action":"start","index":0,"revision":service.view_revision})
	grill.started -= 600000
	grill._process(0.1)
	check(grill.cooking(), "Shared galley has no hidden two-minute timeout")
	check(grill.handle(service,{"action":"finish","token":grill.token}), "Score-free result accepted")
	check(service.inventory.get_quantity(&"dried_fish") == 1, "One kabob awarded regardless of rating")
	print("CASUAL COOKING / SHARED CRAFTING: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)

