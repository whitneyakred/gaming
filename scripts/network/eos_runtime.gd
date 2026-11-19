extends Node
## Web-safe facade; native EOS code is loaded only on supported desktop builds.
signal changed
var local_product_user_id: String = ""
var local_epic_account_id: String = ""
var backend: Node
var busy: bool = false
var crews: Dictionary = {}
var status: String = ""

func ensure_backend() -> bool:
	if backend != null: return true
	if OS.has_feature("web"):
		set_status("Online crews require the desktop build with EOS installed.")
		return false
	if not ClassDB.class_exists("EOSGMultiplayerPeer"):
		if OS.has_feature("editor"):
			set_status("EOS extension is not loaded. Install the project’s native EOS files, restart Godot, and check the Output panel for loading errors.")
		else:
			set_status("The networking library could not load. Extract the complete game package, then try again.")
		return false
	var script = load("res://scripts/network/eos/online_backend.gd")
	if script == null: return false
	backend = script.new()
	add_child(backend)
	return true

func set_status(value: String) -> void:
	status = value
	NetworkSession.set_status(value)
	changed.emit()

func browse() -> void:
	if busy or NetworkSession.online: return
	if not ensure_backend(): return
	busy = true
	await backend.browse()
	busy = false
	changed.emit()

func host(title: String, secret: String, resume_world: bool) -> void:
	if busy or NetworkSession.online: return
	if not ensure_backend(): return
	busy = true
	await backend.host(title, secret, resume_world)
	busy = false
	changed.emit()

func join_crew(id: String, secret: String = "") -> void:
	if busy or NetworkSession.online: return
	if not ensure_backend(): return
	busy = true
	await backend.join_crew(id, secret)
	busy = false
	changed.emit()

func leave_lobby() -> void:
	# A window-close request may arrive while sign-in or lobby creation is pending.
	# Finish that operation before destroying its lobby or releasing native handles.
	while busy: await get_tree().process_frame
	if backend != null: await backend.leave_lobby()

func shutdown() -> void:
	if backend != null: backend.shutdown()

func _exit_tree() -> void:
	shutdown()
