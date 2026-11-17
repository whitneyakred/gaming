extends Control
const WATER := preload("res://assets/menus/title_ocean.png")
var _time := 0.0
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var surface := ShaderMaterial.new()
 surface.shader = preload("res://shaders/ocean_surface.gdshader")
 surface.set_shader_parameter("ocean_texture", WATER)
 surface.set_shader_parameter("screen_space", true)
 material = surface
func _process(delta: float) -> void:
 if not GameWindow.preferences.reduced_motion: _time += delta
 material.set_shader_parameter("ocean_time", 0.0 if GameWindow.preferences.reduced_motion else _time)
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
