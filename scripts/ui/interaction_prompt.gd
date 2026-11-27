extends CanvasLayer
## Local hint; refresh proximity at 10 Hz but follow the moving target every frame.
var label: Label
var elapsed := 0.1
var target: Node2D
var target_offset := Vector2.ZERO
@onready var ship: Ship = get_parent()

func _ready() -> void:
	layer = 25
	label = Label.new()
	label.text = "Space - interact"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.hide()

func _process(delta: float) -> void:
	var crew: CharacterBody2D = ship.player
	if crew == null or crew.health <= 0 or crew.using_station or crew.inventory_open or crew.fishing_active or IslandChallenges.local_active() or PauseMenu.is_paused() or MapState.map_open:
		label.hide()
		target = null
		elapsed = 0.1
		return
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0.0
		_choose_target(crew)
	label.visible = is_instance_valid(target)
	if not label.visible: return
	var screen_point := target.get_global_transform_with_canvas() * target_offset
	label.position = (screen_point - Vector2(label.size.x * 0.5, 32 + label.size.y)).round()

func _choose_target(crew: CharacterBody2D) -> void:
	target = null
	target_offset = Vector2.ZERO
	var service := ship.get_node("InventorySystem") as InventoryService
	if service.grill_is_nearest():
		target = ship.get_node("Cooking") as Node2D
	elif service.chest_is_nearest():
		target = ship
		target_offset = service.storage_position if crew.position.distance_to(service.storage_position) <= crew.position.distance_to(service.second_storage_position) else service.second_storage_position
	elif not crew.is_overboard:
		var best := INF
		for node in ship.get_children():
			if node is ShipStation and node.name != "Galley" and node.can_interact(crew) and not is_instance_valid(node.operator):
				var gap: float = crew.global_position.distance_to(node.global_position)
				if gap < best:
					best = gap
					target = node
	if crew.on_land:
		var challenges := ship.get_node("IslandChallenges") as IslandChallenges
		var island := challenges.nearest(crew)
		if island != null and not challenges.locks.has(str(island.name)):
			target = island.get_node("MinigameTotem") as Node2D
			target_offset = Vector2(0, -48)
		for land in ship.get_islands():
			if not land is QuestIsland: continue
			var targets: Array = [QuestIsland.GATE] if land.paradise else [Vector2.ZERO] + QuestIsland.SEALS
			if land.paradise and VoyageState.paradise_quest.get("gate_open", false): targets.append(QuestIsland.BEACON)
			for point in targets:
				if land.to_local(crew.global_position).distance_to(point) <= land.interaction_distance:
					target = land
					target_offset = point
