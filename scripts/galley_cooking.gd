extends Control
## Local recipe activity. Only the station awards/consumes stock.
signal completed(stars: int)
signal cancelled

enum Stage { POTATO, ADD_POTATO, FISH, ADD_FISH, WATER, HEAT, DONE }
@export_range(3, 8) var cuts_per_food: int = 5
@export_range(1.0, 10.0) var fill_seconds: float = 3.0
@export_range(2.0, 30.0) var boil_seconds: float = 8.0
@export var slice_tolerance: float = 26.0
@export_range(20.0, 180.0) var recipe_seconds: float = 90.0
## Fraction of the viewport available to the centered task panel.
@export_range(0.5, 0.95, 0.05) var overlay_size: float = 0.8
var time_left: float
var timed_out: bool = false
var stars: int = 0
var accuracy: float = 0.0
var cut_error: float = 0.0
var cut_scores: Array[float] = []
var drop_scores: Array[float] = []
var water_score: float = 0.0
var heat_score_sum: float = 0.0
var heat_scored_seconds: float = 0.0
var stage: Stage = Stage.POTATO
var cuts: int = 0
var pieces: Array[Vector2] = []
var added: int = 0
var dragging: bool = false
var valid_stroke: bool = false
var selected_piece: int = -1
var pointer := Vector2.ZERO
var jug := Vector2(180, 350)
var water: float = 0.0
var heat: float = 0.0
var temperature: float = 0.0
var simmer: float = 0.0
var elapsed: float = 0.0
var transitioning: bool = false
var veil: float = 0.0
var hint: String = ""
var closed: bool = false
const POT_CENTER := Vector2(550, 350)
const FOOD_CENTER := Vector2(220, 345)
const TITLES := ["Slice the potato", "Potato into the pot", "Cut the fish", "Fish into the pot", "Add fresh water", "Turn up the heat", "Supper is ready"]
const HELP := ["Hold above the bright line. Slice downward and release below the potato.", "Drag each potato piece from the board into the open pot.", "Hold above the bright line. Slice downward through the fish.", "Drag every piece of fish into the pot.", "Hold the pitcher over the pot. Release at the 75% water target.", "Set heat in the green target zone and wait for the pot to boil.", "Stars: 90% = 3, 70% = 2, 40% = 1. Click Serve to finish."]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	time_left = recipe_seconds

func _scale_factor() -> float:
	return maxf(0.001, minf(size.x, size.y) / 720.0 * overlay_size)

func _origin() -> Vector2:
	return (size - Vector2(720, 720) * _scale_factor()) * 0.5

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not closed:
		closed = true
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if transitioning or closed:
		return
	if event is InputEventMouse:
		pointer = (event.position - _origin()) / _scale_factor()
	if stage == Stage.POTATO or stage == Stage.FISH:
		if pointer.y > 130:
			pointer.x -= 140
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(pointer)
		else:
			_release(pointer)
	elif event is InputEventMouseMotion:
		_move(pointer)
	accept_event()

func _cut_x() -> float:
	return 100.0 + 240.0 * float(cuts + 1) / float(cuts_per_food + 1)

func _press(point: Vector2) -> void:
	if Rect2(620, 20, 75, 40).has_point(point):
		closed = true
		cancelled.emit()
		queue_free()
		return
	dragging = true
	hint = ""
	match stage:
		Stage.POTATO, Stage.FISH:
			cut_error = absf(point.x - _cut_x())
			valid_stroke = absf(point.x - _cut_x()) < slice_tolerance and point.y >= 190 and point.y <= 230
		Stage.ADD_POTATO, Stage.ADD_FISH:
			for i in range(pieces.size() - 1, -1, -1):
				if point.distance_to(pieces[i]) < 42:
					selected_piece = i
					break
		Stage.WATER:
			dragging = point.distance_to(jug) < 90
		Stage.HEAT:
			dragging = Rect2(120, 510, 480, 65).has_point(point)
			if dragging:
				heat = clampf((point.x - 140) / 440.0, 0, 1)
		Stage.DONE:
			if Rect2(240, 530, 240, 65).has_point(point):
				if timed_out:
					_retry()
					return
				closed = true
				completed.emit(stars)
				queue_free()

func _move(point: Vector2) -> void:
	if not dragging:
		return
	match stage:
		Stage.POTATO, Stage.FISH:
			cut_error = maxf(cut_error, absf(point.x - _cut_x()))
			valid_stroke = valid_stroke and absf(point.x - _cut_x()) <= slice_tolerance
		Stage.ADD_POTATO, Stage.ADD_FISH:
			if selected_piece >= 0:
				pieces[selected_piece] = point
		Stage.WATER:
			jug = point
		Stage.HEAT:
			heat = clampf((point.x - 140) / 440.0, 0, 1)

