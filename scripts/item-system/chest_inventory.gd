class_name ChestInventory
extends Control

## A modal two-container view.  It only renders the canonical inventory
## Resources and never owns a second copy of their quantities.
signal close_requested

const SLOT_COUNT := 12
const PANEL_COLOR := Color(0.035, 0.075, 0.11, 0.96)
const SLOT_COLOR := Color(0.12, 0.19, 0.25, 1.0)

var _player_inventory: PlayerInventory
var _chest_inventory: PlayerInventory
var _player_slots: Array[Button] = []
var _chest_slots: Array[Button] = []
var _feedback: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	hide()


func _exit_tree() -> void:
	_disconnect_inventories()


func open_for(player_inventory: PlayerInventory, chest_inventory: PlayerInventory) -> void:
	_disconnect_inventories()
	_player_inventory = player_inventory
	_chest_inventory = chest_inventory
	_connect_inventories()
	refresh()
	show()


func close() -> void:
	if not visible:
		return
	hide()
	_disconnect_inventories()
	close_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel")) and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()


func refresh() -> void:
	_refresh_slots(_player_slots, _player_inventory)
	_refresh_slots(_chest_slots, _chest_inventory)


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.58)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(245, 115)
	panel.size = Vector2(790, 490)
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL_COLOR, Color(0.95, 0.78, 0.35, 0.9), 2, 8))
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var title := Label.new()
	title.text = "Ship's Chest"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	title_row.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close  [Esc]"
	close_button.pressed.connect(close)
	title_row.add_child(close_button)

	var instruction := Label.new()
	instruction.text = "Click an item to move one into the other inventory. Press E, Space, or Esc to close."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(instruction)

	var containers := HBoxContainer.new()
	containers.add_theme_constant_override("separation", 20)
	containers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(containers)
	containers.add_child(_make_inventory_panel("Your Inventory", true))
	containers.add_child(_make_inventory_panel("Shared Ship Storage", false))

	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_color_override("font_color", Color(1, 0.75, 0.38))
	content.add_child(_feedback)


func _make_inventory_panel(title_text: String, is_player: bool) -> VBoxContainer:
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	holder.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	holder.add_child(grid)
	for index in SLOT_COUNT:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(82, 72)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("font_size", 13)
		slot.add_theme_stylebox_override("normal", _stylebox(SLOT_COLOR, Color(0.44, 0.59, 0.67), 1, 4))
		slot.pressed.connect(_transfer_slot.bind(is_player, index))
		grid.add_child(slot)
		if is_player:
			_player_slots.append(slot)
		else:
			_chest_slots.append(slot)
	return holder


func _refresh_slots(slots: Array[Button], inventory: PlayerInventory) -> void:
	for index in slots.size():
		var slot := slots[index]
		slot.text = ""
		slot.tooltip_text = "Empty slot"
		slot.disabled = true
		if inventory == null or index >= inventory.inventory.size():
			continue
		var item := inventory.inventory[index]
		if item == null:
			continue
		var quantity := inventory.get_quantity(item.id)
		slot.text = "%s%s" % [item.display_name, "\nx%d" % quantity if quantity > 1 else ""]
		slot.tooltip_text = "%s\n%s" % [item.display_name, item.description]
		slot.disabled = false


func _transfer_slot(from_player: bool, slot_index: int) -> void:
	var source := _player_inventory if from_player else _chest_inventory
	var destination := _chest_inventory if from_player else _player_inventory
	if source == null or destination == null or slot_index < 0 or slot_index >= source.inventory.size():
		return
	var item := source.inventory[slot_index]
	if item == null:
		return
	if not destination.try_add(item.id, 1):
		_feedback.text = "%s has no room for %s." % ["Chest" if from_player else "Player inventory", item.display_name]
		return
	if not source.try_remove(item.id, 1):
		destination.try_remove(item.id, 1)
		_feedback.text = "Could not move %s." % item.display_name
		return
	_feedback.text = "Moved %s." % item.display_name


func _connect_inventories() -> void:
	if _player_inventory != null and not _player_inventory.inventory_changed.is_connected(refresh):
		_player_inventory.inventory_changed.connect(refresh)
	if _chest_inventory != null and not _chest_inventory.inventory_changed.is_connected(refresh):
		_chest_inventory.inventory_changed.connect(refresh)


func _disconnect_inventories() -> void:
	if _player_inventory != null and _player_inventory.inventory_changed.is_connected(refresh):
		_player_inventory.inventory_changed.disconnect(refresh)
	if _chest_inventory != null and _chest_inventory.inventory_changed.is_connected(refresh):
		_chest_inventory.inventory_changed.disconnect(refresh)


func _stylebox(color: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
