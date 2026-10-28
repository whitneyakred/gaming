class_name IslandHUD
extends CanvasLayer

## Shared on-screen HUD for island games: objective line, countdown,
## pirate-ship track, and a centered pop-up message.
## IslandGame drives it; island scripts normally don't touch it directly.

## The icon's tip sits this far ahead of its position, so the tip lands
## exactly on the track's right edge when time runs out.
const ICON_TIP_OFFSET: float = 8.0

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
var _inventory: PlayerInventory


func set_objective(text: String) -> void:
	objective_label.text = text
	objective_label.visible = not text.is_empty()

## Tints the objective line (e.g. hot/cold). Pass Color.WHITE to reset.
func set_objective_color(color: Color) -> void:
	objective_label.add_theme_color_override("font_color", color)

func set_time_left(seconds: float) -> void:
	time_label.text = "Time left: %ds" % int(ceil(seconds))

func set_threat_label(text: String) -> void:
	threat_label.text = text

func set_timer_visible(value: bool) -> void:
	time_label.visible = value
	threat_label.visible = value
	pirate_track.visible = value

## 0.0 = pirate ship at the start of the track, 1.0 = arrived.
func set_progress(progress: float) -> void:
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
	_toast_token += 1
	var token := _toast_token
	toast_label.text = text
	toast_label.visible = true
	await get_tree().create_timer(seconds, false).timeout
	if token == _toast_token:
		toast_label.visible = false

func _refresh_bag() -> void:
	if _inventory == null:
		bag_label.visible = false
		return
	bag_label.visible = true
	var parts: PackedStringArray = []
	for item in _inventory.inventory:
		parts.append("%s x%d" % [item.display_name, _inventory.get_quantity(item.id)])
	bag_label.text = "Bag: " + (", ".join(parts) if not parts.is_empty() else "empty")
