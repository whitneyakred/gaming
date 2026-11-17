class_name HarborButton
extends Button
@export var title_plank: bool = false
var _tween: Tween
var action: Callable
var _hover_stamp := -1000

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(260, 52) if not title_plank else Vector2(250, 44)
	add_theme_font_override("font", HarborTheme.PIXEL_FONT)
	add_theme_font_size_override("font_size", 20 if title_plank else 22)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		if title_plank:
			var style := StyleBoxTexture.new()
			style.texture = HarborTheme.trimmed(HarborTheme.PLANK)
			style.modulate_color = Color("ffd6d6") if state == "hover" else Color.WHITE
			if state == "pressed": style.modulate_color = Color("e3b7aa")
			if state == "disabled": style.modulate_color = Color("b39ba6")
			style.content_margin_top = 0
			style.content_margin_bottom = 3
			add_theme_stylebox_override(state, StyleBoxEmpty.new() if state == "focus" else style)
		else:
			var fill := Color("fff0d9") if state == "normal" else Color("f3c6b7")
			if state == "pressed": fill = Color("dda49d")
			if state == "disabled": fill = Color("c6b5a5")
			var style := HarborTheme.box(Color(0,0,0,0) if state == "focus" else fill, HarborTheme.CORAL if state in ["focus", "hover"] else Color("876474"), 2)
			style.content_margin_left = 16
			style.content_margin_right = 16
			style.content_margin_top = 5
			style.content_margin_bottom = 5
			if state != "focus":
				style.shadow_color = Color("5c4352")
				style.shadow_size = 2
				style.shadow_offset = Vector2(0, 3)
			add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_pressed_color"]:
		add_theme_color_override(state, HarborTheme.INK)
	for state in ["font_hover_color", "font_focus_color"]:
		add_theme_color_override(state, HarborTheme.CORAL)
	add_theme_color_override("font_disabled_color", HarborTheme.MUTED)
	mouse_entered.connect(_hover)
	focus_entered.connect(_hover)
	mouse_exited.connect(func() -> void: _animate(1.0))
	focus_exited.connect(func() -> void: _animate(1.0))
	button_down.connect(func() -> void: _animate(0.97))
	button_up.connect(func() -> void: _animate(1.0))
	pressed.connect(func() -> void:
		GameWindow.play_ui()
		if action.is_valid(): action.call())

func _hover() -> void:
	if disabled: return
	if Time.get_ticks_msec() - _hover_stamp > 90:
		GameWindow.play_ui("hover")
		_hover_stamp = Time.get_ticks_msec()
	_animate(1.025)

func _animate(amount: float) -> void:
	if _tween != null: _tween.kill()
	if GameWindow.preferences.reduced_motion:
		scale = Vector2.ONE
		return
	pivot_offset = size / 2
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * amount, 0.12)
