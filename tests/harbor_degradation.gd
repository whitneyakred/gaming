extends SceneTree

func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/harbor_degradation_suite.gd").new())
