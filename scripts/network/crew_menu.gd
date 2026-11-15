class_name CrewMenu
extends Control
var name_field: LineEdit
var address: LineEdit
var port_field: SpinBox
var secret: LineEdit
var resume_box: CheckBox
var message: Label
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.08, 0.94)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 560)
	card.add_theme_stylebox_override("panel", HarborTheme.panel())
	center.add_child(card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	card.add_child(rows)
	rows.add_child(HarborTheme.label("ASSEMBLE YOUR CREW", 26))
	rows.add_child(HarborTheme.label("Up to 4 sailors • Desktop co-op testing", 16))
	name_field = field(rows, "Your name", "Sailor")
	address = field(rows, "Host / tunnel address (without port)", "127.0.0.1")
	var port_row := HBoxContainer.new()
	rows.add_child(port_row)
	port_row.add_child(HarborTheme.label("UDP port  ", 16))
	port_field = SpinBox.new()
	port_field.min_value = 1024
	port_field.max_value = 65535
	port_field.value = NetworkSession.DEFAULT_PORT
	port_row.add_child(port_field)
	secret = field(rows, "Session password (optional)", "")
	secret.secret = true
	secret.max_length = 64
	resume_box = CheckBox.new()
	resume_box.text = "Host: continue saved voyage (uncheck for a new world)"
	resume_box.button_pressed = true
	rows.add_child(resume_box)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	rows.add_child(buttons)
	buttons.add_child(HarborTheme.button("Host & Play", func() -> void:
		NetworkSession.host_session(name_field.text, int(port_field.value), secret.text, resume_box.button_pressed)))
	buttons.add_child(HarborTheme.button("Join crew", func() -> void:
		NetworkSession.join_session(address.text, int(port_field.value), name_field.text, secret.text)))
	message = HarborTheme.label("Host PC must stay running. Internet play needs a reachable UDP port or tunnel.", 15)
	message.custom_minimum_size = Vector2(560, 50)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(message)
	rows.add_child(HarborTheme.button("Back / Cancel", func() -> void:
		if NetworkSession.online and not NetworkSession.world_ready:
			NetworkSession.leave("Connection cancelled.")
		hide()))
	NetworkSession.status_changed.connect(func(text: String) -> void: message.text = text)
	hide()

func field(rows: VBoxContainer, caption: String, initial: String) -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = caption
	line.text = initial
	line.tooltip_text = caption
	line.custom_minimum_size.y = 38
	line.max_length = 128
	rows.add_child(line)
	return line

func open() -> void:
	show()
	name_field.grab_focus()
	if OS.has_feature("web"):
		message.text = "Co-op requires the downloadable desktop build. Solo play still works in your browser."
	elif not NetworkSession.status.is_empty():
		message.text = NetworkSession.status
