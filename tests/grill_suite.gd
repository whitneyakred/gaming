extends Node
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	GameWindow.set_preference("fullscreen", false)
	GameWindow.set_preference("pause_unfocused", false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship := get_tree().current_scene.get_node("Ship")
	var grill: ShipGrill = ship.get_node("Cooking")
	var service: InventoryService = ship.get_node("InventorySystem")
	grill.set_process(false)
	service.player.position = grill.position + Vector2(-20, 12)
	service.hud.grill_open = true
	check(service.grill_is_nearest(), "Galley interaction opens grill")
	var stock := service.storage.capture()
	grill.seed_fuel()
	check(service.storage.capture() == stock, "Starter fuel is granted only once")
	check(stock[0].id == &"wood" and stock[0].quantity == 6 and stock[1].id == &"coal" and stock[1].quantity == 4, "Chest starts with wood and coal")
	service.inventory.restore([{ "id": &"fish_cod", "quantity": 4 }, {"id": &"wood", "quantity": 2}, {}, {}])
	check(grill.handle(service, {"action": "fuel", "index": 1, "revision": service.view_revision}), "Fuel enters single slot")
	grill.advance(100)
	check(grill.fuel.quantity == 2 and grill.burn_remaining == 0, "Idle grill never consumes fuel")
	var revision := service.view_revision
	check(grill.handle(service, {"action": "fish", "index": 0, "revision": revision, "point": Vector2(0.2, 0.4)}), "Fish can be placed freely")
	check(not grill.handle(service, {"action": "fish", "index": 0, "revision": revision}), "Stale inventory command cannot duplicate placement")
	check(grill.fish[0].point == Vector2(0.2, 0.4), "Fish placement retained")
	grill.advance(3)
	check(is_equal_approx(grill.fish[0].progress, 3) and is_equal_approx(grill.burn_remaining, 9), "Cooking consumes measured heat")
	grill.advance(100)
	check(is_equal_approx(grill.fish[0].progress, 8) and is_equal_approx(grill.burn_remaining, 4) and grill.fuel.quantity == 1, "Completed meals stop burning fuel exactly")
	grill.advance(100)
	check(is_equal_approx(grill.burn_remaining, 4), "Leftover heat is preserved")
	var saved := grill.capture()
	grill.restore(saved)
	check(grill.capture() == saved, "Save/snapshot roundtrip preserves fish and fuel")
	service.inventory.restore([{ "id": &"fish_cod", "quantity": 3 }, {"id": &"wood", "quantity": 30}, {"id": &"fishing_rod", "quantity": 1}, {"id": &"spyglass", "quantity": 1}])
	var key: int = grill.fish[0].key
	check(grill.handle(service, {"action": "collect", "key": key}), "Collect meal with full bag")
	check(grill.fish.is_empty() and service.drops.size() == 1 and service.drops.values()[0].id == &"dried_fish", "Full bag sends meal to deck")
	check(not grill.handle(service, {"action": "collect", "key": key}) and service.drops.size() == 1, "Repeated collect cannot grant second fish")
	grill.handle(service, {"action": "fish", "index": 0, "revision": service.view_revision})
	grill.handle(service, {"action": "withdraw"})
	grill.advance(100)
	check(is_equal_approx(grill.fish[0].progress, 4) and not grill.cooking(), "Cooking pauses when fuel runs out")
	service.inventory.restore([{ "id": &"coal", "quantity": 2 }, {}, {}, {}])
	grill.handle(service, {"action": "fuel", "index": 0, "revision": service.view_revision})
	grill.advance(4)
	check(is_equal_approx(grill.burn_remaining, 32) and grill.fuel.quantity == 1, "Coal resumes progress and burns longer")
	grill.handle(service, {"action": "collect", "key": grill.fish[0].key})
	check(service.inventory.get_quantity(&"dried_fish") == 1, "Meal enters available bag slot")
	service.hud.close()
	check(not grill.handle(service, {"action": "withdraw"}), "Closed grill cannot be operated")
	service.hud.grill_open = true
	service.player.position = Vector2(-300, -300)
	check(not grill.handle(service, {"action": "withdraw"}), "Distant sailor cannot operate grill")
	service.player.position = grill.position + Vector2(-20, 12)
	service.inventory.restore([{ "id": &"fish_cod", "quantity": 10 }, {}, {}, {}])
	for i in 8:
		grill.handle(service, {"action": "fish", "index": 0, "revision": service.view_revision, "point": Vector2(0.1 + (i % 4) * 0.26, 0.3 + floorf(i / 4.0) * 0.45)})
	check(not grill.handle(service, {"action": "fish", "index": 0, "revision": service.view_revision}) and service.inventory.get_quantity(&"fish_cod") == 2, "Full grill rejects fish without consuming it")
	grill.advance(4)
	service.hud.grill_panel.visible = true
	await get_tree().process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/grill-preview.png")
	print("GRILL: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
