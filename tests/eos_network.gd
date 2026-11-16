extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/eos_network_suite.gd").new())
