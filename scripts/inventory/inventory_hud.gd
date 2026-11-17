extends CanvasLayer
## Port of inventory-system's slot UI, connected to the single-player service.
const HOTBAR_SLOTS: int = 4
var service: InventoryService
var selected: int = 0
var storage_open: bool = false
var grill_open: bool = false
var grill_panel: Control
var hotbar: Control
var chest_panel: PanelContainer
var panels: HBoxContainer
var buttons: Array[InventorySlotButton] = []
var chest_buttons: Array[InventorySlotButton] = []
var drop_zone: Control
var hint: Label
var message: String = ""
var message_time: float = 0.0
var cursor_data: Dictionary = {}
var _pending_one: Dictionary = {}
var cursor_layer: CanvasLayer
var cursor_icon: TextureRect
var cursor_count: Label
var _cursor_position := Vector2.ZERO

func bind_service(value: InventoryService) -> void:
	service = value
	layer = 5
	cursor_layer = CanvasLayer.new()
	cursor_layer.layer = 120
	add_child(cursor_layer)
	cursor_icon = TextureRect.new()
	cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor_icon.size = Vector2(42,42)
	cursor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor_layer.add_child(cursor_icon)
	cursor_count = Label.new()
	cursor_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_count.add_theme_color_override("font_outline_color",Color("201b2c"))
	cursor_count.add_theme_constant_override("outline_size",4)
	cursor_layer.add_child(cursor_count)
	cursor_layer.hide()
	drop_zone = Control.new()
	add_child(drop_zone)
	drop_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_zone.set_drag_forwarding(Callable(), _can_drop_on_deck, _drop_on_deck)
	hotbar = preload("res://scenes/inventory/bottle_hotbar.tscn").instantiate()
	add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.offset_left = -168.5
	hotbar.offset_right = 168.5
	hotbar.offset_top = -124
	hotbar.offset_bottom = -5
	for index in HOTBAR_SLOTS:
		var button := hotbar.get_node("Slot%d" % (index + 1)) as InventorySlotButton
		button.hud = self
		button.slot_index = index
		button.pressed.connect(func() -> void:
			selected = index
			if NetworkSession.online:
				NetworkSession.command("select", {"index": index})
			_refresh())
		buttons.append(button)
	panels = HBoxContainer.new()
	add_child(panels)
	panels.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panels.offset_left = -402
	panels.offset_right = -24
	panels.offset_top = -160
	panels.offset_bottom = 120
	panels.add_theme_constant_override("separation", 14)
	chest_panel = _container("SHIP'S CHEST", "")
	grill_panel = preload("res://scripts/inventory/grill_panel.gd").new()
	grill_panel.hud = self
	add_child(grill_panel)
	grill_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	grill_panel.offset_left = -402
	grill_panel.offset_right = -24
	grill_panel.offset_top = -240
	grill_panel.offset_bottom = 198
	grill_panel.hide()
	hint = _label("", 14, Color("ead7ad"))
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -420
	hint.offset_right = 420
	hint.offset_top = -151
	hint.offset_bottom = -128
	service.updated.connect(_refresh)
	service.feedback.connect(func(text: String) -> void:
		message = text
		message_time = 3.0)
	_refresh()

func _container(title: String, help: String) -> PanelContainer:
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
	for index in service.storage_view.size():
		chest_buttons.append(_slot(grid, index, true))
	if not help.is_empty():
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
			if NetworkSession.online:
				NetworkSession.command("select", {"index": index})
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
	for button in buttons:
		var index: int = button.slot_index
		button.set_entry(_cursor_slot(service.local_slots[index], index, false), str(index + 1) if index < HOTBAR_SLOTS else "", selected == index)
	for button in chest_buttons:
		button.set_entry(_cursor_slot(service.storage_view[button.slot_index], button.slot_index, true), "", false)

func request_grill(args: Dictionary) -> void:
	if NetworkSession.online:
		GameWindow.play_ui("grill_place")
		NetworkSession.command("grill", args)
	elif service.get_parent().get_node("Cooking").handle(service, args):
		GameWindow.play_ui("grill_place")

func quick_transfer(index: int, from_storage: bool) -> void:
	if grill_open and not from_storage:
		var entry: Dictionary = service.local_slots[index]
		var id: StringName = entry.get("id", &"")
		var model: ShipGrill = service.get_parent().get_node("Cooking")
		var n := model.fish.size()
		request_grill({"action": "fuel" if id in [&"wood", &"coal"] else "fish", "index": index, "revision": service.view_revision, "point": Vector2(0.12 + (n % 4) * 0.25, 0.3 + (n / 4) * 0.45)})
	elif storage_open:
		service.request("take" if from_storage else "store", index)

