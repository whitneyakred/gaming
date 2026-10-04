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

var _message_token: int = 0


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
		await get_tree().create_timer(seconds).timeout
		if token == _message_token:
			message_label.visible = false

func hide_message() -> void:
	_message_token += 1
	message_label.visible = false
