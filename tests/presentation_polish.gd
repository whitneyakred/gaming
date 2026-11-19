extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 GameWindow.set_preference("fullscreen",false)
 GameWindow.set_preference("pause_unfocused",false)
 GameWindow.set_preference("window_size",1)
 var scene := preload("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(scene)
 get_tree().current_scene = scene
 var ship: Ship = scene.get_node("Ship")
 ship.set_physics_process(false)
 var wake: Node2D = ship.get_node("Wake")
 wake.set_process(false)
 for i in 65:
  ship.global_rotation = float(i) * 0.009
  ship.global_position += Vector2.UP.rotated(ship.global_rotation) * 7.0
  wake._process(0.08)
 check(wake.samples.size() > 40 and wake.samples.size() <= 80,"Wake keeps a bounded history while moving")
 var stored: Vector2 = wake.samples[-1].position
 ship.global_position += Vector2(12,0)
 wake._process(0.08)
 check(Vector2(wake.samples[-2].position).is_equal_approx(stored),"Foam stays in world space when ship moves")
 var map: Control = Control.new()
 map.set_script(preload("res://scripts/map_system/MapCanvas.gd"))
 var layer := CanvasLayer.new()
 layer.layer = 100
 add_child(layer)
 layer.add_child(map)
 map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for angle in [0.0,PI/2,PI,-PI/2]:
  ship.global_rotation = angle
  map._process(0.0)
  var points: PackedVector2Array = map.heading_marker(Vector2.ZERO)
  check(points[0].normalized().is_equal_approx(Vector2.UP.rotated(angle)),"Map arrow follows actual ship heading")
 ship.global_rotation = 0.57
 map.hide()
 await get_tree().create_timer(0.3).timeout
 if "--capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.godot/boat-wake.png")
  map.show()
  map._process(0.0)
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.godot/map-heading.png")
 for i in 70: wake._process(0.1)
 check(wake.samples.is_empty(),"Wake fades completely after boat stops")
 ship.global_position += Vector2(1000,1000)
 wake._process(0.08)
 check(wake.samples.is_empty(),"Teleports do not create a streak across the map")
 ship.rebuild_world(12345)
 var island: WorldIsland = ship.get_islands()[0]
 ship.global_position = island.global_position + Vector2(1200,0)
 ship.global_rotation = -PI/2
 while ship._is_pose_blocked(ship.global_position,ship.global_rotation): ship.global_position.x += 100
 ship.wind_velocity = Vector2.LEFT
 ship.changing_wind_enabled = false
 ship.set_sail_angle(0)
 ship.set_sail_level(3)
 ship.speed = ship.maximum_speed
 var touched := false
 var banner := false
 for i in 1800:
  ship._physics_process(1.0/60.0)
  touched = touched or ship.aground
  banner = banner or (ship.status_label.visible and ship.status_label.text.begins_with("Ran aground"))
  if touched and i > 100: break
 check(touched,"Grounding check actually reaches generated island coast")
 check(not banner,"Grounding no longer displays the removed white banner")
 print("PRESENTATION: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
