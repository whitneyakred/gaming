extends PanelContainer
## Choosing an icon previews its recipe; only Craft submits the transaction.
var hud: CanvasLayer
var selected_recipe: String = ""
var recipe_name: Label
var ingredients: HBoxContainer
var craft_button: Button
var choices: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -378
	offset_right = -24
	offset_top = -155
	offset_bottom = 155
	add_theme_stylebox_override("panel", hud._panel_style())
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	add_child(rows)
	rows.add_child(hud._label("Workbench", 24, Color("e5c58a")))
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override("separation", 8)
	rows.add_child(icons)
	var group := ButtonGroup.new()
	for recipe: String in CraftingStation.RECIPES:
		var item := ItemDatabase.get_item(StringName(recipe))
		var button := Button.new()
		button.icon = item.icon
		button.tooltip_text = item.display_name
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", 44)
		button.custom_minimum_size = Vector2(70, 64)
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(select_recipe.bind(recipe))
		icons.add_child(button)
		choices[recipe] = button
	recipe_name = hud._label("", 20, Color("ead7ad"))
	rows.add_child(recipe_name)
	ingredients = HBoxContainer.new()
	ingredients.alignment = BoxContainer.ALIGNMENT_CENTER
	ingredients.add_theme_constant_override("separation", 18)
	rows.add_child(ingredients)
	craft_button = Button.new()
	craft_button.custom_minimum_size.y = 36
	craft_button.pressed.connect(_craft)
	rows.add_child(craft_button)
	var done := Button.new()
	done.text = "Close [E / Esc]"
	done.pressed.connect(func() -> void:
		if NetworkSession.online: NetworkSession.command("close")
		hud.close())
	rows.add_child(done)
	hud.service.updated.connect(_refresh)
	select_recipe("fishing_rod")

func select_recipe(recipe: String) -> void:
	selected_recipe = recipe
	choices[recipe].button_pressed = true
	_refresh()

func _refresh() -> void:
	if selected_recipe.is_empty(): return
	var item := ItemDatabase.get_item(StringName(selected_recipe))
	recipe_name.text = item.display_name
	for child in ingredients.get_children():
		ingredients.remove_child(child)
		child.queue_free()
	var affordable := true
	for material: String in CraftingStation.RECIPES[selected_recipe]:
		var needed: int = CraftingStation.RECIPES[selected_recipe][material]
		var owned: int = hud.service.inventory.get_quantity(StringName(material))
		affordable = affordable and owned >= needed
		var column := VBoxContainer.new()
		ingredients.add_child(column)
		var icon := TextureRect.new()
		icon.texture = ItemDatabase.get_item(StringName(material)).icon
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(62, 32)
		column.add_child(icon)
		column.add_child(hud._label("%d %s" % [needed, material.capitalize()], 15, Color("ead7ad") if owned >= needed else Color("dc9280")))
	craft_button.text = "Craft " + item.display_name
	craft_button.disabled = not affordable

func _craft() -> void:
	if NetworkSession.online:
		NetworkSession.command("craft", {"action": selected_recipe, "revision": hud.service.view_revision})
	else:
		hud.service.get_parent().get_node("Crafting").craft(hud.service, selected_recipe, hud.service.view_revision)
