extends SceneTree
## Run with: godot --headless --path . --script res://tests/fishing_station_test.gd

const FISHING_STATION_SCENE := preload("res://scenes/stations/fishing_station.tscn")
const ITEM_DATABASE_SCRIPT := preload("res://scripts/item-system/item_database.gd")
const PLAYER_INVENTORY_SCRIPT := preload("res://scripts/inventory-system/player_inventory.gd")

class TestPlayer:
	extends CharacterBody2D
	var player_inventory
	var active_station: Node = null

	func try_use_station(station: Node) -> bool:
		if active_station != null:
			return false
		active_station = station
		return true

	func leave_station(station: Node) -> void:
		if active_station == station:
			active_station = null

var failures: int = 0
var test_root: Node2D

func _initialize() -> void:
	var item_database := ITEM_DATABASE_SCRIPT.new()
	item_database.name = &"ItemDatabase"
	root.add_child(item_database)
	_register_test_items(item_database)
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _register_test_items(item_database: Node) -> void:
	for definition in [
		[&"fish_cod", "Cod", 10],
		[&"fishing_rod", "Fishing Rod", 1],
	]:
		var item := ItemData.new()
		item.id = definition[0]
		item.display_name = definition[1]
		item.max_stack = definition[2]
		item_database.register_item(item)

func _make_player(max_inventory_spaces: int = 4) -> TestPlayer:
	var player := TestPlayer.new()
	var inventory = PLAYER_INVENTORY_SCRIPT.new()
	inventory.max_inv_space = max_inventory_spaces
	inventory.add_item(root.get_node("ItemDatabase").get_item(&"fishing_rod"))
	player.player_inventory = inventory
	test_root.add_child(player)
	await process_frame
	return player

func _make_station(player: CharacterBody2D) -> FishingStation:
	var station := FISHING_STATION_SCENE.instantiate() as FishingStation
	station.minimum_hold_seconds = 0.05
	station.maximum_hold_seconds = 0.05
	station.result_feedback_seconds = 0.05
	station.loot_ids = [&"fish_cod"]
	test_root.add_child(station)
	station.interacting_player = player
	station.is_player_in_range = true
	await process_frame
	return station

func _run() -> void:
	test_root = Node2D.new()
	root.add_child(test_root)
	await _test_missing_rod_does_not_claim()
	await _test_cancel_releases_lock()
	await _test_success_awards_loot_and_releases_lock()
	await _test_full_inventory_releases_lock_with_feedback()
	test_root.queue_free()
	print("Fishing station: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _test_missing_rod_does_not_claim() -> void:
	var player := await _make_player()
	player.player_inventory.remove_item(&"fishing_rod")
	var station := await _make_station(player)
	station.start_attempt()
	_check(player.active_station == null, "Fishing without a rod must not claim the player")
	_check(station.status_label.text == "Fishing rod required", "Fishing must explain the missing rod")
	station.queue_free()
	player.queue_free()
	await process_frame

func _test_cancel_releases_lock() -> void:
	var player := await _make_player()
	var station := await _make_station(player)
	station.start_attempt()
	_check(player.active_station == station, "Starting fishing must claim the player")
	station.cancel_attempt()
	_check(player.active_station == null, "Cancelling fishing must restore movement")
	_check(station.status_label.text == "Fishing cancelled", "Cancelling fishing must show feedback")
	station.queue_free()
	player.queue_free()
	await process_frame

func _test_success_awards_loot_and_releases_lock() -> void:
	var player := await _make_player()
	var station := await _make_station(player)
	var before: int = player.player_inventory.get_quantity(&"fish_cod")
	station.start_attempt()
	await _wait(0.1)
	_check(station.state == FishingStation.State.READY_TO_RELEASE, "Fishing must become ready after the hold duration")
	station.complete_attempt()
	_check(player.player_inventory.get_quantity(&"fish_cod") == before + 1, "A completed attempt must award its configured item")
	_check(player.active_station != station, "A completed attempt must release the fishing station")
	_check(station.status_label.text == "Caught: Cod", "A completed attempt must show the catch")
	station.queue_free()
	player.queue_free()
	await process_frame

func _test_full_inventory_releases_lock_with_feedback() -> void:
	var player := await _make_player(1)
	var station := await _make_station(player)
	station.start_attempt()
	await _wait(0.1)
	station.complete_attempt()
	_check(player.player_inventory.get_quantity(&"fish_cod") == 0, "A full inventory must not receive a fishing reward")
	_check(player.active_station == null, "A full inventory result must release the player")
	_check(station.status_label.text == "Inventory is full", "A full inventory must show feedback")
	station.queue_free()
	player.queue_free()
	await process_frame
