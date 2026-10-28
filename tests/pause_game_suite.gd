extends Node
## UC-PROG-pause-game checks, one function per row of the design's test list
## (docs/design/PROG.md, "Pause-game ... (single-player)"). Started by
## tests/pause_game.gd.

var failures: int = 0


func _ready() -> void:
	# The suite must keep running while it pauses the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _screen_visible() -> bool:
	return (PauseMenu.get_node("Screen") as Control).visible


func _run() -> void:
	get_tree().create_timer(120.0).timeout.connect(func() -> void:
		push_error("Pause test timed out")
		get_tree().quit(1))

	await _test_repeated_calls()

	if PauseMenu.is_paused():
		PauseMenu.resume()
	print("Pause game: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


# Row "Pause-game: repeated calls" (unit): pause() while paused and resume()
# while running change nothing and emit nothing.
func _test_repeated_calls() -> void:
	var emitted: Array[bool] = []
	var record := func(is_paused: bool) -> void: emitted.append(is_paused)
	PauseMenu.pause_changed.connect(record)

	_check(not PauseMenu.is_paused() and not get_tree().paused, "The game must start unpaused")
	_check(not _screen_visible(), "The pause screen must start hidden")

	PauseMenu.resume()
	_check(not get_tree().paused and emitted.is_empty(), "resume() while running must change nothing and emit nothing")

	PauseMenu.pause()
	_check(get_tree().paused and PauseMenu.is_paused(), "pause() must pause the tree")
	_check(_screen_visible(), "pause() must show the pause screen")
	_check(emitted == [true], "pause() must emit pause_changed(true) once")

	PauseMenu.pause()
	_check(get_tree().paused and _screen_visible(), "pause() while paused must leave the game paused")
	_check(emitted == [true], "pause() while paused must emit nothing")

	PauseMenu.resume()
	_check(not get_tree().paused and not _screen_visible(), "resume() must unpause the tree and hide the screen")
	_check(emitted == [true, false], "resume() must emit pause_changed(false) once")

	PauseMenu.resume()
	_check(emitted == [true, false], "resume() while running must emit nothing")

	PauseMenu.pause_changed.disconnect(record)
