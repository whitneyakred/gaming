extends SharkVisual
## Independent patrol cadence and twelve-frame swimming; wakes follow the heading.
var index: int = 0
var clock: float = 0.0
var trail: Array[Vector2] = []
var trail_tick: float = 0.0
func _ready() -> void:
 super._ready()
 sprite.scale = Vector2.ONE * (0.18 + float(index % 3) * 0.008)
 _update_pose()
func route(t: float) -> Vector2:
 var phase := t * (0.075 + index * 0.009) + index * 1.2566 + sin(t * 0.2 + index) * 0.13
 var radius := Vector2(245 + index * 4, 198 + index * 5)
 return Vector2(585, 273) + Vector2(cos(phase), sin(phase)) * radius + Vector2(sin(phase * 3.0 + index) * 13.0, 0)
func _process(delta: float) -> void:
 if GameWindow.preferences.reduced_motion:
  clock = 0.0
  trail.clear()
 else:
  clock += delta
  trail_tick += delta
  if trail_tick > 0.12:
   trail_tick = 0.0
   trail.push_front(sprite.position)
   if trail.size() > 14: trail.pop_back()
 _update_pose()
 queue_redraw()
func _update_pose() -> void:
 sprite.position = route(clock)
 var direction := route(clock + 0.1) - sprite.position
 sprite.rotation = direction.angle() + PI * 0.5
 set_swim_time(clock, index)
func _draw() -> void:
 for i in trail.size():
  var fade := (1.0 - float(i) / 14.0) * 0.24
  var radius := 2.0 + i * 0.5
  draw_arc(trail[i], radius, 0.2, 2.7, 7, Color(0.72,0.86,0.94,fade), 1.0)
 super._draw()

