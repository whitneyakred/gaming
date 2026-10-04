extends Node

## Optional component for nodes that need to add items to one player inventory.
@export var player_inventory: PlayerInventory

func add_item(item: ItemData) -> bool:
	if player_inventory == null:
		push_warning("InventoryUsage has no PlayerInventory assigned.")
		return false

	return player_inventory.add_item(item)

func get_quantity(item_id: StringName) -> int:
	if player_inventory == null:
		return 0

	return player_inventory.get_quantity(item_id)