func valid_drag(data: Variant) -> bool:
	return service.can_handle_items() and data is Dictionary and data.get("inventory_drag", false) and data.get("service_id", 0) == service.get_instance_id() and (not data.get("storage", false) or storage_open)

func _can_drop_on_deck(_position: Vector2, data: Variant) -> bool:
	var mouse := drop_zone.get_global_transform() * _position
	return valid_drag(data) and not hotbar.get_global_rect().has_point(mouse) and not (grill_panel.visible and grill_panel.get_global_rect().has_point(mouse)) and not (panels.visible and panels.get_global_rect().has_point(mouse))

func _drop_on_deck(_position: Vector2, data: Variant) -> void:
	service.request_drag(data)

func close() -> void:
	cancel_cursor()
	storage_open = false
	grill_open = false
	if is_instance_valid(service.player):
		service.player.set("inventory_open", false)

func _process(delta: float) -> void:
	if service == null:
		return
	if not service.can_handle_items():
		close()
	if storage_open and not service.near_storage():
		close()
	if not cursor_data.is_empty():
		_resolve_one()
	if not cursor_data.is_empty():
		if cursor_data.revision != service.view_revision or (cursor_data.get("chest_session",false) and not storage_open) or (cursor_data.get("grill_session",false) and not grill_open): cancel_cursor()
		else:
			cursor_icon.position = _cursor_position - Vector2(21,21)
			cursor_count.position = _cursor_position + Vector2(7,9)
	service.player.set("inventory_open", storage_open or grill_open)
	hotbar.visible = not MapState.map_open
	if grill_open and not service.get_parent().get_node("Cooking").near(service):
		close()
	grill_panel.visible = grill_open
	panels.visible = storage_open
	chest_panel.visible = storage_open
	drop_zone.mouse_filter = Control.MOUSE_FILTER_STOP if service.can_handle_items() and get_viewport().gui_is_dragging() else Control.MOUSE_FILTER_IGNORE
	message_time = maxf(0, message_time - delta)
	# Show brief action feedback only; controls remain in How to play.
	hint.visible = not MapState.map_open and message_time > 0
	hint.text = message if message_time > 0 else ""

func _unhandled_input(event: InputEvent) -> void:
	if service == null or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") and (storage_open or grill_open):
		if NetworkSession.online:
			NetworkSession.command("close")
		close()
		get_viewport().set_input_as_handled()
		return
	if not service.can_handle_items():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not storage_open and not grill_open and not get_viewport().gui_is_dragging():
		var item_id: StringName = service.local_slots[selected].get("id", &"")
		if item_id in [&"fish_cod", &"dried_fish"]:
			service.get_node("Eating").start()
			get_viewport().set_input_as_handled()
			return
	var handled := false
	if event.is_action_pressed("interact"):
		if NetworkSession.online:
			NetworkSession.command("interact")
			get_viewport().set_input_as_handled()
			return
		if storage_open or grill_open:
			close()
			handled = true
		elif service.grill_is_nearest():
			grill_open = true
			handled = true
		elif service.chest_is_nearest():
			service.open_nearest_chest()
			storage_open = true
			handled = true
	elif event is InputEventKey and event.pressed:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key >= KEY_1 and key < KEY_1 + buttons.size():
			selected = key - KEY_1
			handled = true
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		selected = posmod(selected + (-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1), buttons.size())
		handled = true
	if handled:
		if NetworkSession.online:
			NetworkSession.command("select", {"index": selected})
		service.player.set("inventory_open", storage_open or grill_open)
		_refresh()
		get_viewport().set_input_as_handled()

func pick_cursor(index: int, storage: bool, amount: int = -1) -> void:
	if not cursor_data.is_empty() or not service.can_handle_items(): return
	if storage and not storage_open: return
	var slots: Array[Dictionary] = service.storage_view if storage else service.local_slots
	if index < 0 or index >= slots.size() or slots[index].is_empty(): return
	var item := ItemDatabase.get_item(slots[index].id)
	if amount != -1 and item.max_stack <= 1: return
	cursor_data = {"inventory_drag":true,"index":index,"storage":storage,"amount":amount,"revision":service.view_revision,"service_id":service.get_instance_id(),"chest_session":storage_open,"grill_session":grill_open}
	cursor_icon.texture = item.icon
	var quantity: int = int(slots[index].quantity) if amount == -1 else amount
	cursor_count.text = str(quantity) if quantity > 1 else ""
	cursor_icon.position = get_viewport().get_mouse_position()-Vector2(21,21)
	cursor_count.position = get_viewport().get_mouse_position()+Vector2(7,9)
	cursor_layer.show()
	_refresh()

