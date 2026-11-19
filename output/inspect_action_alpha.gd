extends SceneTree
func _initialize() -> void:
	var img := Image.load_from_file("res://assets/player/characters/viking/actions.png")
	var cell := Vector2(img.get_size()) / Vector2(4, 2)
	for row in 2:
		for col in 4:
			var bounds := Rect2i()
			var first := true
			for y in range(int(row * cell.y), int((row + 1) * cell.y)):
				for x in range(int(col * cell.x), int((col + 1) * cell.x)):
					if img.get_pixel(x, y).a < 0.5: continue
					if first:
						bounds = Rect2i(x, y, 1, 1)
						first = false
					else: bounds = bounds.expand(Vector2i(x, y))
			print(row, ",", col, " ", bounds, " center ", bounds.get_center())
	quit()
