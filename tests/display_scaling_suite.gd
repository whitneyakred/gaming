extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frames() -> void:
	for i in 5:
		await get_tree().process_frame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("fullscreen", false)
	GameWindow.set_preference("pause_unfocused", false)
	GameWindow.set_preference("ui_scale", 1.0)
	GameWindow.set_preference("camera_zoom", 1.0)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await frames()
	var ship := get_tree().current_scene.get_node("Ship")
	var camera: Camera2D = ship.get_node("SailingDemo").camera
	var baseline: float = get_viewport().get_visible_rect().size.y / camera.zoom.y
	for dimensions in [Vector2i(1280, 720), Vector2i(900, 1000), Vector2i(1600, 700)]:
		get_window().size = dimensions
		await frames()
		for ui_scale in [0.8, 1.0, 1.2]:
			GameWindow.set_preference("ui_scale", ui_scale)
			await frames()
			check(absf(get_viewport().get_visible_rect().size.y / camera.zoom.y - baseline) < 0.1, "Stable world height at %s UI %s" % [dimensions, ui_scale])
			check(is_equal_approx(get_window().content_scale_factor, ui_scale), "UI scale applied")
	GameWindow.set_preference("camera_zoom", 1.2)
	await frames()
	check(absf(get_viewport().get_visible_rect().size.y / camera.zoom.y - baseline / 1.2) < 0.1, "Camera zoom works independently")
	GameWindow.save_preferences()
	GameWindow.load_preferences(GameWindow.settings_path)
	check(is_equal_approx(GameWindow.preferences.ui_scale, 1.2) and is_equal_approx(GameWindow.preferences.camera_zoom, 1.2), "Display preferences survive reload")
	GameWindow.set_preference("fullscreen", true)
	await frames()
	check(absf(get_viewport().get_visible_rect().size.y / camera.zoom.y - baseline / 1.2) < 0.1, "Fullscreen preserves view")
	var service: InventoryService = ship.get_node("InventorySystem")
	service.hud.selected = 1
	var scope: SpyglassController = service.get_node("Spyglass")
	scope.set_process(false)
	scope.start()
	scope._update_view(scope.zoom_seconds)
	check(scope.active, "Spyglass can start with display scaling")
	GameWindow.set_preference("fullscreen", false)
	get_window().size = Vector2i(900, 1000)
	await frames()
	scope.start()
	scope._update_view(scope.zoom_seconds)
	check(absf(get_viewport().get_visible_rect().size.y / scope._scope_camera.zoom.y - baseline / 1.2 / scope.zoom_multiplier) < 0.1, "Spyglass keeps its relative zoom after resize")
	scope.stop(true)
	get_window().size = Vector2i(1280, 720)
	await frames()
	var settings := SettingsPanel.new()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	layer.add_child(settings)
	settings.open()
	await frames()
	await get_tree().create_timer(0.4).timeout
	check(settings._display_scales.size() == 2, "Both display controls available")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/display-settings.png")
	GameWindow.set_preference("ui_scale", 1.0)
	GameWindow.set_preference("camera_zoom", 1.0)
	GameWindow.set_preference("fullscreen", false)
	print("DISPLAY: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
