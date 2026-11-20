class_name HarborPeer
extends MultiplayerPeerExtension
## One outbound TLS WebSocket per player, with server-assigned packet identities.
const HEADER := 12
const MAX_PACKET := 65536
var socket := WebSocketPeer.new()
var state: MultiplayerPeer.ConnectionStatus = MultiplayerPeer.CONNECTION_DISCONNECTED
var own_id := 0
var identities: Dictionary = {}
var incoming: Array[Dictionary] = []
var events: Array[Dictionary] = []
var target := 0
var channel := 0
var mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
var refusing := false
var last_heartbeat := 0
var last_reply := 0
var failure := ""
var started := 0
var packets_sent := 0
var bytes_sent := 0
var bytes_received := 0
var skipped_packets := 0
var latest_snapshot := PackedByteArray()

func connect_url(url: String) -> Error:
	socket.inbound_buffer_size = 1048576
	socket.outbound_buffer_size = 1048576
	socket.max_queued_packets = 512
	var result := socket.connect_to_url(url)
	if result == OK:
		state = MultiplayerPeer.CONNECTION_CONNECTING
		started = Time.get_ticks_msec()
		last_reply = started
	return result

func advance(emit_events: bool = false) -> void:
	socket.poll()
	var now := Time.get_ticks_msec()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			bytes_received += packet.size()
			last_reply = now
			if socket.was_string_packet():
				var data: Variant = JSON.parse_string(packet.get_string_from_utf8())
				if data is Dictionary: control(data)
			elif packet.size() >= HEADER and packet.size() <= MAX_PACKET + HEADER:
				# A dedicated host-only envelope avoids SceneMultiplayer splitting
				# a broadcast RPC into one upload per recipient. Keep only newest.
				if packet[10] == 1:
					if packet.decode_s32(0) == 1 and own_id != 1:
						if not latest_snapshot.is_empty(): skipped_packets += 1
						latest_snapshot = packet.slice(HEADER)
					continue
				incoming.append({"peer": packet.decode_s32(0), "channel": int(packet[8]), "mode": int(packet[9]), "bytes": packet.slice(HEADER)})
				if incoming.size() > 512:
					failure = "Connection fell too far behind. Please rejoin."
					_close()
					break
		if now - last_heartbeat > 10000:
			last_heartbeat = now
			socket.send_text('{"type":"heartbeat"}')
	elif socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if failure.is_empty(): failure = socket.get_close_reason()
		state = MultiplayerPeer.CONNECTION_DISCONNECTED
	if state != MultiplayerPeer.CONNECTION_DISCONNECTED and now - last_reply > 20000:
		failure = "Connection timed out. Please try joining again."
		_close()
	if emit_events:
		var pending := events.duplicate()
		events.clear()
		for event: Dictionary in pending:
			if event.joined: peer_connected.emit(int(event.id))
			else: peer_disconnected.emit(int(event.id))

func control(data: Dictionary) -> void:
	if not valid_control(data):
		failure = "Invalid harbor message. Please rejoin."
		_close()
		return
	match str(data.get("type", "")):
		"welcome":
			own_id = int(data.id)
			identities[own_id] = str(data.identity)
			for other: Dictionary in data.peers:
				identities[int(other.id)] = str(other.identity)
				events.append({"id": int(other.id), "joined": true})
			state = MultiplayerPeer.CONNECTION_CONNECTED
		"peer_joined":
			identities[int(data.id)] = str(data.identity)
			events.append({"id": int(data.id), "joined": true})
		"peer_left":
			identities.erase(int(data.id))
			events.append({"id": int(data.id), "joined": false})

