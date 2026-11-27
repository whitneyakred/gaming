extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/foliage_suite.gd").new())
