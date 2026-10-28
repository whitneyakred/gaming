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

	# --- Island rewards ---
	ItemDatabase.register_item(make_item(
		&"gold_coin",
		"Gold Coin",
		"Pirate gold from an island treasure.",
		999
	))
	ItemDatabase.register_item(make_item(
		&"wood",
		"Wood",
		"Chopped timber. Used to patch leaks in the hull.",
		30
	))
	ItemDatabase.register_item(make_item(
		&"crab_meat",
		"Crab Meat",
		"Sweet meat from a beach crab.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"mango",
		"Mango",
		"A ripe island mango.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"banana",
		"Banana",
		"A bunch-fresh banana.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"papaya",
		"Papaya",
		"A soft, sweet papaya.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"fresh_water",
		"Fresh Water",
		"A flask of drinkable spring water.",
		10
	))
	ItemDatabase.register_item(make_item(
		&"compass",
		"Lost Compass",
		"An old brass compass recovered from the jungle."
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
