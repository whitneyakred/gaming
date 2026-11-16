@tool
extends EditorExportPlugin
func _get_name() -> String: return "HolyShipExport"
func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	# Current releases use the shared browser/desktop harbor, never native EOS.
	if path.begins_with("res://addons/epic-online-services-godot/") or path.begins_with("res://scripts/network/eos/") or path.begins_with("res://online/"):
		skip()
