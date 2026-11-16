@tool
extends EditorExportPlugin
var web := false
func _get_name() -> String: return "HolyShipExport"
func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
	web = "web" in features
	if not web and FileAccess.file_exists("res://.local/eos.cfg"):
		add_file("res://online/eos.cfg", FileAccess.get_file_as_bytes("res://.local/eos.cfg"), false)
func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if web and (path.begins_with("res://addons/epic-online-services-godot/") or path.begins_with("res://scripts/network/eos/")):
		skip()
