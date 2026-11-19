class_name QuestClue
extends Node2D
var key_id: String = "bronze"

func _ready() -> void:
	var label := Label.new()
	label.text = "E · Read " + key_id + " chart"
	label.position = Vector2(-130, 20)
	label.size.x = 260
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color("102531"))
	add_child(label)

func interact(crew: CharacterBody2D) -> bool:
	if not crew.on_land or crew.global_position.distance_to(global_position) > 75: return false
	for region in MapState.key_regions:
		if region.key != key_id: continue
		var island: Dictionary = MapState.island_catalog[region.island]
		MapState.discover_island(region.island, island.name, island.position)
		MapState.set_destination(island.position)
	return true

func _draw() -> void:
	draw_rect(Rect2(-5, -16, 10, 36), Color("785640"))
	draw_rect(Rect2(-25, -32, 50, 34), Color("e8d4a0"))
	draw_string(ThemeDB.fallback_font, Vector2(-8, -7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, QuestIsland.key_color(key_id))
