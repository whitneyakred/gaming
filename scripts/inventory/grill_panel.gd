extends Control
## Drawn at UI resolution; food positions are normalized for every screen.
const BOARD := Rect2(22, 64, 334, 218)
const FUEL := Rect2(24, 320, 56, 56)
const FOOD_SIZE := Vector2(48, 36)
var hud: CanvasLayer
var elapsed: float = 0.0
var sizzle: AudioStreamPlayer
var _ready_keys: Dictionary = {}
var _was_visible: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sizzle = AudioStreamPlayer.new()
	sizzle.bus = &"Effects"
	sizzle.volume_db = -24
	add_child(sizzle)
	var rng := RandomNumberGenerator.new()
	rng.seed = 744
	var bytes := PackedByteArray()
	bytes.resize(22050 * 2)
	var previous := 0.0
	for i in 22050:
		var sample := rng.randf_range(-1, 1)
		var value := (sample - previous) * 0.22 * (0.6 + 0.4 * sin(float(i) * 0.007))
		previous = sample
		bytes.encode_s16(i * 2, int(value * 32767))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = bytes
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_end = 22050
	sizzle.stream = sound

func _exit_tree() -> void:
	if is_instance_valid(sizzle):
		sizzle.stop()
		sizzle.stream = null

func grill() -> ShipGrill:
	return hud.service.get_parent().get_node_or_null("Cooking") as ShipGrill

func _process(delta: float) -> void:
	var model := grill()
	if model == null:
		return
	if visible:
		elapsed += delta
		var keys := {}
		for entry in model.fish:
			if float(entry.progress) >= model.cook_seconds:
				keys[entry.key] = true
				if _was_visible and not _ready_keys.has(entry.key):
					GameWindow.play_ui("grill_ready")
		_ready_keys = keys
		queue_redraw()
	var audible := visible and model.cooking()
	if audible and not sizzle.playing:
		sizzle.play()
	elif not audible:
		sizzle.stop()
	_was_visible = visible

func _food_point(entry: Dictionary) -> Vector2:
	return BOARD.position + FOOD_SIZE / 2 + entry.point * (BOARD.size - FOOD_SIZE)

