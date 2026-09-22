extends Node2D
var service: Node

func _ready() -> void:
	service = get_node("../../InventorySystem")
	z_index = 2

func _process(_delta: float) -> void:
	visible = service.session != null and service.session.running
	queue_redraw()

func _draw() -> void:
	if service == null:
		return
	var p: Vector2 = service.storage_position
	draw_ellipse_shadow(p)
	draw_rect(Rect2(p - Vector2(19, 13), Vector2(38, 28)), Color("32231c"))
	draw_rect(Rect2(p - Vector2(17, 12), Vector2(34, 24)), Color("96602f"))
	for y in [-6, 1, 8]:
		draw_line(p + Vector2(-16, y), p + Vector2(16, y), Color("58391f"), 2)
	for x in [-12, 10]:
		draw_rect(Rect2(p + Vector2(x, -12), Vector2(3, 24)), Color("dfb35b"))
	draw_rect(Rect2(p + Vector2(-3, -3), Vector2(6, 7)), Color("f8d780"))
	for key: int in service.drops_view:
		var entry: Dictionary = service.drops_view[key]
		var item: ItemData = ItemDatabase.get_item(entry.id)
		var point: Vector2 = entry.position + Vector2((key % 3 - 1) * 7, (key % 2) * 5)
		draw_circle(point + Vector2(0, 6), 12, Color(0, 0, 0, 0.3))
		if item != null and item.icon != null:
			draw_texture_rect(item.icon, Rect2(point - Vector2(13, 13), Vector2(26, 26)), false)

func draw_ellipse_shadow(point: Vector2) -> void:
	draw_style_box(_shadow(), Rect2(point - Vector2(21, 10), Vector2(42, 29)))

func _shadow() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.3)
	style.set_corner_radius_all(8)
	return style
