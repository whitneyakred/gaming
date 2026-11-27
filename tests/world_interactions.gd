extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/world_interactions_suite.gd").new())
