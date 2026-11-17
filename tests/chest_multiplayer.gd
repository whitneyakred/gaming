extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/chest_multiplayer_suite.gd").new())
