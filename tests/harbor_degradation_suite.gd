extends Node
## ROB-HARBOR-unavailable: the API error reaches the real crew menu.

class FailedHarbor extends "res://scripts/network/harbor_service.gd":
	var attempted: bool = false
	func call_api(_path: String, _data: Dictionary = {}) -> Dictionary:
		attempted = true
		return {"error": "The harbor is unavailable. Please try again shortly."}

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var menu := CrewMenu.new()
	add_child(menu)
	var harbor := FailedHarbor.new()
	add_child(harbor)
	harbor.endpoint = "https://example.invalid"
	await harbor.host("Failure test", "")
	var passed: bool = harbor.attempted and not harbor.busy and harbor.operation.is_empty()
	passed = passed and not NetworkSession.online and harbor.peer == null
	passed = passed and menu.message.text == "The harbor is unavailable. Please try again shortly."
	print("Harbor degradation UI: ", "PASS" if passed else "FAIL")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if passed else 1)
