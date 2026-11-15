class_name PlayerInventory
extends ShipInventory
## Existing gameplay API backed by fixed slots. Multiple stacks may share an ID.
@export var player_id: StringName

var inventory: Array[ItemData]:
	get:
		var result: Array[ItemData] = []
		var seen: Dictionary = {}
		for entry in slots:
			if not entry.is_empty() and not seen.has(entry.id):
				result.append(definition(entry.id))
				seen[entry.id] = true
		return result

var quantities: Dictionary[StringName, int]:
	get:
		var result: Dictionary[StringName, int] = {}
		for entry in slots:
			if not entry.is_empty():
				result[entry.id] = result.get(entry.id, 0) + int(entry.quantity)
		return result

func add_item(item: ItemData) -> bool:
	return add_items(item, 1) == 1

func try_add(item_id: StringName, amount: int = 1) -> bool:
	var item := definition(item_id)
	if amount <= 0 or capacity_for(item) < amount:
		return false
	return add_items(item, amount) == amount

func get_quantity(item_id: StringName) -> int:
	return quantities.get(item_id, 0)

func remove_item(item_id: StringName, amount: int = 1) -> bool:
	return try_remove(item_id, amount)

func try_remove(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or get_quantity(item_id) < amount:
		return false
	var remaining := amount
	for index in slots.size():
		if slots[index].get("id", &"") != item_id:
			continue
		var moved := mini(remaining, int(slots[index].quantity))
		slots[index].quantity -= moved
		remaining -= moved
		if slots[index].quantity == 0:
			slots[index] = {}
		if remaining == 0:
			break
	_notify()
	return true

func move_item(item_id: StringName, target_index: int) -> bool:
	_ensure_slots()
	if target_index < 0 or target_index >= slots.size():
		return false
	for index in slots.size():
		if slots[index].get("id", &"") == item_id:
			return true if index == target_index else move_to(index, self, target_index)
	return false
