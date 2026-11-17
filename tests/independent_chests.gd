extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var service = current_scene.get_node("Ship/InventorySystem")
	var art = service.get_node("DeckItems")
	service.player.position = service.storage_position
	service.open_nearest_chest()
	assert(service.active_chest_id == 0)
	var first = service.storage
	var contents: Array[Dictionary] = [{"id": "wood", "quantity": 3}]
	first.restore(contents)
	service.hud.storage_open = true
	assert(art.chest_texture(0) == art.open_chest_texture)
	assert(art.chest_texture(1) == art.closed_chest_texture)
	service.hud.storage_open = false
	service.player.position = service.second_storage_position
	service.open_nearest_chest()
	assert(service.active_chest_id == 1)
	assert(service.storage != first)
	assert(service.storage.capture()[0].is_empty())
	service.hud.storage_open = true
	assert(art.chest_texture(0) == art.closed_chest_texture)
	assert(art.chest_texture(1) == art.open_chest_texture)
	assert(first.capture()[0].quantity == 3)
	print("Independent chest contents and lid states PASS")
	quit()
