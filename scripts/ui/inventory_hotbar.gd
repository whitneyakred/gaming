class_name InventoryHotbar
extends Control

## A four-slot, signal-driven view of one PlayerInventory. The hotbar never
## owns item quantities; it redraws from the player's inventory whenever that
## resource changes.

@export var player_path: NodePath

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipText

var _inventory: PlayerInventory
var _slots: Array[Button] = []
var _icon_nodes: Array[TextureRect] = []
var _name_nodes: Array[Label] = []
var _quantity_nodes: Array[Label] = []
var _selection_nodes: Array[Panel] = []
var _selected_index: int = -1
var _tooltip_token: int = 0


func _ready() -> void:
	_slots.assign([$Slot1, $Slot2, $Slot3, $Slot4])
	_icon_nodes.assign([$Slot1/Icon, $Slot2/Icon, $Slot3/Icon, $Slot4/Icon])
	_name_nodes.assign([$Slot1/FallbackName, $Slot2/FallbackName, $Slot3/FallbackName, $Slot4/FallbackName])
	_quantity_nodes.assign([$Slot1/Quantity, $Slot2/Quantity, $Slot3/Quantity, $Slot4/Quantity])
	_selection_nodes.assign([$Slot1/Selection, $Slot2/Selection, $Slot3/Selection, $Slot4/Selection])

	for index in _slots.size():
		_slots[index].pressed.connect(_select_slot.bind(index))

	tooltip_panel.hide()
	_bind_inventory()
	refresh()


func _exit_tree() -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(refresh):
		_inventory.inventory_changed.disconnect(refresh)


func _unhandled_input(event: InputEvent) -> void:
	for index in _slots.size():
		var action := "hotbar_slot_%d" % (index + 1)
		if event.is_action_pressed(action) and not event.is_echo():
			_select_slot(index)
			get_viewport().set_input_as_handled()
			return


## Rebuilds every visible slot from the canonical PlayerInventory data.
func refresh() -> void:
	for index in _slots.size():
		_clear_slot(index)

	if _inventory == null:
		return

	for index in mini(_inventory.inventory.size(), _slots.size()):
		var item := _inventory.inventory[index]
		if item == null:
			continue
		_show_item(index, item, _inventory.get_quantity(item.id))

	if _selected_index >= _inventory.inventory.size():
		_selected_index = -1
		_tooltip_token += 1
		tooltip_panel.hide()
	_update_selection()


func _bind_inventory() -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		push_warning("InventoryHotbar could not find its player at %s." % player_path)
		return

	_inventory = player.get("player_inventory") as PlayerInventory
	if _inventory == null:
		push_warning("InventoryHotbar player has no PlayerInventory.")
		return

	if not _inventory.inventory_changed.is_connected(refresh):
		_inventory.inventory_changed.connect(refresh)


func _clear_slot(index: int) -> void:
	_icon_nodes[index].texture = null
	_icon_nodes[index].hide()
	_name_nodes[index].text = ""
	_name_nodes[index].hide()
	_quantity_nodes[index].text = ""
	_quantity_nodes[index].hide()


func _show_item(index: int, item: ItemData, quantity: int) -> void:
	if item.icon != null:
		_icon_nodes[index].texture = item.icon
		_icon_nodes[index].show()
	else:
		_name_nodes[index].text = item.display_name
		_name_nodes[index].show()

	if quantity > 1:
		_quantity_nodes[index].text = "x%d" % quantity
		_quantity_nodes[index].show()


func _select_slot(index: int) -> void:
	if _inventory == null or index >= _inventory.inventory.size():
		_selected_index = -1
		_tooltip_token += 1
		tooltip_panel.hide()
		_update_selection()
		return

	var item := _inventory.inventory[index]
	if item == null:
		return

	_selected_index = index
	var quantity := _inventory.get_quantity(item.id)
	tooltip_label.text = "%s%s\n%s" % [
		item.display_name,
		" x%d" % quantity if quantity > 1 else "",
		item.description,
	]
	tooltip_panel.show()
	_tooltip_token += 1
	_hide_tooltip_after_delay(_tooltip_token)
	_update_selection()


func _update_selection() -> void:
	for index in _selection_nodes.size():
		_selection_nodes[index].visible = index == _selected_index


func _hide_tooltip_after_delay(token: int) -> void:
	await get_tree().create_timer(4.0).timeout
	if token == _tooltip_token:
		tooltip_panel.hide()
