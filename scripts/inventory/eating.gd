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
	z_index = 20
	voice = AudioStreamPlayer.new()
	voice.bus = "Effects"
	voice.stream = ActionAudio.make("eat")
	add_child(voice)

func start() -> void:
	if active or service.player.hunger >= 15: return
	slot = service.hud.selected
	item = service.local_slots[slot].get("id", &"")
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
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not DisplayServer.window_is_focused() or not service.can_handle_items() or service.hud.storage_open or service.hud.grill_open or service.player.fishing_active or service.hud.selected != slot or service.local_slots[slot].get("id", &"") != item or service.player.hunger >= 15:
			active = false
			elapsed = 0.0
			voice.stop()
		else:
			elapsed += delta
			beat -= delta
			if beat <= 0:
				beat = 0.28
				voice.pitch_scale = randf_range(0.9,1.15)
				voice.play()
				for i in 4:
					crumbs.append({"position": service.player.global_position + Vector2(5,-19), "velocity": Vector2(randf_range(-35,35),randf_range(-40,-15)), "life": 0.5, "color": Color("e6bf80") if item == &"dried_fish" else Color("a7c8be")})
			if elapsed >= HOLD_SECONDS:
				if NetworkSession.online:
					NetworkSession.command("eat", {"index": slot, "revision": service.view_revision})
				else: service.get_parent().survival.eat(service.network_id,slot)
				elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	for crumb in crumbs:
		var color: Color = crumb.color
		color.a = minf(1,crumb.life*4)
		draw_rect(Rect2(crumb.position,Vector2(3,3)),color)