func cancel_cursor() -> void:
	_pending_one.clear()
	cursor_data.clear()
	if cursor_layer != null: cursor_layer.hide()
	if service != null: _refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse: _cursor_position = event.position
	if cursor_data.is_empty(): return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		cancel_cursor()
		return # Normal close handling can still close the chest or grill.
	if not event is InputEventMouseButton or not event.pressed or event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]: return
	get_viewport().set_input_as_handled()
	if not _pending_one.is_empty(): return
	if not service.can_handle_items() or cursor_data.revision != service.view_revision:
		cancel_cursor()
		return
	var point: Vector2 = event.position
	for button in buttons + chest_buttons:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_place_one(button)
				return
			service.request_drag(cursor_data,button.slot_index,button.is_storage)
			cancel_cursor()
			return
	if event.button_index == MOUSE_BUTTON_RIGHT: return
	if grill_panel.visible and grill_panel.get_global_rect().has_point(point):
		var local: Vector2 = grill_panel.get_global_transform().affine_inverse()*point
		if grill_panel._can_drop_data(local,cursor_data):
			grill_panel._drop_data(local,cursor_data)
			cancel_cursor()
		return
	if panels.visible and panels.get_global_rect().has_point(point):
		cancel_cursor()
		return
	if hotbar.get_global_rect().has_point(point): return
	service.request_drag(cursor_data)
	cancel_cursor()

func _cursor_slot(entry: Dictionary, index: int, storage: bool) -> Dictionary:
	if cursor_data.is_empty() or cursor_data.index != index or cursor_data.storage != storage or cursor_data.revision != service.view_revision: return entry
	var left := entry.duplicate()
	if left.is_empty(): return left
	left.quantity -= int(left.quantity) if cursor_data.amount == -1 else int(cursor_data.amount)
	return left if left.quantity > 0 else {}

func _place_one(button: InventorySlotButton) -> void:
	var source_slots: Array[Dictionary] = service.storage_view if cursor_data.storage else service.local_slots
	var source: Dictionary = source_slots[cursor_data.index]
	if source.is_empty(): return
	var item := ItemDatabase.get_item(source.id)
	if item.max_stack <= 1: return
	var remaining: int = int(source.quantity) if cursor_data.amount == -1 else int(cursor_data.amount)
	if button.is_storage == cursor_data.storage and button.slot_index == cursor_data.index:
		_set_cursor_remaining(remaining - 1)
		return
	var target_slots: Array[Dictionary] = service.storage_view if button.is_storage else service.local_slots
	var target: Dictionary = target_slots[button.slot_index]
	if not target.is_empty() and (target.id != source.id or int(target.quantity) >= item.max_stack): return
	_pending_one = {"id": source.id, "source_left": int(source.quantity) - 1, "remaining": remaining - 1, "destination": button.slot_index, "storage": button.is_storage, "target_quantity": int(target.get("quantity", 0)) + 1, "expires": Time.get_ticks_msec() + 2000}
	var data := cursor_data.duplicate()
	data.amount = 1
	service.request_drag(data, button.slot_index, button.is_storage)
	_resolve_one()

func _resolve_one() -> void:
	if _pending_one.is_empty(): return
	if service.view_revision == cursor_data.revision:
		if Time.get_ticks_msec() > int(_pending_one.expires): cancel_cursor()
		return
	var source_slots: Array[Dictionary] = service.storage_view if cursor_data.storage else service.local_slots
	var target_slots: Array[Dictionary] = service.storage_view if _pending_one.storage else service.local_slots
	var source: Dictionary = source_slots[cursor_data.index]
	var target: Dictionary = target_slots[_pending_one.destination]
	var expected_source: bool = int(source.get("quantity", 0)) == int(_pending_one.source_left) and (source.is_empty() or source.id == _pending_one.id)
	if not expected_source or target.get("id", &"") != _pending_one.id or int(target.get("quantity", 0)) != int(_pending_one.target_quantity):
		cancel_cursor()
		return
	var remaining: int = _pending_one.remaining
	_pending_one.clear()
	cursor_data.revision = service.view_revision
	_set_cursor_remaining(remaining)

func _set_cursor_remaining(amount: int) -> void:
	if amount <= 0:
		cancel_cursor()
		return
	cursor_data.amount = amount
	cursor_count.text = str(amount) if amount > 1 else ""
	_refresh()


