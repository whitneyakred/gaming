extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await physics_frame
	var ship = current_scene.get_node("Ship")
	var access = ship.get_node("SwimAccess")
	var crew = ship.player
	crew.position = Vector2(-45, -42)
	Input.action_press("move_left")
	for i in range(45):
		await physics_frame
	Input.action_release("move_left")
	assert(crew.is_overboard, "Plank must enter water")
	crew.global_position = ship.to_global(access.ladder_water)
	access.update_crew(crew)
	assert(not crew.is_overboard, "Ladder must board")
	ship.set_wheel_angle(-180.0)
	ship.get_node("Helm/Visual")._process(0.0)
	assert(is_equal_approx(ship.get_node("Helm/Visual/Wheel").rotation, -PI))
	assert(ship.get_node("Cooking").position == Vector2(66,72))
	print("Boat integration PASS: plank, ladder, wheel rotation, cooking position")
	quit()
