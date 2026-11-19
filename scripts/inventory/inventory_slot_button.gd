class_name InventorySlotButton
extends Button
var entry: Dictionary = {}
var number: String = ""
var selected: bool = false
@export var slot_size := Vector2(76, 80)
@export var parchment_slot: bool = false
var hud: Node
var slot_index: int = -1
var is_storage: bool = false
@export_range(0.1, 1.0, 0.05) var pickup_hold_seconds: float = 0.15
var _pickup_hold: float = -1.0

func _process(delta: float) -> void:
	if _pickup_hold < 0.0: return
	if not is_visible_in_tree() or not is_hovered() or not hud.service.can_handle_items() or hud.storage_open or hud.grill_open:
		_pickup_hold = -1.0
		return
	_pickup_hold += delta
	if _pickup_hold >= pickup_hold_seconds:
		_pickup_hold = -1.0
		hud.pick_cursor(slot_index, is_storage)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_pickup_hold = -1.0
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_pickup_hold = -1.0

func _gui_input(event: InputEvent) -> void:
	if hud == null or not event is InputEventMouseButton or not event.pressed: return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed: hud.quick_transfer(slot_index, is_storage)
		elif is_storage or hud.storage_open or hud.grill_open:
			hud.pick_cursor(slot_index, is_storage)
		else:
			hud.select_slot(slot_index)
			_pickup_hold = 0.0
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		var item := ItemDatabase.get_item(entry.get("id", &""))
		if item != null and item.max_stack > 1:
			hud.pick_cursor(slot_index, is_storage, ceili(float(entry.quantity)/2.0) if event.shift_pressed else 1)
		accept_event()

func _get_drag_data(_position: Vector2) -> Variant:
	return null # Click-to-carry is owned by the HUD, above all station canvas layers.
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return hud != null and hud.valid_drag(data) and (not is_storage or hud.storage_open)

func _drop_data(_position: Vector2, data: Variant) -> void:
	hud.service.request_drag(data, slot_index, is_storage)

func _ready() -> void:
	custom_minimum_size = slot_size
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxEmpty.new()
		add_theme_stylebox_override(state, style)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	mouse_exited.connect(func() -> void: _pickup_hold = -1.0)

func set_entry(value: Dictionary, key: String, active: bool) -> void:
	entry = value
	number = key
	selected = active
	var item: ItemData = ItemDatabase.get_item(entry.get("id", &""))
	tooltip_text = "Empty slot" if item == null else "%s\n%s\nStack limit: %d" % [item.display_name, item.description, item.max_stack]
	if item != null and item.max_stack > 1: tooltip_text += "\nRight-click: one · Shift-right-click: half"
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	if not parchment_slot:
		draw_style_box(_box(Color("382b24"), Color("dcb76a") if selected else Color("796044"), 3 if selected else 1), rect)
	elif selected:
		draw_rect(rect.grow(-3), Color(0.35, 0.8, 0.4, 0.16))
		var edge := rect.grow(-4)
		var green := Color("568b50")
		draw_dashed_line(edge.position, Vector2(edge.end.x, edge.position.y), green, 3, 5)
		draw_dashed_line(Vector2(edge.end.x, edge.position.y), edge.end, green, 3, 5)
		draw_dashed_line(edge.end, Vector2(edge.position.x, edge.end.y), green, 3, 5)
		draw_dashed_line(Vector2(edge.position.x, edge.end.y), edge.position, green, 3, 5)
	if is_hovered():
		draw_rect(rect.grow(-4), Color(1, 0.86, 0.58, 0.07))
	var font := ThemeDB.fallback_font
	if not parchment_slot:
		draw_string(font, Vector2(8, 15), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3bd94"))
	var item: ItemData = ItemDatabase.get_item(entry.get("id", &""))
	if item != null and item.icon != null:
		var icon_size := Vector2.ONE * minf(42, size.x - 24)
		draw_texture_rect(item.icon, Rect2((size - icon_size) / 2, icon_size), false)
	if not entry.is_empty() and int(entry.quantity) > 1:
		draw_string(font, Vector2(size.x - 30, size.y - 10), str(entry.quantity), HORIZONTAL_ALIGNMENT_RIGHT, 20, 15, Color("493329") if parchment_slot else Color("fff1cc"))
	if selected and not parchment_slot:
		draw_line(Vector2(22, size.y - 5), Vector2(size.x - 22, size.y - 5), Color("ffe0a0"), 2)

func _box(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	return style
