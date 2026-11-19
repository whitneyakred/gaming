extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/wind_integration_suite.gd").new())
