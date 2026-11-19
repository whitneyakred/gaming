extends Node
@onready var root: Window = get_tree().root
func _ready() -> void:
	run.call_deferred()
func capture(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://output/fish-preview")
	var title: Control = load("res://scenes/menus/title_screen.tscn").instantiate()
	root.add_child(title)
	await get_tree().create_timer(3.0).timeout
	await capture("res://output/fish-preview/title.png")
	print("TITLE FISH: ", title.get_node("Composition/Props/MenuFish").visible_fish)
	root.remove_child(title)
	title.queue_free()
	var ship := load("res://scenes/ship.tscn").instantiate() as Ship
	root.add_child(ship)
	ship.rebuild_world(71923)
	await get_tree().create_timer(3.0).timeout
	await capture("res://output/fish-preview/ocean.png")
	print("WORLD FISH: ", ship.ocean_fish.visible_fish)
	root.remove_child(ship)
	ship.queue_free()
	await get_tree().process_frame
	# Enlarged, labeled art preview using exactly the in-game atlas shader.
	var stage := Node2D.new()
	root.add_child(stage)
	var water := TextureRect.new()
	water.texture = load("res://assets/menus/title_ocean.png")
	water.stretch_mode = TextureRect.STRETCH_TILE
	water.size = Vector2(1280,720)
	stage.add_child(water)
	var sample := OceanFish.new()
	sample.menu_mode = true
	stage.add_child(sample)
	sample.set_process(false)
	var names := ["Silver sardine", "Amber reef fish", "Blue mackerel", "Violet flatfish", "Coral fish", "Olive needlefish"]
	for row in 6:
		var label := Label.new()
		label.text = names[row]
		label.position = Vector2(30, row*118+44)
		stage.add_child(label)
		for frame in 4:
			var pose := Transform2D(PI*0.5, Vector2(410+frame*230,row*118+68))
			pose.x *= 140.0
			pose.y *= 140.0
			var index := row*4+frame
			sample.batch.multimesh.set_instance_transform_2d(index,pose)
			sample.batch.multimesh.set_instance_custom_data(index,Color((row+0.5)/6.0,frame/4.0,1.0,6.0))
	sample.batch.multimesh.visible_instance_count = 24
	await capture("res://output/fish-preview/species.png")
	stage.queue_free()
	await get_tree().process_frame
	get_tree().quit()
