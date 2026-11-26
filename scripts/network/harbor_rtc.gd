class_name HarborRTC
extends RefCounted
## Optional browser-only fast lane. The authenticated relay owns membership.
## No TURN, credentials, native plugin, or paid service is used.
signal signal_out(peer_id: int, message: Dictionary)
signal packet_in(peer_id: int, packet: PackedByteArray)
const STUN := "stun:stun.cloudflare.com:3478"
const CONNECT_TIMEOUT := 12000
const SILENCE_TIMEOUT := 2000
const MAX_DIRECT_PACKET := 16000
var enabled := OS.has_feature("web") and bool(ProjectSettings.get_setting("network/webrtc_enabled", true)) and bool(JavaScriptBridge.eval("typeof RTCPeerConnection !== 'undefined'"))
var own_id := 0
var links: Dictionary = {}
var reasons: Dictionary = {}
var direct_sent := 0
var direct_received := 0
var fallbacks := 0

func join(id: int) -> void:
	if not enabled or id == own_id or (own_id != 1 and id != 1) or links.has(id): return
	# Allocate only after the other endpoint advertises support. Native clients
	# remain on the relay without ever instantiating a missing native extension.
	reasons[id] = "waiting for capability"
	signal_out.emit(id, {"type": "hello"})

static func valid_signal(data: Variant) -> bool:
	if not data is Dictionary or not data.get("type") is String: return false
	match data.type:
		"hello", "stop": return data.size() == 1
		"offer", "answer": return data.get("sdp") is String and data.sdp.length() > 0 and data.sdp.length() <= 12000
		"ice":
			return data.get("media") is String and data.media.length() <= 256 and (data.get("index") is int or data.get("index") is float) and is_finite(float(data.index)) and data.index == floor(data.index) and data.index >= 0 and data.index <= 16 and data.get("candidate") is String and data.candidate.length() <= 2048
	return false

func receive_signal(id: int, data: Variant) -> void:
	if not enabled or not reasons.has(id) or not valid_signal(data): return
	if data.type == "stop":
		stop(id, "remote fallback", false)
		return
	if data.type == "hello":
		if links.has(id) or reasons[id] != "waiting for capability": return
		var connection := WebRTCPeerConnection.new()
		if connection.initialize({"iceServers": [{"urls": [STUN]}]}) != OK:
			stop(id, "initialization failed")
			return
		var fast := connection.create_data_channel("holy-ship-motion", {"negotiated": true, "id": 1, "ordered": false, "maxRetransmits": 0})
		if fast == null:
			connection.close()
			stop(id, "channel unavailable")
			return
		var now := Time.get_ticks_msec()
		links[id] = {"connection": connection, "channel": fast, "started": now, "last_seen": now, "last_ping": 0, "confirmed": false, "remote": false, "signals": 0, "candidates": []}
		reasons[id] = "connecting"
		connection.session_description_created.connect(_description.bind(id))
		connection.ice_candidate_created.connect(_candidate.bind(id))
		if own_id == 1 and connection.create_offer() != OK: stop(id, "offer failed")
		return
	if not links.has(id): return
	var link: Dictionary = links[id]
	link.signals += 1
	if link.signals > 128:
		stop(id, "signaling limit")
		return
	var connection: WebRTCPeerConnection = link.connection
	if data.type == "ice":
		if not link.remote:
			link.candidates.append(data)
		elif connection.add_ice_candidate(data.media, int(data.index), data.candidate) != OK:
			stop(id, "candidate rejected")
	elif (data.type == "offer" and own_id != 1) or (data.type == "answer" and own_id == 1):
		if link.remote: return
		if connection.set_remote_description(data.type, data.sdp) != OK:
			stop(id, "description rejected")
			return
		link.remote = true
		for candidate: Dictionary in link.candidates:
			connection.add_ice_candidate(candidate.media, int(candidate.index), candidate.candidate)
		link.candidates.clear()

func _description(type: String, sdp: String, id: int) -> void:
	if not links.has(id): return
	var connection: WebRTCPeerConnection = links[id].connection
	if sdp.length() > 12000 or connection.set_local_description(type, sdp) != OK:
		stop(id, "local description failed")
		return
	signal_out.emit(id, {"type": type, "sdp": sdp})

func _candidate(media: String, index: int, candidate: String, id: int) -> void:
	if links.has(id): signal_out.emit(id, {"type": "ice", "media": media, "index": index, "candidate": candidate})

func poll() -> void:
	var now := Time.get_ticks_msec()
	for id: int in links.keys():
		var link: Dictionary = links[id]
		var connection: WebRTCPeerConnection = link.connection
		connection.poll()
		if not links.has(id): continue
		var fast: WebRTCDataChannel = link.channel
		if connection.get_connection_state() in [WebRTCPeerConnection.STATE_FAILED, WebRTCPeerConnection.STATE_CLOSED, WebRTCPeerConnection.STATE_DISCONNECTED]:
			stop(id, "connection lost")
			continue
		if fast.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			# A ping/pong proves bidirectional delivery, not just an open channel.
			if now - int(link.last_ping) >= 500:
				fast.put_packet(PackedByteArray([0]))
				link.last_ping = now
			var budget := 128
			while fast.get_available_packet_count() > 0 and budget > 0:
				budget -= 1
				var packet := fast.get_packet()
				if packet.size() == 1:
					if packet[0] == 0: fast.put_packet(PackedByteArray([1]))
					elif packet[0] == 1:
						link.last_seen = now
						link.confirmed = true
						reasons[id] = "direct"
				elif packet.size() >= 16 and packet.size() <= MAX_DIRECT_PACKET:
					direct_received += packet.size()
					packet_in.emit(id, packet)
		if link.confirmed and now - int(link.last_seen) > SILENCE_TIMEOUT:
			stop(id, "direct path timed out")
		elif not link.confirmed and now - int(link.started) > CONNECT_TIMEOUT:
			stop(id, "direct connection unavailable")

func send(id: int, packet: PackedByteArray) -> bool:
	if not links.has(id) or not links[id].confirmed or packet.size() > MAX_DIRECT_PACKET: return false
	var fast: WebRTCDataChannel = links[id].channel
	if fast.get_ready_state() != WebRTCDataChannel.STATE_OPEN or fast.get_buffered_amount() > 16384: return false
	if fast.put_packet(packet) != OK:
		stop(id, "send failed")
		return false
	direct_sent += packet.size()
	return true

func stop(id: int, reason: String, notify_remote := true) -> void:
	if links.has(id):
		var connection: WebRTCPeerConnection = links[id].connection
		connection.close()
		links.erase(id)
		fallbacks += 1
	reasons[id] = reason
	if notify_remote: signal_out.emit(id, {"type": "stop"})

func leave(id: int) -> void:
	stop(id, "left", false)
	reasons.erase(id)

func close() -> void:
	for id: int in links.keys(): leave(id)
	reasons.clear()

func diagnostics() -> Dictionary:
	return {"enabled": enabled, "peers": reasons.duplicate(), "direct_sent_bytes": direct_sent, "direct_received_bytes": direct_received, "fallbacks": fallbacks}
