extends Node

var items_by_id: Dictionary[StringName, ItemData] = {}

func register_item(item: ItemData) -> void:
	assert(item != null, "Cannot register a null item.")
	assert(not item.id.is_empty(), "Items need an id.")
	assert(not items_by_id.has(item.id), "Duplicate item id: %s" % item.id)
	assert(item.max_stack >= 1, "Item max stack must be at least 1: %s" % item.id)
	assert(item.draw_weight > 0.0, "Item draw weight must be positive: %s" % item.id)
	assert(item.sell_value >= 0, "Item sell value cannot be negative: %s" % item.id)
	items_by_id[item.id] = item

func get_item(item_id: StringName) -> ItemData:
	return items_by_id.get(item_id)

func get_all_items() -> Array[ItemData]:
	var registered_items: Array[ItemData] = []
	for item in items_by_id.values():
		registered_items.append(item)
	return registered_items
