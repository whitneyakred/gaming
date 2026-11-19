extends SceneTree
## Run with Godot --path . --script tools/preview_shark_water.gd.
func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 root.size = Vector2i(1000, 760)
 root.content_scale_size = Vector2i(1000, 760)
 var background := TextureRect.new()
 background.texture = load("res://assets/menus/title_ocean.png")
 background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 background.stretch_mode = TextureRect.STRETCH_TILE
 background.size = Vector2(1000, 760)
 root.add_child(background)
 for row in 4:
  var label := Label.new()
  label.text = "ORIGINAL" if row % 2 == 0 else "SUBMERGED BODY / SURFACE FIN"
  label.position = Vector2(20, row * 190 + 6)
  root.add_child(label)
  for col in 6:
   var visual := SharkVisual.new()
   root.add_child(visual)
   visual.position = Vector2(85 + col * 165, row * 190 + 100)
   visual.sprite.scale = Vector2.ONE * 0.48
   visual.set_swim_time(0.0, (row / 2) * 6 + col)
   if row % 2 == 0:
    var original := ShaderMaterial.new()
    original.shader = load("res://shaders/sprite_alpha.gdshader")
    visual.sprite.material = original
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://output/shark-preview")
 root.get_texture().get_image().save_png("res://output/shark-preview/comparison.png")
 print("Shark preview saved. Sheet size: ", SharkVisual.SHEET.get_size())
 quit()
