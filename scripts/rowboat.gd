extends Area2D

# The rowboat only lets the player leave once island.gd confirms every
# coconut has been collected and time hasn't run out. All the actual
# win/lose logic lives in island.gd's try_escape(); this script just
# reports that the player reached the boat.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		get_parent().try_escape()
