class_name HarborButton
extends Button
var _tween: Tween
var action: Callable

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(260, 52)
	add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("223a43") if state == "normal" else Color("36545a")
		if state == "pressed":
			style.bg_color = Color("172d36")
		style.border_color = Color("b89459") if state != "focus" else Color("f5d999")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 20
		style.content_margin_right = 20
		add_theme_stylebox_override(state, style)
	add_theme_color_override("font_color", Color("f2dfb8"))
	add_theme_color_override("font_hover_color", Color("fff0cd"))
	mouse_entered.connect(_hover)
	focus_entered.connect(_hover)
	mouse_exited.connect(func() -> void: _animate(1.0))
	focus_exited.connect(func() -> void: _animate(1.0))
	button_down.connect(func() -> void: _animate(0.97))
	button_up.connect(func() -> void: _animate(1.0))
	pressed.connect(func() -> void:
		get_node("/root/GameWindow").play_ui()
		if action.is_valid():
			action.call())

func _hover() -> void:
	if disabled:
		return
	get_node("/root/GameWindow").play_ui("hover")
	_animate(1.025)

func _animate(amount: float) -> void:
	if _tween != null:
		_tween.kill()
	if get_node("/root/GameWindow").preferences.reduced_motion:
		scale = Vector2.ONE
		return
	pivot_offset = size / 2
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * amount, 0.12)
