extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/ocean_fish_suite.gd").new())
