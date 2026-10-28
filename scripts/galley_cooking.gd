extends Control
## Local recipe activity. Only the station awards/consumes stock.
signal completed(stars: int)
signal cancelled

var use_potato: bool = true
var use_fish: bool = true

enum Stage { POTATO, ADD_POTATO, FISH, ADD_FISH, WATER, HEAT, DONE }
@export_range(3, 8) var cuts_per_food: int = 5
@export_range(1.0, 10.0) var fill_seconds: float = 3.0
@export_range(2.0, 30.0) var boil_seconds: float = 8.0
@export var slice_tolerance: float = 26.0
@export_range(20.0, 180.0) var recipe_seconds: float = 90.0
## Fraction of the viewport available to the centered task panel.
@export_range(0.5, 0.95, 0.05) var overlay_size: float = 0.8
@export var potato_texture: Texture2D = preload("res://assets/cooking/potato.svg")
@export var fish_texture: Texture2D = preload("res://assets/cooking/fish.svg")
@export var knife_texture: Texture2D = preload("res://assets/cooking/knife.svg")
@export var jug_texture: Texture2D = preload("res://assets/cooking/jug.svg")
var feedback: String = ""
var feedback_life: float = 0.0
var feedback_color := Color("a6dfb0")
var splash: float = 0.0
var cut_pulse: float = 0.0
var result_age: float = 0.0
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
const HELP := ["Hold above the bright line. Slice downward and release below the potato.", "Drag each potato piece from the board into the open pot.", "Hold above the bright line. Slice downward through the fish.", "Drag every piece of fish into the pot.", "Hold the pitcher over the pot. Release at the 75% water target.", "Set heat in the green target zone and wait for the food to cook.", "Stars: 90% = 3, 70% = 2, 40% = 1. Click Serve to finish."]

func _ready() -> void:
	add_to_group("cooking_activity")
	stage = Stage.POTATO if use_potato else Stage.FISH
	mouse_filter = Control.MOUSE_FILTER_STOP
	time_left = recipe_seconds

func _scale_factor() -> float:
	return maxf(0.001, minf(size.x, size.y) / 720.0 * overlay_size)

func _origin() -> Vector2:
	return (size - Vector2(720, 720) * _scale_factor()) * 0.5 + VoyageSurvival.visual_offset * 1.5

func _input(event: InputEvent) -> void:
	if get_tree().paused or VoyageSurvival.dead:
		return
	if event.is_action_pressed("ui_cancel") and not closed:
		closed = true
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if get_tree().paused or VoyageSurvival.dead or transitioning or closed:
		return
	if event is InputEventMouse:
		pointer = (event.position - _origin()) / _scale_factor()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(_gesture_point(pointer))
		else:
			_release(_gesture_point(pointer))
	elif event is InputEventMouseMotion:
		_move(_gesture_point(pointer))
	accept_event()

func _gesture_point(point: Vector2) -> Vector2:
	if (stage == Stage.POTATO or stage == Stage.FISH) and point.y > 130:
		return point - Vector2(140, 0)
	return point

func _respond(message: String, good: bool = true) -> void:
	feedback = message
	feedback_life = 1.0
	feedback_color = Color("a6dfb0") if good else Color("f3ab8c")

func _cut_x() -> float:
	return 100.0 + 240.0 * float(cuts + 1) / float(cuts_per_food + 1)

func _press(point: Vector2) -> void:
	if get_tree().paused or VoyageSurvival.dead or transitioning or closed:
		return
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
				closed = true
				completed.emit(stars)
				queue_free()

