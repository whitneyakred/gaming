extends CanvasLayer
## Local-only playtest display. F3 toggles; F4 prints a copyable sample to the log.
var label: Label
var enabled := false
var clock := 0.0
var frame_peak := 0.0
var ping_clock := 0.0
var ping_sent := 0
var rtt_ms := -1
var previous_sent := 0
var previous_received := 0
var upload := 0.0
var download := 0.0
var last_frame_peak := 0.0
var peak_snapshot_gap := 0
var peak_correction := 0.0
const HISTORY_LIMIT := 240 # Two minutes at two samples per second.
var history: Array[Dictionary] = []
var events: Array[Dictionary] = []
const EVENT_LIMIT := 600
var _recording := false
var pending_pings: Dictionary = {}
var snapshot_delay_growth_ms := 0.0
var _minimum_snapshot_offset := INF
var _previous_frame_usec := 0

func accept_ping_reply(stamp: int) -> void:
	if not pending_pings.has(stamp): return
	rtt_ms = maxi(0, Time.get_ticks_msec() - stamp)
	pending_pings.erase(stamp)

func record_event(kind: String, details: Dictionary) -> void:
	if not _recording:
		history.clear()
		events.clear()
		_recording = true
	if kind == "snapshot_received" and details.get("host_time") is float:
		var offset := Time.get_ticks_msec() - float(details.host_time) * 1000.0
		_minimum_snapshot_offset = minf(_minimum_snapshot_offset, offset)
		snapshot_delay_growth_ms = maxf(0.0, offset - _minimum_snapshot_offset)
	events.append({"tick_ms": Time.get_ticks_msec(), "kind": kind, "details": details})
	while events.size() > EVENT_LIMIT: events.pop_front()

func export_history() -> void:
	var payload := JSON.stringify({"schema": 1, "protocol": NetworkSession.PROTOCOL, "samples": history, "events": events}, "\t")
	var filename := "holy-ship-network-%d.json" % Time.get_unix_time_from_system()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(payload.to_utf8_buffer(), filename, "application/json")
	else:
		var file := FileAccess.open("user://" + filename, FileAccess.WRITE)
		if file == null:
			push_warning("Could not save network diagnostics.")
			return
		file.store_string(payload)
		print("Network history saved: ", ProjectSettings.globalize_path("user://" + filename))

func record_sample() -> void:
	var session := NetworkSession
	var queues := {}
	for id: int in session._crew_buffers:
		var buffer: CrewInputBuffer = session._crew_buffers[id]
		queues[str(id)] = {"queued": buffer.frames.size(), "ack": buffer.acknowledged, "rejected": buffer.rejected}
	var peer := multiplayer.multiplayer_peer as HarborPeer
	history.append({"utc": Time.get_unix_time_from_system(), "tick_ms": Time.get_ticks_msec(), "role": "host" if session.local_id == 1 else "guest", "fps": Engine.get_frames_per_second(), "frame_peak_ms": last_frame_peak, "host_frame_ms": session.host_frame_ms, "rtt_ms": rtt_ms, "snapshot_gap_ms": session.snapshot_gap_ms, "snapshot_age_ms": Time.get_ticks_msec() - session.snapshot_received_at if session.snapshot_received_at else 0, "buffer_ms": session._motion_buffer.playback_delay * 1000, "underruns": session._motion_buffer.underruns, "correction_px": session.last_correction, "state_resets": session.transition_resets, "drift_resets": session.distance_resets, "replayed": session.replayed_frames, "replay_ms": session.replay_ms, "access_rejections": session.access_rejections, "up_kib_s": upload, "down_kib_s": download, "queued_bytes": peer.socket.get_current_outbound_buffered_amount() if peer else 0, "coalesced": peer.skipped_packets if peer else 0, "transport": peer.rtc.diagnostics() if peer else {}, "relay_snapshot_window": peer.snapshot_window.diagnostics() if peer else {}, "snapshot_delay_growth_ms": snapshot_delay_growth_ms, "crew_inputs": queues, "layout_version":session.ship.layout_version if is_instance_valid(session.ship) else 0, "world_generation_ms":session.ship.generation_ms if is_instance_valid(session.ship) else 0.0})
	while history.size() > HISTORY_LIMIT: history.pop_front()

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	label = Label.new()
	label.position = Vector2(12, 170)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	label.hide()
	enabled = "--network-diagnostics" in OS.get_cmdline_user_args()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			enabled = not enabled
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F4 and NetworkSession.online:
			print("NETWORK DIAGNOSTICS\n", report())
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F6 and not history.is_empty():
			export_history()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	label.visible = enabled and NetworkSession.online
	var now_usec := Time.get_ticks_usec()
	var frame_ms := float(now_usec - _previous_frame_usec) / 1000.0 if _previous_frame_usec else delta * 1000.0
	_previous_frame_usec = now_usec
	NetworkSession._frame_peak_ms = maxf(NetworkSession._frame_peak_ms, frame_ms)
	frame_peak = maxf(frame_peak, frame_ms)
	clock += delta
	if not NetworkSession.online or not NetworkSession.world_ready:
		_recording = false
		rtt_ms = -1
		ping_sent = 0
		pending_pings.clear()
		_minimum_snapshot_offset = INF
		snapshot_delay_growth_ms = 0.0
		previous_sent = 0
		previous_received = 0
		clock = 0.0
		frame_peak = 0.0
		last_frame_peak = 0.0
		peak_snapshot_gap = 0
		peak_correction = 0.0
		return
	if not _recording:
		history.clear()
		events.clear()
		_recording = true
	peak_snapshot_gap = maxi(peak_snapshot_gap, NetworkSession.snapshot_gap_ms)
	peak_correction = maxf(peak_correction, NetworkSession.last_correction)
	ping_clock += delta
	for stamp: int in pending_pings.keys():
		if Time.get_ticks_msec() - stamp > 30000: pending_pings.erase(stamp)
	if NetworkSession.local_id != 1 and ping_clock >= 2.0:
		ping_clock = 0.0
		ping_sent = Time.get_ticks_msec()
		pending_pings[ping_sent] = true
		NetworkSession.diagnostic_ping.rpc_id(1, ping_sent)
	if clock < 0.5: return
	last_frame_peak = frame_peak
	var peer := multiplayer.multiplayer_peer as HarborPeer
	if peer:
		upload = (peer.bytes_sent - previous_sent) / clock / 1024.0
		download = (peer.bytes_received - previous_received) / clock / 1024.0
		previous_sent = peer.bytes_sent
		previous_received = peer.bytes_received
	label.text = report()
	record_sample()
	clock = 0.0
	frame_peak = 0.0

