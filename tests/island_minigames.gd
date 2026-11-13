extends SceneTree
## Plays every island minigame headlessly and checks that what you collect
## lands in the voyage inventory (and that the ship has no nearest-island text).
## Run with: godot --headless --path . --script res://tests/island_minigames.gd
##
## The checks live in island_minigames_suite.gd. It is loaded here, after the
## autoloads (ItemDatabase, VoyageState...) exist, so it can use them by name.

func _initialize() -> void:
	var suite: Node = load("res://tests/island_minigames_suite.gd").new()
	suite.name = "IslandMinigamesSuite"
	root.add_child.call_deferred(suite)
