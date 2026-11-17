extends SceneTree
## --script res://tests/run_after_autoloads.gd -- survival_integration
## Deferred loading lets suites using Ship see the newer map/pause autoloads.
func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0].is_valid_identifier():
		push_error("Pass one test script name without its .gd extension.")
		quit(1)
		return
	var suite := load("res://tests/%s.gd" % args[0]) as Script
	if suite == null:
		quit(1)
		return
	set_script(suite)
	call("_initialize")
