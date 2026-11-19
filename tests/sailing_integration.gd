extends SceneTree
## Run after autoloads exist; legacy rowing/cooking cases are superseded.
func _initialize() -> void:
	root.add_child.call_deferred(load("res://tests/sailing_integration_suite.gd").new())
