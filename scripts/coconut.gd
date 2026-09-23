extends Area2D

# Emitted when the player walks over this coconut.
# island.gd listens for this to update the on-screen count.
signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		queue_free()
