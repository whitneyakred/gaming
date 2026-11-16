extends Node
## Display preferences, menu soundtrack and synthesized button sounds.
signal preferences_changed
const DEFAULTS := {"fullscreen": true, "window_size": 1, "vsync": true, "master": 0.8, "music": 0.35, "effects": 0.7, "reduced_motion": false, "mute_unfocused": true, "pause_unfocused": true}
const WINDOW_SIZES := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900)]
var preferences: Dictionary = DEFAULTS.duplicate()
var settings_path: String = "user://settings.cfg"
var sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var _sounds: Dictionary = {}
var _save_timer: Timer
var _focused: bool = true
var _music_started: bool = false
var _menu_music_requested: bool = false
var _quitting: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	if "--settings-test" in OS.get_cmdline_user_args():
		settings_path = "res://.godot/menu-test-settings.cfg"
	load_preferences(settings_path)
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(save_preferences)
	add_child(_save_timer)
	sound_player = AudioStreamPlayer.new()
	sound_player.bus = &"Effects"
	add_child(sound_player)
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	_sounds["hover"] = _tone(720.0, 0.045, 0.12)
	_sounds["click"] = _tone(440.0, 0.09, 0.3)
	_sounds["back"] = _tone(290.0, 0.12, 0.22)
	var track := load("res://assets/audio/menu_theme.ogg") as AudioStreamOggVorbis
	track.loop = true
	music_player.stream = track
	apply_preferences()

func load_preferences(path: String) -> void:
	preferences = DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for key: String in DEFAULTS:
		var value: Variant = config.get_value("preferences", key, DEFAULTS[key])
		if typeof(value) == typeof(DEFAULTS[key]):
			preferences[key] = value
	for key in ["master", "music", "effects"]:
		preferences[key] = clampf(preferences[key], 0.0, 1.0)
	preferences.window_size = clampi(preferences.window_size, 0, WINDOW_SIZES.size() - 1)

func save_preferences() -> void:
	var config := ConfigFile.new()
	for key: String in preferences:
		config.set_value("preferences", key, preferences[key])
	var result := config.save(settings_path)
	if result != OK:
		push_warning("Could not save preferences: %s" % error_string(result))

func set_preference(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	preferences[key] = value
	apply_preferences(key)
	_save_timer.start()
	preferences_changed.emit()

func reset_preferences() -> void:
	preferences = DEFAULTS.duplicate()
	apply_preferences()
	save_preferences()
	preferences_changed.emit()

func apply_preferences(changed_key: String = "") -> void:
	for key in ["master", "music", "effects"]:
		var bus := AudioServer.get_bus_index("Master" if key == "master" else key.capitalize())
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, preferences[key])))
	AudioServer.set_bus_mute(0, preferences.mute_unfocused and not _focused)
	if DisplayServer.get_name() != "headless":
		if changed_key in ["", "fullscreen", "window_size"]:
			# Browser fullscreen is requested only by a button/key gesture.
			if not OS.has_feature("web") or changed_key == "fullscreen":
				get_window().mode = Window.MODE_FULLSCREEN if preferences.fullscreen else Window.MODE_WINDOWED
			if not preferences.fullscreen and not OS.has_feature("web"):
				var screen := DisplayServer.screen_get_usable_rect(get_window().current_screen)
				get_window().size = WINDOW_SIZES[preferences.window_size].min(screen.size)
				get_window().position = screen.position + (screen.size - get_window().size) / 2
		if not OS.has_feature("web"):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if preferences.vsync else DisplayServer.VSYNC_DISABLED)

func _input(event: InputEvent) -> void:
	# Browser audio unlock must happen during a real user gesture.
	if _menu_music_requested and not _music_started and ((event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed)):
		_begin_menu_music()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_preference("fullscreen", get_window().mode != Window.MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
		return
	if what not in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	_focused = what == NOTIFICATION_APPLICATION_FOCUS_IN
	AudioServer.set_bus_mute(0, preferences.mute_unfocused and not _focused)
	if not _focused and preferences.pause_unfocused:
		var pause_menu := get_node_or_null("/root/PauseMenu")
		if pause_menu != null:
			pause_menu.call_deferred("pause")

func play_ui(kind: String = "click") -> void:
	if sound_player == null or _quitting or _sounds.is_empty():
		return
	sound_player.stream = _sounds.get(kind, _sounds.click)
	sound_player.play()
	if _menu_music_requested and kind != "hover":
		_begin_menu_music()

func _begin_menu_music() -> void:
	if not _quitting and not music_player.playing and music_player.stream != null:
		music_player.play()
		_music_started = true

func start_menu_music() -> void:
	_menu_music_requested = true
	if not OS.has_feature("web"):
		_begin_menu_music()

func stop_menu_music() -> void:
	_menu_music_requested = false
	music_player.stop()
	_music_started = false

func _exit_tree() -> void:
	if is_instance_valid(_save_timer) and not _save_timer.is_stopped():
		save_preferences()
	shutdown_audio()

func shutdown_audio() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	if is_instance_valid(sound_player):
		sound_player.stop()
		sound_player.stream = null
	_sounds.clear()

func quit_game() -> void:
	NetworkSession.save_world()
	if _quitting:
		return
	_quitting = true
	await EOSGRuntime.leave_lobby()
	HarborService.leave()
	if NetworkSession.online:
		NetworkSession.multiplayer.multiplayer_peer.close()
	NetworkSession.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	EOSGRuntime.shutdown()
	save_preferences()
	shutdown_audio()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _tone(frequency: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var count := int(22050 * duration)
	data.resize(count * 2)
	for i in count:
		var t := float(i) / 22050.0
		var envelope := minf(t / 0.004, 1.0) * pow(1.0 - float(i) / count, 2)
		var sample := (sin(TAU * frequency * t) + 0.3 * sin(TAU * frequency * 2.01 * t)) * envelope * amplitude
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	return _wav(data)

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream
