class_name RelaySnapshotWindow
extends RefCounted
## Receipt-based flow control, independent for each guest. Never queue history.
const LIMIT := 2
var pending: Dictionary = {}
var skipped := 0
func available(id: int) -> bool:
	return pending.get(id, []).size() < LIMIT
func sent(id: int, serial: int) -> void:
	if not pending.has(id): pending[id] = []
	pending[id].append(serial)
func acknowledge(id: int, serial: Variant) -> void:
	if not (serial is int or serial is float): return
	if not is_finite(float(serial)) or serial != floor(float(serial)): return
	# Only an actually outstanding receipt can free this guest's window.
	if not pending.has(id) or not pending[id].has(int(serial)): return
	while not pending[id].is_empty() and int(pending[id][0]) <= int(serial): pending[id].pop_front()
func remove(id: int) -> void:
	pending.erase(id)
func diagnostics() -> Dictionary:
	var counts := {}
	for id: int in pending: counts[str(id)] = pending[id].size()
	return {"pending": counts, "skipped": skipped}
