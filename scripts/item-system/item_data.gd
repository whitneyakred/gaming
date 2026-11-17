class_name ItemData
extends Resource

enum Category {
	FOOD,
	MATERIAL,
	TOOL,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var max_stack: int = 1
@export var icon: Texture2D
@export var category: Category = Category.FOOD
@export_range(0.01, 1000.0, 0.01) var draw_weight: float = 1.0
@export_range(0, 999999, 1) var sell_value: int = 0
