class_name FishingHUD
extends Control
const PANEL := preload("res://assets/menus/fishing_panel.png")
const INK := Color("443247")
const CREAM := Color("fff1cf")
var fishing: Node
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 offset_left = -230
 offset_right = 230
 offset_top = 24
 offset_bottom = 176
func _process(_delta: float) -> void:
 visible = fishing != null and fishing.state == 4 and not fishing.local_done
 queue_redraw()
func _fish(at: Vector2, color: Color) -> void:
 draw_colored_polygon(PackedVector2Array([at+Vector2(-8,0),at+Vector2(-14,-6),at+Vector2(-14,6)]),color)
 _ellipse(at, Vector2(10,5),color)
 draw_circle(at+Vector2(5,-1),1.2,INK)
func _ellipse(at: Vector2, dimensions: Vector2, color: Color) -> void:
 var points := PackedVector2Array()
 for i in 16: points.append(at+Vector2(cos(i*TAU/16),sin(i*TAU/16))*dimensions)
 draw_colored_polygon(points,color)
func _mouse(at: Vector2, held: bool) -> void:
 draw_rect(Rect2(at,Vector2(16,20)),INK)
 draw_rect(Rect2(at+Vector2(1,1),Vector2(14,18)),CREAM)
 draw_rect(Rect2(at+Vector2(2,2),Vector2(6,8)),Color("bd526b") if held else CREAM)
 draw_line(at+Vector2(8,1),at+Vector2(8,11),INK,1)
func _draw() -> void:
 if fishing == null: return
 var font := HarborTheme.UI_FONT
 if fishing.state != 4:
  var text := "CAST" if fishing.state == 1 else ("CLICK!" if fishing.state == 3 else "…")
  var badge := Rect2(170,0,120,42)
  draw_style_box(HarborTheme.panel(),badge)
  _mouse(Vector2(184,10),fishing.state == 3)
  draw_string(font,Vector2(209,28),text,HORIZONTAL_ALIGNMENT_LEFT,74,18,INK)
  return
 draw_texture_rect(PANEL,Rect2(Vector2.ZERO,size),false)
 var fight: FishingFight = fishing.fight
 var bar := Rect2(62,35,336,23)
 draw_rect(bar.grow(2),INK)
 draw_rect(bar,Color("a17470"))
 var green := Rect2(bar.position+Vector2((fight.green_center-fight.green_width*0.5)*bar.size.x,0),Vector2(fight.green_width*bar.size.x,bar.size.y))
 draw_rect(green,Color("499c7a"))
 draw_rect(green.grow(-2),Color("95d3a2"),false,1)
 var x := bar.position.x+fight.tension*bar.size.x
 draw_line(Vector2(x,30),Vector2(x,64),INK,6)
 draw_line(Vector2(x,30),Vector2(x,64),CREAM,3)
 # Fish approaches the basket as catch progress fills. Red spool shows strain.
 _fish(Vector2(70,85),Color("568b82"))
 draw_rect(Rect2(88,80,176,9),INK)
 draw_rect(Rect2(89,81,174*fight.progress,7),Color("70b892"))
 draw_arc(Vector2(295,85),7,0,TAU,16,INK,2)
 draw_arc(Vector2(295,85),4,0,TAU,16,Color("bd526b"),2)
 draw_rect(Rect2(310,80,87,9),INK)
 draw_rect(Rect2(311,81,85*fight.danger,7),Color("db705e"))
 if fight.danger > 0.6:
  draw_string(font,Vector2(401,91),"!",HORIZONTAL_ALIGNMENT_LEFT,12,21,Color("bd526b"))
