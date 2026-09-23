extends Area2D

# A walk-over trigger that sends the player to another scene.
# Set target_scene in the Inspector for each trigger that uses this script
# (e.g. the ship's Gangplank goes to island.tscn, the island's ReturnToShip
# goes back to ship.tscn).
@export_file("*.tscn") var target_scene: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and target_scene != "":
		get_tree().change_scene_to_file(target_scene)
