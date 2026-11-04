extends SceneTree
## Run with Godot --headless --path . --script res://tests/voyage_inventory_test.gd

const PLAYER_SCENE_PATH := "res://scenes/player.tscn"
const COCONUT_SCENE_PATH := "res://scenes/coconut.tscn"

var failures: int = 0
var checks_run: int = 0
var coconut_collected_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, test_name: String) -> void:
	checks_run += 1
	if condition:
		print("PASS: %s" % test_name)
		return

	failures += 1
	push_error("Voyage inventory test failed: %s" % test_name)


func _on_coconut_collected(_item_id: StringName) -> void:
	coconut_collected_count += 1


func _run() -> void:
	var voyage_state := root.get_node_or_null("VoyageState")
	_check(voyage_state != null, "VoyageState autoload is available")
	if voyage_state == null:
		quit(1)
		return
	voyage_state.call(&"clear_voyage")
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	var coconut_scene := load(COCONUT_SCENE_PATH) as PackedScene
	_check(player_scene != null and coconut_scene != null, "Player and coconut scenes load after autoload startup")
	if player_scene == null or coconut_scene == null:
		quit(1)
		return

	var item_database := root.get_node_or_null("ItemDatabase")
	var rope := item_database.call(&"get_item", &"rope") as ItemData if item_database != null else null
	_check(rope != null, "Catalog provides rope for persistence testing")
	if rope == null:
		quit(1)
		return

	var ship_player := player_scene.instantiate() as CharacterBody2D
	root.add_child(ship_player)
	await process_frame
	var original_inventory := ship_player.get("player_inventory") as PlayerInventory
	_check(original_inventory != null, "Initial player receives a voyage inventory")
	if original_inventory == null:
		quit(1)
		return
	_check(original_inventory.add_item(rope), "Initial player can receive an item before changing scenes")

	ship_player.queue_free()
	await process_frame
	var island_player := player_scene.instantiate() as CharacterBody2D
	root.add_child(island_player)
	await process_frame
	var returned_inventory := island_player.get("player_inventory") as PlayerInventory
	_check(returned_inventory == original_inventory, "Replacement player reuses the active voyage inventory")
	_check(returned_inventory.get_quantity(&"rope") == 1, "Items survive the player scene replacement")

	var coconut := coconut_scene.instantiate() as Area2D
	coconut.collected.connect(_on_coconut_collected)
	root.add_child(coconut)
	await process_frame
	coconut._on_body_entered(island_player)
	await process_frame
	_check(coconut_collected_count == 1, "Coconut emits collected after inventory storage succeeds")
	_check(returned_inventory.get_quantity(&"coconut") == 1, "Coconut pickup adds its item to the player inventory")

	island_player.queue_free()
	voyage_state.call(&"clear_voyage")
	await process_frame
	print("Voyage inventory test: %d check(s), %d failure(s)" % [checks_run, failures])
	quit(0 if failures == 0 else 1)
