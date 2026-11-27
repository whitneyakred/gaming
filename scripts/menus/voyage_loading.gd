class_name VoyageLoading
extends CanvasLayer
## One painted frame before scene construction; no fake percentage/progress timer.
static func show_loading(tree: SceneTree) -> VoyageLoading:
	var overlay := VoyageLoading.new()
	tree.root.add_child(overlay)
	return overlay
func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	var curtain := ColorRect.new()
	curtain.color = Color("132a38")
	add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var message := Label.new()
	message.text = "Charting your voyage…"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_override("font",HarborTheme.UI_FONT)
	message.add_theme_font_size_override("font_size",28)
	message.add_theme_color_override("font_color",Color("e8d4a5"))
	curtain.add_child(message)
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
