extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	NetworkSession._input_clock = 0.1
	NetworkSession._last_local_move = Vector2.RIGHT
	NetworkSession._last_local_held = false
	NetworkSession._last_local_blocked = false
	check(not NetworkSession.input_needs_send(Vector2.RIGHT, false, false), "Unchanged input does not spend another relay request")
	check(NetworkSession.input_needs_send(Vector2.ZERO, false, false), "Releasing movement sends immediately")
	check(NetworkSession.input_needs_send(Vector2.RIGHT, true, false), "Mouse changes send immediately even with unchanged movement")
	check(NetworkSession.input_needs_send(Vector2.RIGHT, false, true), "Focus loss/pause sends immediately")
	NetworkSession._last_local_held = true
	check(NetworkSession.input_needs_send(Vector2.RIGHT, false, false), "Releasing fishing input sends immediately")
	NetworkSession._input_clock = 0.51
	check(NetworkSession.input_needs_send(Vector2.RIGHT, true, false), "Held input periodically refreshes the host watchdog")
	var transport := HarborPeer.new()
	check(transport.send_world_snapshot(PackedByteArray([1])) == ERR_UNAUTHORIZED, "Guests cannot originate snapshots")
	transport.latest_snapshot = PackedByteArray([1, 2, 3])
	check(transport.take_world_snapshot() == PackedByteArray([1, 2, 3]) and transport.take_world_snapshot().is_empty(), "Latest snapshot is consumed once")
	print("CLASSROOM POLICY: 8 checks, ", failures, " failures")
	get_tree().quit(failures)
