extends CanvasLayer
## Port of inventory-system's slot UI, connected to the single-player service.
const HOTBAR_SLOTS: int = 6
var service: InventoryService
var selected: int = 0
var storage_open: bool = false
var bag_open: bool = false
var hotbar: HBoxContainer
var bag_panel: PanelContainer
var chest_panel: PanelContainer
var panels: HBoxContainer
var buttons: Array[InventorySlotButton] = []
var bag_buttons: Array[InventorySlotButton] = []
var chest_buttons: Array[InventorySlotButton] = []
var drop_zone: Control
var hint: Label
var message: String = ""
var message_time: float = 0.0

func bind_service(value: InventoryService) -> void:
	service = value
	layer = 5
	drop_zone = Control.new()
	add_child(drop_zone)
	drop_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_zone.set_drag_forwarding(Callable(), _can_drop_on_deck, _drop_on_deck)
	hotbar = HBoxContainer.new()
	add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.offset_top = -74
	hotbar.offset_bottom = -14
	hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar.add_theme_constant_override("separation", 6)
	panels = HBoxContainer.new()
	add_child(panels)
	panels.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panels.offset_top = -396
	panels.offset_bottom = -116
	panels.add_theme_constant_override("separation", 14)
	bag_panel = _container("YOUR BAG", "Drag to move · Drag outside to drop", false)
	chest_panel = _container("SHIP'S CHEST", "Shift-click to transfer · E / Esc to close", true)
	for index in mini(HOTBAR_SLOTS, service.local_slots.size()):
		buttons.append(_slot(hotbar, index, false))
	hint = _label("", 14, Color("ead7ad"))
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -420
	hint.offset_right = 420
	hint.offset_top = -103
	hint.offset_bottom = -80
	service.updated.connect(_refresh)
	service.feedback.connect(func(text: String) -> void:
		message = text
		message_time = 3.0)
	_refresh()

func _container(title: String, help: String, storage: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panels.add_child(panel)
	panel.add_theme_stylebox_override("panel", _panel_style())
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	panel.add_child(rows)
	rows.add_child(_label(title, 20, Color("e5c58a")))
	var grid := GridContainer.new()
	grid.columns = 6
	rows.add_child(grid)
	var count: int = service.storage_view.size() if storage else service.local_slots.size()
	for index in count:
		var button := _slot(grid, index, storage)
		if storage:
			chest_buttons.append(button)
		else:
			bag_buttons.append(button)
	rows.add_child(_label(help, 12, Color("c0b499")))
	return panel

func _slot(parent: Control, index: int, storage: bool) -> InventorySlotButton:
	var button := InventorySlotButton.new()
	button.hud = self
	button.slot_index = index
	button.is_storage = storage
	button.slot_size = Vector2(54, 56)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.pressed.connect(func() -> void:
		if not storage and index < HOTBAR_SLOTS:
			selected = index
			_refresh())
	parent.add_child(button)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("201f1cf5")
	style.border_color = Color("8a6b40")
	style.set_border_width_all(2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("17171c"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _refresh() -> void:
	for button in buttons + bag_buttons:
		var index: int = button.slot_index
		button.set_entry(service.local_slots[index], str(index + 1) if index < HOTBAR_SLOTS else "", selected == index)
	for button in chest_buttons:
		button.set_entry(service.storage_view[button.slot_index], "", false)
	var width := buttons.size() * 60.0 - 6
	hotbar.offset_left = -width / 2
	hotbar.offset_right = width / 2

func quick_transfer(index: int, from_storage: bool) -> void:
	if storage_open:
		service.request("take" if from_storage else "store", index)

func valid_drag(data: Variant) -> bool:
	return service.can_handle_items() and data is Dictionary and data.get("inventory_drag", false) and data.get("service_id", 0) == service.get_instance_id() and (not data.get("storage", false) or storage_open)

func _can_drop_on_deck(_position: Vector2, data: Variant) -> bool:
	var mouse := drop_zone.get_global_transform() * _position
	return valid_drag(data) and not hotbar.get_global_rect().has_point(mouse) and not (panels.visible and panels.get_global_rect().has_point(mouse))

func _drop_on_deck(_position: Vector2, data: Variant) -> void:
	service.request_drag(data)

func close() -> void:
	storage_open = false
	bag_open = false
	if is_instance_valid(service.player):
		service.player.set("inventory_open", false)

func _process(delta: float) -> void:
	if service == null:
		return
	if not service.can_handle_items():
		close()
	if storage_open and not service.near_storage():
		close()
	service.player.set("inventory_open", bag_open or storage_open)
	hotbar.visible = not MapState.map_open
	panels.visible = bag_open or storage_open
	bag_panel.visible = panels.visible
	chest_panel.visible = storage_open
	var width := 756.0 if storage_open else 371.0
	panels.offset_left = -width / 2
	panels.offset_right = width / 2
	drop_zone.mouse_filter = Control.MOUSE_FILTER_STOP if service.can_handle_items() and get_viewport().gui_is_dragging() else Control.MOUSE_FILTER_IGNORE
	message_time = maxf(0, message_time - delta)
	hint.visible = not MapState.map_open
	hint.text = message if message_time > 0 else ("E / Space  Open ship's chest  ·  I  Bag" if service.chest_is_nearest() and not storage_open else "I  Bag  ·  1–6 / Wheel  Select  ·  Drag outside to drop")

func _unhandled_input(event: InputEvent) -> void:
	if service == null or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") and (bag_open or storage_open):
		close()
		get_viewport().set_input_as_handled()
		return
	if not service.can_handle_items():
		return
	var handled := false
	if event.is_action_pressed("interact"):
		if storage_open or bag_open:
			close()
			handled = true
		elif service.chest_is_nearest():
			storage_open = true
			handled = true
	elif event is InputEventKey and event.pressed:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_I:
			if storage_open or bag_open:
				close()
			else:
				bag_open = true
			handled = true
		elif key >= KEY_1 and key < KEY_1 + buttons.size():
			selected = key - KEY_1
			handled = true
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		selected = posmod(selected + (-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1), buttons.size())
		handled = true
	if handled:
		service.player.set("inventory_open", bag_open or storage_open)
		_refresh()
		get_viewport().set_input_as_handled()
