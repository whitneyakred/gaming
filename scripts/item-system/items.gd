extends Node

func _ready() -> void:
	ItemDatabase.register_item(make_item(&"fish_cod", "Cod", "A common ocean fish. Supplies for the crew.", 10, preload("res://assets/items/fish_cod.svg")))
	ItemDatabase.register_item(make_item(&"rope", "Rope", "Useful for ship repairs.", 25, preload("res://assets/items/rope.svg")))
	ItemDatabase.register_item(make_item(&"fishing_rod", "Fishing Rod", "A tool for fishing. Takes one pocket.", 1, preload("res://assets/items/fishing_rod.svg")))
	ItemDatabase.register_item(make_item(&"water", "Water", "A bottle of fresh drinking water.", 5, preload("res://assets/items/water.svg")))
	ItemDatabase.register_item(make_item(&"shovel", "Shovel", "A sturdy digging tool. Takes one pocket.", 1, preload("res://assets/items/shovel.svg")))
	ItemDatabase.register_item(make_item(&"spyglass", "Spyglass", "Keep an eye on the horizon. Takes one pocket.", 1, preload("res://assets/items/spyglass.svg")))

func make_item(item_id: StringName, item_display_name: String, item_description: String, item_max_stack: int = 1, item_icon: Texture2D = null) -> ItemData:
	var item := ItemData.new()
	item.id = item_id
	item.display_name = item_display_name
	item.description = item_description
	item.max_stack = item_max_stack
	item.icon = item_icon
	return item
