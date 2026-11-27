extends Node2D
@export var closed_chest_texture: Texture2D = preload("res://assets/props/chest_overhead_closed.png")
@export var open_chest_texture: Texture2D = preload("res://assets/props/chest_overhead_open.png")
@export var chest_size := Vector2(22, 34)
var service: Node

func chest_texture(chest_id: int) -> Texture2D:
	if NetworkSession.online:
		for value in NetworkSession.services.values():
			if value.hud.storage_open and value.active_chest_id == chest_id:
				return open_chest_texture
	return open_chest_texture if service.hud != null and service.hud.storage_open and service.active_chest_id == chest_id else closed_chest_texture

func _ready() -> void:
	service = get_parent()
	z_index = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if service.chest_enabled:
		for index in range(2):
			var body := StaticBody2D.new()
			body.name = "ChestCollision%d" % index
			body.position = service.storage_positions()[index]
			body.rotation = deg_to_rad(service.chest_wall_angle_degrees) * (1.0 if index == 0 else -1.0)
			body.collision_layer = 1
			body.collision_mask = 0
			var shape := RectangleShape2D.new()
			shape.size = chest_size
			var collider := CollisionShape2D.new()
			collider.shape = shape
			body.add_child(collider)
			add_child(body)
func _process(_delta: float) -> void:
	visible = true
	queue_redraw()

func _draw() -> void:
	if service == null:
		return
	if service.chest_enabled:
		for index in range(2):
			var mirror := 1.0 if index == 0 else -1.0
			draw_set_transform(service.storage_positions()[index], deg_to_rad(service.chest_wall_angle_degrees) * mirror, Vector2(mirror, 1))
			draw_texture_rect_region(chest_texture(index), Rect2(-chest_size * 0.5, chest_size), Rect2(180, 80, 650, 1400))
		draw_set_transform(Vector2.ZERO)
	for key: int in service.drops:
		var entry: Dictionary = service.drops[key]
		var item: ItemData = ItemDatabase.get_item(entry.id)
		var point: Vector2 = (to_local(entry.position) if entry.get("world", false) else entry.position) + Vector2((key % 3 - 1) * 7, (key % 2) * 5)
		if entry.has("spawn_origin") and entry.has("spawn_time") and service.get_parent() is Ship:
			var t := clampf((service.get_parent().ocean_fish.shared_time()-float(entry.spawn_time))/0.75,0.0,1.0)
			point = to_local(entry.spawn_origin).lerp(point,t) + Vector2(0,-sin(t*PI)*32.0)
		draw_set_transform(point, -global_rotation)
		draw_circle(Vector2(0, 6), 12, Color(0, 0, 0, 0.3))
		if item != null and item.icon != null:
			draw_texture_rect(item.icon, Rect2(Vector2(-13, -13), Vector2(26, 26)), false)
	draw_set_transform(Vector2.ZERO)




