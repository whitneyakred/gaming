extends Node

func _ready() -> void:
	ItemDatabase.register_item(make_item(
		&"fish_cod",
		"Cod",
		"A common ocean fish.",
		10,
		ItemData.Category.FOOD
	))
	ItemDatabase.register_item(make_item(
		&"rope",
		"Rope",
		"Strong cordage for general shipboard tasks.",
		25,
		ItemData.Category.MATERIAL
	))
	ItemDatabase.register_item(make_item(
		&"fishing_rod",
		"Fishing Rod",
		"An old but useful tool for getting food and other items from the sea.",
		1,
		ItemData.Category.TOOL
	))
	ItemDatabase.register_item(make_item(
		&"coconut",
		"Coconut",
		"A fresh coconut gathered from a tropical island.",
		20,
		ItemData.Category.FOOD
	))

func make_item(
	item_id: StringName,
	item_display_name: String,
	item_description: String,
	item_max_stack: int = 1,
	item_category: ItemData.Category = ItemData.Category.FOOD,
	item_draw_weight: float = 1.0,
	item_sell_value: int = 0
) -> ItemData:
	var item := ItemData.new()
	item.id = item_id
	item.display_name = item_display_name
	item.description = item_description
	item.max_stack = item_max_stack
	item.category = item_category
	item.draw_weight = item_draw_weight
	item.sell_value = item_sell_value
	return item
