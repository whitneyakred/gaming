extends Node
## Display preferences, menu soundtrack and synthesized button sounds.
signal preferences_changed
const DEFAULTS := {"ui_scale": 1.0, "camera_zoom": 1.0, "fullscreen": true, "window_size": 1, "vsync": true, "master": 0.8, "music": 0.35, "effects": 0.7, "reduced_motion": false, "mute_unfocused": true, "pause_unfocused": true}
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
const VOYAGE_TRACKS := ["res://assets/audio/voyage_01.ogg", "res://assets/audio/voyage_02.ogg"]
var _voyage_tracks: Array[AudioStreamOggVorbis] = []
var _voyage_index: int = 0
var _voyage_music_requested: bool = false

func _enter_tree() -> void:
	# Custom-drawn HUD text uses the same font as themed Controls.
	ThemeDB.fallback_font = HarborTheme.UI_FONT

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
	music_player.finished.connect(_next_voyage_track)
	_sounds["hover"] = _menu_sound("hover")
	_sounds["click"] = _menu_sound("click")
	_sounds["grill_place"] = _grill_sound(false)
	_sounds["grill_ready"] = _grill_sound(true)
	_sounds["pickup"] = _tone(1046.5, 0.10, 0.16)
	_sounds["drop"] = _tone(145.0, 0.12, 0.16)
	_sounds["back"] = _menu_sound("back")
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
	preferences.ui_scale = clampf(preferences.ui_scale, 0.8, 1.2)
	preferences.camera_zoom = clampf(preferences.camera_zoom, 0.8, 1.2)
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
	if key in ["ui_scale", "camera_zoom"]:
		value = clampf(float(value), 0.8, 1.2)
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
	get_window().content_scale_factor = preferences.ui_scale
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
	if (_menu_music_requested or _voyage_music_requested) and not _music_started and ((event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed)):
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
	if not _menu_music_requested:
		music_player.stop()
		music_player.stream = load("res://assets/audio/menu_theme.ogg")
		_music_started = false
	_voyage_music_requested = false
	_menu_music_requested = true
	# Start immediately when autoplay is permitted. Godot resumes the web audio
	# context on user interaction if the browser initially suspends it.
	_begin_menu_music()

func stop_menu_music() -> void:
	_menu_music_requested = false
	_voyage_music_requested = false
	music_player.stop()
	_music_started = false

func start_voyage_music() -> void:
	if _voyage_music_requested:
		return
	stop_menu_music()
	_voyage_tracks.clear()
	for path in VOYAGE_TRACKS:
		# Recordings may be supplied later; never substitute menu music at sea.
		if ResourceLoader.exists(path):
			var track := load(path) as AudioStreamOggVorbis
			if track != null:
				track.loop = false
				_voyage_tracks.append(track)
	if _voyage_tracks.is_empty():
		music_player.stream = null
		return
	_voyage_music_requested = true
	_voyage_index = 0
	music_player.stream = _voyage_tracks[0]
	_begin_menu_music()

func _next_voyage_track() -> void:
	if not _voyage_music_requested or _voyage_tracks.is_empty() or _quitting:
		return
	_voyage_index = (_voyage_index + 1) % _voyage_tracks.size()
	music_player.stream = _voyage_tracks[_voyage_index]
	music_player.play()

func _exit_tree() -> void:
	if is_instance_valid(_save_timer) and not _save_timer.is_stopped():
		save_preferences()
	shutdown_audio()

func shutdown_audio() -> void:
	_voyage_tracks.clear()
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

func _grill_sound(ready: bool) -> AudioStreamWAV:
	# Soft iron tap for placement, a rising two-note bell for a cooked meal.
	var data := PackedByteArray()
	var count := 8820 if ready else 3307
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 744
	for i in count:
		var t := float(i) / 22050.0
		var note_time := t if not ready or t < 0.12 else t - 0.12
		var frequency := (660.0 if t < 0.12 else 990.0) if ready else 185.0
		var envelope := minf(note_time / 0.003, 1.0) * exp(-note_time * 19.0)
		var sample := (sin(TAU * frequency * note_time) + 0.22 * sin(TAU * frequency * 2.76 * note_time)) * envelope * 0.12
		if not ready:
			sample += rng.randf_range(-1, 1) * exp(-t * 110.0) * 0.07
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	return _wav(data)

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func _menu_sound(kind: String) -> AudioStreamWAV:
	# Short wooden attack followed by a soft, watery two-note pluck.
	var duration := 0.065 if kind == "hover" else 0.19
	var data := PackedByteArray()
	var count := int(22050 * duration)
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in count:
		var t := float(i) / 22050.0
		var base := 740.0 if kind == "hover" else (392.0 if kind == "back" else 523.25)
		var frequency := base * (1.0 if t < 0.055 else (0.75 if kind == "back" else 1.5))
		var attack := minf(t / 0.003, 1.0)
		var decay := exp(-t * (54.0 if kind == "hover" else 20.0))
		var wood := rng.randf_range(-1, 1) * exp(-t * 190.0) * 0.07
		var note := (sin(TAU * frequency * t) + 0.22 * sin(TAU * frequency * 2 * t)) * attack * decay
		var sample := note * (0.075 if kind == "hover" else 0.17) + wood
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	return _wav(data)
