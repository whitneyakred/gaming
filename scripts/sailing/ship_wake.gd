extends Node2D
## Bounded, world-space wake: older foam remains where the stern passed.
@export var lifetime: float = 5.0
@export var sample_interval: float = 0.075
var samples: Array[Dictionary] = []
var vessel: Node2D
var _last_position: Vector2
var _elapsed := 0.0
var _serial := 0
var _live: Dictionary = {}
var _strength := 0.0
func _ready() -> void:
 vessel = get_parent()
 _last_position = vessel.global_position
 set_as_top_level(true)
 global_transform = Transform2D.IDENTITY
 z_index = -12
func _process(delta: float) -> void:
 if delta <= 0.0: return
 var distance := vessel.global_position.distance_to(_last_position)
 var velocity := distance / delta
 _last_position = vessel.global_position
 for sample in samples: sample.age += delta
 while not samples.is_empty() and samples[0].age > lifetime: samples.pop_front()
 if distance > 180.0:
  samples.clear()
  _live.clear()
  _strength = 0.0
  queue_redraw()
  return
 _strength = lerpf(_strength,clampf(velocity/90.0,0.0,1.0),1.0-exp(-delta*8.0))
 _elapsed += delta
 if velocity > 4.0 and distance < 180.0 and _elapsed >= sample_interval:
  _elapsed = fmod(_elapsed,sample_interval)
  _serial += 1
  samples.append({"position":vessel.to_global(Vector2(5,205)), "side":Vector2.RIGHT.rotated(vessel.global_rotation), "age":0.0, "strength":maxf(_strength,0.1), "serial":_serial})
  if samples.size() > 80: samples.pop_front()
 if _strength > 0.04 and not samples.is_empty():
  _live = {"position":vessel.to_global(Vector2(5,205)), "side":Vector2.RIGHT.rotated(vessel.global_rotation), "age":0.0, "strength":_strength, "serial":_serial+1}
 else: _live.clear()
 queue_redraw()
func _draw() -> void:
 var points := samples.duplicate()
 if not _live.is_empty(): points.append(_live)
 for i in range(1,points.size()):
  var a: Dictionary = points[i-1]
  var b: Dictionary = points[i]
  if a.position.distance_to(b.position) > 60.0: continue
  var stamp: int = a.serial
  var fade: float = pow(1.0 - a.age / lifetime, 1.5) * a.strength
  var width_a: float = 32.0 + a.age * 16.0
  var width_b: float = 32.0 + b.age * 16.0
  var fill := PackedVector2Array([a.position-a.side*width_a,b.position-b.side*width_b,b.position+b.side*width_b,a.position+a.side*width_a])
  var hull := Geometry2D.convex_hull(fill)
  if hull.size() > 3:
   hull.remove_at(hull.size()-1)
   if not Geometry2D.triangulate_polygon(hull).is_empty():
    draw_colored_polygon(hull, Color(0.61,0.80,0.89,fade*0.15))
  for side in [-1.0,1.0]:
   var pa: Vector2 = a.position + a.side * width_a * side
   var pb: Vector2 = b.position + b.side * width_b * side
   draw_line(pa,pb,Color(0.58,0.78,0.90,fade*0.25),7.0)
   if stamp % 3 != 0:
    draw_line(pa,pb,Color(0.84,0.94,0.97,fade*0.66),2.0,true)
   var spread: float = sin(float(stamp)*1.7+a.age*0.8)*5.0
   var speck: Vector2 = pa + a.side * spread
   draw_rect(Rect2(speck,Vector2(3,2)),Color(0.87,0.96,1.0,fade*0.6))
   if stamp % 5 == 0:
    draw_arc(pa, 6.0+a.age*2.0, a.side.angle()+0.3,a.side.angle()+2.5,8,Color(0.72,0.88,0.96,fade*0.3),1.0)
  if stamp % 2 == 0:
   var center: Vector2 = a.position + a.side * sin(float(stamp)*2.3+a.age) * width_a * 0.3
   draw_arc(center, 4.0+a.age*3.0, 0.3,2.7,7,Color(0.76,0.88,0.95,fade*0.45),1.5)

