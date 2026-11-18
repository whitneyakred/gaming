extends Node
var failures: int = 0
var checks: int = 0
var capture: bool = false

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = "--capture" in OS.get_cmdline_user_args()
	run.call_deferred()

func frames(count: int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func screenshot(file: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + file + ".png")

func open_scene(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await frames()
	return get_tree().current_scene

func run() -> void:
	get_tree().create_timer(50).timeout.connect(func() -> void: get_tree().quit(1))
	GameWindow.preferences = GameWindow.DEFAULTS.duplicate()
	GameWindow.set_preference("fullscreen", false)
	GameWindow.set_preference("pause_unfocused", false)
	GameWindow.set_preference("reduced_motion", true)
	var title := await open_scene("res://scenes/menus/title_screen.tscn")
	check(title.is_in_group("title_screen"), "Title screen is the entry point")
	PauseMenu.pause()
	check(not get_tree().paused, "Title screen cannot be paused")
	check(get_window().content_scale_size == Vector2i(1280, 720), "Design canvas is 1280 by 720")
	var logo_rect: Rect2 = title.logo.get_global_rect()
	var ship_rest: Vector2 = title.logo_ship.position
	GameWindow.set_preference("reduced_motion", false)
	title._process(0.5)
	check(title.logo.get_global_rect() == logo_rect, "Lettering remains still while water animates")
	check(title.logo_ship.position.is_equal_approx(ship_rest), "Broken hull remains stationary")
	var shark: Node2D = title.get_node("Composition/Props").get_child(0)
	var shark_rest: Vector2 = shark.sprite.position
	var swim_frame: Texture2D = shark.sprite.texture
	shark._process(0.25)
	check(shark.sprite.position.distance_to(shark_rest) > 0.5, "Shark travels along its patrol")
	check(shark.sprite.texture != swim_frame and shark.frames.size() == 12, "Shark cycles twelve swimming poses")
	check(float(title.logo_ship.material.get_shader_parameter("ocean_time")) > 0.0, "Waterline moves independently of fixed wood")
	GameWindow.set_preference("reduced_motion", true)
	title._process(0.0)
	check(title.logo_ship.position.is_equal_approx(ship_rest), "Reduced motion restores ship rest position")
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		get_window().size = dimensions
		await frames(5)
		check(title.logo.get_global_rect().size.is_equal_approx(logo_rect.size) and title.get_global_rect().encloses(title.logo.get_global_rect()), "Logo stays proportional and fully visible at %s" % dimensions)
		var expected_scale := minf(dimensions.x / 1280.0, dimensions.y / 720.0)
		var expected_view := Vector2(dimensions) / expected_scale
		check(get_viewport().get_visible_rect().size.is_equal_approx(expected_view), "View expands without letterboxing at %s" % dimensions)
		await screenshot("title-%dx%d" % [dimensions.x, dimensions.y])
	get_window().size = Vector2i(1280, 720)
	title.open_customize()
	await frames()
	check(title.get_node("ProfileOverlay").visible, "Customize opens character and name popup")
	await screenshot("customize-menu")
	title.close_customize()
	check(not title.get_node("ProfileOverlay").visible, "Done closes customization")
	title.crew_menu.open()
	await frames()
	check(title.crew_menu.visible, "Crew menu opens from the title")
	await screenshot("crew-menu")
	check(title.crew_menu.tabs.current_tab == 0, "Crew browser opens first")
	check(title.crew_menu.tabs.get_tab_count() == 2, "Only browse and host tabs are shown")
	var browse_rect: Rect2 = title.crew_menu.tabs.get_parent().get_parent().get_global_rect()
	title.crew_menu.tabs.current_tab = 1
	await frames()
	check(title.crew_menu.tabs.get_parent().get_parent().get_global_rect() == browse_rect, "Host and browse panel bounds match")
	check(title.crew_menu.privacy.selected == 0 and not title.crew_menu.password_row.visible, "Public voyage defaults to no password field")
	title.crew_menu.privacy.select(1)
	title.crew_menu.privacy.item_selected.emit(1)
	check(title.crew_menu.password_row.visible and title.crew_menu.secret.text.is_empty(), "Private voyage starts with an empty password")
	await frames()
	await screenshot("crew-browser")
	check(title.crew_menu.tabs.get_parent().get_parent().get_global_rect() == browse_rect, "Private fields do not resize the crew panel")
	GameWindow.play_ui()
	await frames()
	check(GameWindow.music_player.playing and GameWindow.music_player.stream is AudioStreamOggVorbis, "Menu uses the supplied song")
	title.crew_menu.hide()
	title.settings.open()
	await frames()
	var tab_event := InputEventAction.new()
	tab_event.action = &"ui_focus_next"
	tab_event.pressed = true
	for i in 12:
		title.settings._input(tab_event)
		check(title.settings.is_ancestor_of(get_viewport().gui_get_focus_owner()), "Tab focus stays inside settings")
	await screenshot("settings-display")
	title.settings.open(1)
	await frames()
	await screenshot("settings-audio")
	title.settings.open(3)
	await frames()
	await screenshot("settings-controls")
	GameWindow.set_preference("master", 0.42)
	GameWindow.set_preference("music", 0.2)
	GameWindow.set_preference("reduced_motion", true)
	GameWindow.save_preferences()
	GameWindow.preferences.master = 1.0
	GameWindow.load_preferences(GameWindow.settings_path)
	check(is_equal_approx(GameWindow.preferences.master, 0.42), "Volume preference survives reload")
	check(GameWindow.preferences.reduced_motion, "Reduced motion survives reload")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.42), "Master slider drives audio bus")
	var corrupt := ConfigFile.new()
	corrupt.set_value("preferences", "master", -20.0)
	corrupt.set_value("preferences", "window_size", 500)
	corrupt.set_value("preferences", "fullscreen", "invalid")
	corrupt.save("res://.godot/invalid-settings.cfg")
	GameWindow.load_preferences("res://.godot/invalid-settings.cfg")
	check(GameWindow.preferences.master == 0.0 and GameWindow.preferences.window_size == 2 and GameWindow.preferences.fullscreen == true, "Invalid preferences are clamped or replaced by defaults")
	GameWindow.load_preferences(GameWindow.settings_path)
	title.settings.close()
	MapState.add_marker(Vector2(55, 44))
	Ship.completed_islands.append(&"old_test_island")
	VoyageState.get_inventory(&"player_1").try_add(&"rope", 3)
	title.play_button.emit_signal("pressed")
	check(title.crew_menu.visible, "Set Sail opens crew selection")
	title.crew_menu.solo_button.emit_signal("pressed")
	await get_tree().scene_changed
	await frames()
	check(get_tree().current_scene.has_node("Ship"), "Play starts a voyage")
	GameWindow.play_ui()
	check(GameWindow.music_player.playing and GameWindow.music_player.stream.resource_path.ends_with("voyage_01.ogg"), "Gameplay starts supplied voyage music, not menu music")
	check(MapState.markers.is_empty() and Ship.completed_islands.is_empty(), "New voyage clears map and island completion")
	check(VoyageState.get_inventory(&"player_1").get_quantity(&"rope") == 0, "New voyage clears carried items")
	var ship := get_tree().current_scene.get_node("Ship")
	var service := ship.get_node("InventorySystem")
	service.player.play_fishing_animation()
	check(service.player.idle_sprite.visible and not service.player.fishing_animation.visible, "Fishing leaves the normal sailor visible")
	service.player.position = service.storage_position
	service.hud.storage_open = true
	for dimensions in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		get_window().size = dimensions
		await frames(5)
		check(service.hud.hotbar.get_global_rect().size == Vector2(337, 119), "Hotbar design size stays consistent at %s" % dimensions)
		await screenshot("game-%dx%d" % [dimensions.x, dimensions.y])
	get_window().size = Vector2i(1280, 720)
	service.hud.close()
	PauseMenu.pause()
	check(get_tree().paused, "Pause freezes the voyage")
	await frames()
	await screenshot("pause-menu")
	PauseMenu._settings.open()
	check(PauseMenu._settings.visible, "Settings accessible during pause")
	PauseMenu._settings.close()
	check(get_tree().paused, "Closing settings keeps voyage paused")
	PauseMenu._ask_return()
	check(PauseMenu._confirm.visible, "Ending a voyage asks for confirmation")
	PauseMenu._confirm.hide()
	check(get_tree().current_scene.has_node("Ship"), "Cancelling return keeps current voyage")
	PauseMenu.resume()
	check(not get_tree().paused, "Resume restores gameplay")
	GameWindow.set_preference("pause_unfocused", true)
	GameWindow._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames()
	check(get_tree().paused, "Focus loss can auto-pause gameplay")
	GameWindow._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(get_tree().paused, "Focus regain does not unexpectedly resume gameplay")
	PauseMenu.return_to_title()
	await get_tree().scene_changed
	check(get_tree().current_scene.is_in_group("title_screen") and not get_tree().paused, "Return to title clears paused state")
	GameWindow.preferences = GameWindow.DEFAULTS.duplicate()
	GameWindow.preferences.fullscreen = false
	GameWindow.preferences.pause_unfocused = false
	GameWindow.save_preferences()
	print("MENU FLOW: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(failures)
