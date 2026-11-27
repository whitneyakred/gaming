extends Node
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	add_child(world)
	var service = world.get_node("Ship/InventorySystem")
	var bench = world.get_node("Ship/Crafting")
	service.player.position = Vector2(3, -143)
	service.hud.crafting_open = true
	var panel = service.hud.crafting_panel
	var untouched = service.inventory.capture()
	panel.choices["axe"].pressed.emit()
	assert(panel.selected_recipe == "axe")
	assert(service.inventory.capture() == untouched)
	panel.choices["fishing_rod"].pressed.emit()
	assert(panel.ingredients.get_child_count() == 3)
	assert(CraftingStation.RECIPES.fishing_rod == {"wood": 3, "rope": 1, "string": 1})
	for recipe: String in CraftingStation.RECIPES:
		service.inventory.clear()
		for material: String in CraftingStation.RECIPES[recipe]:
			assert(service.inventory.try_add(StringName(material), CraftingStation.RECIPES[recipe][material]))
		assert(bench.craft(service, recipe, service.view_revision))
		assert(service.inventory.get_quantity(StringName(recipe)) == 1)
		var slot := 0
		while service.inventory.slots[slot].get("id") != StringName(recipe): slot += 1
		var item = service.inventory.definition(StringName(recipe))
		if recipe == "spyglass":
			assert(item.max_durability == 0)
			assert(not service.inventory.slots[slot].has("durability"))
			assert(not service.inventory.wear(slot, 999))
			assert(service.inventory.get_quantity(&"spyglass") == 1)
			continue
		assert(service.inventory.slots[slot].durability == item.max_durability)
		service.wear_tool(slot)
		var chest := ShipInventory.new()
		assert(service.inventory.transfer_to(slot, chest) == 1)
		assert(chest.slots[0].durability == item.max_durability - 1)
		assert(chest.transfer_to(0, service.inventory) == 1)
		assert(service.inventory.slots[0].durability == item.max_durability - 1)
		assert(service.inventory.wear(0, item.max_durability))
		assert(service.inventory.slots[0].is_empty())
	service.inventory.clear()
	service.inventory.try_add(&"wood", 3)
	var before = service.inventory.capture()
	assert(not bench.craft(service, "axe", service.view_revision))
	assert(before == service.inventory.capture())
	assert(not bench.craft(service, "unknown", service.view_revision))
	service.inventory.try_add(&"stone", 3)
	service.inventory.try_add(&"rope", 2)
	service.inventory.try_add(&"coconut", 1)
	before = service.inventory.capture()
	assert(not bench.craft(service, "spyglass", service.view_revision))
	assert(before == service.inventory.capture())
	assert(not bench.craft(service, "axe", service.view_revision - 1))
	assert(not SharedSnapshotState.valid_slots([{"id":"axe", "quantity":1, "durability":"bad"}]))
	assert(not SharedSnapshotState.valid_slots([{"id":"axe", "quantity":1, "durability":0}]))
	service.inventory.clear()
	service.inventory.try_add(&"axe")
	service.inventory.wear(0, 10)
	service._spawn_drop(service.inventory.slots[0], Vector2(3, -145))
	service.inventory.clear()
	service.pickup_inside.clear()
	service.server_pickups()
	assert(service.inventory.slots[0].durability == 20)
	if "--preview-crafting" in OS.get_cmdline_user_args():
		service.hud.crafting_open = true
		service.player.position = Vector2(3, -143)
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/crafting-preview.png")
	print("CRAFTING AND DURABILITY PASS")
	get_tree().quit()

