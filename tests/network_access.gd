extends SceneTree
func _initialize() -> void:
	var suite: Node = load("res://tests/network_access_suite.gd").new()
	root.add_child.call_deferred(suite)
