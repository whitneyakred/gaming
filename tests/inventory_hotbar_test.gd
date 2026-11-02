extends SceneTree
## Run with Godot --headless --path . --script res://tests/inventory_hotbar_test.gd

const HOTBAR_SCENE := preload("res://scenes/ui/inventory_hotbar.tscn")
const ITEM_DATA_SCRIPT := preload("res://scripts/item-system/item_data.gd")
const PLAYER_INVENTORY_SCRIPT := preload("res://scripts/inventory-system/player_inventory.gd")


class HotbarTestPlayer extends Node:
	var player_inventory: PlayerInventory


var failures: int = 0
var checks_run: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, test_name: String) -> void:
	checks_run += 1
	if condition:
		print("PASS: %s" % test_name)
		return

	failures += 1
	push_error("Inventory hotbar test failed: %s" % test_name)


func _slot(hotbar: InventoryHotbar, slot_number: int) -> Button:
	return hotbar.get_node("Slot%d" % slot_number) as Button


func _icon(hotbar: InventoryHotbar, slot_number: int) -> TextureRect:
	return _slot(hotbar, slot_number).get_node("Icon") as TextureRect


func _fallback_name(hotbar: InventoryHotbar, slot_number: int) -> Label:
	return _slot(hotbar, slot_number).get_node("FallbackName") as Label


func _quantity(hotbar: InventoryHotbar, slot_number: int) -> Label:
	return _slot(hotbar, slot_number).get_node("Quantity") as Label


func _selection(hotbar: InventoryHotbar, slot_number: int) -> Panel:
	return _slot(hotbar, slot_number).get_node("Selection") as Panel


func _pressed_action(action: StringName, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	match action:
		&"hotbar_slot_1":
			event.keycode = KEY_1
		&"hotbar_slot_2":
			event.keycode = KEY_2
		&"hotbar_slot_3":
			event.keycode = KEY_3
		&"hotbar_slot_4":
			event.keycode = KEY_4
	event.pressed = true
	event.echo = echo
	return event


func _run() -> void:
	var item_database: Node = root.get_node_or_null("ItemDatabase")
	_check(item_database != null, "ItemDatabase autoload is available for hotbar items")
	if item_database == null:
		quit(1)
		return

	var cod := item_database.call("get_item", &"fish_cod") as ItemData
	var rope := item_database.call("get_item", &"rope") as ItemData
	_check(cod != null and rope != null, "Catalog provides items for the hotbar")
	if cod == null or rope == null:
		quit(1)
		return

	var player := HotbarTestPlayer.new()
	player.name = "TestPlayer"
	player.player_inventory = PLAYER_INVENTORY_SCRIPT.new()
	root.add_child(player)

	var hotbar := HOTBAR_SCENE.instantiate() as InventoryHotbar
	hotbar.player_path = NodePath("../TestPlayer")
	root.add_child(hotbar)
	await process_frame

	_check(hotbar.get_node_or_null("Slot1") != null and hotbar.get_node_or_null("Slot4") != null, "Scene exposes all four hotbar slots")
	_check(not hotbar.tooltip_panel.visible, "Tooltip is hidden before a slot is selected")
	for slot_number in range(1, 5):
		_check(not _icon(hotbar, slot_number).visible, "Empty slot %d hides its icon" % slot_number)
		_check(not _fallback_name(hotbar, slot_number).visible, "Empty slot %d hides its fallback name" % slot_number)
		_check(not _quantity(hotbar, slot_number).visible, "Empty slot %d hides its quantity" % slot_number)
		_check(not _selection(hotbar, slot_number).visible, "Empty slot %d has no selection border" % slot_number)

	_check(player.player_inventory.add_item(cod), "Inventory accepts the first hotbar item")
	_check(player.player_inventory.try_add(&"fish_cod", 2), "Inventory can create a visible item stack")
	_check(player.player_inventory.add_item(rope), "Inventory accepts a second hotbar item")
	_check(_fallback_name(hotbar, 1).visible and _fallback_name(hotbar, 1).text == "Cod", "Signal refresh displays an iconless item name")
	_check(_quantity(hotbar, 1).visible and _quantity(hotbar, 1).text == "x3", "Signal refresh displays stack quantity above one")
	_check(_fallback_name(hotbar, 2).visible and _fallback_name(hotbar, 2).text == "Rope", "Signal refresh preserves inventory ordering")
	_check(not _quantity(hotbar, 2).visible, "A single item hides its quantity label")
	_check(not _fallback_name(hotbar, 3).visible, "Unused slots remain empty after refresh")

	_check(player.player_inventory.try_remove(&"fish_cod", 2), "Inventory removes part of a hotbar stack")
	_check(not _quantity(hotbar, 1).visible and _quantity(hotbar, 1).text == "", "Refresh hides quantity when a stack reaches one")

	var icon_item := ITEM_DATA_SCRIPT.new() as ItemData
	icon_item.id = &"hotbar_icon_test"
	icon_item.display_name = "Icon Test"
	icon_item.description = "Verifies icon rendering."
	icon_item.icon = GradientTexture2D.new()
	_check(player.player_inventory.add_item(icon_item), "Inventory accepts an item with an icon")
	_check(_icon(hotbar, 3).visible and _icon(hotbar, 3).texture == icon_item.icon, "Hotbar renders an item icon when one is assigned")
	_check(not _fallback_name(hotbar, 3).visible, "Icon rendering hides the fallback item name")

	_slot(hotbar, 2).emit_signal("pressed")
	_check(_selection(hotbar, 2).visible and not _selection(hotbar, 1).visible, "Clicking a slot updates the selection border")
	_check(hotbar.tooltip_panel.visible, "Clicking an occupied slot opens its tooltip")
	_check(hotbar.tooltip_label.text == "Rope\nStrong cordage for general shipboard tasks.", "Tooltip displays an item name and description")

	hotbar._unhandled_input(_pressed_action(&"hotbar_slot_3"))
	_check(_selection(hotbar, 3).visible and hotbar.tooltip_label.text == "Icon Test\nVerifies icon rendering.", "Hotbar number action selects its matching occupied slot")
	hotbar._unhandled_input(_pressed_action(&"hotbar_slot_1", true))
	_check(_selection(hotbar, 3).visible, "Echoed hotbar input does not change the current selection")
	hotbar._unhandled_input(_pressed_action(&"hotbar_slot_4"))
	_check(not hotbar.tooltip_panel.visible and not _selection(hotbar, 4).visible, "Selecting an empty slot clears the tooltip and selection")

	_slot(hotbar, 2).emit_signal("pressed")
	_check(player.player_inventory.try_remove(&"rope", 1), "Inventory removes a selected item")
	_check(not hotbar.tooltip_panel.visible and not _selection(hotbar, 2).visible, "Removing the selected final slot clears stale UI state")

	_slot(hotbar, 1).emit_signal("pressed")
	_check(hotbar.tooltip_panel.visible, "Tooltip can be opened after inventory changes")
	await create_timer(4.1).timeout
	_check(not hotbar.tooltip_panel.visible, "Tooltip automatically hides after its display delay")

	hotbar.queue_free()
	player.queue_free()
	await process_frame
	print("Inventory hotbar test: %d check(s), %d failure(s)" % [checks_run, failures])
	quit(0 if failures == 0 else 1)
