extends Control
## Drawn at UI resolution; food positions are normalized for every screen.
const FRAME = preload("res://assets/menus/grill_iron.png")
const BOARD := Rect2(48, 78, 282, 176)
const FUEL := Rect2(54, 320, 64, 64)
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
		elapsed += 0.0 if GameWindow.preferences.reduced_motion else delta
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
	draw_texture_rect(FRAME, Rect2(Vector2.ZERO, size), false)
	_text("GRILL", Vector2(162, 35), 18, Color("ddd0bf"))
	draw_rect(BOARD.grow(4), Color("15131d"))
	var active := model.cooking()
	for row in 8:
		for column in 15:
			var origin := BOARD.position + Vector2(column * 19 + 2, row * 22 + 3)
			var pulse := 0.5 + 0.5 * sin(elapsed * 2.2 + column * 2.7 + row * 4.1)
			var coal := Color("66302b").lerp(Color("db713c"), pulse * 0.65) if active else Color("241f29")
			draw_rect(Rect2(origin, Vector2(13, 13)), coal)
			if active:
				draw_rect(Rect2(origin + Vector2(2, 1), Vector2(7, 2)), Color(1, 0.66, 0.3, pulse * 0.7))
	for y in range(82, 251, 13):
		draw_line(Vector2(48, y + 3), Vector2(330, y + 3), Color("090d14"), 6)
		draw_line(Vector2(48, y), Vector2(330, y), Color("49515b"), 3)
		draw_line(Vector2(48, y - 1), Vector2(330, y - 1), Color("72747c"), 1)
	for x in [58, 320]:
		draw_line(Vector2(x, 78), Vector2(x, 254), Color("88909a"), 3)
	if model.fish.is_empty():
		var ghost := ItemDatabase.get_item(&"fish_cod")
		draw_texture_rect(ghost.icon, Rect2(BOARD.get_center() - FOOD_SIZE / 2, FOOD_SIZE), false, Color(1, 1, 1, 0.28))
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
			draw_polyline(PackedVector2Array([point + Vector2(-5, -22), point + Vector2(-1, -18), point + Vector2(7, -27)]), Color("cbe6a0"), 3)
		elif active and not GameWindow.preferences.reduced_motion:
			for i in 3:
				var phase := fmod(elapsed * 0.55 + float(i) / 3 + float(entry.key) * 0.13, 1.0)
				var puff := point + Vector2(sin(phase * 5 + i) * 9, -10 - phase * 30)
				draw_circle(puff, 2 + phase * 3, Color(0.87, 0.93, 0.93, (1 - phase) * 0.32), true, -1, true)
	draw_style_box(_box(Color("17151e"), Color("76727c"), 2, 3), FUEL)
	var fuel_item := ItemDatabase.get_item(model.fuel.get("id", &"wood"))
	if fuel_item != null:
		draw_texture_rect(fuel_item.icon, Rect2(FUEL.position + Vector2(10, 8), Vector2(42, 42)), false, Color(1, 1, 1, 0.35 if model.fuel.is_empty() else 1.0))
	if not model.fuel.is_empty():
		_text(str(model.fuel.quantity), FUEL.position + Vector2(43, 56), 14, Color("ffe2b1"))
	var heat := clampf(model.burn_remaining / maxf(1, model.burn_capacity), 0, 1)
	var flame := Vector2(157, 338)
	draw_colored_polygon(PackedVector2Array([flame + Vector2(-9, 5), flame + Vector2(-6, -7), flame + Vector2(-2, -2), flame + Vector2(2, -17), flame + Vector2(9, -3), flame + Vector2(8, 7), flame + Vector2(0, 11)]), Color("efa354") if active else Color("8b8185"))
	draw_style_box(_box(Color("14141d"), Color("78737c"), 2, 2), Rect2(179, 328, 146, 17))
	for i in 12:
		draw_rect(Rect2(183 + i * 11, 332, 8, 9), Color("eda05c") if heat > float(i) / 12 else Color("3d3843"))
	for i in 7:
		draw_rect(Rect2(152 + i * 24, 370, 15, 4), Color("17151e"))
	_text("Esc", Vector2(177, 412), 11, Color("ada4a5"))
func draw_ellipse_shadow(point: Vector2) -> void:
	draw_style_box(_box(Color(0, 0, 0, 0.4), Color.TRANSPARENT, 0, 12), Rect2(point - Vector2(25, 12), Vector2(50, 26)))

func _text(value: String, point: Vector2, font_size: int, color: Color) -> void:
	draw_string(HarborTheme.UI_FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
