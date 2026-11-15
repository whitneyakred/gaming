class_name FishingHUD
extends Control
var fishing: Node
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -260
	offset_right = 260
	offset_top = 32
	offset_bottom = 190
func _process(_delta: float) -> void:
	visible = fishing != null and fishing.state != 0
	queue_redraw()
func _draw() -> void:
	if fishing == null:
		return

	var font := ThemeDB.fallback_font
	var gold := Color("edd29a")
	var title: String = fishing.status_text()
	if fishing.state != 4:
		# A single outlined line leaves the ocean and bobber unobstructed.
		draw_string_outline(font, Vector2(0, 27), title, HORIZONTAL_ALIGNMENT_CENTER, 520, 20, 5, Color("102531"))
		draw_string(font, Vector2(0, 27), title, HORIZONTAL_ALIGNMENT_CENTER, 520, 20, gold)
		return
	draw_style_box(HarborTheme.panel(), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(20, 29), title, HORIZONTAL_ALIGNMENT_LEFT, 480, 20, gold)
	var fight: FishingFight = fishing.fight
	var bar := Rect2(20, 49, 480, 24)
	draw_rect(bar, Color("663c38"))
	var green := Rect2(bar.position + Vector2((fight.green_center - fight.green_width * 0.5) * bar.size.x, 0), Vector2(fight.green_width * bar.size.x, bar.size.y))
	draw_rect(green, Color("4d9a70"))
	draw_rect(green.grow(-3), Color("75bc80"), false, 1)
	var x := bar.position.x + fight.tension * bar.size.x
	draw_line(Vector2(x, 45), Vector2(x, 77), Color("fff1ce"), 4)
	draw_string(font, Vector2(20, 96), "SLACK", HORIZONTAL_ALIGNMENT_LEFT, 100, 12, gold)
	draw_string(font, Vector2(425, 96), "TOO TIGHT", HORIZONTAL_ALIGNMENT_RIGHT, 75, 12, gold)
	draw_string(font, Vector2(135, 96), "Hold to pull  /  Release to ease", HORIZONTAL_ALIGNMENT_CENTER, 250, 14, Color("c2d9dc"))
	draw_rect(Rect2(20, 110, 310, 9), Color("253b43"))
	draw_rect(Rect2(20, 110, 310 * fight.progress, 9), Color("75bc80"))
	draw_rect(Rect2(350, 110, 150, 9), Color("253b43"))
	draw_rect(Rect2(350, 110, 150 * fight.danger, 9), Color("e97c58"))
	draw_string(font, Vector2(20, 143), "CATCH %d%%" % int(fight.progress * 100), HORIZONTAL_ALIGNMENT_LEFT, 300, 13, gold)
	draw_string(font, Vector2(350, 143), "LINE STRAIN", HORIZONTAL_ALIGNMENT_LEFT, 150, 13, Color("e9ab8e"))
