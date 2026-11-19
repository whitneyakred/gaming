extends SceneTree
## Run with the Godot console executable, --main-pack BUILD.pck and --script tools/export_smoke.gd.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("Packaged startup/quit timed out")
		quit(1))
	var result := change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	if result != OK:
		push_error("Packaged main scene failed to load")
		quit(1)
		return
	await scene_changed
	if not current_scene.is_in_group("title_screen"):
		push_error("Packaged build did not reach the title screen")
		quit(1)
		return
	await create_timer(0.5).timeout
	print("PACKAGED STARTUP: title scene loaded; exercising normal Quit")
	root.get_node("GameWindow").quit_game()
