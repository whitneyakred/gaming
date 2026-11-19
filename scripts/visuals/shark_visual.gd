class_name SharkVisual
extends Node2D
## Shared body frames and fin foam for menu and gameplay sharks.
const SHEET := preload("res://assets/menus/shark_swim_upright.png")
# Dorsal fin endpoints in source-atlas pixels, following each swimming pose.
const FIN_TIPS: Array[Vector2] = [Vector2(207,114),Vector2(550,114),Vector2(892,114),Vector2(1236,114),Vector2(206,470),Vector2(550,470),Vector2(892,470),Vector2(1238,470),Vector2(206,826),Vector2(550,826),Vector2(895,826),Vector2(1242,826)]
const FIN_BASES: Array[Vector2] = [Vector2(209,205),Vector2(550,205),Vector2(888,205),Vector2(1232,205),Vector2(205,554),Vector2(548,554),Vector2(893,554),Vector2(1242,554),Vector2(213,910),Vector2(573,910),Vector2(903,910),Vector2(1241,910)]
# Per-frame nose registration measured from opaque head pixels in the source atlas.
# Sprite offsets change texture alignment only; the swimming path and fin foam stay fixed.
const FRAME_OFFSETS: Array[Vector2] = [Vector2(-26.372,2.44),Vector2(-7.588,2.44),Vector2(9.729,2.44),Vector2(27.542,1.44),Vector2(-26.481,9.44),Vector2(-8.352,10.44),Vector2(8.594,10.44),Vector2(26.156,10.44),Vector2(-26.324,15.44),Vector2(-7.866,17.44),Vector2(8.769,16.44),Vector2(26.837,16.44)]
var sprite: Sprite2D
var frames: Array[AtlasTexture] = []
var swim_time := 0.0
func _ready() -> void:
 var cell := Vector2(SHEET.get_size()) / Vector2(4,3)
 for i in 12:
  var frame := AtlasTexture.new()
  frame.atlas = SHEET
  frame.region = Rect2(Vector2(i%4,i/4)*cell,cell)
  frames.append(frame)
 sprite = Sprite2D.new()
 sprite.texture = frames[0]
 sprite.offset = FRAME_OFFSETS[0]
 sprite.scale = Vector2.ONE * 0.25
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.show_behind_parent = true
 var cutout := ShaderMaterial.new()
 cutout.shader = preload("res://shaders/shark_water.gdshader")
 sprite.material = cutout
 add_child(sprite)
 set_swim_time(0.0)
func set_swim_time(value: float, phase: float = 0.0) -> void:
 swim_time = value
 var frame := int(value*4.5+phase)%12
 sprite.texture = frames[frame]
 sprite.offset = FRAME_OFFSETS[frame]
 sprite.material.set_shader_parameter("fin_tip", FIN_TIPS[frame])
 sprite.material.set_shader_parameter("fin_base", FIN_BASES[frame])
 queue_redraw()
func _draw() -> void:
 if sprite == null: return
 var factor := sprite.scale.x / 0.18
 draw_set_transform(sprite.position,sprite.rotation,Vector2.ONE*factor)
 # Bubbles originate alongside the narrow fin, peel outwards, then fade behind it.
 for i in 14:
  var progress := fposmod(swim_time*0.65+float(i)/14.0,1.0)
  var side := -1.0 if i%2 == 0 else 1.0
  var point := Vector2(side*(2.5+progress*10),-8+progress*25)
  point.x += sin(progress*4.0+float(i))*1.2
  var alpha := (1.0-progress)*0.8
  draw_rect(Rect2(point,Vector2(1.2,1.2+progress)),Color(0.85,0.95,1,alpha))
 for side in [-1.0,1.0]:
  var points := PackedVector2Array([Vector2(side*2,-7),Vector2(side*4,0),Vector2(side*8,7)])
  draw_polyline(points,Color(0.8,0.91,0.97,0.55),1.0,true)
 draw_set_transform(Vector2.ZERO)
