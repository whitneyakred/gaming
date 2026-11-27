extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/generated_world_save_suite.gd").new())
