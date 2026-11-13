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

## Input action that toggles pause. Bound to P in project.godot (not Escape:
## ui_cancel already closes the cooking minigames).
const PAUSE_ACTION: StringName = &"pause"

@onready var _screen: Control = $Screen
@onready var _resume_button: Button = %ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen.visible = false
	_resume_button.pressed.connect(resume)


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
	if is_paused():
		return
	get_tree().paused = true
	_screen.visible = true
	_resume_button.grab_focus()
	pause_changed.emit(true)


## Hides the pause screen and lets the game carry on from the values it was
## frozen at (step 5, POST-1). Does nothing if the game is not paused.
func resume() -> void:
	if not is_paused():
		return
	get_tree().paused = false
	_screen.visible = false
	pause_changed.emit(false)


func is_paused() -> bool:
	return get_tree().paused
