class_name PlayerInventory
extends Resource

## Stores one player's owned item types and their individual quantities.
## ItemData remains shared metadata supplied by ItemDatabase.
signal inventory_changed

@export var player_id: StringName
@export_range(1, 99, 1) var max_inv_space: int = 4
@export var inventory: Array[ItemData] = []
@export var quantities: Dictionary[StringName, int] = {}

func add_item(item: ItemData) -> bool:
	if item == null:
		return false

	return _try_add_item(item, 1)

## Adds an amount of a registered item without partially changing the inventory.
## The current four-space prototype keeps one stack per item type and uses that
## item's configured stack limit.
func try_add(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var item: ItemData = _get_catalog_item(item_id)
	if item == null:
		return false

	return _try_add_item(item, amount)

func get_quantity(item_id: StringName) -> int:
	return quantities.get(item_id, 0)

## Removes an amount from one item type. Removes the item type entirely when
## its quantity reaches zero. Returns false without changing the inventory
## when the requested amount is invalid or unavailable.
func remove_item(item_id: StringName, amount: int = 1) -> bool:
	return try_remove(item_id, amount)

## Removes an amount from one item type without partially changing the inventory.
func try_remove(item_id: StringName, amount: int = 1) -> bool:
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

	inventory_changed.emit()
	return true

## Moves one owned item type to another occupied-space index. This preserves the
## prototype's four distinct-item spaces while allowing an inventory view to
## reorder them without editing exported data directly.
func move_item(item_id: StringName, target_index: int) -> bool:
	var item_index := _get_item_index(item_id)
	if item_index == -1 or target_index < 0 or target_index >= inventory.size():
		return false
	if item_index == target_index:
		return true

	var item := inventory[item_index]
	inventory.remove_at(item_index)
	inventory.insert(target_index, item)
	inventory_changed.emit()
	return true

## Removes every owned item type and quantity. Used by reset flows such as a
## future capsize without exposing direct collection mutation to callers.
func clear() -> void:
	if inventory.is_empty() and quantities.is_empty():
		return

	inventory.clear()
	quantities.clear()
	inventory_changed.emit()

func _try_add_item(item: ItemData, amount: int) -> bool:
	var current_quantity := get_quantity(item.id)
	if current_quantity > 0:
		if current_quantity + amount > item.max_stack:
			return false
		quantities[item.id] = current_quantity + amount
		inventory_changed.emit()
		return true

	if inventory.size() >= max_inv_space or amount > item.max_stack:
		return false

	inventory.append(item)
	quantities[item.id] = amount
	inventory_changed.emit()
	return true

func _get_item_index(item_id: StringName) -> int:
	for index in range(inventory.size()):
		if inventory[index].id == item_id:
			return index

	return -1

func _get_catalog_item(item_id: StringName) -> ItemData:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return null

	var item_database := scene_tree.root.get_node_or_null("ItemDatabase")
	if item_database == null:
		return null

	return item_database.call("get_item", item_id) as ItemData