func _draw() -> void:
	var model := grill()
	if model == null:
		return
	draw_style_box(_box(Color("172a30"), Color("b48c4e"), 2, 8), Rect2(Vector2.ZERO, size))
	_text("SHIP'S GRILL", Vector2(22, 33), 22, Color("f2d69d"))
	_text("Click fish, then the grate · Click to collect", Vector2(22, 51), 12, Color("b7c9c7"))
	draw_style_box(_box(Color("0d151a"), Color("735337"), 4, 8), BOARD)
	var active := model.cooking()
	if active:
		for x in range(34, 348, 18):
			var glow := 0.16 + 0.08 * sin(elapsed * 4 + x)
			draw_rect(Rect2(x, BOARD.end.y - 28, 10, 22), Color(1, 0.32, 0.06, glow))
	for y in range(78, 276, 14):
		draw_line(Vector2(28, y + 2), Vector2(350, y + 2), Color("050a0e"), 5)
		draw_line(Vector2(28, y), Vector2(350, y), Color("465055"), 3, true)
	for x in [42, 336]:
		draw_line(Vector2(x, 71), Vector2(x, 275), Color("687075"), 3, true)
	if model.fish.is_empty():
		_text("Place sea bass anywhere", Vector2(94, 178), 14, Color("99a7a5"))
	for entry in model.fish:
		var point := _food_point(entry)
		var done: bool = float(entry.progress) >= model.cook_seconds
		draw_ellipse_shadow(point)
		var item := ItemDatabase.get_item(&"dried_fish" if done else &"fish_cod")
		if item != null and item.icon != null:
			draw_texture_rect(item.icon, Rect2(point - FOOD_SIZE / 2, FOOD_SIZE), false, Color("ffda93") if done else Color.WHITE)
		var progress := clampf(float(entry.progress) / model.cook_seconds, 0, 1)
		draw_rect(Rect2(point + Vector2(-20, 21), Vector2(40, 4)), Color("10191b"))
		draw_rect(Rect2(point + Vector2(-20, 21), Vector2(40 * progress, 4)), Color("9acb85") if done else Color("eda85c"))
		if done:
			_text("READY", point + Vector2(-18, -21), 10, Color("cbeca5"))
		elif active and not GameWindow.preferences.reduced_motion:
			for i in 3:
				var phase := fmod(elapsed * 0.55 + float(i) / 3 + float(entry.key) * 0.13, 1.0)
				var puff := point + Vector2(sin(phase * 5 + i) * 9, -10 - phase * 30)
				draw_circle(puff, 2 + phase * 3, Color(0.87, 0.93, 0.93, (1 - phase) * 0.32), true, -1, true)
	var status := "Cooking…" if active else ("Add wood or coal to cook" if model.has_raw() else "Grill idle · Fuel saved")
	_text(status, Vector2(22, 305), 15, Color("f2d69d") if active else Color("b7c9c7"))
	draw_style_box(_box(Color("382b24"), Color("967345"), 1, 5), FUEL)
	if not model.fuel.is_empty():
		var item := ItemDatabase.get_item(model.fuel.id)
		draw_texture_rect(item.icon, Rect2(FUEL.position + Vector2(8, 5), Vector2(38, 38)), false)
		_text(str(model.fuel.quantity), FUEL.position + Vector2(35, 49), 14, Color("fff1cc"))
	else:
		_text("FUEL", FUEL.position + Vector2(9, 33), 12, Color("b9a583"))
	_text("Heat remaining", Vector2(96, 337), 13, Color("c4d4cd"))
	draw_style_box(_box(Color("0d171c"), Color("506367"), 1, 3), Rect2(96, 348, 258, 15))
	var heat := clampf(model.burn_remaining / maxf(1, model.burn_capacity), 0, 1)
	draw_rect(Rect2(99, 351, 252 * heat, 9), Color("ee9d4d") if active else Color("98794d"))
	_text("Shift-click fuel to add · Click slot to remove", Vector2(22, 398), 12, Color("acbdbb"))
	_text("E / Esc to close", Vector2(140, 420), 12, Color("acbdbb"))

func draw_ellipse_shadow(point: Vector2) -> void:
	draw_style_box(_box(Color(0, 0, 0, 0.4), Color.TRANSPARENT, 0, 12), Rect2(point - Vector2(25, 12), Vector2(50, 26)))

func _text(value: String, point: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _box(fill: Color, edge: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _can_drop_data(point: Vector2, data: Variant) -> bool:
	if not hud.valid_drag(data) or data.get("storage", false):
		return false
	var index: int = data.get("index", -1)
	if index < 0 or index >= hud.service.local_slots.size():
		return false
	var id: StringName = hud.service.local_slots[index].get("id", &"")
	return (BOARD.has_point(point) and id == &"fish_cod") or (FUEL.has_point(point) and id in [&"wood", &"coal"])

func _drop_data(point: Vector2, data: Variant) -> void:
	var action := "fuel" if FUEL.has_point(point) else "fish"
	hud.request_grill({"action": action, "index": data.index, "revision": data.revision, "point": (point - BOARD.position - FOOD_SIZE / 2) / (BOARD.size - FOOD_SIZE)})

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if FUEL.has_point(event.position):
			hud.request_grill({"action": "withdraw"})
		else:
			var model := grill()
			for i in range(model.fish.size() - 1, -1, -1):
				var entry: Dictionary = model.fish[i]
				if Rect2(_food_point(entry) - Vector2(26, 24), Vector2(52, 52)).has_point(event.position):
					hud.request_grill({"action": "collect", "key": entry.key})
					break
		accept_event()
