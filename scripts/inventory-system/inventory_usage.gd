extends Node

## Optional component for nodes that need to add items to one player inventory.
@export var player_inventory: PlayerInventory

func add_item(item: ItemData) -> bool:
	if player_inventory == null:
		push_warning("InventoryUsage has no PlayerInventory assigned.")
		return false

	return player_inventory.add_item(item)

func try_add(item_id: StringName, amount: int = 1) -> bool:
	if player_inventory == null:
		push_warning("InventoryUsage has no PlayerInventory assigned.")
		return false

	return player_inventory.try_add(item_id, amount)

func get_quantity(item_id: StringName) -> int:
	if player_inventory == null:
		return 0

	return player_inventory.get_quantity(item_id)

func try_remove(item_id: StringName, amount: int = 1) -> bool:
	if player_inventory == null:
		push_warning("InventoryUsage has no PlayerInventory assigned.")
		return false

	return player_inventory.try_remove(item_id, amount)

func move_item(item_id: StringName, target_index: int) -> bool:
	if player_inventory == null:
		push_warning("InventoryUsage has no PlayerInventory assigned.")
		return false

	return player_inventory.move_item(item_id, target_index)

func clear() -> void:
	if player_inventory == null:
		return

	player_inventory.clear()
