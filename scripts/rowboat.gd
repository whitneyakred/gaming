extends Area2D

# Reports that the player reached the rowboat. Whether they're allowed to
# leave (and win) is decided by the island's IslandGame script via
# try_escape() — see scripts/islands/island_game.gd.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	var game := _find_island_game()
	if game:
		game.try_escape()

func _find_island_game() -> IslandGame:
	var node := get_parent()
	while node != null and not (node is IslandGame):
		node = node.get_parent()
	return node as IslandGame
