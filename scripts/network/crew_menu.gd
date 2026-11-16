class_name CrewMenu
extends Control
var secret: LineEdit
var crew_name: LineEdit
var privacy: OptionButton
var password_row: VBoxContainer
var launch: Button
var refresh: Button
var message: Label
var list: VBoxContainer
var tabs: TabContainer
var refresh_clock := 0.0
var password_dialog: ConfirmationDialog
var notice: Label

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
	card.custom_minimum_size = Vector2(820, 570)
	card.add_theme_stylebox_override("panel", HarborTheme.panel())
	center.add_child(card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	card.add_child(rows)
	rows.add_child(HarborTheme.label("FIND YOUR CREW", 28))
	rows.add_child(HarborTheme.label("An open sea. A shared ship. Up to four sailors.", 17))
	notice = HarborTheme.label("", 16)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(notice)
	notice.hide()
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(tabs)
	var browse := page("Browse crews")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 260
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browse.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	refresh = HarborTheme.button("Refresh crews", search_crews)
	browse.add_child(refresh)
	var host := page("Host a voyage")
	host.add_child(HarborTheme.label("Voyage name", 18))
	crew_name = field(host, "Name your voyage", "The Wandering Ship")
	crew_name.max_length = 32
	privacy = OptionButton.new()
	privacy.add_item("Public")
	privacy.add_item("Private")
	privacy.custom_minimum_size.y = 44
	privacy.add_theme_font_size_override("font_size", 20)
	host.add_child(privacy)
	password_row = VBoxContainer.new()
	host.add_child(password_row)
	password_row.add_child(HarborTheme.label("Password", 16))
	secret = field(password_row, "Crew password", "123")
	secret.max_length = 64
	password_row.hide()
	privacy.item_selected.connect(func(index: int):
		password_row.visible = index == 1
		if index == 1:
			if secret.text.is_empty(): secret.text = "123"
			secret.grab_focus())
	host.add_child(HarborTheme.label("Keep the game open while your crew is sailing.", 16))
	launch = HarborTheme.button("Launch voyage", host_voyage)
	host.add_child(launch)
	message = HarborTheme.label("", 15)
	message.custom_minimum_size = Vector2(700, 44)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(message)
	rows.add_child(HarborTheme.button("Back to harbor", close))
	NetworkSession.status_changed.connect(func(text: String): message.text = text)
	HarborService.changed.connect(refresh_list)
	tabs.tab_changed.connect(func(index: int):
		if index == 0 and visible: search_crews())
	hide()

func _process(delta: float) -> void:
	if not visible or tabs.current_tab != 0 or is_instance_valid(password_dialog): return
	refresh_clock += delta
	if refresh_clock >= 15.0: search_crews()

func host_voyage() -> void:
	if HarborService.busy or NetworkSession.online: return
	var title := crew_name.text.strip_edges().left(32)
	if title.is_empty(): title = "The Wandering Ship"
	if privacy.selected == 1 and secret.text.is_empty():
		message.text = "Enter a password for your private voyage."
		secret.grab_focus()
		return
	# Resume automatically; save management is not part of the join/host flow.
	HarborService.host(title, secret.text if privacy.selected == 1 else "")

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
	launch.disabled = HarborService.busy or NetworkSession.online
	refresh.disabled = HarborService.busy or NetworkSession.online
	var crews: Array = HarborService.crews.values()
	crews.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.title).naturalnocasecmp_to(str(b.title)) < 0)
	if crews.is_empty():
		list.add_child(HarborTheme.label("Looking for crews…" if HarborService.busy else "No ships at sea yet.\nHost a voyage and invite your friends!", 18))
	for entry: Dictionary in crews:
		var data := entry.duplicate()
		var caption := "%s   ·   %d / 4 sailors   ·   %s" % [str(data.title).left(32), int(data.count), "Private" if data.get("locked", false) else "Public"]
		var button := HarborTheme.button(caption, func(): join_listing(data))
		list.add_child(button)
		button.disabled = int(data.count) >= NetworkSession.MAX_CREW or HarborService.busy or NetworkSession.online
		button.add_theme_font_size_override("font_size", 18)

func join_listing(data: Dictionary) -> void:
	if is_instance_valid(password_dialog) or HarborService.busy: return
	if not data.get("locked", false):
		HarborService.join_crew(data.id, "")
		return
	password_dialog = ConfirmationDialog.new()
	var dialog := password_dialog
	dialog.title = "Join " + str(data.title).left(32)
	dialog.ok_button_text = "Join crew"
	var input := LineEdit.new()
	input.secret = true
	input.placeholder_text = "Crew password"
	input.max_length = 64
	dialog.add_child(input)
	add_child(dialog)
	dialog.confirmed.connect(func():
		HarborService.join_crew(data.id, input.text)
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(400, 140))
	input.grab_focus()

func search_crews() -> void:
	refresh_clock = 0
	if HarborService.busy or NetworkSession.online: return
	HarborService.browse()

func open() -> void:
	show()
	var previous := NetworkSession.status
	if "disconnected" in previous or "ended" in previous or "timed out" in previous:
		notice.text = previous
		notice.show()
	# Opening always starts in the browser, including after a failed join.
	tabs.set_current_tab(0)
	message.text = NetworkSession.status
	refresh_list()
	search_crews()
	refresh.grab_focus()

func close() -> void:
	HarborService.cancel_browse()
	if HarborService.busy:
		message.text = "Finishing your connection…"
		return
	if NetworkSession.online and not NetworkSession.world_ready:
		NetworkSession.leave("Connection cancelled.")
	hide()

func _input(event: InputEvent) -> void:
	if not visible: return
	if HarborTheme.trap_focus(self, event): return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
