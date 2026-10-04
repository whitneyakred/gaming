class_name PlayerInventory
extends Resource

## Stores one player's owned item types and their individual quantities.
## ItemData remains shared metadata supplied by ItemDatabase.
@export var player_id: StringName
@export_range(1, 99, 1) var max_inv_space: int = 4
@export var inventory: Array[ItemData] = []
@export var quantities: Dictionary[StringName, int] = {}

func add_item(item: ItemData) -> bool:
	if item == null:
		return false

	if quantities.has(item.id):
		if quantities[item.id] >= item.max_stack:
			return false
		quantities[item.id] += 1
		return true

	if inventory.size() >= max_inv_space:
		return false

	inventory.append(item)
	quantities[item.id] = 1
	return true

func get_quantity(item_id: StringName) -> int:
	return quantities.get(item_id, 0)


