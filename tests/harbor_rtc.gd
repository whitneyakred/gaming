extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	for invalid: Variant in [null, [], "hello", {}, {"type": 2}, {"type": "offer", "sdp": 12}, {"type": "ice", "media": "0", "index": INF, "candidate": "x"}, {"type": "ice", "media": "0", "index": 0.5, "candidate": "x"}, {"type": "offer", "sdp": "x".repeat(12001)}]:
		check(not HarborRTC.valid_signal(invalid), "Malformed signaling must be ignored")
	check(HarborRTC.valid_signal({"type": "hello"}), "Capability message accepted")
	check(HarborRTC.valid_signal({"type": "ice", "media": "0", "index": 0, "candidate": "candidate"}), "Typed ICE message accepted")
	var host := HarborPeer.new()
	var guest := HarborPeer.new()
	host.own_id = 1
	guest.own_id = 2
	guest.identities = {1: "host", 2: "guest"}
	var first := host._envelope(PackedByteArray([10]), 0, 2, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 1)
	var second := host._envelope(PackedByteArray([20]), 0, 2, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 1)
	guest._receive_direct(1, second)
	guest._receive_packet(first)
	check(guest.take_world_snapshot() == PackedByteArray([20]), "Older relay snapshot cannot overwrite newer direct snapshot")
	guest._receive_packet(second)
	check(guest.take_world_snapshot().is_empty(), "Duplicate snapshot discarded across transports")
	var forged := second.duplicate()
	forged.encode_s32(0, 3)
	guest._receive_direct(1, forged)
	check(guest.take_world_snapshot().is_empty(), "Direct sender cannot forge another identity")
	guest._receive_direct(3, second)
	check(guest.take_world_snapshot().is_empty(), "Non-member direct sender ignored")
	var reliable := host._envelope(PackedByteArray([30]), 2, 0, MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)
	guest._receive_direct(1, reliable)
	check(guest.incoming.is_empty(), "Direct lane cannot inject reliable RPCs")
	guest._receive_packet(reliable)
	check(guest._get_packet_script() == PackedByteArray([30]), "Reliable relay delivery preserved")
	check(not guest.rtc.send(1, second), "No negotiated channel uses relay fallback")
	check(not guest.rtc.enabled, "Native build retains relay without new plugin")
	guest.control({"type": "peer_left", "id": 1})
	check(not guest.received_serials.has(1), "Departure clears ordering history")
	host.close()
	guest.close()
	print("HARBOR RTC: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
