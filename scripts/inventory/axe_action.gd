class_name AxeAction
extends Node2D
var service: InventoryService
var timer := 0.0
var cooldown := 0.0
var seen := 0
var direction := Vector2.RIGHT
var held: Sprite2D

func _ready() -> void:
	held = Sprite2D.new()
	held.texture = PixelItemIcons.get_icon(&"axe")
	held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	held.scale = Vector2.ONE*45.0/held.texture.get_width()
	held.visible = false
	add_child(held)
	z_index = 5

func local_control() -> bool:
	return not NetworkSession.online or service.network_id == NetworkSession.local_id

func _unhandled_input(event: InputEvent) -> void:
	if not local_control(): return
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if not tapped and not clicked: return
	if cooldown > 0 or not service.can_handle_items() or service.player.inventory_open or service.player.fishing_active: return
	var slot: int = service.hud.selected
	if slot < 0 or slot >= service.local_slots.size() or service.local_slots[slot].get("id") not in [&"axe",&"pickaxe"]: return
	if (service.player.is_overboard and not service.player.on_land) or service.player.access_motion != &"": return
	var point := service.player.get_global_mouse_position()
	if tapped: point = service.player.get_canvas_transform().affine_inverse()*event.position
	direction = (point-service.player.global_position).normalized()
	start_swing()
	cooldown = IslandFoliage.COOLDOWN
	if NetworkSession.online:
		NetworkSession.command("chop",{"point":point,"index":slot})
	else: service.get_parent().foliage.chop(service,point,slot)
	get_viewport().set_input_as_handled()

func start_swing() -> void:
	var item_id: StringName = service.local_slots[service.hud.selected].get("id",&"axe")
	held.texture = PixelItemIcons.get_icon(item_id if item_id in [&"axe",&"pickaxe"] else &"axe")
	held.scale = Vector2.ONE*30.0/maxf(held.texture.get_width(),held.texture.get_height())
	timer = 0.48
	service.player.chop_visual = 0.48
	service.player.chop_direction = direction
	service.get_parent().foliage.sound("axe_swing",service.player.global_position)

func _process(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	var serial: int = service.player.chop_serial
	if serial != seen:
		seen = serial
		if not local_control():
			direction = service.player.chop_direction
			start_swing()
	timer = maxf(0,timer-delta)
	service.player.chop_visual = timer
	held.visible = timer > 0 and service.player.health > 0
	queue_redraw()
	if not held.visible: return
	var t := 1.0-timer/0.48
	var arc := lerpf(-1.5,1.0,smoothstep(0.08,0.8,t))
	var angle := direction.angle()+arc
	held.position = Vector2(0,-13)+Vector2.from_angle(angle)*19.0
	held.rotation = angle+PI/4
	z_index = -1 if direction.y < -0.6 else 5

func _draw() -> void:
	if timer <= 0: return
	var hand := held.position+Vector2(-3,3).rotated(held.rotation)
	draw_line(Vector2(0,-14),hand,Color("775943"),5)
	draw_circle(hand,2.5,Color("dfaa77"))
	if timer > 0.13 and timer < 0.29:
		draw_arc(Vector2(0,-13),25,direction.angle()-0.6,direction.angle()+0.6,8,Color(1,0.9,0.65,0.35),2)

