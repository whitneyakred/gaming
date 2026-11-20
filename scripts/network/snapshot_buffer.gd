class_name SnapshotBuffer
extends RefCounted
## Presentation only. Never extrapolate collisions or gameplay beyond the host.
const DELAY := 0.15
const LIMIT := 12
var frames: Array[Dictionary] = []
var cursor := 0.0
var underruns := 0
var playback_delay := DELAY
var _arrival := 0.0
var _host_time := 0.0
func clear() -> void:
	frames.clear()
	cursor = 0.0
	underruns = 0
	playback_delay = DELAY
	_arrival = 0.0
	_host_time = 0.0
func push(state: Dictionary, arrival: float = -1.0) -> void:
	var time := float(state.get("time", float(state.serial) * 0.1))
	if not frames.is_empty() and int(state.serial) <= int(frames.back().state.serial): return
	if not frames.is_empty() and (Vector2(state.position).distance_to(frames.back().state.position) > 500.0 or time - float(frames.back().time) > 0.5):
		clear()
	if arrival < 0.0: arrival = Time.get_ticks_msec() / 1000.0
	if _arrival > 0.0 and arrival > _arrival:
		var excess := maxf(0.0, (arrival - _arrival) - (time - _host_time))
		# Grow quickly for jitter, shrink slowly; never hide unlimited latency.
		playback_delay = clampf(maxf(DELAY + excess, playback_delay - 0.002), DELAY, 0.3)
	_arrival = arrival
	_host_time = time
	if frames.is_empty(): cursor = time - playback_delay
	frames.append({"time": time, "state": state})
	while frames.size() > LIMIT: frames.pop_front()
func sample(delta: float) -> Dictionary:
	if frames.is_empty(): return {}
	var latest := float(frames.back().time)
	# Gentle clock adjustment absorbs drift without jumping at every packet.
	var lag := latest - cursor
	cursor += delta * clampf(1.0 + (lag - playback_delay) * 0.5, 0.9, 1.1)
	if cursor > latest:
		cursor = latest
		underruns += 1
	while frames.size() > 2 and float(frames[1].time) <= cursor: frames.pop_front()
	var a: Dictionary = frames[0]
	var b: Dictionary = frames[1] if frames.size() > 1 else a
	var fraction := clampf((cursor - float(a.time)) / maxf(float(b.time) - float(a.time), 0.0001), 0.0, 1.0)
	var result: Dictionary = b.state.duplicate()
	result.position = Vector2(a.state.position).lerp(b.state.position, fraction)
	result.rotation = lerp_angle(a.state.rotation, b.state.rotation, fraction)
	result.trim = rad_to_deg(lerp_angle(deg_to_rad(a.state.trim), deg_to_rad(b.state.trim), fraction))
	result.wheel = lerpf(a.state.wheel, b.state.wheel, fraction)
	result.crew = {}
	for id in b.state.crew:
		var newer: Dictionary = b.state.crew[id]
		var older: Dictionary = a.state.crew.get(id, newer)
		var entry := newer.duplicate()
		# Boarding, respawns and ownership changes must not blend coordinate spaces.
		if older.get("outside") == newer.get("outside") and older.get("station") == newer.get("station") and older.get("respawn") == newer.get("respawn") and Vector2(older.position).distance_to(newer.position) < 150.0:
			entry.position = Vector2(older.position).lerp(newer.position, fraction)
		result.crew[id] = entry
	return result
