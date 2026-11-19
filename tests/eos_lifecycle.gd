extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/eos_lifecycle_suite.gd").new())
