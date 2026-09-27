extends Control
## A standalone preparation activity. The station decides what completion awards.
signal completed
signal cancelled

@export_range(3, 10, 1) var required_cuts: int = 6
@export_range(12.0, 40.0, 1.0) var cut_tolerance: float = 24.0

var cuts: int = 0
var dragging: bool = false
var stroke_valid: bool = false
var knife_position: Vector2 = Vector2.ZERO
var finished: bool = false

@onready var board: Control = $Center/Panel/Layout/Board
@onready var instructions: Label = $Center/Panel/Layout/Instructions
@onready var progress: ProgressBar = $Center/Panel/Layout/Progress
@onready var finish_button: Button = $Center/Panel/Layout/Buttons/Finish

func _ready() -> void:
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_input)
	$Center/Panel/Layout/Buttons/Cancel.pressed.connect(_cancel)
	finish_button.pressed.connect(_finish)
	progress.max_value = required_cuts
	_update_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()
	# Releasing outside the board must also end the gesture.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging:
			_end_stroke(board.get_local_mouse_position())

func _on_board_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		knife_position = event.position
		dragging = true
		stroke_valid = absf(knife_position.x - _cut_x(cuts)) <= cut_tolerance and knife_position.y <= 65.0
		instructions.text = "Pull the knife down along the bright line." if stroke_valid else "Start above the onion, at the bright dot."
	elif event is InputEventMouseMotion and dragging:
		knife_position = event.position
		if absf(knife_position.x - _cut_x(cuts)) > cut_tolerance:
			stroke_valid = false
	board.queue_redraw()
	board.accept_event()

func _end_stroke(end: Vector2) -> void:
	dragging = false
	if stroke_valid and absf(end.x - _cut_x(cuts)) <= cut_tolerance and end.y >= 255.0:
		cuts += 1
		_update_display()
	else:
		instructions.text = "Try again: hold at the bright dot, drag down past the onion, then release."
	board.queue_redraw()

func _cut_x(index: int) -> float:
	return board.size.x * 0.5 - 120.0 + 240.0 * float(index + 1) / float(required_cuts + 1)

func _update_display() -> void:
	progress.value = cuts
	finished = cuts >= required_cuts
	finish_button.disabled = not finished
	instructions.text = "Onion chopped! Finish prep to return to the kitchen." if finished else "Cut %d of %d: hold at the bright dot and drag down, then release." % [cuts + 1, required_cuts]
	if finished:
		finish_button.grab_focus()
	board.queue_redraw()

func _draw_board() -> void:
	var center := Vector2(board.size.x * 0.5, 160.0)
	board.draw_style_box(_board_style(), Rect2(Vector2.ZERO, board.size))
	# Placeholder onion rings, drawn locally so no texture assets are needed.
	for ring in range(7, 0, -1):
		board.draw_circle(center, float(ring) * 17.0, Color("d5b6db") if ring % 2 == 0 else Color("f4e5ed"))
	for index in range(cuts):
		var x := _cut_x(index)
		board.draw_line(Vector2(x, 46), Vector2(x, 274), Color("865936"), 7.0)
	if not finished:
		var x := _cut_x(cuts)
		board.draw_dashed_line(Vector2(x, 42), Vector2(x, 280), Color("fff1a6"), 3.0, 8.0)
		board.draw_circle(Vector2(x, 30), 9.0, Color("fff1a6"))
		board.draw_line(Vector2(x - 7, 272), Vector2(x, 282), Color("fff1a6"), 3.0)
		board.draw_line(Vector2(x + 7, 272), Vector2(x, 282), Color("fff1a6"), 3.0)
	if dragging:
		board.draw_rect(Rect2(knife_position - Vector2(5, 45), Vector2(10, 58)), Color("dce8ec"))
		board.draw_rect(Rect2(knife_position - Vector2(5, 65), Vector2(10, 24)), Color("293948"))

func _board_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("a97749")
	style.set_corner_radius_all(16)
	return style

func _finish() -> void:
	if finished:
		completed.emit()
		queue_free()

func _cancel() -> void:
	cancelled.emit()
	queue_free()
