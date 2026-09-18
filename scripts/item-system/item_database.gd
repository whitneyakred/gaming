extends Node

var items_by_id: Dictionary[StringName, ItemData] = {}

func register_item(item: ItemData) -> void:
	assert(not item.id.is_empty(), "Items need an id.")
	assert(not items_by_id.has(item.id), "Duplicate item id: %s" % item.id)
	items_by_id[item.id] = item

func get_item(item_id: StringName) -> ItemData:
	return items_by_id.get(item_id)
