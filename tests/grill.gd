extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/grill_suite.gd").new())
