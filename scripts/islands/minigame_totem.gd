class_name MinigameTotem
extends Node2D
## Lightweight replaceable marker. Occupancy belongs to IslandChallenges.
@export var interaction_distance: float = 64.0
var occupied: bool = false
var cooldown := 0
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

func set_cooldown(seconds: float) -> void:
	var remaining := ceili(seconds)
	if remaining == cooldown: return
	cooldown = remaining
	set_occupied(occupied)

func set_occupied(value: bool) -> void:
	occupied = value
	if caption:
		var island := get_parent() as WorldIsland
		var title := island.scene.get_file().get_basename().replace("_", " ").capitalize()
		if title == "Island": title = "Coconut Island"
		caption.text = title + ("\nResting %d:%02d" % [cooldown / 60,cooldown % 60] if cooldown > 0 else ("\nOccupied — wait for your turn" if value else ""))
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 27, Color(0.08, 0.2, 0.2, 0.4))
	var icon := TotemArt.texture(0)
	var size := icon.get_size() * (80.0 / icon.get_height())
	draw_texture_rect(icon, Rect2(Vector2(-size.x / 2, -size.y + 8), size), false, Color("a39b86") if occupied else Color.WHITE)
