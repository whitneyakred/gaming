class_name QuestIsland
extends WorldIsland
## Replaceable sanctuary encounter. Quest progress belongs to the voyage.
@export_enum("bronze", "silver", "gold") var key_id: String = "bronze"
@export var paradise: bool = false
@export var radius: Vector2 = Vector2(760, 620)
@export var interaction_distance: float = 80.0
const SEALS := [Vector2(-320, 120), Vector2(0, -280), Vector2(320, 120)]
const GATE := Vector2(0, 210)
const BEACON := Vector2(0, -100)
const COURT := Rect2(-220, -300, 440, 510)
var generated_ground := false
var caption: Label

func _ready() -> void:
	var land := StaticBody2D.new()
	land.name = "Land"
	var coast := CollisionPolygon2D.new()
	coast.name = "Coast"
	var outline := PackedVector2Array()
	for i in 48:
		var angle := TAU * i / 48.0
		outline.append(Vector2(cos(angle), sin(angle)) * radius * (1.0 + sin(angle * 5) * 0.035))
	coast.polygon = outline
	land.add_child(coast)
	add_child(land)
	super._ready()
	if generated_ground:
		var ground := IslandGround.new()
		ground.z_index = -1
		add_child(ground)
		ground.build(outline,abs(hash(key_id)),false)
	caption = Label.new()
	caption.position = Vector2(-310, 270) if paradise else Vector2(-310, 210)
	caption.size = Vector2(620, 120)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_outline_color", Color("102531"))
	caption.add_theme_constant_override("outline_size", 6)
	add_child(caption)
	VoyageState.quest_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if paradise:
		caption.text = "PARADISE ISLAND\n" + ("Gate open. E at the beacon to finish your voyage." if VoyageState.paradise_quest.get("gate_open", false) else "E at gate · Insert carried keys")
		if VoyageState.paradise_quest.get("complete", false): caption.text = "PARADISE REACHED\nYour beacon welcomes future sailors. Keep exploring!"
	else:
		caption.text = display_name + "\n" + ("Key is away from its pedestal" if VoyageState.has_key(key_id) else "E at each seal: 1, 2, 3\nThen E at the central key pedestal")
	queue_redraw()

func seal_count() -> int:
	return int(VoyageState.paradise_quest.get(key_id + "_seals", 0))

func interact(crew: CharacterBody2D) -> bool:
	if not crew.on_land or crew.health <= 0 or crew.inventory_open or crew.fishing_active or crew.island_challenge: return false
	var point := to_local(crew.global_position)
	if paradise:
		if point.distance_to(GATE) <= interaction_distance:
			VoyageState.open_paradise(crew.player_inventory)
			return true
		if point.distance_to(BEACON) <= interaction_distance and VoyageState.paradise_quest.get("gate_open", false):
			VoyageState.complete_voyage()
			return true
		return false
	for index in SEALS.size():
		if point.distance_to(SEALS[index]) <= interaction_distance:
			if not VoyageState.has_key(key_id):
				var count := seal_count()
				if index == count: count += 1
				elif index >= count: count = 0
				VoyageState.paradise_quest[key_id + "_seals"] = count
				VoyageState.quest_changed.emit()
			return true
	if point.length() <= interaction_distance:
		if seal_count() == 3: VoyageState.grant_key(key_id, crew.player_inventory)
		return true
	return false

## World swimmers bypass physics, so their movement explicitly checks these walls.
func blocks_path(start: Vector2, end: Vector2) -> bool:
	if not paradise: return false
	var walls: Array[Rect2] = [Rect2(-236, -316, 472, 24), Rect2(-236, -316, 24, 542), Rect2(212, -316, 24, 542), Rect2(-236, 198, 156, 28), Rect2(80, 198, 156, 28)]
	if not VoyageState.paradise_quest.get("gate_open", false): walls.append(Rect2(-80, 198, 160, 28))
	var path := PackedVector2Array([to_local(start), to_local(end)])
	for wall in walls:
		wall = wall.grow(8)
		var polygon := PackedVector2Array([wall.position, Vector2(wall.end.x, wall.position.y), wall.end, Vector2(wall.position.x, wall.end.y)])
		if not Geometry2D.intersect_polyline_with_polygon(path, polygon).is_empty(): return true
	return false

static func key_color(key: String) -> Color:
	return {"bronze": Color("d89355"), "silver": Color("c6d9e8"), "gold": Color("ffcf55")}.get(key, Color.WHITE)

func _draw() -> void:
	var beach := PackedVector2Array()
	var grass := PackedVector2Array()
	for i in 48:
		var angle := TAU * i / 48.0
		var point := Vector2(cos(angle), sin(angle)) * radius * (1.0 + sin(angle * 5) * 0.035)
		beach.append(point)
		grass.append(point * 0.84)
	if not generated_ground:
		draw_colored_polygon(beach, Color("dcca8b"))
		draw_colored_polygon(grass, Color("4e9866") if paradise else Color("527b64"))
	for point in ([] if generated_ground else [Vector2(-460, -220), Vector2(460, -200), Vector2(-430, 320), Vector2(450, 330)]):
		draw_circle(point, 55, Color("30694e"))
		draw_circle(point + Vector2(-15, -15), 36, Color("3d8656"))
	if paradise:
		draw_rect(COURT, Color("78ac76"))
		draw_rect(COURT, Color("647578"), false, 24)
		draw_rect(Rect2(-80, 190, 160, 42), Color("78ac76") if VoyageState.paradise_quest.get("gate_open", false) else Color("725b48"))
		for i in 3:
			var key: String = VoyageState.KEY_IDS[i]
			var at := GATE + Vector2((i - 1) * 44, 0)
			draw_circle(at, 14, key_color(key))
			draw_circle(at, 5, Color("182e32") if not VoyageState.paradise_quest.get(key + "_inserted", false) else Color.WHITE)
			draw_rect(Rect2(at + Vector2(-3, 2), Vector2(6, 9)), Color("182e32"))
		draw_circle(BEACON, 38, Color("687879"))
		draw_circle(BEACON, 24, Color("ffe38a") if VoyageState.paradise_quest.get("complete", false) else Color("30454b"))
	else:
		for i in SEALS.size():
			draw_circle(SEALS[i], 40, Color("344c52"))
			draw_arc(SEALS[i], 33, 0, TAU, 32, key_color(key_id) if i < seal_count() else Color("84918b"), 5)
			draw_string(ThemeDB.fallback_font, SEALS[i] + Vector2(-10, 8), ["I", "II", "III"][i], HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		draw_circle(Vector2.ZERO, 55, Color("344c52"))
		if not VoyageState.has_key(key_id):
			var color := key_color(key_id) if seal_count() == 3 else Color("7a8582")
			draw_circle(Vector2(-13, -5), 12, color, false, 5)
			draw_line(Vector2(-1, -5), Vector2(28, -5), color, 6)
			draw_line(Vector2(23, -5), Vector2(23, 8), color, 6)
