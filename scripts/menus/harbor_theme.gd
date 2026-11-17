class_name HarborTheme
extends RefCounted
## One palette and one set of controls for title, crew, settings and pause menus.
const INK := Color("30243e")
const MUTED := Color("736073")
const CORAL := Color("bd526b")
const PAPER := Color("f5dfc4")
const SHADE := Color(0.10, 0.12, 0.25, 0.72)
const UI_FONT := preload("res://assets/fonts/rye/Rye-Regular.ttf")
const PLANK := preload("res://assets/menus/menu_plank.png")
static var _theme: Theme
static var _trimmed: Dictionary = {}

static func trimmed(texture: Texture2D) -> AtlasTexture:
	if _trimmed.has(texture): return _trimmed[texture]
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	# Ignore near-transparent generation padding without altering source artwork.
	var regions := {
		"menu_plank.png": Rect2(76, 162, 2020, 396),
		"title_wordmark.png": Rect2(20, 34, 1268, 1182),
		"title_wreck.png": Rect2(5, 9, 735, 2043),
		"title_shark.png": Rect2(145, 159, 671, 1278),
	}
	atlas.region = regions.get(texture.resource_path.get_file(), Rect2(Vector2.ZERO, texture.get_size()))
	_trimmed[texture] = atlas
	return atlas

static func panel() -> StyleBoxFlat:
	var style := box(PAPER, Color("5c4352"), 4)
	style.border_blend = false
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color("221e38b0")
	style.shadow_size = 8
	style.shadow_offset = Vector2(7, 8)
	return style

static func box(fill: Color, edge: Color, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.set_content_margin_all(10)
	return style

static func menu_theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	_theme.default_font = UI_FONT
	_theme.default_font_size = 22
	for type in ["Label", "Button", "CheckButton", "CheckBox", "OptionButton", "LineEdit", "PopupMenu", "TabBar"]:
		_theme.set_color("font_color", type, INK)
		_theme.set_color("font_hover_color", type, CORAL)
		_theme.set_color("font_focus_color", type, CORAL)
		_theme.set_color("font_pressed_color", type, INK)
		_theme.set_color("font_disabled_color", type, MUTED)
	for type in ["LineEdit", "OptionButton", "Button", "PopupMenu"]:
		_theme.set_stylebox("normal", type, box(Color("fff0d9"), Color("b28c7b")))
		_theme.set_stylebox("hover", type, box(Color("ffe8d6"), CORAL))
		_theme.set_stylebox("pressed", type, box(Color("e5b5a8"), INK))
		_theme.set_stylebox("focus", type, box(Color(0,0,0,0), CORAL, 2))
	_theme.set_color("caret_color", "LineEdit", CORAL)
	_theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	_theme.set_color("selection_color", "LineEdit", Color("e9b1ad"))
	_theme.set_stylebox("panel", "PopupMenu", panel())
	_theme.set_stylebox("panel", "TabContainer", box(Color("ecd2b8"), Color("b99584"), 2))
	for type in ["TabBar", "TabContainer"]:
		_theme.set_stylebox("tab_selected", type, box(Color("f5dfc4"), CORAL, 2))
		_theme.set_stylebox("tab_unselected", type, box(Color("c4a19a"), Color("846879"), 2))
		_theme.set_stylebox("tab_hovered", type, box(Color("efd0bd"), CORAL, 2))
		_theme.set_color("font_selected_color", type, INK)
		_theme.set_color("font_unselected_color", type, Color("58445d"))
		_theme.set_color("font_hovered_color", type, INK)
		_theme.set_font_size("font_size", type, 22)
	_theme.set_stylebox("slider", "HSlider", box(Color("b1979c"), Color("71566e"), 1))
	_theme.set_stylebox("grabber_area", "HSlider", box(Color("cc7180"), Color("915363"), 1))
	_theme.set_stylebox("grabber_area_highlight", "HSlider", box(Color("e78d98"), CORAL, 1))
	_theme.set_stylebox("panel", "AcceptDialog", panel())
	_theme.set_stylebox("embedded_border", "Window", panel())
	_theme.set_color("title_color", "Window", INK)
	_theme.set_font("title_font", "Window", UI_FONT)
	for state in ["on", "off", "on_disabled", "off_disabled"]:
		var icon := Image.create(34, 18, false, Image.FORMAT_RGBA8)
		icon.fill(Color("60475d"))
		var enabled: bool = state.begins_with("on")
		icon.fill_rect(Rect2i(2,2,30,14), CORAL if enabled else Color("b19a9f"))
		icon.fill_rect(Rect2i(19 if enabled else 3,3,12,12), Color("fff0d9"))
		_theme.set_icon(state, "CheckButton", ImageTexture.create_from_image(icon))
	_theme.set_color("arrow", "OptionButton", INK)
	return _theme

static func label(text: String, font_size: int = 20, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", UI_FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func button(text: String, action: Callable) -> HarborButton:
	var node := HarborButton.new()
	node.text = text
	node.action = action
	return node

static func reveal(control: Control) -> void:
	control.show()
	control.modulate.a = 1.0
	if GameWindow.preferences.reduced_motion: return
	control.modulate.a = 0.0
	control.create_tween().tween_property(control, "modulate:a", 1.0, 0.16)

static func trap_focus(root: Control, event: InputEvent) -> bool:
	if not event.is_action_pressed("ui_focus_next") and not event.is_action_pressed("ui_focus_prev"):
		return false
	var candidates: Array[Control] = []
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree():
			if control is BaseButton and control.disabled: continue
			candidates.append(control)
	if candidates.is_empty(): return false
	var index := candidates.find(root.get_viewport().gui_get_focus_owner())
	var step := -1 if event.is_action_pressed("ui_focus_prev") else 1
	candidates[posmod(index + step, candidates.size())].grab_focus()
	root.get_viewport().set_input_as_handled()
	return true
