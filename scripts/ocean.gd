class_name Ocean
extends Node2D
## A camera-sized recycled surface, sampled in world space for indefinite travel.
@export var scroll_speed: float = 0.0
@export var cover_size: Vector2 = Vector2(1600, 1000)
@export var world_anchored: bool = false
var scroll_offset: float = 0.0
var _time: float = 0.0
func _ready() -> void:
 var surface := ShaderMaterial.new()
 surface.shader = preload("res://shaders/ocean_surface.gdshader")
 surface.set_shader_parameter("ocean_texture", preload("res://assets/menus/title_ocean.png"))
 surface.set_shader_parameter("world_anchored", world_anchored)
 material = surface
func _process(delta: float) -> void:
 if not GameWindow.preferences.reduced_motion: _time += delta
 scroll_offset = fmod(scroll_offset + scroll_speed * delta, 1536.0)
 material.set_shader_parameter("ocean_time", 0.0 if GameWindow.preferences.reduced_motion else _time)
 material.set_shader_parameter("ambient_scroll", 0.0 if world_anchored else scroll_offset)
 queue_redraw()
func _draw() -> void:
 var area := cover_size
 var center := Vector2.ZERO
 var camera := get_viewport().get_camera_2d()
 if is_instance_valid(camera):
  center = to_local(camera.get_screen_center_position())
  area = area.max(get_viewport_rect().size / camera.zoom + Vector2.ONE * 64)
 else: area = area.max(get_viewport_rect().size + Vector2.ONE * 64)
 draw_rect(Rect2(center - area * 0.5, area), Color.WHITE)
