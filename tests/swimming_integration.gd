extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	var crew := ship.player
	var access := ship.get_node("SwimAccess") as SwimAccess
	crew.position = Vector2(-45, -42)
	Input.action_press("move_left")
	for i in range(45):
		await physics_frame
	Input.action_release("move_left")
	_check(crew.is_overboard, "Walking along the plank must enter water")
	_check(crew.idle_sprite.region_enabled, "Swimming must display the cropped head")
	_check(crew.swim_speed < crew.walk_speed, "Swimming must be slower")
	_check(not crew.try_use_station(ship.get_node("Sail")), "Swimming must block station claims")
	var world := crew.global_position
	ship.global_position += Vector2(0, 30)
	_check(crew.global_position.is_equal_approx(world), "Ship movement must not tow the swimmer")
	crew.global_position = ship.to_global(access.ladder_water)
	access._physics_process(0.016)
	_check(not crew.is_overboard and crew.position == access.ladder_top, "Ladder must restore deck movement")
	_check(not crew.idle_sprite.region_enabled and crew.collision_mask != 0, "Ladder must restore full artwork and collisions")
	crew.set_overboard(true)
	var island := ship.get_island(&"CoconutIsland")
	var island_scene := island.scene
	var coast := island.get_nearest_coast_point(island.global_position + Vector2(1000, 0))
	crew.global_position = coast + Vector2(10, 0)
	access._physics_process(0.016)
	await scene_changed
	_check(current_scene.scene_file_path == island_scene, "Swimming ashore must start the minigame")
	current_scene._row_back(false)
	await scene_changed
	ship = current_scene as Ship
	_check(ship != null and ship.player.is_overboard, "Returning from a swimming visit must restore the swimmer")
	var restored := ship.player.global_position
	ship.get_node("SwimAccess")._physics_process(4.0)
	_check(ship.player.global_position == restored, "Return must not teleport onto the deck")
	_check(not ship.get_node("SwimAccess")._transitioning, "Return must not immediately restart the minigame")
	print("Swimming integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
