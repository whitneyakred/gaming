extends Node2D
var service: Node

func _ready() -> void:
	service = get_parent()
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta: float) -> void:
	visible = true
	queue_redraw()

func _draw() -> void:
	if service == null:
		return
	if service.chest_enabled:
		draw_texture_rect(preload("res://assets/items/chest.svg"), Rect2(service.storage_position - Vector2(24, 24), Vector2(48, 48)), false)
	for key: int in service.drops:
		var entry: Dictionary = service.drops[key]
		var item: ItemData = ItemDatabase.get_item(entry.id)
		var point: Vector2 = entry.position + Vector2((key % 3 - 1) * 7, (key % 2) * 5)
		draw_set_transform(point, -global_rotation)
		draw_circle(Vector2(0, 6), 12, Color(0, 0, 0, 0.3))
		if item != null and item.icon != null:
			draw_texture_rect(item.icon, Rect2(Vector2(-13, -13), Vector2(26, 26)), false)
	draw_set_transform(Vector2.ZERO)
