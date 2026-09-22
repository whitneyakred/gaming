extends Node

func register_item(item: ItemData) -> void:
	if item == null or item.id.is_empty() or item.max_stack < 1:
		push_error("Items require a nonempty ID and a positive stack limit.")
		return
	if items_by_id.has(item.id):
		push_error("Duplicate item ID: %s" % item.id)
		return
	items_by_id[item.id] = item

var items_by_id: Dictionary[StringName, ItemData] = {}

func get_item(item_id: StringName) -> ItemData:
	return items_by_id.get(item_id)
