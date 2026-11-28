extends Node2D
## Local presentation stays responsive; the host validates the completed food use.
const HOLD_SECONDS := 1.4
var service: InventoryService
var active := false
var elapsed := 0.0
var beat := 0.0
var slot := -1
var item: StringName
var crumbs: Array[Dictionary] = []
var voice: AudioStreamPlayer

func _ready() -> void:
	set_as_top_level(true)
	global_transform = Transform2D.IDENTITY
	z_as_relative = false
	z_index = 4090
	voice = AudioStreamPlayer.new()
	voice.bus = "Effects"
	voice.stream = ActionAudio.make("eat")
	add_child(voice)

func start() -> void:
	if active: return
	slot = service.hud.selected
	item = service.local_slots[slot].get("id", &"")
	if (service.player.health >= 15 if item == &"medpack" else service.player.hunger >= 15): return
	voice.stream = ActionAudio.make("bandage" if item == &"medpack" else "eat")
	if item == &"medpack": medical_command("start")
	active = true
	elapsed = 0.0
	beat = 0.0

func _process(delta: float) -> void:
	for crumb in crumbs:
		crumb.life -= delta
		crumb.velocity.y += delta * 90
		crumb.position += crumb.velocity * delta
	crumbs = crumbs.filter(func(c): return c.life > 0)
	if active:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not DisplayServer.window_is_focused() or not service.can_handle_items() or service.hud.storage_open or service.hud.grill_open or service.hud.crafting_open or service.player.fishing_active or service.hud.selected != slot or service.local_slots[slot].get("id", &"") != item or (service.player.health >= 15 if item == &"medpack" else service.player.hunger >= 15):
			active = false
			if item == &"medpack": medical_command("cancel")
			elapsed = 0.0
			voice.stop()
		else:
			elapsed += delta
			beat -= delta
			if beat <= 0:
				beat = 0.28
				voice.pitch_scale = randf_range(0.9,1.15)
				voice.play()
				for i in (0 if item == &"medpack" else 4):
					crumbs.append({"position": service.player.global_position + Vector2(5,-19), "velocity": Vector2(randf_range(-35,35),randf_range(-40,-15)), "life": 0.5, "color": Color("e6bf80") if item == &"dried_fish" else Color("a7c8be")})
			if elapsed >= (2.0 if item == &"medpack" else HOLD_SECONDS):
				if item == &"medpack":
					medical_command("finish")
					active = false
					voice.stop()
				elif NetworkSession.online:
					NetworkSession.command("eat", {"index": slot, "revision": service.view_revision})
				else: service.get_parent().survival.eat(service.network_id,slot)
				elapsed = 0.0
	queue_redraw()

func medical_command(action: String) -> void:
	if NetworkSession.online: NetworkSession.command("medpack",{"action":action,"index":slot})
	else: service.get_parent().survival.medpack(1,action,slot)

func _draw() -> void:
	if active:
		var at: Vector2 = service.player.visual_position() + Vector2(0,-37)
		var duration := 2.0 if item == &"medpack" else HOLD_SECONDS
		var color := Color("a8edb8") if item == &"medpack" else Color("f2ce62")
		draw_arc(at,10,0,TAU,32,Color(0.04,0.12,0.16,0.8),4.0)
		draw_arc(at,10,-PI*0.5,-PI*0.5+TAU*clampf(elapsed/duration,0,1),32,color,3.0)
	for crumb in crumbs:
		var color: Color = crumb.color
		color.a = minf(1,crumb.life*4)
		draw_rect(Rect2(crumb.position,Vector2(3,3)),color)
