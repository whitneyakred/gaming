extends Node

const SEABASS_ICON := preload("res://assets/items/seabass_alive.png")
const ROPE_ICON := preload("res://assets/items/rope_var1.png")
const COCONUT_WHOLE_ICON := preload("res://assets/items/coconut_whole.png")


func _ready() -> void:
	ItemDatabase.register_item(make_item(&"pickaxe","Pickaxe","Click a rock to mine stone.",1,ItemData.Category.TOOL))
	ItemDatabase.register_item(make_item(&"stone","Stone","Stone gathered from island rocks.",30,ItemData.Category.MATERIAL))
	ItemDatabase.register_item(make_item(&"axe","Axe","Click near a tree to chop. Three hits yield wood.",1,ItemData.Category.TOOL))
	for id in [&"string", &"leather"]:
		ItemDatabase.register_item(make_item(id,String(id).capitalize(),"Totem supplies.",20,ItemData.Category.MATERIAL))
	ItemDatabase.register_item(make_item(&"medpack","Medpack","Hold to restore full health.",1,ItemData.Category.TOOL))
	for metal in ["bronze", "silver", "gold"]:
		ItemDatabase.register_item(make_item(StringName(metal + "_key"), metal.capitalize() + " Key",
			"Insert into the Paradise gate. Returns to its sanctuary if lost.", 1, ItemData.Category.TOOL,
			load("res://assets/items/%s_key.png" % metal) as Texture2D))
	ItemDatabase.register_item(make_item(
		&"spyglass", "Spyglass",
		"Hold left-click to zoom out. Move the mouse to scout; release to return.",
		1, ItemData.Category.TOOL, preload("res://assets/items/spyglass.svg")
	))
	ItemDatabase.register_item(make_item(
		&"fish_cod",
		"Fish",
		"A common sea fish.",
		10,
		ItemData.Category.FOOD,
		SEABASS_ICON
	))
	ItemDatabase.register_item(make_item(
		&"rope",
		"Rope",
		"Strong cordage for general shipboard tasks.",
		25,
		ItemData.Category.MATERIAL,
		ROPE_ICON
	))
	ItemDatabase.register_item(make_item(
		&"fishing_rod",
		"Fishing Rod",
		"Click water to cast. At a bite, click again; hold and release to keep tension green.",
		1,
		ItemData.Category.TOOL
	))
	ItemDatabase.register_item(make_item(
		&"coconut",
		"Coconut",
		"A fresh coconut gathered from a tropical island.",
		20,
		ItemData.Category.FOOD,
		COCONUT_WHOLE_ICON
	))

	ItemDatabase.register_item(make_item(
		&"coal", "Coal", "Slow-burning fuel for the ship's grill.",
		30, ItemData.Category.MATERIAL, preload("res://assets/items/coal.svg")
	))
	# --- Island rewards ---
	ItemDatabase.register_item(make_item(
		&"wood",
		"Wood",
		"Timber for the grill or hull repairs.",
		30
	))
	ItemDatabase.register_item(make_item(
		&"dried_fish",
		"Fish Kabob",
		"Tender fish pieces on a wooden skewer. Supper at sea.",
		20,
		ItemData.Category.FOOD
	))

func make_item(
	item_id: StringName,
	item_display_name: String,
	item_description: String,
	item_max_stack: int = 1,
	item_category: ItemData.Category = ItemData.Category.FOOD,
	item_icon: Texture2D = null,
	item_draw_weight: float = 1.0,
	item_sell_value: int = 0
) -> ItemData:
	var item := ItemData.new()
	item.id = item_id
	item.max_durability = {&"axe": 30, &"pickaxe": 30, &"fishing_rod": 20}.get(item_id, 0)
	item.display_name = item_display_name
	item.description = item_description
	item.max_stack = item_max_stack
	item.category = item_category
	item.icon = item_icon
	var icon_path := "res://assets/items/%s.svg" % item_id
	if item.icon == null and ResourceLoader.exists(icon_path):
		item.icon = load(icon_path) as Texture2D
	var pixel_icon := PixelItemIcons.get_icon(item_id)
	if pixel_icon != null: item.icon = pixel_icon
	item.draw_weight = item_draw_weight
	item.sell_value = item_sell_value
	return item
