extends SceneTree
var ship: Node
var crew: Node
var access: Node
func _initialize() -> void:
	run.call_deferred()
func capture(label: String) -> void:
	crew.idle_sprite.refresh(0)
	crew._process(0)
	for child in crew.get_children():
		if child.get_script() == load("res://scripts/inventory/held_item.gd"): child._process(0)
	var camera: Camera2D = ship.get_node("Camera2D")
	camera.global_position = ship.to_global(Vector2(-100, -50))
	camera.zoom = Vector2(3.0, 3.0)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/" + label + ".png")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	ship = main.get_node("Ship")
	crew = ship.player
	access = ship.get_node("SwimAccess")
	main.process_mode = Node.PROCESS_MODE_DISABLED
	crew.position = access.plank_end
	access.update_crew(crew)
	access._advance_access(crew, access.jump_seconds * 0.6)
	await capture("cannonball-air")
	access._advance_access(crew, access.jump_seconds * 0.4 + access.dunk_seconds * 0.65)
	for child in ship.get_children():
		if child.get_script() == load("res://scripts/visuals/water_splash.gd"): child._process(0.12)
	await capture("cannonball-dip")
	access._advance_access(crew, 1.0)
	crew.global_position = ship.to_global(access.ladder_water)
	access.update_crew(crew)
	access._advance_access(crew, access.align_seconds + access.climb_seconds * 0.5)
	await capture("ladder-climb")
	access._advance_access(crew, access.climb_seconds * 0.5 + access.step_seconds * 0.5)
	await capture("ladder-step")
	quit()


