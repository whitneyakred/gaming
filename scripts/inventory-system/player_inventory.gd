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

## Removes an amount from one item type. Removes the item type entirely when
## its quantity reaches zero. Returns false without changing the inventory
## when the requested amount is invalid or unavailable.
func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var current_quantity := get_quantity(item_id)
	if current_quantity < amount:
		return false

	var item_index := -1
	for index in range(inventory.size()):
		if inventory[index].id == item_id:
			item_index = index
			break

	if item_index == -1:
		push_warning("Inventory quantity has no matching item type: %s" % item_id)
		return false

	if current_quantity == amount:
		quantities.erase(item_id)
		inventory.remove_at(item_index)
	else:
		quantities[item_id] = current_quantity - amount

	return true


