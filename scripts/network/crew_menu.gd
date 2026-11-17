class_name CrewMenu
extends Control
signal solo_requested
var solo_button: Button
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
var save_buttons: Array[Button] = []
var reset_save: Button

func _ready() -> void:
	theme = HarborTheme.menu_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = HarborTheme.SHADE
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
	var heading := HBoxContainer.new()
	rows.add_child(heading)
	var caption := HarborTheme.label("CHOOSE YOUR VOYAGE", 28)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(caption)
	solo_button = HarborTheme.button("Sail solo", start_solo)
	heading.add_child(solo_button)
	solo_button.custom_minimum_size = Vector2(210, 40)
	solo_button.add_theme_font_size_override("font_size", 17)
	rows.add_child(HarborTheme.label("An open sea. A shared ship. Up to four sailors.", 17))
	notice = HarborTheme.label("", 16)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(notice)
	notice.hide()
	tabs = TabContainer.new()
	tabs.use_hidden_tabs_for_min_size = true
	# Reserve room for both tabs, including the private-password fields.
	tabs.custom_minimum_size.y = 330
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(tabs)
	var browse := page("Browse crews")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 210
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browse.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	refresh = HarborTheme.button("Refresh crews", search_crews)
	browse.add_child(refresh)
	var host_page := page("Host a voyage")
	var host_columns := HBoxContainer.new()
	host_columns.add_theme_constant_override("separation", 24)
	host_page.add_child(host_columns)
	var host := VBoxContainer.new()
	host.custom_minimum_size.x = 350
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_theme_constant_override("separation", 12)
	host_columns.add_child(host)
	var saves := VBoxContainer.new()
	saves.custom_minimum_size.x = 350
	saves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saves.add_theme_constant_override("separation", 8)
	host_columns.add_child(saves)
	saves.add_child(HarborTheme.label("YOUR VOYAGES", 18))
	for i in VoyageSaves.COUNT:
		var slot := i
		var button := HarborTheme.button("", func(): select_save(slot))
		button.custom_minimum_size.y = 64
		button.add_theme_font_size_override("font_size", 15)
		saves.add_child(button)
		save_buttons.append(button)
	reset_save = HarborTheme.button("Clear selected save", confirm_clear)
	reset_save.add_theme_font_size_override("font_size", 16)
	saves.add_child(reset_save)
	host.add_child(HarborTheme.label("Voyage name", 18))
	crew_name = field(host, "Name your voyage", "The Wandering Ship")
	crew_name.max_length = 32
	privacy = OptionButton.new()
	privacy.add_item("Public")
	privacy.add_item("Private")
	privacy.custom_minimum_size.y = 44
	privacy.add_theme_font_size_override("font_size", 20)
	host.add_child(privacy)
	var password_space := VBoxContainer.new()
	password_space.custom_minimum_size.y = 78
	host.add_child(password_space)
	password_row = VBoxContainer.new()
	password_space.add_child(password_row)
	password_row.add_child(HarborTheme.label("Password", 16))
	secret = field(password_row, "Crew password", "123")
	secret.max_length = 64
	password_row.hide()
	privacy.item_selected.connect(func(index: int):
		password_row.visible = index == 1
		if index == 1:
			if secret.text.is_empty(): secret.text = "123"
			secret.grab_focus())
	host.add_child(HarborTheme.label("Keep the game open for your crew.", 14))
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
	VoyageSaves.changed.connect(refresh_saves)
	refresh_saves()
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
	# Selected slot resumes when occupied; empty slots start a new voyage.
	HarborService.host(title, secret.text if privacy.selected == 1 else "")

func select_save(slot: int) -> void:
	if HarborService.busy or NetworkSession.online: return
	VoyageSaves.selected = slot
	var entry := VoyageSaves.read_slot(slot)
	crew_name.text = str(entry.get("title", "The Wandering Ship"))
	refresh_saves()

func refresh_saves() -> void:
	for i in save_buttons.size():
		var entry := VoyageSaves.read_slot(i)
		var selected := i == VoyageSaves.selected
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := save_buttons[i].get_theme_stylebox(state).duplicate() as StyleBoxFlat
			style.set_border_width_all(3 if selected else 1)
			style.border_color = HarborTheme.CORAL if selected else Color("876474")
			save_buttons[i].add_theme_stylebox_override(state, style)
		save_buttons[i].text = "Slot %d · " % (i + 1) + ("New voyage" if entry.is_empty() else str(entry.title))
		if not entry.is_empty(): save_buttons[i].text += "\n" + VoyageSaves.timestamp(entry)
	var occupied := not VoyageSaves.read_slot(VoyageSaves.selected).is_empty()
	reset_save.disabled = not occupied or NetworkSession.online or HarborService.busy
	launch.text = "Resume voyage" if occupied else "Launch voyage"

func confirm_clear() -> void:
	var slot := VoyageSaves.selected
	var dialog := ConfirmationDialog.new()
	dialog.title = "Clear voyage save?"
	dialog.dialog_text = "Permanently clear slot %d and start a fresh world?" % (slot + 1)
	dialog.ok_button_text = "Clear save"
	add_child(dialog)
	dialog.confirmed.connect(func():
		if not VoyageSaves.clear_slot(slot): message.text = "Could not clear this save."
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(440, 160))

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
	for button in save_buttons: button.disabled = HarborService.busy or NetworkSession.online
	reset_save.disabled = VoyageSaves.read_slot(VoyageSaves.selected).is_empty() or HarborService.busy or NetworkSession.online
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
	HarborTheme.reveal(self)
	var previous := NetworkSession.status
	if "disconnected" in previous or "ended" in previous or "timed out" in previous:
		notice.text = previous
		notice.show()
	# Opening always starts in the browser, including after a failed join.
	select_save(VoyageSaves.selected)
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

func start_solo() -> void:
	HarborService.cancel_browse()
	if HarborService.busy or NetworkSession.online: return
	hide()
	solo_requested.emit()
