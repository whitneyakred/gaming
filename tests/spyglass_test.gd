extends Node
@onready var root: Window = get_tree().root
var failures: int = 0
var checks: int = 0
func _ready() -> void:
	run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	get_tree().create_timer(15).timeout.connect(func() -> void: get_tree().quit(1))
	var voyage := root.get_node("VoyageState")
	var window := root.get_node("GameWindow")
	window.set_preference("fullscreen", false)
	window.set_preference("pause_unfocused", false)
	voyage.reset()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var service: InventoryService = main.get_node("Ship/InventorySystem")
	var scope: SpyglassController = service.get_node("Spyglass")
	check(service.inventory.get_quantity(&"spyglass") == 1, "Fresh player receives one spyglass")
	check(service.inventory.get_quantity(&"fishing_rod") == 1, "Starter rod retained")
	voyage.grant_starter(service.inventory)
	check(service.inventory.get_quantity(&"spyglass") == 1, "Starter tools cannot duplicate")
	service.hud.selected = 1
	var original := root.get_camera_2d()
	var zoom := original.zoom
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1080, 300)
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = motion.position
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	await get_tree().process_frame
	check(scope.active, "World left-click activates spyglass through input routing")
	check(scope._scope_camera.global_position.distance_to(service.player.global_position) <= 450.01, "Camera remains bounded after frames of ship tracking")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/spyglass-view.png")
	press.pressed = false
	press.position = Vector2(640, 680)
	Input.parse_input_event(press)
	await get_tree().process_frame
	check(not scope.active, "Mouse release over hotbar stops scouting")
	scope.start()
	check(scope.active and root.get_camera_2d() == scope._scope_camera, "Spyglass immediately owns camera")
	check(scope._scope_camera.zoom.x > zoom.x * 0.6, "Zoom starts without snapping to the far view")
	scope._update_view(scope.zoom_seconds * 0.5)
	check(scope._scope_camera.zoom.x < zoom.x and scope._scope_camera.zoom.x > zoom.x * 0.6, "Zoom passes through intermediate scale")
	scope._update_view(scope.zoom_seconds)
	check(scope._scope_camera.zoom.is_equal_approx(zoom * 0.6), "Zoom reaches its intended scale")
	check(is_equal_approx(scope.pan_for_mouse(Vector2(854, 360), Vector2(1280, 720)).length(), 450), "Small mouse movement reaches full pan at triple sensitivity")
	check(scope.pan_for_mouse(Vector2(640, 360), Vector2(1280, 720)) == Vector2.ZERO, "Centered mouse has no pan")
	check(is_equal_approx(scope.pan_for_mouse(Vector2(1280, 720), Vector2(1280, 720)).length(), 450), "Diagonal pan stays inside circular limit")
	check(scope.pan_for_mouse(Vector2(9000, -5000), Vector2(1280, 720)).length() <= 450.01, "Offscreen mouse cannot exceed pan limit")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	scope._input(release)
	check(not scope.active and root.get_camera_2d() == scope._scope_camera, "Release starts a smooth return")
	scope._update_view(scope.zoom_seconds * 0.5)
	check(scope._scope_camera.zoom.x > zoom.x * 0.6 and scope._scope_camera.zoom.x < zoom.x, "Return zoom passes through intermediate scale")
	scope._update_view(scope.zoom_seconds)
	check(root.get_camera_2d() == original and original.zoom == zoom, "Return restores original camera and zoom")
	scope.start()
	service.hud.selected = 0
	scope._process(0)
	check(not scope.active, "Switching items ends scouting")
	service.hud.selected = 1
	service.hud.storage_open = true
	scope.start()
	check(not scope.active, "Chest interaction cannot start scouting")
	service.hud.close()
	scope.start()
	get_tree().paused = true
	scope._process(0)
	check(not scope.active and root.get_camera_2d() == original, "Pause restores camera")
	get_tree().paused = false
	scope.start()
	scope.stop()
	service.inventory.transfer_to(1, service.storage)
	voyage.grant_starter(service.inventory)
	check(service.inventory.get_quantity(&"spyglass") == 0 and service.storage.slots[0].id == &"spyglass", "Stored spyglass does not respawn")
	scope.start()
	check(not scope.active, "Cannot use a stored spyglass")
	main.queue_free()
	await get_tree().process_frame
	var island: Node = load("res://scenes/islands/cannon_cove.tscn").instantiate()
	root.add_child(island)
	await get_tree().process_frame
	await get_tree().process_frame
	var island_service: InventoryService = island.find_child("InventorySystem", true, false)
	check(island_service != null, "Island provides shared inventory tools")
	if island_service != null:
		island_service.storage.transfer_to(0, island_service.inventory)
		island_service.hud.selected = 1
		var island_scope: SpyglassController = island_service.get_node("Spyglass")
		island_scope.start()
		check(island_scope.active, "Spyglass works on island camera")
		island_scope.stop()
	island.queue_free()
	await get_tree().process_frame
	print("SPYGLASS: %d checks, %d failures" % [checks, failures])
	window.shutdown_audio()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(1 if failures else 0)
