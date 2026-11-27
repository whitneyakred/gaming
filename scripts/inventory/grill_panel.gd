extends Control
## Local copy of the galley minigame from main; only final commands go online.
const ACTIVITY := preload("res://scenes/galley_cooking.tscn")
var hud: CanvasLayer
var activity: Control
var menu: VBoxContainer
var status: Label
var start: Button
var recover: Button
var playing_token := -1
var submitted_token := -1
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := PanelContainer.new()
	background.add_theme_stylebox_override("panel",HarborTheme.panel())
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	background.offset_left = -205
	background.offset_right = 205
	background.offset_top = -110
	background.offset_bottom = 90
	menu = VBoxContainer.new()
	background.add_child(menu)
	status = HarborTheme.label("", 20)
	menu.add_child(status)
	start = HarborTheme.button("Prepare fish", _start)
	menu.add_child(start)
	recover = HarborTheme.button("Recover stored food / fuel", func(): hud.request_grill({"action": "recover"}))
	menu.add_child(recover)
	menu.add_child(HarborTheme.button("Close", _close))
func _close() -> void:
	if NetworkSession.online: NetworkSession.command("close")
	else: hud.close()
func grill() -> ShipGrill:
	return hud.service.get_parent().get_node_or_null("Cooking") as ShipGrill
func _start() -> void:
	for i in hud.service.local_slots.size():
		if hud.service.local_slots[i].get("id") == &"fish_cod":
			hud.request_grill({"action": "start", "index": i, "revision": hud.service.view_revision})
			return
	hud.service.feedback.emit("Catch a fish first.")
func _process(_delta: float) -> void:
	var model := grill()
	if model == null: return
	var id: int = hud.service.network_id if NetworkSession.online else 1
	if not visible or model.active_id != id:
		if is_instance_valid(activity): activity.queue_free(); activity = null
		playing_token = -1
	if not visible: return
	menu.get_parent().visible = model.active_id != id
	status.text = "Food Preparation Table" if model.active_id == 0 else "Another sailor is cooking…"
	start.disabled = model.active_id != 0
	recover.visible = not model.fish.is_empty() or not model.fuel.is_empty()
	if model.active_id == id and playing_token != model.token and submitted_token != model.token:
		playing_token = model.token
		activity = ACTIVITY.instantiate()
		add_child(activity)
		var attempt := playing_token
		activity.completed.connect(func(stars: int):
			submitted_token = attempt
			hud.request_grill({"action": "finish", "token": attempt, "stars": stars}))
		activity.cancelled.connect(func():
			submitted_token = attempt
			hud.request_grill({"action": "cancel", "token": attempt}))
func _can_drop_data(_at: Vector2, _data: Variant) -> bool: return false
func _drop_data(_at: Vector2, _data: Variant) -> void: pass
