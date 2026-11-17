extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var visual = load("res://scripts/visuals/shark_visual.gd").new()
 root.add_child(visual)
 var img: Image = visual.SHEET.get_image()
 var cell := Vector2i(img.get_size()/Vector2i(4,3))
 var failures := 0
 for i in 12:
  var origin := Vector2i(i%4,i/4)*cell
  var top := cell.y
  for y in cell.y/2:
   for x in cell.x:
    if img.get_pixelv(origin+Vector2i(x,y)).a > 0.85: top=mini(top,y)
  var total := 0.0
  var count := 0
  for y in range(top+12,top+32):
   for x in cell.x:
    if img.get_pixelv(origin+Vector2i(x,y)).a > 0.85: total+=x; count+=1
  var anchor: Vector2 = Vector2(total/maxi(count,1),top)+visual.FRAME_OFFSETS[i]
  if anchor.distance_to(Vector2(cell.x*0.5,cell.y*0.12)) > 0.1:
   failures+=1
   push_error("Misaligned shark frame %d" % i)
 print("SHARK ALIGNMENT: 12 checks, %d failures" % failures)
 quit(failures)

