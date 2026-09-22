class_name InventorySlotButton
extends Button
var entry: Dictionary = {}
var number: String = ""
var selected: bool = false
@export var slot_size := Vector2(76, 80)
var hud: Node
var slot_index: int = -1
var is_storage: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.shift_pressed:
		hud.quick_transfer(slot_index, is_storage)
		accept_event()

func _get_drag_data(_position: Vector2) -> Variant:
	if entry.is_empty() or hud == null or Input.is_key_pressed(KEY_SHIFT):
		return null
	var preview := TextureRect.new()
	preview.texture = ItemDatabase.get_item(entry.id).icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(40, 40)
	preview.size = Vector2(40, 40)
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"inventory_drag": true, "index": slot_index, "storage": is_storage, "revision": hud.service.view_revision}

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

func set_entry(value: Dictionary, key: String, active: bool) -> void:
	entry = value
	number = key
	selected = active
	var item: ItemData = ItemDatabase.get_item(entry.get("id", &""))
	tooltip_text = "Empty slot" if item == null else "%s\n%s\nStack limit: %d" % [item.display_name, item.description, item.max_stack]
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	draw_style_box(_box(Color("382b24"), Color("dcb76a") if selected else Color("796044"), 3 if selected else 1), rect)
	if is_hovered():
		draw_rect(rect.grow(-4), Color(1, 0.86, 0.58, 0.07))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, 15), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3bd94"))
	var item: ItemData = ItemDatabase.get_item(entry.get("id", &""))
	if item != null and item.icon != null:
		var icon_size := Vector2.ONE * minf(42, size.x - 24)
		draw_texture_rect(item.icon, Rect2((size - icon_size) / 2, icon_size), false)
	if not entry.is_empty() and int(entry.quantity) > 1:
		draw_string(font, Vector2(size.x - 30, size.y - 10), str(entry.quantity), HORIZONTAL_ALIGNMENT_RIGHT, 20, 15, Color("fff1cc"))
	if selected:
		draw_line(Vector2(22, size.y - 5), Vector2(size.x - 22, size.y - 5), Color("ffe0a0"), 2)

func _box(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	return style
