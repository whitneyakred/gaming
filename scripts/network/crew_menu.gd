class_name CrewMenu
extends Control
var secret: LineEdit
var crew_name: LineEdit
var address: LineEdit
var port_field: SpinBox
var resume_box: CheckBox
var message: Label
var list: VBoxContainer
var tabs: TabContainer

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
	card.custom_minimum_size = Vector2(820, 610)
	card.add_theme_stylebox_override("panel", HarborTheme.panel())
	center.add_child(card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	card.add_child(rows)
	rows.add_child(HarborTheme.label("FIND YOUR CREW", 28))
	rows.add_child(HarborTheme.label("An open sea. A shared ship. Up to four sailors.", 17))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(tabs)
	var host := page("Host a crew")
	host.add_child(HarborTheme.label("Give your voyage a name", 18))
	crew_name = field(host, "Crew name", "The Wandering Ship")
	crew_name.max_length = 32
	host.add_child(HarborTheme.label("Crew password · optional", 16))
	secret = field(host, "Anyone nearby can join when left empty", "")
	secret.secret = true
	secret.max_length = 64
	resume_box = CheckBox.new()
	resume_box.text = "Continue my saved voyage"
	resume_box.button_pressed = true
	host.add_child(resume_box)
	host.add_child(HarborTheme.label("Visible to nearby players on your network.\nKeep the game open while your crew is sailing.", 16))
	host.add_child(HarborTheme.button("Launch crew", func() -> void:
		NetworkSession.crew_title = crew_name.text.strip_edges().left(32)
		if NetworkSession.crew_title.is_empty(): NetworkSession.crew_title = "The Wandering Ship"
		NetworkSession.host_session(NetworkSession.local_name, NetworkSession.DEFAULT_PORT, secret.text, resume_box.button_pressed)))
	var browse := page("Browse crews")
	browse.add_child(HarborTheme.label("NEARBY CREWS", 18))
	browse.add_child(HarborTheme.label("Same network · Internet crew discovery is not connected yet", 15))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 225
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browse.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	browse.add_child(HarborTheme.button("Refresh crews", func() -> void: NetworkSession.discovery.browse()))
	var direct := page("Direct connect")
	direct.add_child(HarborTheme.label("For invited internet playtests and custom servers", 17))
	address = field(direct, "Host or tunnel address", "")
	port_field = SpinBox.new()
	port_field.min_value = 1024
	port_field.max_value = 65535
	port_field.value = NetworkSession.DEFAULT_PORT
	direct.add_child(HarborTheme.label("Port supplied by the host", 16))
	direct.add_child(port_field)
	var direct_secret := field(direct, "Password, if the crew has one", "")
	direct_secret.secret = true
	direct.add_child(HarborTheme.button("Join crew", func() -> void:
		if address.text.strip_edges().is_empty():
			message.text = "Enter the address supplied by your host."
			return
		NetworkSession.join_session(address.text, int(port_field.value), NetworkSession.local_name, direct_secret.text)))
	message = HarborTheme.label("", 15)
	message.custom_minimum_size = Vector2(700, 42)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(message)
	rows.add_child(HarborTheme.button("Back to harbor", close))
	NetworkSession.status_changed.connect(func(text: String) -> void: message.text = text)
	NetworkSession.discovery.changed.connect(refresh_list)
	tabs.tab_changed.connect(func(_index: int) -> void: NetworkSession.discovery.browse())
	hide()

func page(caption: String) -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.name = caption
	rows.add_theme_constant_override("separation", 12)
	tabs.add_child(rows)
	return rows

func field(rows: VBoxContainer, caption: String, initial: String) -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = caption
	line.text = initial
	line.tooltip_text = caption
	line.custom_minimum_size.y = 42
	line.max_length = 128
	rows.add_child(line)
	return line

func refresh_list() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if NetworkSession.discovery.crews.is_empty():
		list.add_child(HarborTheme.label("No nearby crews yet.\nAsk a friend on this network to launch a crew.", 18))
	for entry in NetworkSession.discovery.crews.values():
		var data: Dictionary = entry.duplicate()
		var caption := "%s   ·   %d / 4 sailors%s" % [str(data.title).left(32), int(data.count), "   ·   Password" if data.get("locked", false) else ""]
		var button := HarborTheme.button(caption, func() -> void: join_listing(data))
		list.add_child(button)
		button.disabled = int(data.count) >= NetworkSession.MAX_CREW
		button.add_theme_font_size_override("font_size", 18)

func join_listing(data: Dictionary) -> void:
	if data.get("locked", false):
		var dialog := ConfirmationDialog.new()
		dialog.title = "Join " + str(data.title).left(32)
		dialog.ok_button_text = "Join crew"
		var input := LineEdit.new()
		input.secret = true
		input.placeholder_text = "Crew password"
		input.max_length = 64
		dialog.add_child(input)
		add_child(dialog)
		dialog.confirmed.connect(func() -> void:
			NetworkSession.join_session(data.address, int(data.port), NetworkSession.local_name, input.text)
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(400, 140))
		input.grab_focus()
	else:
		NetworkSession.join_session(data.address, int(data.port), NetworkSession.local_name)

func open() -> void:
	show()
	NetworkSession.discovery.browse()
	refresh_list()
	crew_name.grab_focus()
	message.text = NetworkSession.status if not NetworkSession.status.is_empty() else NetworkSession.discovery.notice
	if OS.has_feature("web"): message.text = "Co-op requires the desktop game. Solo is available in your browser."

func close() -> void:
	NetworkSession.discovery.browsing = false
	if NetworkSession.online and not NetworkSession.world_ready:
		NetworkSession.leave("Connection cancelled.")
	hide()

func _input(event: InputEvent) -> void:
	if not visible: return
	if HarborTheme.trap_focus(self, event): return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
