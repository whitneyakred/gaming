extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/character_animation_suite.gd").new())
