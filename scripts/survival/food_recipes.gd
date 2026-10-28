class_name FoodRecipes
extends RefCounted
## Small deterministic table. Stars describe preparation, never recipe safety.
const INGREDIENTS: Array[StringName] = [&"fish_cod", &"potato"]
const RECIPES: Array[Dictionary] = [
	{"id": "grilled_cod", "name": "Grilled cod", "fish": 1, "potato": 0, "hunger": 28.0, "healing": 12.0},
	{"id": "roasted_potato", "name": "Roasted potato", "fish": 0, "potato": 1, "hunger": 24.0, "healing": 8.0},
	{"id": "fish_skillet", "name": "Fish & potato skillet", "fish": 1, "potato": 1, "hunger": 55.0, "healing": 25.0},
	# Fictional game recipe, not a real food-safety claim.
	{"id": "horrible_mash", "name": "Horrible galley mash", "fish": 2, "potato": 1, "hunger": 0.0, "healing": 0.0, "poison": 0.4},
]

static func resolve(fish: int, potato: int) -> Dictionary:
	if fish < 0 or potato < 0 or fish + potato < 1 or fish + potato > 3:
		return {}
	for recipe in RECIPES:
		if recipe.fish == fish and recipe.potato == potato:
			return recipe.duplicate(true)
	return {"id": "mixed_skillet", "name": "Mixed skillet", "fish": fish, "potato": potato,
		"hunger": 18.0 * (fish + potato), "healing": 5.0 * (fish + potato)}

static func prepare(recipe: Dictionary, stars: int) -> Dictionary:
	if recipe.is_empty():
		return {}
	var meal := recipe.duplicate(true)
	meal["stars"] = clampi(stars, 0, 3)
	meal["poison"] = maxf(float(meal.get("poison", 0.0)), 0.3 if stars <= 0 else 0.0)
	if float(meal.poison) > 0.0:
		meal["name"] = "Poisonous " + str(meal.name)
		meal["healing"] = 0.0
		meal["hunger"] = 0.0
	return meal
