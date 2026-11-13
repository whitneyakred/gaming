extends SceneTree
## Run with Godot --headless --path . --script res://tests/item_system_test.gd

const ITEM_DATABASE_SCRIPT := preload("res://scripts/item-system/item_database.gd")

var failures: int = 0
var checks_run: int = 0
var item_database: Node

func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var invalid_case_index := arguments.find("--invalid-case")
	if invalid_case_index != -1:
		if invalid_case_index + 1 >= arguments.size():
			push_error("Item-system validation test requires an invalid-case name.")
			quit(2)
			return
		create_timer(0.1).timeout.connect(func() -> void:
			quit(0)
		)
		_run_invalid_case(arguments[invalid_case_index + 1])
		return

	item_database = root.get_node_or_null(NodePath("ItemDatabase"))
	_run.call_deferred()

func _check(condition: bool, test_name: String, expected: String, actual: String) -> void:
	checks_run += 1
	if condition:
		return

	failures += 1
	push_error("Item-system test failed: %s\nExpected: %s\nActual: %s" % [
		test_name,
		expected,
		actual,
	])

func _check_equal(actual: Variant, expected: Variant, test_name: String) -> void:
	_check(
		actual == expected,
		test_name,
		var_to_str(expected),
		var_to_str(actual)
	)

func _test_registered_catalog() -> void:
	_check(item_database != null, "ItemDatabase autoload is available", "An ItemDatabase node at /root/ItemDatabase", var_to_str(item_database))
	if item_database == null:
		return

	var expected_items: Array[Dictionary] = [
		{
			"id": &"fish_cod",
			"display_name": "Cod",
			"description": "A common ocean fish.",
			"max_stack": 10,
			"category": ItemData.Category.FOOD,
		},
		{
			"id": &"rope",
			"display_name": "Rope",
			"description": "Strong cordage for general shipboard tasks.",
			"max_stack": 25,
			"category": ItemData.Category.MATERIAL,
		},
		{
			"id": &"fishing_rod",
			"display_name": "Fishing Rod",
			"description": "An old but useful tool for getting food and other items from the sea.",
			"max_stack": 1,
			"category": ItemData.Category.TOOL,
		},
		{
			"id": &"coconut",
			"display_name": "Coconut",
			"description": "A fresh coconut gathered from a tropical island.",
			"max_stack": 20,
			"category": ItemData.Category.FOOD,
		},
	]

	for expected_item in expected_items:
		var item_id: StringName = expected_item["id"]
		var item := item_database.call(&"get_item", item_id) as ItemData
		_check(item != null, "Catalog lookup: %s exists" % item_id, "A registered ItemData instance", var_to_str(item))
		if item == null:
			continue

		_check_equal(item.id, item_id, "Catalog item %s keeps its stable ID" % item_id)
		_check_equal(item.display_name, expected_item["display_name"], "Catalog item %s has its display name" % item_id)
		_check_equal(item.description, expected_item["description"], "Catalog item %s has its description" % item_id)
		_check_equal(item.max_stack, expected_item["max_stack"], "Catalog item %s has its stack limit" % item_id)
		_check_equal(item.category, expected_item["category"], "Catalog item %s has its category" % item_id)
		_check_equal(item.draw_weight, 1.0, "Catalog item %s uses the neutral draw weight" % item_id)
		_check_equal(item.sell_value, 0, "Catalog item %s uses the neutral sell value" % item_id)
		_check(item.icon == null, "Catalog item %s leaves the optional icon unassigned" % item_id, "No icon texture", var_to_str(item.icon))

	var missing_item := item_database.call(&"get_item", &"missing_item") as ItemData
	_check(missing_item == null, "Unknown item lookup", "null", var_to_str(missing_item))

	var all_items: Array = item_database.call(&"get_all_items")
	var island_ids: Array[StringName] = [&"gold_coin", &"wood", &"crab_meat", &"mango", &"banana", &"papaya", &"fresh_water", &"compass"]
	_check_equal(all_items.size(), expected_items.size() + island_ids.size(), "Catalog enumeration includes the island rewards")
	var found_ids: Dictionary[StringName, int] = {}
	for item in all_items:
		_check(item != null, "Catalog enumeration contains no null entries", "An ItemData instance", var_to_str(item))
		if item == null:
			continue
		found_ids[item.id] = found_ids.get(item.id, 0) + 1
	for item_id in island_ids:
		_check_equal(found_ids.get(item_id, 0), 1, "Island reward %s is registered exactly once" % item_id)

	for expected_item in expected_items:
		var item_id: StringName = expected_item["id"]
		_check_equal(found_ids.get(item_id, 0), 1, "Catalog enumeration contains %s exactly once" % item_id)

func _test_registration_validation() -> void:
	var invalid_cases: Array[Dictionary] = [
		{"name": "null_item", "error": "Cannot register a null item."},
		{"name": "empty_id", "error": "Items need an id."},
		{"name": "duplicate_id", "error": "Duplicate item id: duplicate_item"},
		{"name": "invalid_stack", "error": "Item max stack must be at least 1: invalid_stack"},
		{"name": "zero_weight", "error": "Item draw weight must be positive: invalid_weight"},
		{"name": "negative_weight", "error": "Item draw weight must be positive: invalid_weight"},
		{"name": "negative_value", "error": "Item sell value cannot be negative: invalid_value"},
	]

	for invalid_case in invalid_cases:
		var output: Array[String] = []
		var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://tests/item_system_test.gd",
			"--",
			"--invalid-case",
			invalid_case["name"],
		]), output, true)
		var output_text := "\n".join(output)
		_check(
			exit_code == 0,
			"Registry rejects %s" % invalid_case["name"],
			"A clean child-process exit after the validation assertion",
			"Exit code: %d\nProcess output:\n%s" % [exit_code, output_text]
		)
		_check(
			output_text.contains(invalid_case["error"]),
			"Registry reports the %s validation error" % invalid_case["name"],
			invalid_case["error"],
			output_text
		)

func _make_item(item_id: StringName) -> ItemData:
	var item := ItemData.new()
	item.id = item_id
	item.display_name = "Test Item"
	item.description = "Used only by item-system validation tests."
	return item

func _run_invalid_case(invalid_case: String) -> void:
	var database := ITEM_DATABASE_SCRIPT.new()
	match invalid_case:
		"null_item":
			database.register_item(null)
		"empty_id":
			database.register_item(_make_item(&""))
		"duplicate_id":
			var duplicate_item := _make_item(&"duplicate_item")
			database.register_item(duplicate_item)
			database.register_item(duplicate_item)
		"invalid_stack":
			var invalid_stack := _make_item(&"invalid_stack")
			invalid_stack.max_stack = 0
			database.register_item(invalid_stack)
		"zero_weight":
			var zero_weight := _make_item(&"invalid_weight")
			zero_weight.draw_weight = 0.0
			database.register_item(zero_weight)
		"negative_weight":
			var negative_weight := _make_item(&"invalid_weight")
			negative_weight.draw_weight = -1.0
			database.register_item(negative_weight)
		"negative_value":
			var negative_value := _make_item(&"invalid_value")
			negative_value.sell_value = -1
			database.register_item(negative_value)
		_:
			push_error("Unknown item-system validation case: %s" % invalid_case)
			quit(2)

func _run() -> void:
	_test_registered_catalog()
	_test_registration_validation()
	print("Item-system test: %d check(s), %d failure(s)" % [checks_run, failures])
	quit(0 if failures == 0 else 1)
