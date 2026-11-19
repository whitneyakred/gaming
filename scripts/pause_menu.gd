extends CanvasLayer

## Autoload `PauseMenu`: pauses and resumes the game (UC-PROG-pause-game,
## single-player slice; see docs/design/PROG.md).
##
## The freeze is SceneTree.paused. This node runs with process mode Always, so
## the pause screen and the pause key keep working while every gameplay node
## (ship, stations, player, island timer, cooking) is stopped. Gameplay code
## gets no pause hook of its own. A one-shot timer must be created with
## get_tree().create_timer(seconds, false) so that it stops too.
##
## In single-player the local player holds the Host's right to pause
## (BR-host-controls-session). Quit (extension 4a) waits for
## UC-PROG-quit-voyage (OI-21), so the screen has Resume only.

## Emitted after the game pauses (true) or resumes (false). Not emitted when
## pause() or resume() is called in the state the game is already in.
signal pause_changed(is_paused: bool)

## Input action that toggles pause. Bound to ESC in project.godot
const PAUSE_ACTION: StringName = &"pause"

@onready var _screen: Control = $Screen
var _restart_button: Button

@onready var _resume_button: Button = %ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen.visible = false
	_resume_button.pressed.connect(resume)
	_restart_button = Button.new()
	_restart_button.text = "Start new voyage"
	_restart_button.pressed.connect(func() -> void: VoyageSurvival.restart())
	$Screen/Center/Box.add_child(_restart_button)
	_restart_button.hide()


# Steps 1 and 4: the pause key pauses, and pressing it again resumes.
# Holding the key down (echo) does nothing more.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(PAUSE_ACTION, false):
		return
	get_viewport().set_input_as_handled()
	if is_paused():
		resume()
	else:
		pause()


## Freezes the game and shows the pause screen (steps 2 and 3).
## Does nothing if the game is already paused.
func pause() -> void:
	if VoyageSurvival.dead:
		return
	if is_paused():
		return
	get_tree().paused = true
	_screen.visible = true
	_resume_button.grab_focus()
	pause_changed.emit(true)


## Hides the pause screen and lets the game carry on from the values it was
## frozen at (step 5, POST-1). Does nothing if the game is not paused.
func resume() -> void:
	if VoyageSurvival.dead:
		return
	if not is_paused():
		return
	get_tree().paused = false
	_screen.visible = false
	_resume_button.show()
	_restart_button.hide()
	$Screen/Center/Box/Title.text = "Paused"
	$Screen/Center/Box/Hint.text = "Press ESC to resume"
	pause_changed.emit(false)


func is_paused() -> bool:
	return get_tree().paused

func show_game_over() -> void:
	get_tree().paused = true
	_screen.show()
	$Screen/Center/Box/Title.text = "Game over"
	$Screen/Center/Box/Hint.text = "Your health reached zero."
	_resume_button.hide()
	_restart_button.show()
	pause_changed.emit(true)
