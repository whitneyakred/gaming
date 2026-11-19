class_name MinigameTotem
extends Node2D
## Lightweight replaceable marker. Occupancy belongs to IslandChallenges.
@export var interaction_distance: float = 64.0
var occupied: bool = false
var caption: Label

func _ready() -> void:
	z_index = 30
	caption = Label.new()
	caption.position = Vector2(-150, 12)
	caption.size = Vector2(300, 60)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color("102531"))
	caption.add_theme_constant_override("outline_size", 4)
	add_child(caption)
	set_occupied(false)

func set_occupied(value: bool) -> void:
	occupied = value
	if caption:
		var island := get_parent() as WorldIsland
		var title := island.scene.get_file().get_basename().replace("_", " ").capitalize()
		if title == "Island": title = "Coconut Island"
		caption.text = title + ("\nOccupied — wait for your turn" if value else "\nE · Play challenge")
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 27, Color(0.08, 0.2, 0.2, 0.55))
	draw_rect(Rect2(-13, -45, 26, 48), Color("765239"))
	draw_rect(Rect2(-18, -44, 36, 10), Color("e3c17b"))
	draw_circle(Vector2(-6, -24), 4, Color("e3a459") if occupied else Color("6ee7cc"))
	draw_circle(Vector2(6, -24), 4, Color("e3a459") if occupied else Color("6ee7cc"))
	draw_line(Vector2(-7, -10), Vector2(7, -10), Color("e3c17b"), 3)
