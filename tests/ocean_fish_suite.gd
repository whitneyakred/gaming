extends Node
@onready var root: Window = get_tree().root
var checks := 0
var failures := 0
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	for cell in [Vector2i.ZERO, Vector2i(-17,23), Vector2i(120000,-90000)]:
		var host := FishSchool.create(71923, cell)
		var peer := FishSchool.create(71923, cell)
		check(host == peer, "Joining peers reconstruct identical school descriptors")
		for time in [0.0, 16.3, 70.0, 70000.0]:
			for i in host.members.size():
				var a := FishSchool.pose(host, host.members[i], time)
				var b := FishSchool.pose(peer, peer.members[i], time)
				check(a == b, "Peer position does not depend on animation or frame rate")
				check(a.origin.distance_to(host.center) + float(host.members[i].length) < FishSchool.CLEARANCE, "Entire fish fits reserved water envelope")
		for i in 20:
			var knot := float(i) * 13.7 - float(host.phase)
			var before := FishSchool.pose(host, host.members[0], knot-0.0001)
			var after := FishSchool.pose(host, host.members[0], knot+0.0001)
			check(before.origin.distance_to(after.origin) < 0.1, "Independent paths remain continuous")
		check(FishSchool.visibility(host, -float(host.phase)) == 0.0, "School fades through its lifecycle boundary")
		check(FishSchool.visibility(host, -float(host.phase)+10.0) == 1.0, "School is visible after arrival")
		# Measure local travel before world-coordinate float precision at distant cells.
		var local_school := host.duplicate()
		local_school.center = Vector2.ZERO
		for member: Dictionary in host.members:
			for tick in 180:
				var time := tick*0.37
				var before := FishSchool.pose(local_school, member, time).origin
				var after := FishSchool.pose(local_school, member, time+1.0/60.0).origin
				check(before.distance_to(after)*60.0 > float(member.speed)*0.45, "Fish keeps travelling instead of treading water at bends")
				check(before.distance_to(after)*60.0 < float(member.speed)*1.4, "Independent motion stays within cruising/burst speed limits")
				check(before.length()+FishSchool.ESCAPE_RANGE+float(member.length) < FishSchool.CLEARANCE, "Full fish plus maximum evasion stays clear of land")
		if host.members.size() > 1:
			check(host.members[0].path != host.members[1].path, "Neighbors have independent routes, not leader-following copies")
	check(FishSchool.animation_rate(0.0,30.0) == 0.0, "Stationary fish do not thrash their tails")
	check(FishSchool.animation_rate(20.0,30.0) < FishSchool.animation_rate(50.0,30.0), "Tail beats increase with movement speed")
	var threats: Array[Vector3] = [Vector3(0,0,115)]
	var empty_threats: Array[Vector3] = []
	for fps in [30,60,120]:
		var escape: Dictionary = {}
		var before := Vector2.ZERO
		for tick in fps*6:
			var next := FishSchool.advance_escape(escape,Transform2D(0,Vector2(30,0)),threats,1.0/fps)
			check(next.distance_to(before) <= 100.0/fps+0.001, "Escape cannot snap between positions")
			check(next.length() <= FishSchool.ESCAPE_RANGE+0.001, "Escape remains in reserved water")
			before = next
		check(before.x > 60.0, "Fish stays displaced while its return path is blocked")
		var held := before.x
		for tick in fps*2:
			before = FishSchool.advance_escape(escape,Transform2D(0,Vector2(30,0)),empty_threats,1.0/fps)
		check(before.x > held-5.0, "Fish waits after danger clears instead of snapping home")
		for tick in fps*24:
			var next := FishSchool.advance_escape(escape,Transform2D(0,Vector2(30,0)),empty_threats,1.0/fps)
			check(next.distance_to(before) <= 12.0/fps+0.001, "Return is slow and speed limited")
			before = next
		check(before.length() < 2.0, "Undisturbed fish eventually returns")
	var species_counts := [0,0,0,0,0,0]
	for index in 12:
		var menu := FishSchool.create_menu(74219,index,Vector2.ZERO)
		species_counts[int(menu.species)] += menu.members.size()
	for count in species_counts: check(count == 2, "Title menu has equal populations of all six species")
	var field := OceanFish.new()
	field.menu_mode = true
	root.add_child(field)
	field.set_process(false)
	field.menu_mode = false
	field.configure(71923, [])
	field.refresh(Vector2.ZERO)
	var original: Dictionary = field.schools[Vector2i.ZERO].duplicate(true)
	for i in 100:
		field.refresh(Vector2(i*12000, -i*8000))
		check(field.schools.size() <= 25, "Indefinite travel never grows the school cache")
	field.refresh(Vector2.ZERO)
	check(field.schools[Vector2i.ZERO].seed == original.seed, "Revisiting an evicted cell preserves its school")
	field._local_time = 20.0
	field.synchronize(1234.0)
	check(absf(field.shared_time()-1234.0) < 0.02, "Late join starts at host time")
	field._navigation.obstacles.clear()
	field._navigation.obstacles.append(PackedVector2Array([Vector2(-5000,-5000),Vector2(5000,-5000),Vector2(5000,5000),Vector2(-5000,5000)]))
	field._navigation.prepare()
	field.schools.clear()
	field._last_cell = Vector2i(99999,99999)
	field.refresh(Vector2.ZERO)
	for school: Dictionary in field.schools.values():
		check(not school.water, "Schools on land are rejected")
	field.render_fish(Vector2.ZERO, Vector2(800,450), 30.0)
	check(field.visible_fish == 0, "No land fish reach the renderer")
	field.configure(71923, [])
	field.refresh(Vector2.ZERO)
	field._local_time += 3.0
	var started := Time.get_ticks_usec()
	for i in 300:
		field.render_fish(Vector2.ZERO, Vector2(800,450), 30.0 + i/60.0)
	check(field.visible_fish > 0 and field.visible_fish <= field.max_fish, "Visible field respects its fixed fish budget")
	print("FISH CPU: ", (Time.get_ticks_usec()-started)/300.0, " us/update, ", field.visible_fish, " visible fish")
	field.queue_free()
	await get_tree().process_frame
	print("OCEAN FISH: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
