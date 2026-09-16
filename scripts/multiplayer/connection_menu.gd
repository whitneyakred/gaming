extends CanvasLayer
## Small UI adapter: the session owns all networking and gameplay state.
@onready var session: Node = get_parent()
@onready var address: LineEdit = $Panel/Rows/Address

func _ready() -> void:
	$Panel/Rows/Host.disabled = OS.has_feature("web")
	$Panel/Rows/Host.pressed.connect(session.host_game)
	$Panel/Rows/Join.pressed.connect(_join)
	$Panel/Rows/Offline.pressed.connect(session.start_offline)

func _join() -> void:
	var host := address.text.strip_edges()
	if host.is_empty() or "/" in host or " " in host:
		session.status.text = "Enter the host's local IP address, such as 192.168.1.20."
		return
	# Brackets allow IPv6 addresses as well as the usual local IPv4 address.
	if ":" in host and not host.begins_with("["):
		host = "[" + host + "]"
	session.join_game("ws://%s:%d" % [host, session.port])
