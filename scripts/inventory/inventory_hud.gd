extends CanvasLayer
## Presentation and local selection only. All item mutations go through the service.
var service: Node
var session: Node
var selected: int = 0
var storage_open := false
var hotbar: HBoxContainer
var chest_panel: PanelContainer
var hotbar_row: HBoxContainer
var storage_grid: GridContainer
var buttons: Array[InventorySlotButton] = []
var chest_buttons: Array[InventorySlotButton] = []

func _ready() -> void:
	session = get_parent()
	service = session.get_node("InventorySystem")
	layer = 5
	hotbar = HBoxContainer.new()
	add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.offset_top = -66
	hotbar.offset_bottom = -10
	hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar.add_theme_constant_override("separation", 6)
	hotbar_row = hotbar
	chest_panel = PanelContainer.new()
	add_child(chest_panel)
	chest_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	chest_panel.offset_left = -322
	chest_panel.offset_right = -24
	chest_panel.offset_top = -190
	chest_panel.offset_bottom = 190
	chest_panel.add_theme_stylebox_override("panel", _panel_style())
	var chest_rows := VBoxContainer.new()
	chest_rows.add_theme_constant_override("separation", 10)
	chest_panel.add_child(chest_rows)
	chest_rows.add_child(_label("SHIP'S SUPPLIES", 19, Color("e5c58a")))
	chest_rows.add_child(_label("Shared by the whole crew", 12, Color("c0b499")))
	storage_grid = GridContainer.new()
	storage_grid.columns = 3
	storage_grid.add_theme_constant_override("h_separation", 7)
	storage_grid.add_theme_constant_override("v_separation", 7)
	chest_rows.add_child(storage_grid)
	chest_rows.add_child(_label("Click chest slot to take a stack.\nClick pocket slot to store it.\nF / Esc  Close", 12, Color("c0b499")))
	service.updated.connect(_refresh)
	session.session_reset.connect(_reset_selection)
	_refresh()

func _reset_selection() -> void:
	selected = 0
	storage_open = false
	_refresh()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("201f1cef")
	style.border_color = Color("8a6b40")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _refresh() -> void:
	while buttons.size() < service.local_slots.size():
		var button := InventorySlotButton.new()
		var index := buttons.size()
		button.pressed.connect(func(): _pocket_clicked(index))
		button.slot_size = Vector2(56, 56)
		hotbar_row.add_child(button)
		buttons.append(button)
	for index in range(buttons.size()):
		buttons[index].visible = index < service.local_slots.size()
		if buttons[index].visible:
			buttons[index].set_entry(service.local_slots[index], str(index + 1), selected == index)
	while chest_buttons.size() < service.storage_view.size():
		var button := InventorySlotButton.new()
		var index := chest_buttons.size()
		button.pressed.connect(func(): service.request("take", index))
		storage_grid.add_child(button)
		chest_buttons.append(button)
	for index in range(chest_buttons.size()):
		chest_buttons[index].visible = index < service.storage_view.size()
		if chest_buttons[index].visible:
			chest_buttons[index].set_entry(service.storage_view[index], "", false)
	var width: float = service.local_slots.size() * 62.0 - 6.0
	hotbar.offset_left = -width / 2
	hotbar.offset_right = width / 2

func _pocket_clicked(index: int) -> void:
	selected = index
	if storage_open:
		service.request("store", index)
	_refresh()

func _process(_delta: float) -> void:
	hotbar.visible = session.running
	if not session.running or not service.near_storage(multiplayer.get_unique_id()):
		storage_open = false
	chest_panel.visible = storage_open and session.running

func _unhandled_input(event: InputEvent) -> void:
	if not session.running or event.is_echo():
		return
	var handled := false
	if event is InputEventKey and event.pressed:
		var key: int = event.physical_keycode
		if key >= KEY_1 and key < KEY_1 + service.local_slots.size():
			selected = key - KEY_1
			handled = true
		elif key == KEY_Q:
			service.request("drop", selected)
			handled = true
		elif key == KEY_G:
			service.request("pickup", service.nearest_drop(multiplayer.get_unique_id()))
			handled = true
		elif key == KEY_F:
			if service.near_storage(multiplayer.get_unique_id()):
				storage_open = not storage_open
			handled = true
		elif key == KEY_ESCAPE and storage_open:
			storage_open = false
			handled = true
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if not service.local_slots.is_empty():
			selected = posmod(selected + (-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1), service.local_slots.size())
		handled = true
	if handled:
		_refresh()
		get_viewport().set_input_as_handled()


