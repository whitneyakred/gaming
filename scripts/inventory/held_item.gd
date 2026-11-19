class_name HeldItem
extends Sprite2D
var service: InventoryService
var last_id: StringName = &""
var clock := 0.0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 3
func _process(delta: float) -> void:
	if not is_instance_valid(service): return
	clock += delta
	var selected: int = service.hud.selected
	var item_id: StringName = service.local_slots[selected].get("id", &"") if selected >= 0 and selected < service.local_slots.size() else &""
	if item_id != last_id:
		last_id = item_id
		var item := ItemDatabase.get_item(item_id)
		texture = item.icon if item else null
		if texture:
			var length := 30.0 if item_id == &"fishing_rod" else 17.0
			scale = Vector2.ONE * length / maxf(texture.get_width(), texture.get_height())
	visible = texture != null and not service.player.using_station and not (item_id == &"fishing_rod" and service.player.fishing_active)
	visible = visible and not (service.player.is_overboard and not service.player.on_land)
	position = Vector2(12, -15 if not service.player.is_overboard else -7)
	if service.player.idle_sprite is CrewSprite:
		var facing: int = service.player.idle_sprite.facing
		position = [Vector2(11, -12), Vector2(-10, -13), Vector2(10, -13), Vector2(-9, -15)][facing]
		z_index = -1 if facing == 3 else 3
		flip_h = facing == 1
	rotation = -0.35 + sin(clock*7)*0.06 if service.player.velocity.length()>1 else -0.35
