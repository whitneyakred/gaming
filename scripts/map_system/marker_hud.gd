extends Control
## Screen-edge waypoints; local drawing only, no per-frame network traffic.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:
	visible = MapState.has_player_position and not MapState.map_open
	if visible: queue_redraw()
func _draw() -> void:
	var bounds := get_viewport_rect().grow(-42.0)
	var origin := MapState.player_position
	var scene := get_tree().current_scene
	var ship := scene.get_node_or_null("Ship") if scene else null
	var player: Node2D = NetworkSession.players.get(NetworkSession.local_id) if NetworkSession.online else (ship.player if ship is Ship else null)
	if is_instance_valid(player): origin = player.global_position
	for id: int in MapState.crew_markers:
		var world: Vector2 = MapState.crew_markers[id]
		var at: Vector2 = get_viewport().get_canvas_transform() * world
		var point := at.clamp(bounds.position, bounds.end)
		var color := MapState.marker_color(id)
		draw_circle(point, 8, Color("172331"))
		draw_circle(point, 6, color, false, 2)
		draw_string(HarborTheme.UI_FONT, point + Vector2(-28, 25), "%d m" % roundi(origin.distance_to(world)/maxf(MapState.pixels_per_meter,0.001)), HORIZONTAL_ALIGNMENT_CENTER, 62, 15, color)
