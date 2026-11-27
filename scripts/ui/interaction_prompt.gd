extends CanvasLayer
## Local presentation only. Uses the same proximity checks as interaction input.
var label: Label
var panel: PanelContainer
var elapsed := 0.0
@onready var ship: Ship = get_parent()
func _ready() -> void:
	layer = 25
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme = HarborTheme.menu_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142c32ee")
	style.border_color = Color("c7aa70")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 17)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.1: return
	elapsed = 0.0
	var crew: CharacterBody2D = ship.player
	panel.hide()
	if crew == null or crew.health <= 0 or crew.inventory_open or crew.fishing_active or IslandChallenges.local_active() or PauseMenu.is_paused() or MapState.map_open: return
	var service := ship.get_node("InventorySystem") as InventoryService
	var action := ""
	if crew.using_station:
		action = "Leave station"
	elif service.grill_is_nearest(): action = "Prepare food"
	elif service.chest_is_nearest(): action = "Open storage"
	elif not crew.is_overboard:
		var best := INF
		for node in ship.get_children():
			if node is ShipStation and node.name != "Galley" and node.can_interact(crew) and not is_instance_valid(node.operator):
				var gap: float = crew.global_position.distance_to(node.global_position)
				if gap < best:
					best = gap
					action = "Use " + String(node.name).to_lower()
	if crew.on_land:
		var challenges := ship.get_node("IslandChallenges") as IslandChallenges
		var island := challenges.nearest(crew)
		if island != null and not challenges.locks.has(str(island.name)): action = "Play challenge"
		for land in ship.get_islands():
			if not land is QuestIsland: continue
			var targets: Array = [QuestIsland.GATE] if land.paradise else [Vector2.ZERO] + QuestIsland.SEALS
			if land.paradise and VoyageState.paradise_quest.get("gate_open", false): targets.append(QuestIsland.BEACON)
			for point in targets:
				if land.to_local(crew.global_position).distance_to(point) <= land.interaction_distance: action = "Interact"
	if action.is_empty(): return
	label.text = "Space  ·  " + action
	panel.reset_size()
	var screen := get_viewport().get_visible_rect().size
	panel.position = Vector2((screen.x - panel.size.x) * 0.5, screen.y - 145)
	panel.show()
