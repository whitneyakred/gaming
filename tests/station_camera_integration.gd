extends SceneTree
func _initialize() -> void:
	var suite: Node = load("res://tests/station_camera_suite.gd").new()
	root.add_child.call_deferred(suite)
