class_name MinigameTotem
extends Node2D
## Lightweight replaceable marker. Occupancy belongs to IslandChallenges.
@export var interaction_distance: float = 64.0
var occupied: bool = false
var cooldown := 0
var caption: Label
var cooldown_remaining := 0.0
var cooldown_ring: Node2D

func _ready() -> void:
	z_index = 30
	z_as_relative = false
	cooldown_ring = Node2D.new()
	cooldown_ring.z_as_relative = false
	cooldown_ring.z_index = 4080
	cooldown_ring.draw.connect(_draw_cooldown)
	add_child(cooldown_ring)
	caption = Label.new()
	caption.z_as_relative = false
	caption.z_index = 4081
	caption.position = Vector2(-150, 12)
	caption.size = Vector2(300, 60)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color("102531"))
	caption.add_theme_constant_override("outline_size", 4)
	add_child(caption)
	set_occupied(false)

func set_cooldown(seconds: float) -> void:
	var next := clampf(seconds,0.0,300.0)
	if cooldown_remaining != next:
		cooldown_remaining = next
		if cooldown_ring != null: cooldown_ring.queue_redraw()
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

func _draw_cooldown() -> void:
	if cooldown_remaining <= 0.0: return
	var at := Vector2(0,-88)
	cooldown_ring.draw_arc(at,11,0,TAU,40,Color(0.08,0.12,0.1,0.8),4.0)
	cooldown_ring.draw_arc(at,11,-PI*0.5,-PI*0.5+TAU*cooldown_remaining/300.0,40,Color("f6d565"),3.0)