func _move(point: Vector2) -> void:
	if get_tree().paused or VoyageSurvival.dead or transitioning or closed:
		return
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
	if get_tree().paused or VoyageSurvival.dead or transitioning or closed:
		return
	if not dragging:
		return
	dragging = false
	match stage:
		Stage.POTATO, Stage.FISH:
			if valid_stroke and absf(point.x - _cut_x()) <= slice_tolerance and point.y >= 470:
				cut_error = maxf(cut_error, absf(point.x - _cut_x()))
				cut_scores.append(clampf(1.0 - cut_error / slice_tolerance, 0, 1))
				cut_pulse = 1.0
				_respond("Clean cut!" if cut_error < 8 else "Sliced!")
				cuts += 1
				if cuts >= cuts_per_food:
					_next_stage()
			else:
				cut_scores.append(0.0)
				_respond("Follow the line", false)
			hint = "Start at the dot and pull straight down past the food."
		Stage.ADD_POTATO, Stage.ADD_FISH:
			if selected_piece >= 0:
				if point.distance_to(POT_CENTER) < 125:
					drop_scores.append(clampf(1.0 - point.distance_to(POT_CENTER) / 125.0, 0, 1))
					pieces.remove_at(selected_piece)
					added += 1
					splash = 1.0
					_respond("Perfect drop!" if point.distance_to(POT_CENTER) < 25 else "In the pot!")
				else:
					drop_scores.append(0.0)
					_respond("Aim inside the rim", false)
					var index := selected_piece
					var start := pieces[index]
					transitioning = true
					var settle := create_tween()
					settle.tween_method(func(t: float) -> void: pieces[index] = start.lerp(_piece_home(index), t), 0.0, 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					settle.tween_callback(func() -> void: transitioning = false)
				selected_piece = -1
				if pieces.is_empty():
					_next_stage()
		Stage.WATER:
			create_tween().tween_property(self, "jug", Vector2(180, 350), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if water >= 0.2:
				water_score = clampf(1.0 - absf(water - 0.75) / 0.25, 0, 1)
				_respond("Perfect pour!" if water_score > 0.9 else "Water added")
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
	if stage == Stage.FISH and not use_fish:
		stage = Stage.HEAT
	if stage == Stage.WATER:
		stage = Stage.HEAT
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
	result_age = 0.0
	var heat_score := heat_score_sum / maxf(heat_scored_seconds, 0.001)
	accuracy = (_average(cut_scores) + _average(drop_scores) + heat_score) / 3.0
	stars = 3 if accuracy >= 0.9 else (2 if accuracy >= 0.7 else (1 if accuracy >= 0.4 else 0))
	if timed_out:
		stars = 0

func _retry() -> void:
	feedback_life = 0
	splash = 0
	cut_pulse = 0
	result_age = 0
	stage = Stage.POTATO if use_potato else Stage.FISH
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
	feedback_life = maxf(0, feedback_life - delta)
	splash = maxf(0, splash - delta * 2.0)
	cut_pulse = maxf(0, cut_pulse - delta * 5.0)
	if stage == Stage.DONE:
		result_age += delta
	if not transitioning and stage != Stage.DONE and not closed:
		time_left = maxf(0, time_left - delta)
		if time_left <= 0:
			timed_out = true
			stage = Stage.DONE
			dragging = false
			hint = "Time ran out. This batch is poisonous. Serve or leave without spending ingredients."
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
	_panel(Rect2(0, 0, 720, 720), Color("26333c"), 18)
	_panel(Rect2(18, 125, 684, 490), Color("1c2931"), 12)
	_text(Vector2(25, 48), "Time's up" if timed_out else ("Meal is ready" if stage == Stage.DONE else TITLES[stage]), 28)
	draw_rect(Rect2(620, 20, 75, 40), Color.DIM_GRAY)
	_text(Vector2(630, 48), "X / Esc", 18)
	_text(Vector2(25, 95), "No water required • fish / potato galley")
	_text(Vector2(500, 95), "Time: %d s" % ceili(time_left), 24)
	if stage == Stage.POTATO or stage == Stage.FISH:
		_board(Rect2(55, 160, 610, 385))
		# The cutting board uses the whole work area; pot appears for transfer steps.
		draw_set_transform(_origin() + Vector2(140, 0) * _scale_factor(), 0, Vector2.ONE * _scale_factor())
		var food: Texture2D = fish_texture if stage == Stage.FISH else potato_texture
		var left := 65.0
		for i in range(cuts + 1):
			var right := 100.0 + 240.0 * float(i + 1) / float(cuts_per_food + 1) if i < cuts else 375.0
			var separation := float(cuts - i) * 5.0
			var source := Rect2((left - 65) / 310 * food.get_width(), 0, (right - left) / 310 * food.get_width(), food.get_height())
			draw_texture_rect_region(food, Rect2(left - separation, 230 + cut_pulse * 5, right - left, 245), source)
			left = right
		for i in range(cuts):
			var x := 100.0 + 240.0 * float(i + 1) / float(cuts_per_food + 1)
			draw_line(Vector2(x, 265), Vector2(x, 420), Color("b18b5d"), 6)
		if not transitioning:
			draw_dashed_line(Vector2(_cut_x(), 230), Vector2(_cut_x(), 485), Color.WHITE, 3, 9)
			draw_circle(Vector2(_cut_x(), 215), 9, Color.WHITE)
		draw_set_transform(_origin(), 0, Vector2.ONE * _scale_factor())
		_text(Vector2(80, 525), "Cut %d / %d" % [mini(cuts + 1, cuts_per_food), cuts_per_food])
	elif stage == Stage.ADD_POTATO or stage == Stage.ADD_FISH:
		_board(Rect2(45, 190, 315, 330))
		_draw_pot()
		for point in pieces:
			var lift := 1.15 if dragging and pieces.find(point) == selected_piece else 1.0
			draw_circle(point + Vector2(3, 20), 25, Color(0, 0, 0, 0.2))
			draw_texture_rect(potato_texture if stage == Stage.ADD_POTATO else fish_texture, Rect2(point - Vector2(40, 35) * lift, Vector2(80, 70) * lift), false)
		_text(Vector2(50, 555), "%d pieces left" % pieces.size())
	elif stage == Stage.WATER:
		_draw_pot()
		draw_texture_rect(jug_texture, Rect2(jug - Vector2(65, 65), Vector2(130, 130)), false)
		draw_arc(Vector2(550, 200), 50, 0, TAU, 24, Color.LIGHT_BLUE, 2)
		if dragging and jug.distance_to(Vector2(550, 200)) < 110:
			draw_line(jug + Vector2(-35, -20), POT_CENTER, Color.LIGHT_BLUE, 7)
			for i in range(6):
				var t := fmod(elapsed * 1.8 + i / 6.0, 1.0)
				draw_circle((jug + Vector2(-35, -20)).lerp(POT_CENTER, t), 4, Color("deeff1"))
		draw_rect(Rect2(65, 540, 560, 24), Color.DIM_GRAY)
		draw_rect(Rect2(65, 540, water * 560, 24), Color.STEEL_BLUE)
		draw_line(Vector2(485, 530), Vector2(485, 575), Color.GREEN, 4)
		_text(Vector2(450, 515), "75% target", 20)
		_text(Vector2(65, 605), "Water: %d%%" % int(water * 100))
	elif stage == Stage.HEAT:
		_draw_pot()
		_text(Vector2(40, 280), "Temperature: %d C" % int(20 + temperature * 80))
		_text(Vector2(40, 330), "Finishing..." if temperature >= 1 else "Cooking...", 20)
		draw_line(Vector2(140, 540), Vector2(580, 540), Color.GRAY, 8)
		draw_line(Vector2(426, 540), Vector2(470, 540), Color.GREEN, 12)
		draw_circle(Vector2(140 + heat * 440, 540), 15, Color.WHITE)
		_text(Vector2(160, 595), "Heat: %d%%  (target 70%%)" % int(heat * 100))
	elif stage == Stage.DONE:
		for i in range(3):
			var pop := clampf((result_age - i * 0.18) * 5, 0, 1)
			_star(Vector2(265 + i * 95, 205), 32 * pop, Color("f4ce77") if i < stars else Color("52616b"))
		_text(Vector2(160, 280), "Accuracy: %d%%" % roundi(accuracy * 100), 26)
		_text(Vector2(120, 365), "Cuts: %d%%   Drops: %d%%" % [roundi(_average(cut_scores) * 100), roundi(_average(drop_scores) * 100)])
		_text(Vector2(120, 415), "Heat control: %d%%" % roundi(heat_score_sum / maxf(heat_scored_seconds, 0.001) * 100))
		draw_rect(Rect2(240, 530, 240, 65), Color.DIM_GRAY)
		_text(Vector2(315, 570), "Serve batch", 26)
	if dragging and (stage == Stage.POTATO or stage == Stage.FISH):
		draw_texture_rect(knife_texture, Rect2(pointer - Vector2(55, 110), Vector2(110, 130)), false)
	if feedback_life > 0:
		draw_string(ThemeDB.fallback_font, Vector2(255, 595 - (1 - feedback_life) * 12), feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(feedback_color, feedback_life))
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
		draw_rect(Rect2(0, 130, 720, 490), Color(0.11, 0.16, 0.19, veil))

func _panel(rect: Rect2, color: Color, radius: int = 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _board(rect: Rect2) -> void:
	_panel(Rect2(rect.position + Vector2(0, 7), rect.size), Color("3e3027"))
	_panel(rect, Color("b18b5d"))
	for i in range(1, 5):
		var y := rect.position.y + rect.size.y * i / 5.0
		draw_line(Vector2(rect.position.x + 12, y), Vector2(rect.end.x - 12, y), Color("a57f53"), 2)

func _star(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0:
		return
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2 + i * TAU / 10
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.0 if i % 2 == 0 else 0.45))
	draw_colored_polygon(points, color)

func _draw_pot() -> void:
	var center := POT_CENTER
	_panel(Rect2(center + Vector2(-145, -15), Vector2(290, 30)), Color("7d9297"))
	draw_circle(center + Vector2(0, 8), 130, Color("121d24"))
	draw_circle(center, 125, Color("9cacac"))
	draw_circle(center, 113, Color("344b55") if water <= 0 else Color("5993aa").lerp(Color("b39157"), temperature))
	draw_arc(center, 119, PI, TAU, 40, Color("d3dfd7"), 4)
	if stage == Stage.ADD_POTATO or stage == Stage.ADD_FISH:
		draw_arc(center, 30 + sin(elapsed * 4) * 3, 0, TAU, 32, Color("accabb"), 2)
	for i in range(added):
		var point := center + Vector2(-65 + (i % 5) * 30, -30 + floori(i / 5.0) * 25)
		draw_circle(point + Vector2(0, sin(elapsed * 2 + i) * temperature * 3), 9, Color.KHAKI if i < cuts_per_food + 1 else Color.SALMON)
	if splash > 0:
		draw_arc(center, 25 + (1 - splash) * 75, 0, TAU, 40, Color(0.8, 0.95, 1, splash), 3)
		for i in range(8):
			var angle := i * TAU / 8
			draw_circle(center + Vector2(cos(angle), sin(angle)) * (35 + (1 - splash) * 65), 4 * splash, Color("bce3e4"))
	if stage == Stage.HEAT or stage == Stage.DONE:
		for i in range(int(temperature * 14)):
			var point := center + Vector2(sin(i * 3.7), cos(i * 2.4)) * 75
			draw_arc(point, 3 + fmod(elapsed * 8 + i, 8), 0, TAU, 16, Color(1, 0.94, 0.75, 0.6), 2)
		for i in range(4):
			var rise := fmod(elapsed * 35 + i * 24, 95)
			draw_circle(center + Vector2(-60 + i * 40 + sin(elapsed + i) * 8, -100 - rise), 10, Color(0.85, 0.94, 0.92, temperature * (1 - rise / 95) * 0.35))
