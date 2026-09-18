extends Node

func _ready() -> void:
	ItemDatabase.register_item(make_cod())
	ItemDatabase.register_item(make_rope())
	ItemDatabase.register_item(make_fishing_rod())

func make_cod() -> ItemData:
	var item := ItemData.new()
	item.id = &"fish_cod"
	item.display_name = "Cod"
	item.description = "A common ocean fish."
	item.max_stack = 10
	return item

func make_rope() -> ItemData:
	var item := ItemData.new()
	item.id = &"rope"
	item.display_name = "Rope"
	item.description = "Useful for ship repairs."
	item.max_stack = 25
	return item

func make_fishing_rod() -> ItemData:
	var item := ItemData.new()
	item.id = &"fishing_rod"
	item.display_name = "Fishing Rod"
	item.description = "An old but useful tool for getting food and other items from the sea."
	item.max_stack = 1
	return item
