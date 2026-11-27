extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/prop_polish_suite.gd").new())