func _release(point: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	match stage:
		Stage.POTATO, Stage.FISH:
			if valid_stroke and absf(point.x - _cut_x()) <= slice_tolerance and point.y >= 470:
				cut_error = maxf(cut_error, absf(point.x - _cut_x()))
				cut_scores.append(clampf(1.0 - cut_error / slice_tolerance, 0, 1))
				cuts += 1
				if cuts >= cuts_per_food:
					_next_stage()
			else:
				cut_scores.append(0.0)
			hint = "Start at the dot and pull straight down past the food."
		Stage.ADD_POTATO, Stage.ADD_FISH:
			if selected_piece >= 0:
				if point.distance_to(POT_CENTER) < 125:
					drop_scores.append(clampf(1.0 - point.distance_to(POT_CENTER) / 125.0, 0, 1))
					pieces.remove_at(selected_piece)
					added += 1
				else:
					drop_scores.append(0.0)
					pieces[selected_piece] = _piece_home(selected_piece)
				selected_piece = -1
				if pieces.is_empty():
					_next_stage()
		Stage.WATER:
			jug = Vector2(180, 350)
			if water >= 0.2:
				water_score = clampf(1.0 - absf(water - 0.75) / 0.25, 0, 1)
				_next_stage()
			else:
				hint = "Add more water, then release near the 75% line."

func _next_stage() -> void:
	if transitioning:
		return
	transitioning = true
	dragging = false
	var tween := create_tween()
	tween.tween_property(self, "veil", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_advance)
	tween.tween_property(self, "veil", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: transitioning = false)

func _advance() -> void:
	stage = (int(stage) + 1) as Stage
	if stage == Stage.DONE:
		_score_result()
	cuts = 0
	hint = ""
	selected_piece = -1
	if stage == Stage.ADD_POTATO or stage == Stage.ADD_FISH:
		pieces.clear()
		for i in range(cuts_per_food + 1):
			pieces.append(_piece_home(i))

func _piece_home(index: int) -> Vector2:
	return Vector2(100 + (index % 3) * 90, 280 + floori(index / 3.0) * 95)

func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / values.size()

func _score_result() -> void:
	var heat_score := heat_score_sum / maxf(heat_scored_seconds, 0.001)
	accuracy = (_average(cut_scores) + _average(drop_scores) + water_score + heat_score) / 4.0
	stars = 3 if accuracy >= 0.9 else (2 if accuracy >= 0.7 else (1 if accuracy >= 0.4 else 0))
	if timed_out:
		stars = 0

func _retry() -> void:
	stage = Stage.POTATO
	cuts = 0
	pieces.clear()
	added = 0
	dragging = false
	selected_piece = -1
	water = 0
	heat = 0
	temperature = 0
	simmer = 0
	cut_scores.clear()
	drop_scores.clear()
	water_score = 0
	heat_score_sum = 0
	heat_scored_seconds = 0
	time_left = recipe_seconds
	timed_out = false
	stars = 0
	accuracy = 0
	hint = ""
	jug = Vector2(180, 350)

func _process(delta: float) -> void:
	elapsed += delta
	if not transitioning and stage != Stage.DONE and not closed:
		time_left = maxf(0, time_left - delta)
		if time_left <= 0:
			timed_out = true
			stage = Stage.DONE
			dragging = false
			hint = "Time ran out. No meal awarded. Retry or press Escape to leave."
			_score_result()
		elif stage == Stage.WATER and dragging and jug.distance_to(Vector2(550, 200)) < 110:
			water = minf(1.0, water + delta / fill_seconds)
		elif stage == Stage.HEAT:
			if heat > 0:
				heat_score_sum += clampf(1.0 - absf(heat - 0.7) / 0.3, 0, 1) * delta
				heat_scored_seconds += delta
			temperature = clampf(temperature + (heat - 0.2) * delta / boil_seconds, 0, 1)
			if temperature >= 1 and heat > 0.2:
				simmer += delta
				if simmer >= 2.0:
					_next_stage()
	queue_redraw()

# Deliberately plain shapes. Replace this drawing layer when art direction is set.
func _text(point: Vector2, text: String, font_size: int = 22) -> void:
	draw_string(ThemeDB.fallback_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	draw_set_transform(_origin(), 0, Vector2.ONE * _scale_factor())
	draw_rect(Rect2(0, 0, 720, 720), Color(0.15, 0.15, 0.17))
	draw_rect(Rect2(0, 0, 720, 720), Color.GRAY, false, 3)
	_text(Vector2(25, 48), "Time's up" if timed_out else TITLES[stage], 28)
	draw_rect(Rect2(620, 20, 75, 40), Color.DIM_GRAY)
	_text(Vector2(630, 48), "X / Esc", 18)
	_text(Vector2(25, 95), "Step %d / 6" % mini(int(stage) + 1, 6))
	_text(Vector2(500, 95), "Time: %d s" % ceili(time_left), 24)
	if stage == Stage.POTATO or stage == Stage.FISH:
		draw_rect(Rect2(55, 160, 610, 385), Color(0.4, 0.35, 0.28))
		# The cutting board uses the whole work area; pot appears for transfer steps.
		draw_set_transform(_origin() + Vector2(140, 0) * _scale_factor(), 0, Vector2.ONE * _scale_factor())
		draw_rect(Rect2(85, 245, 270, 200), Color.KHAKI if stage == Stage.POTATO else Color.SALMON)
		for i in range(cuts):
			var x := 100.0 + 240.0 * float(i + 1) / float(cuts_per_food + 1)
			draw_line(Vector2(x, 245), Vector2(x, 445), Color.DIM_GRAY, 5)
		if not transitioning:
			draw_dashed_line(Vector2(_cut_x(), 230), Vector2(_cut_x(), 485), Color.WHITE, 3, 9)
			draw_circle(Vector2(_cut_x(), 215), 9, Color.WHITE)
		draw_set_transform(_origin(), 0, Vector2.ONE * _scale_factor())
		_text(Vector2(80, 525), "Cut %d / %d" % [mini(cuts + 1, cuts_per_food), cuts_per_food])
	elif stage == Stage.ADD_POTATO or stage == Stage.ADD_FISH:
		draw_rect(Rect2(45, 190, 315, 330), Color(0.4, 0.35, 0.28))
		_draw_pot()
		for point in pieces:
			draw_rect(Rect2(point - Vector2(28, 35), Vector2(56, 70)), Color.KHAKI if stage == Stage.ADD_POTATO else Color.SALMON)
		_text(Vector2(50, 555), "%d pieces left" % pieces.size())
	elif stage == Stage.WATER:
		_draw_pot()
		draw_rect(Rect2(jug - Vector2(40, 50), Vector2(80, 100)), Color.STEEL_BLUE)
		_text(jug + Vector2(-25, 0), "JUG")
		draw_arc(Vector2(550, 200), 50, 0, TAU, 24, Color.LIGHT_BLUE, 2)
		if dragging and jug.distance_to(Vector2(550, 200)) < 110:
			draw_line(jug, POT_CENTER, Color.LIGHT_BLUE, 7)
		draw_rect(Rect2(65, 540, 560, 24), Color.DIM_GRAY)
		draw_rect(Rect2(65, 540, water * 560, 24), Color.STEEL_BLUE)
		draw_line(Vector2(485, 530), Vector2(485, 575), Color.GREEN, 4)
		_text(Vector2(450, 515), "75% target", 20)
		_text(Vector2(65, 605), "Water: %d%%" % int(water * 100))
	elif stage == Stage.HEAT:
		_draw_pot()
		_text(Vector2(40, 280), "Temperature: %d C" % int(20 + temperature * 80))
		_text(Vector2(40, 330), "Boiling..." if temperature >= 1 else "Waiting for boil...", 20)
		draw_line(Vector2(140, 540), Vector2(580, 540), Color.GRAY, 8)
		draw_line(Vector2(426, 540), Vector2(470, 540), Color.GREEN, 12)
		draw_circle(Vector2(140 + heat * 440, 540), 15, Color.WHITE)
		_text(Vector2(160, 595), "Heat: %d%%  (target 70%%)" % int(heat * 100))
	elif stage == Stage.DONE:
		_text(Vector2(160, 220), "Stars: %s%s   %d / 3" % ["*".repeat(stars), "-".repeat(3 - stars), stars], 32)
		_text(Vector2(160, 280), "Accuracy: %d%%" % roundi(accuracy * 100), 26)
		_text(Vector2(120, 365), "Cuts: %d%%   Drops: %d%%" % [roundi(_average(cut_scores) * 100), roundi(_average(drop_scores) * 100)])
		_text(Vector2(120, 415), "Water: %d%%   Heat: %d%%" % [roundi(water_score * 100), roundi(heat_score_sum / maxf(heat_scored_seconds, 0.001) * 100)])
		draw_rect(Rect2(240, 530, 240, 65), Color.DIM_GRAY)
		_text(Vector2(315, 570), "Retry" if timed_out else "Serve", 26)
	# Wrap instructions to the panel width instead of shrinking their font.
	var words: PackedStringArray = (hint if not hint.is_empty() else HELP[stage]).split(" ")
	var line := ""
	var y := 650.0
	for word in words:
		var candidate: String = line + word + " "
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x > 660:
			_text(Vector2(30, y), line)
			y += 28
			line = word + " "
		else:
			line = candidate
	_text(Vector2(30, y), line)
	if veil > 0:
		draw_rect(Rect2(0, 130, 720, 490), Color(0.15, 0.15, 0.17, veil))

func _draw_pot() -> void:
	draw_circle(POT_CENTER, 125, Color(0.3, 0.33, 0.36))
	draw_arc(POT_CENTER, 125, 0, TAU, 48, Color.WHITE, 3)
	draw_line(POT_CENTER - Vector2(14, 0), POT_CENTER + Vector2(14, 0), Color.WHITE, 2)
	draw_line(POT_CENTER - Vector2(0, 14), POT_CENTER + Vector2(0, 14), Color.WHITE, 2)
	_text(POT_CENTER + Vector2(-75, 160), "POT: aim here", 20)
	for i in range(added):
		draw_rect(Rect2(POT_CENTER + Vector2(-80 + (i % 6) * 28, 25 + floori(i / 6.0) * 20), Vector2(15, 15)), Color.KHAKI if i < cuts_per_food + 1 else Color.SALMON)

