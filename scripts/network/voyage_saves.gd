extends Node
## Three host-owned local snapshots. Browser writes are synchronous localStorage.
signal changed
const COUNT := 3
const PREFIX := "holyShip.voyage.v1."
var selected: int = 0
var last_error: String = ""

func _ready() -> void:
	if OS.has_feature("web") or "--settings-test" in OS.get_cmdline_user_args(): return
	var old_path := "user://hosted-voyage.save"
	if read_slot(0).is_empty() and FileAccess.file_exists(old_path):
		var old := FileAccess.open(old_path, FileAccess.READ)
		var data: Variant = old.get_var(false)
		old.close()
		if data is Dictionary and store(data):
			DirAccess.rename_absolute(old_path, old_path + ".migrated")

func path(slot: int) -> String:
	var base := "res://.godot/test-save-slot-" if "--settings-test" in OS.get_cmdline_user_args() else "user://voyage-slot-"
	return base + str(slot) + ".save"

func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= COUNT: return {}
	var text := ""
	if OS.has_feature("web"):
		var result: Variant = JavaScriptBridge.eval("(() => {try {return localStorage.getItem(" + JSON.stringify(PREFIX + str(slot)) + ") || '';} catch(e) {return '';}})()")
		if result is String: text = result
	elif FileAccess.file_exists(path(slot)):
		text = FileAccess.get_file_as_string(path(slot))
	if text.is_empty() or text.length() > 4000000: return {}
	var value: Variant = JSON.parse_string(text)
	return value if value is Dictionary and value.get("format") == 1 else {}

func world(slot: int) -> Dictionary:
	var entry := read_slot(slot)
	if entry.is_empty(): return {}
	var bytes := Marshalls.base64_to_raw(str(entry.get("payload", "")))
	var value: Variant = bytes_to_var(bytes) if not bytes.is_empty() else null
	return value if value is Dictionary else {}

func store(data: Dictionary) -> bool:
	last_error = ""
	var entry := {"format": 1, "title": data.get("title", "The Wandering Ship"), "saved_at": Time.get_unix_time_from_system(), "payload": Marshalls.raw_to_base64(var_to_bytes(data))}
	var text := JSON.stringify(entry)
	if text.length() > 4000000:
		last_error = "This voyage is too large to save locally."
		return false
	if OS.has_feature("web"):
		var result: Variant = JavaScriptBridge.eval("(() => {try {localStorage.setItem(" + JSON.stringify(PREFIX + str(selected)) + "," + JSON.stringify(text) + ");return true;} catch(e) {return false;}})()")
		if result != true: last_error = "Browser storage is unavailable or full. This voyage could not be saved."
	else:
		var file := FileAccess.open(path(selected) + ".tmp", FileAccess.WRITE)
		if file == null:
			last_error = "Could not write the local voyage save."
		else:
			file.store_string(text)
			file.close()
			if DirAccess.rename_absolute(path(selected) + ".tmp", path(selected)) != OK:
				last_error = "Could not replace the local voyage save."
	changed.emit()
	return last_error.is_empty()

func clear_slot(slot: int) -> bool:
	if slot < 0 or slot >= COUNT or NetworkSession.online: return false
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("(() => {try {localStorage.removeItem(" + JSON.stringify(PREFIX + str(slot)) + ");return true;} catch(e) {return false;}})()") != true:
			return false
	elif FileAccess.file_exists(path(slot)) and DirAccess.remove_absolute(path(slot)) != OK:
		return false
	changed.emit()
	return true

func timestamp(entry: Dictionary) -> String:
	var value := int(entry.get("saved_at", 0))
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("new Date(" + str(value * 1000) + ").toLocaleString()"))
	var local_seconds := value + int(Time.get_time_zone_from_system().bias) * 60
	return Time.get_datetime_string_from_unix_time(local_seconds).replace("T", "  ")
