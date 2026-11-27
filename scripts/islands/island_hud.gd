class_name IslandHUD
extends CanvasLayer

## Shared on-screen HUD for island games: objective line, countdown,
## pirate-ship track, and a centered pop-up message.
## IslandGame drives it; island scripts normally don't touch it directly.

## The icon's tip sits this far ahead of its position, so the tip lands
## exactly on the track's right edge when time runs out.
const ICON_TIP_OFFSET: float = 14.0

@onready var objective_label: Label = $ObjectiveLabel
@onready var time_label: Label = $TimeLabel
@onready var threat_label: Label = $ThreatLabel
@onready var pirate_track: Control = $PirateTrack
@onready var pirate_ship_icon: Node2D = $PirateTrack/PirateShipIcon
@onready var message_label: Label = $MessageLabel
@onready var prompt_label: Label = $PromptLabel
@onready var toast_label: Label = $ToastLabel
@onready var bag_label: Label = $BagLabel

var _message_token: int = 0
var _toast_token: int = 0
var energy: ProgressBar
var _inventory: PlayerInventory

func _ready() -> void:
	var panel := Panel.new()
	panel.position = Vector2(12,12)
	panel.size = Vector2(408,112)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",HarborTheme.box(Color("182d35eb"),Color("c9ab71"),2))
	add_child(panel)
	move_child(panel,0)
	objective_label.position = Vector2(24,20)
	objective_label.size = Vector2(384,34)
	objective_label.clip_text = true
	time_label.position = Vector2(24,61)
	time_label.size = Vector2(384,30)
	energy = ProgressBar.new()
	energy.show_percentage = false
	energy.position = Vector2(24,100)
	energy.size = Vector2(360,14)
	energy.add_theme_stylebox_override("background",HarborTheme.box(Color("182d35"),Color("c9ab71"),2))
	energy.add_theme_stylebox_override("fill",HarborTheme.box(Color("d7b777"),Color("d7b777"),0))
	add_child(energy)
	pirate_track.hide()
	threat_label.hide()
	objective_label.add_theme_font_size_override("font_size",24)
	time_label.add_theme_font_size_override("font_size",22)
	# Reserve the bottom row for the shared icon hotbar and its controls.
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_left = -350
	prompt_label.offset_right = 350
	prompt_label.offset_top = -164
	prompt_label.offset_bottom = -124
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	toast_label.offset_left = 16
	toast_label.offset_right = 420
	toast_label.offset_top = -194
	toast_label.offset_bottom = -166


func set_objective(text: String) -> void:
	objective_label.text = text
	objective_label.visible = not text.is_empty()

## Tints the objective line (e.g. hot/cold). Pass Color.WHITE to reset.
func set_objective_color(color: Color) -> void:
	objective_label.add_theme_color_override("font_color", color)

func set_time_left(seconds: float) -> void:
	time_label.text = "Totem: %ds" % int(ceil(seconds))

func set_threat_label(text: String) -> void:
	threat_label.text = ""

func set_timer_visible(value: bool) -> void:
	time_label.visible = value
	threat_label.hide()
	pirate_track.hide()
	if energy: energy.visible = value

## 0.0 = pirate ship at the start of the track, 1.0 = arrived.
func set_progress(progress: float) -> void:
	if energy: energy.value = (1.0-clampf(progress,0.0,1.0))*100.0
	var distance: float = pirate_track.size.x - ICON_TIP_OFFSET
	pirate_ship_icon.position.x = lerpf(0.0, distance, clampf(progress, 0.0, 1.0))

## Shows a centered message. seconds <= 0 keeps it up until replaced.
func show_message(text: String, seconds: float = 1.5) -> void:
	_message_token += 1
	var token := _message_token
	message_label.text = text
	message_label.visible = true
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout
		if token == _message_token:
			message_label.visible = false

func hide_message() -> void:
	_message_token += 1
	message_label.visible = false

## Bottom-centre hint such as "Press E to chop". Empty text hides it.
func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

## Shows the crew member's bag along the bottom and keeps it up to date.
func set_inventory(inventory: PlayerInventory) -> void:
	if _inventory and _inventory.changed.is_connected(_refresh_bag):
		_inventory.changed.disconnect(_refresh_bag)
	_inventory = inventory
	if _inventory:
		_inventory.changed.connect(_refresh_bag)
	_refresh_bag()

## A short note above the bag line, e.g. "+1 Coconut".
func show_toast(text: String, seconds: float = 1.6) -> void:
	if get_parent() is IslandGame and get_parent().embedded: return
	_toast_token += 1
	var token := _toast_token
	toast_label.text = text
	toast_label.visible = true
	await get_tree().create_timer(seconds, false).timeout
	if token == _toast_token:
		toast_label.visible = false

func _refresh_bag() -> void:
	# The reusable inventory HUD now renders the bag with icons.
	bag_label.visible = false
