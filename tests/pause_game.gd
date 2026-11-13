extends SceneTree
## Tests UC-PROG-pause-game (single-player slice, docs/design/PROG.md).
## Run with: godot --headless --path . --script res://tests/pause_game.gd
##
## The checks live in pause_game_suite.gd. It is loaded here, after the
## autoloads (PauseMenu, VoyageState...) exist, so it can use them by name.

func _initialize() -> void:
	var suite: Node = load("res://tests/pause_game_suite.gd").new()
	suite.name = "PauseGameSuite"
	root.add_child.call_deferred(suite)
