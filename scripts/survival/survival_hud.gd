extends Control
var world: SurvivalWorld
var eat_seen := -1
var eating_voice: AudioStreamPlayer
var hurt_seen := -1
var sink_seen := -1
var flash := 0.0
var voice: AudioStreamPlayer
var death_screen: ColorRect
var death_label: Label
var respawn_button: Button
var was_dead := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_screen = ColorRect.new()
	death_screen.color = Color(0.25, 0.015, 0.025, 0.9)
	death_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.hide()
	add_child(death_screen)
	death_label = Label.new()
	death_label.text = "You Died"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 52)
	death_label.add_theme_color_override("font_color", Color("ffe1cd"))
	death_screen.add_child(death_label)
	respawn_button = Button.new()
	respawn_button.text = "Respawn to boat"
	respawn_button.add_theme_font_size_override("font_size", 24)
	var button_style := panel()
	button_style.bg_color = Color("243c43")
	button_style.border_color = Color("d9bd89")
	button_style.set_border_width_all(2)
	respawn_button.add_theme_stylebox_override("normal", button_style)
	death_screen.add_child(respawn_button)
	respawn_button.pressed.connect(func() -> void:
		if NetworkSession.online: NetworkSession.command("respawn")
		else: world.respawn(1)
	)
	eating_voice = AudioStreamPlayer.new()
	eating_voice.bus = "Effects"
	add_child(eating_voice)
	eating_voice.stream = ActionAudio.make("eat_complete")
	voice = AudioStreamPlayer.new()
	voice.bus = "Effects"
	add_child(voice)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(6615 * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 78
	for i in 6615:
		var t := float(i) / 22050.0
		var sample := (sin(TAU * (140 * t - 100 * t*t)) * 0.55 + rng.randf_range(-1,1) * 0.25) * pow(1.0 - float(i)/6615, 2)
		bytes.encode_s16(i*2, int(sample * 15000))
	sound.data = bytes
	voice.stream = sound

func _process(delta: float) -> void:
	flash = maxf(0, flash - delta * 2)
	var id := NetworkSession.local_id if NetworkSession.online else 1
	var player: Node = world.crew().get(id)
	if player:
		var dead: bool = player.health <= 0
		if dead != was_dead:
			was_dead = dead
			death_screen.visible = dead
			if dead:
				MapState.map_open = false
				world.ship.get_node("MapUI").hide()
				death_screen.modulate.a = 0.0
				create_tween().tween_property(death_screen, "modulate:a", 1.0, 0.45)
				respawn_button.grab_focus()
		var screen := get_viewport_rect().size
		death_label.position = Vector2(0, screen.y * 0.38)
		death_label.size = Vector2(screen.x, 80)
		respawn_button.position = Vector2(screen.x / 2 - 170, screen.y - 120)
		respawn_button.size = Vector2(340, 64)
		if eat_seen>=0 and eat_seen!=player.eat_serial: eating_voice.play()
		eat_seen=player.eat_serial
		if hurt_seen >= 0 and hurt_seen != player.hurt_serial:
			flash = 0.8
			voice.pitch_scale = 1.0
			voice.play()
		hurt_seen = player.hurt_serial
	if sink_seen >= 0 and sink_seen != world.sink_serial:
		flash = 1
		voice.pitch_scale = 0.45
		voice.play()
	sink_seen = world.sink_serial
	queue_redraw()

func icon(points: PackedVector2Array, at: Vector2, value: int, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points: polygon.append(point + at)
	draw_colored_polygon(polygon, Color("16242b"))
	if value > 0:
		var width := 30.0 * value / 3.0
		var clip := PackedVector2Array([at, at + Vector2(width,0), at + Vector2(width,28), at + Vector2(0,28)])
		for piece in Geometry2D.intersect_polygons(polygon, clip): draw_colored_polygon(piece, color)
	var outline := polygon.duplicate()
	outline.append(polygon[0])
	draw_polyline(outline, Color("d9bd89"), 1.5, true)
	for x in [10,20]:
		for segment in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([at+Vector2(x,0),at+Vector2(x,28)]), polygon):
			draw_polyline(segment, Color(0.08,0.14,0.17,0.6), 1)

func _draw() -> void:
	if not is_instance_valid(world) or MapState.map_open: return
	var id := NetworkSession.local_id if NetworkSession.online else 1
	var player: Node = world.crew().get(id)
	if not player: return
	var screen := get_viewport_rect().size
	if flash > 0:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.7,0.08,0.07,flash*0.15))
	var base := Vector2(24, screen.y - 92)
	draw_style_box(panel(), Rect2(base-Vector2(12,10),Vector2(205,80)))
	var heart := PackedVector2Array([Vector2(0,7),Vector2(5,1),Vector2(10,1),Vector2(15,7),Vector2(20,1),Vector2(25,1),Vector2(30,7),Vector2(30,13),Vector2(15,27),Vector2(0,13)])
	var fish := PackedVector2Array([Vector2(0,7),Vector2(7,12),Vector2(12,5),Vector2(22,5),Vector2(30,14),Vector2(22,23),Vector2(12,23),Vector2(7,16),Vector2(0,21)])
	for i in 5:
		icon(heart,base+Vector2(i*37,0),clampi(player.health-i*3,0,3),Color("d65b50"))
		icon(fish,base+Vector2(i*37,34),clampi(player.hunger-i*3,0,3),Color("d9a650"))
	var danger: float = player.danger_time if player.is_overboard else world.ship_danger
	if danger > 0:
		var text := "%s — %ds to return!" % ["RED WATER" if player.is_overboard else "SHIP IN RED WATER", ceili(world.red_water_seconds-danger)]
		draw_string(ThemeDB.fallback_font, Vector2(screen.x/2-180,58),text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("ffb3a0"))

func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04,0.1,0.14,0.8)
	style.set_corner_radius_all(5)
	return style
