extends Node

func _ready() -> void:
	ItemDatabase.register_item(make_item(
		&"fish_cod",
		"Cod",
		"A common ocean fish.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"rope",
		"Rope",
		"Useful for ship repairs.",
		25
	))
	ItemDatabase.register_item(make_item(
		&"fishing_rod",
		"Fishing Rod",
		"An old but useful tool for getting food and other items from the sea."
	))

func make_item(
	item_id: StringName,
	item_display_name: String,
	item_description: String,
	item_max_stack: int = 1
) -> ItemData:
	var item := ItemData.new()
	item.id = item_id
	item.display_name = item_display_name
	item.description = item_description
	item.max_stack = item_max_stack
	return item
