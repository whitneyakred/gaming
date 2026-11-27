extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/nautical_stations_suite.gd").new())
