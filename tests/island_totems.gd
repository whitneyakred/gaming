extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/island_totems_suite.gd").new())
