class_name HarborTheme
extends RefCounted

static func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142b35f5")
	style.border_color = Color("9d8255")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 12
	return style

static func label(text: String, font_size: int = 18, color: Color = Color("e6d8b7")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func button(text: String, action: Callable) -> HarborButton:
	var node := HarborButton.new()
	node.text = text
	node.action = action
	return node

static func trap_focus(root: Control, event: InputEvent) -> bool:
	if not event.is_action_pressed("ui_focus_next") and not event.is_action_pressed("ui_focus_prev"):
		return false
	var candidates: Array[Control] = []
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree():
			if control is BaseButton and control.disabled:
				continue
			candidates.append(control)
	if candidates.is_empty():
		return false
	var index := candidates.find(root.get_viewport().gui_get_focus_owner())
	var step := -1 if event.is_action_pressed("ui_focus_prev") else 1
	candidates[posmod(index + step, candidates.size())].grab_focus()
	root.get_viewport().set_input_as_handled()
	return true
