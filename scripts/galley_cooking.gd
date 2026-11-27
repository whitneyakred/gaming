extends Control
## Unhurried food preparation. The shared station owns ingredient escrow.
signal completed
signal cancelled
enum Stage { FISH, ADD_FISH, HEAT, SKEWER, DONE }
const TITLES := ["Cut the fish", "Into the pot", "Turn on the heat", "Build your kabob", "Supper is ready"]
const HELP := ["Drag down each dotted line to slice.", "Drag the fish pieces into the pot.", "Click the stove. Let the fish simmer.", "Lift each piece out of the pot and onto the skewer.", "One fish kabob, ready for the voyage."]
const POT_CENTER := Vector2(535, 345)
const SKEWER_CENTER := Vector2(205, 345)
const FONT := preload("res://assets/fonts/rye/Rye-Regular.ttf")
const POT := preload("res://assets/cooking/pot_pixel.tres")
const KABOB := preload("res://assets/cooking/kabob_pixel.tres")
const KNIFE := preload("res://assets/cooking/knife_pixel.tres")
const RAW_PIECE := preload("res://assets/cooking/raw_piece_pixel.tres")
const COOKED_PIECE := preload("res://assets/cooking/cooked_piece_pixel.tres")
const POT_PIECE_SIZE := Vector2(44, 32)
@export_range(2.0, 30.0) var boil_seconds := 8.0
@export_range(0.5, 0.95) var overlay_size := 0.88
var fish_texture: Texture2D
var knife_texture: Texture2D = KNIFE
var stage: Stage = Stage.FISH
var cuts_per_food := 3
var cuts := 0
var pieces: Array[Vector2] = []
var selected_piece := -1
var dragging := false
var valid_stroke := false
var pointer := Vector2.ZERO
var knife_direction := Vector2.DOWN
var stroke_position := Vector2.ZERO
var heat := false
var temperature := 0.0
var elapsed := 0.0
var threaded := 0
var closed := false
var hint := ""

func _ready() -> void:
	add_to_group("cooking_activity")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	fish_texture = ItemDatabase.get_item(&"fish_cod").icon

func _scale_factor() -> float:
	return maxf(0.001, minf(size.x / 760.0, size.y / 660.0) * overlay_size)
func _origin() -> Vector2:
	return (size - Vector2(760, 660) * _scale_factor()) * 0.5
func _input(event: InputEvent) -> void:
	if get_tree().paused or closed: return
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")) and not event.is_echo():
		_cancel()
		get_viewport().set_input_as_handled()
func _cancel() -> void:
	closed = true
	cancelled.emit()
	queue_free()
func _gui_input(event: InputEvent) -> void:
	if get_tree().paused or closed: return
	if event is InputEventMouse: pointer = (event.position - _origin()) / _scale_factor()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(pointer)
		else: _release(pointer)
	elif event is InputEventMouseMotion: _move(pointer)
	accept_event()
func _cut_x() -> float:
	return 235.0 + 290.0 * float(cuts + 1) / 4.0
func _press(point: Vector2) -> void:
	if closed or get_tree().paused: return
	if Rect2(668, 20, 66, 38).has_point(point):
		_cancel()
		return
	dragging = true
	hint = ""
	match stage:
		Stage.FISH:
			knife_direction = Vector2.DOWN
			stroke_position = point
			valid_stroke = absf(point.x - _cut_x()) < 30 and point.y >= 195 and point.y <= 270
		Stage.ADD_FISH, Stage.SKEWER:
			for i in range(pieces.size() - 1, -1, -1):
				if point.distance_to(pieces[i]) < 48:
					selected_piece = i
					break
		Stage.HEAT:
			if Rect2(260, 498, 240, 52).has_point(point): heat = not heat
		Stage.DONE:
			if Rect2(260, 498, 240, 52).has_point(point):
				closed = true
				completed.emit()
				queue_free()
func _move(point: Vector2) -> void:
	if not dragging or closed: return
	if stage == Stage.FISH:
		var motion := point - stroke_position
		if motion.length_squared() >= 9:
			knife_direction = motion.normalized()
			stroke_position = point
		valid_stroke = valid_stroke and absf(point.x - _cut_x()) < 40
	elif selected_piece >= 0: pieces[selected_piece] = point
func _release(point: Vector2) -> void:
	if not dragging or closed: return
	dragging = false
	if stage == Stage.FISH:
		if valid_stroke and absf(point.x - _cut_x()) < 40 and point.y >= 440:
			cuts += 1
			if cuts == cuts_per_food: _advance()
		else: hint = "Start above the fish and slice down the line."
	elif selected_piece >= 0:
		var destination := POT_CENTER if stage == Stage.ADD_FISH else SKEWER_CENTER
		if point.distance_to(destination) < 115:
			pieces.remove_at(selected_piece)
			if stage == Stage.SKEWER: threaded += 1
			selected_piece = -1
			if pieces.is_empty(): _advance()
		else:
			pieces[selected_piece] = _piece_home(selected_piece)
			selected_piece = -1
			hint = "Drop inside the pot." if stage == Stage.ADD_FISH else "Drop onto the skewer."
func _pot_piece_home(index: int) -> Vector2:
	return POT_CENTER + Vector2(-28 + index % 2 * 56, -78 + floori(index / 2.0) * 36)
func _piece_home(index: int) -> Vector2:
	if stage == Stage.SKEWER: return _pot_piece_home(index)
	return Vector2(145 + index % 2 * 105, 290 + index / 2 * 95)
