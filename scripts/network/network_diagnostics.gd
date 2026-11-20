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

func _process(delta: float) -> void:
	label.visible = enabled and NetworkSession.online
	NetworkSession._frame_peak_ms = maxf(NetworkSession._frame_peak_ms, delta * 1000.0)
	frame_peak = maxf(frame_peak, delta * 1000.0)
	clock += delta
	if not NetworkSession.online or not NetworkSession.world_ready:
		rtt_ms = -1
		ping_sent = 0
		previous_sent = 0
		previous_received = 0
		clock = 0.0
		frame_peak = 0.0
		last_frame_peak = 0.0
		peak_snapshot_gap = 0
		peak_correction = 0.0
		return
	peak_snapshot_gap = maxi(peak_snapshot_gap, NetworkSession.snapshot_gap_ms)
	peak_correction = maxf(peak_correction, NetworkSession.last_correction)
	ping_clock += delta
	if enabled and NetworkSession.local_id != 1 and ping_clock >= 2.0:
		ping_clock = 0.0
		ping_sent = Time.get_ticks_msec()
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
	clock = 0.0
	frame_peak = 0.0

func report() -> String:
	var session := NetworkSession
	var age := Time.get_ticks_msec() - session.snapshot_received_at if session.snapshot_received_at else 0
	var text := "Network diagnostics — %s — %s\n" % [session.PROTOCOL, "host" if session.local_id == 1 else "guest"]
	text += "FPS %d | frame peak %.1f ms | host frame peak %.1f ms\n" % [Engine.get_frames_per_second(), maxf(frame_peak, last_frame_peak), session.host_frame_ms if session.local_id != 1 else maxf(frame_peak, last_frame_peak)]
	text += "Host RTT %s | snapshot gap %d / peak %d ms | age %d ms\n" % [str(rtt_ms) + " ms" if rtt_ms >= 0 else "—", session.snapshot_gap_ms, peak_snapshot_gap, age]
	text += "Playback delay %.0f ms | underrun frames %d\n" % [session._motion_buffer.playback_delay * 1000, session._motion_buffer.underruns]
	text += "Correction %.2f / peak %.2f px | state resets %d / drift resets %d | predictions %d\n" % [session.last_correction, peak_correction, session.transition_resets, session.distance_resets, session._prediction.size()]
	text += "Snapshot %d B | build %.2f ms | apply %.2f ms | rejected %d\n" % [session.snapshot_bytes, session.snapshot_build_ms, session.snapshot_apply_ms, session.invalid_packets]
	var peer := multiplayer.multiplayer_peer as HarborPeer
	if peer:
		text += "Up %.1f / down %.1f KiB/s | queued %d B | coalesced/skipped %d\n" % [upload, download, peer.socket.get_current_outbound_buffered_amount(), peer.skipped_packets]
	if session.services.has(session.local_id):
		var fishing: RodFishing = session.services[session.local_id].get_node("Fishing")
		text += "Fishing local %s | frame %d / host %d | geometry %.2f ms\n" % [fishing.local_reeling, fishing.local_frame, fishing.replay_frame, fishing.geometry_ms]
	for id: int in session._crew_buffers:
		if id == session.local_id: continue
		var buffer: CrewInputBuffer = session._crew_buffers[id]
		if session.local_id == 1: text += "Crew %d: queued inputs %d | ack %d | rejected %d\n" % [id, buffer.frames.size(), buffer.acknowledged, buffer.rejected]
	return text + "F3 hide/show • F4 write sample to local log"