static func valid_id(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= 1 and value <= 2147483647

static func valid_control(data: Dictionary) -> bool:
	if not data.get("type") is String: return false
	match data.type:
		"welcome":
			if not valid_id(data.get("id")) or not data.get("identity") is String or not data.get("peers") is Array or data.peers.size() > 4: return false
			for peer: Variant in data.peers:
				if not peer is Dictionary or not valid_id(peer.get("id")) or not peer.get("identity") is String: return false
		"peer_joined":
			return valid_id(data.get("id")) and data.get("identity") is String
		"peer_left":
			return valid_id(data.get("id"))
	return true

func get_peer_user_id(id: int) -> String: return str(identities.get(id, ""))
func _get_unique_id() -> int: return own_id
func _get_connection_status() -> MultiplayerPeer.ConnectionStatus: return state
func _is_server() -> bool: return own_id == 1
func _is_server_relay_supported() -> bool: return false
func _get_max_packet_size() -> int: return MAX_PACKET
func _get_available_packet_count() -> int: return incoming.size()
func _get_packet_peer() -> int: return int(incoming[0].peer) if not incoming.is_empty() else 0
func _get_packet_channel() -> int: return int(incoming[0].channel) if not incoming.is_empty() else 0
func _get_packet_mode() -> MultiplayerPeer.TransferMode: return int(incoming[0].mode) as MultiplayerPeer.TransferMode if not incoming.is_empty() else MultiplayerPeer.TRANSFER_MODE_RELIABLE
func _get_packet_script() -> PackedByteArray:
	return incoming.pop_front().bytes if not incoming.is_empty() else PackedByteArray()
func _set_target_peer(id: int) -> void: target = id
func _get_transfer_channel() -> int: return channel
func _set_transfer_channel(value: int) -> void: channel = value
func _get_transfer_mode() -> MultiplayerPeer.TransferMode: return mode
func _set_transfer_mode(value: MultiplayerPeer.TransferMode) -> void: mode = value
func _is_refusing_new_connections() -> bool: return refusing
func _set_refuse_new_connections(value: bool) -> void: refusing = value
func _poll() -> void: advance(true)
func _put_packet_script(bytes: PackedByteArray) -> Error:
	return _send_packet(bytes, target, channel, mode)

func send_world_snapshot(bytes: PackedByteArray) -> Error:
	if own_id != 1: return ERR_UNAUTHORIZED
	return _send_packet(bytes, 0, 2, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 1)

func take_world_snapshot() -> PackedByteArray:
	var result := latest_snapshot
	latest_snapshot = PackedByteArray()
	return result

func _send_packet(bytes: PackedByteArray, recipient: int, packet_channel: int, packet_mode: MultiplayerPeer.TransferMode, kind: int = 0) -> Error:
	if state != MultiplayerPeer.CONNECTION_CONNECTED: return ERR_UNCONFIGURED
	if bytes.size() > MAX_PACKET: return ERR_OUT_OF_MEMORY
	var queued := socket.get_current_outbound_buffered_amount()
	# Never queue stale movement/snapshots behind a slow link.
	if packet_mode != MultiplayerPeer.TRANSFER_MODE_RELIABLE and queued > 16384:
		skipped_packets += 1
		return OK
	if queued > 524288:
		failure = "Connection is too slow. Please rejoin."
		_close()
		return ERR_CONNECTION_ERROR
	var packet := PackedByteArray()
	packet.resize(HEADER)
	packet.encode_s32(0, own_id)
	packet.encode_s32(4, recipient)
	packet[8] = packet_channel
	packet[9] = packet_mode
	packet[10] = kind
	packet.append_array(bytes)
	var result := socket.put_packet(packet)
	if result == OK:
		packets_sent += 1
		bytes_sent += packet.size()
	return result
func _disconnect_peer(id: int, _force: bool) -> void:
	if own_id == 1: socket.send_text(JSON.stringify({"type": "kick", "id": id}))
	elif id == 1: _close()
func _close() -> void:
	state = MultiplayerPeer.CONNECTION_DISCONNECTED
	incoming.clear()
	latest_snapshot = PackedByteArray()
	events.clear()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text('{"type":"leave"}')
		socket.close(1000, "Left voyage")
		socket.poll()