func _advance() -> void:
	stage = (int(stage) + 1) as Stage
	selected_piece = -1
	dragging = false
	hint = ""
	if stage == Stage.ADD_FISH or stage == Stage.SKEWER:
		pieces.clear()
		for i in 4: pieces.append(_piece_home(i))
func _process(delta: float) -> void:
	if closed: return
	elapsed += delta
	if stage == Stage.HEAT and heat:
		temperature = minf(1, temperature + delta / boil_seconds)
		if temperature >= 1: _advance()
	queue_redraw()
func _text(point: Vector2, value: String, font_size := 22, color := Color("433948")) -> void:
	draw_string(FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
func _panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(5), Color("3f3543"))
	draw_rect(rect, color)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.end.x - 3, rect.position.y + 3), Color("ebdac0"), 3)
func _board(rect: Rect2) -> void:
	_panel(rect, Color("bda98e"))
	for i in range(1, 6):
		var x := rect.position.x + rect.size.x * i / 6
		draw_line(Vector2(x, rect.position.y + 6), Vector2(x, rect.end.y - 6), Color("99866f"), 3)
func _draw_piece(point: Vector2, cooked: bool = false, piece_size := Vector2(62, 46)) -> void:
	draw_texture_rect(COOKED_PIECE if cooked else RAW_PIECE, Rect2(point - piece_size * 0.5, piece_size), false)
func _draw_knife() -> void:
	var knife_size := KNIFE.get_size() * 0.11
	var angle := knife_direction.angle() - Vector2(knife_size.x, -knife_size.y).angle()
	# The blade tip stays at the cursor; the handle trails the cutting direction.
	draw_set_transform(_origin() + pointer * _scale_factor(), angle, Vector2.ONE * _scale_factor())
	draw_texture_rect(KNIFE, Rect2(Vector2(-knife_size.x, 0), knife_size), false)
	draw_set_transform(_origin(), 0, Vector2.ONE * _scale_factor())
func _pot() -> void:
	draw_texture_rect(POT, Rect2(POT_CENTER - Vector2(140, 130), Vector2(280, 260)), false)
	if stage == Stage.ADD_FISH or stage == Stage.HEAT:
		var count := 4 - pieces.size() if stage == Stage.ADD_FISH else 4
		for i in count: _draw_piece(_pot_piece_home(i), temperature > 0.5, POT_PIECE_SIZE)
	if stage == Stage.HEAT and heat:
		for i in 3:
			draw_rect(Rect2(POT_CENTER + Vector2(-28 + i * 24, 78), Vector2(9, 10 + sin(elapsed * 8 + i) * 3)), Color("d78d55"))
	if stage == Stage.HEAT or stage == Stage.SKEWER:
		for i in 4:
			var rise := fmod(elapsed * 23 + i * 22, 85)
			draw_rect(Rect2(POT_CENTER + Vector2(-55 + i * 32, -65 - rise), Vector2(5, 9)), Color(0.95, 0.9, 0.8, temperature * (1 - rise / 85)))
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.18, 0.72))
	draw_set_transform(_origin(), 0, Vector2.ONE * _scale_factor())
	_panel(Rect2(0, 0, 760, 660), Color("f0ddc2"))
	_text(Vector2(28, 50), TITLES[stage], 29)
	_panel(Rect2(668, 20, 66, 38), Color("d6b9a1"))
	_text(Vector2(681, 47), "Esc", 16)
	for i in 4:
		var x := 28 + i * 184
		draw_rect(Rect2(x, 83, 166, 32), Color("bd7180") if i == mini(stage, 3) else Color("d6c1aa"))
		_text(Vector2(x + 12, 106), ["1. Chop", "2. Pot", "3. Heat", "4. Skewer"][i], 17)
	_board(Rect2(28, 144, 704, 422))
	match stage:
		Stage.FISH:
			draw_texture_rect(fish_texture, Rect2(235, 270, 290, 165), false)
			for i in cuts:
				_draw_piece(Vector2(295 + i * 84, 510))
			draw_dashed_line(Vector2(_cut_x(), 230), Vector2(_cut_x(), 470), Color("fff0d8"), 4, 10)
			draw_rect(Rect2(_cut_x() - 7, 221, 14, 14), Color("bd7180"))
			if dragging: _draw_knife()
		Stage.ADD_FISH, Stage.SKEWER:
			_pot()
			if stage == Stage.SKEWER:
				draw_line(Vector2(110, 440), Vector2(300, 250), Color("59493d"), 8)
				draw_line(Vector2(110, 440), Vector2(300, 250), Color("d6b184"), 4)
				for i in threaded: _draw_piece(Vector2(148 + i * 38, 402 - i * 38), true)
			for point in pieces: _draw_piece(point, stage == Stage.SKEWER, POT_PIECE_SIZE if stage == Stage.SKEWER else Vector2(62, 46))
		Stage.HEAT:
			_pot()
			_text(Vector2(70, 295), "A gentle simmer.", 21)
			draw_rect(Rect2(70, 365, 245, 15), Color("7b6b65"))
			draw_rect(Rect2(73, 368, 239 * temperature, 9), Color("e6b476"))
			_panel(Rect2(260, 498, 240, 52), Color("e8c397"))
			_text(Vector2(289, 532), "Heat off" if heat else "Light the stove", 22)
		Stage.DONE:
			draw_texture_rect(KABOB, Rect2(265, 195, 230, 265), false)
			_panel(Rect2(260, 498, 240, 52), Color("e8c397"))
			_text(Vector2(283, 532), "Take fish kabob", 21)
	_text(Vector2(28, 613), hint if not hint.is_empty() else HELP[stage], 19)
