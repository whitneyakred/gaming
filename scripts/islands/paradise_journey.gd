class_name ParadiseJourney
extends Node
@onready var ship: Ship = get_parent()

func _ready() -> void:
	VoyageState.quest_changed.connect(_progress_changed)

func _progress_changed() -> void:
	MapState.changed.emit()
	if NetworkSession.online and multiplayer.is_server(): NetworkSession.save_world()

func interact(crew: CharacterBody2D) -> bool:
	if crew.health <= 0 or crew.inventory_open or crew.fishing_active or crew.island_challenge: return false
	for island in ship.get_islands():
		if island is QuestIsland and island.interact(crew): return true
		for child in island.get_children():
			if child is QuestClue and child.interact(crew): return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if NetworkSession.online or PauseMenu.is_paused() or MapState.map_open or IslandChallenges.local_active(): return
	if event.is_action_pressed("interact") and not event.is_echo() and interact(ship.player):
		get_viewport().set_input_as_handled()