func report() -> String:
	var session := NetworkSession
	var age := Time.get_ticks_msec() - session.snapshot_received_at if session.snapshot_received_at else 0
	var text := "Network diagnostics — %s — %s\n" % [session.PROTOCOL, "host" if session.local_id == 1 else "guest"]
	text += "FPS %d | frame peak %.1f ms | host frame peak %.1f ms\n" % [Engine.get_frames_per_second(), maxf(frame_peak, last_frame_peak), session.host_frame_ms if session.local_id != 1 else maxf(frame_peak, last_frame_peak)]
	if is_instance_valid(session.ship): text += "World v%d | generation %.1f ms\n" % [session.ship.layout_version,session.ship.generation_ms]
	text += "Host RTT %s | snapshot gap %d / peak %d ms | age %d ms\n" % [str(rtt_ms) + " ms" if rtt_ms >= 0 else "—", session.snapshot_gap_ms, peak_snapshot_gap, age]
	text += "Playback delay %.0f ms | underrun frames %d\n" % [session._motion_buffer.playback_delay * 1000, session._motion_buffer.underruns]
	text += "Correction %.2f / peak %.2f px | state resets %d / drift resets %d | predictions %d\n" % [session.last_correction, peak_correction, session.transition_resets, session.distance_resets, session._prediction.size()]
	text += "Snapshot %d B | build %.2f ms | apply %.2f ms | rejected %d\n" % [session.snapshot_bytes, session.snapshot_build_ms, session.snapshot_apply_ms, session.invalid_packets]
	text += "Replay %d frames / %.2f ms | traversal denied %d\n" % [session.replayed_frames, session.replay_ms, session.access_rejections]
	var peer := multiplayer.multiplayer_peer as HarborPeer
	if peer:
		text += "Up %.1f / down %.1f KiB/s | queued %d B | coalesced/skipped %d\n" % [upload, download, peer.socket.get_current_outbound_buffered_amount(), peer.skipped_packets]
		text += "Snapshot delay growth %.0f ms | relay window skips %d\n" % [snapshot_delay_growth_ms, peer.snapshot_window.skipped]
		text += "Motion transport: %s | direct %.1f / %.1f KiB | fallbacks %d\n" % [str(peer.rtc.reasons) if peer.rtc.enabled else "relay (WebRTC unavailable/disabled)", peer.rtc.direct_sent / 1024.0, peer.rtc.direct_received / 1024.0, peer.rtc.fallbacks]
	if session.services.has(session.local_id):
		var fishing: RodFishing = session.services[session.local_id].get_node("Fishing")
		text += "Fishing local %s | frame %d / host %d | geometry %.2f ms\n" % [fishing.local_reeling, fishing.local_frame, fishing.replay_frame, fishing.geometry_ms]
	for id: int in session._crew_buffers:
		if id == session.local_id: continue
		var buffer: CrewInputBuffer = session._crew_buffers[id]
		if session.local_id == 1: text += "Crew %d: queued inputs %d | ack %d | rejected %d\n" % [id, buffer.frames.size(), buffer.acknowledged, buffer.rejected]
	return text + "F3 hide/show • F4 log sample • F6 export history"
