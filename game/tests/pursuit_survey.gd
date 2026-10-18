extends "res://tests/test_platform_pursuit.gd"
## Accelerated 60 Hz physical execution plus directed all-point connectivity.
var shard: int = 0
var records: Array[Dictionary] = []
var simulations: int = 0
var pair_count: int = 0
var case_limit: int = 0
var layouts_override: Array[String] = []
const ROOMS: Array[String] = ["hd_10001_1","hd_10002_1","hd_10002_2","hd_10002_3","hd_10003_1","hd_10004_1","ty_10001_1","ty_10002_1","hd_20001_1","hd_20001_2","hd_20001_3","hd_20002_1","hd_20002_2","hd_20003_1","nszc_10001_1","nszc_10002_1","nszc_10002_2","nszc_10003_1","hd_10004_1_empty","final_battlefield"]
const ROOM_SCENES: Dictionary = {
	"hd_10001_1":preload("res://world/rooms/hd_10001_1.tscn"),
	"hd_10002_1":preload("res://world/rooms/hd_10002_1.tscn"),
	"hd_10002_2":preload("res://world/rooms/hd_10002_2.tscn"),
	"hd_10002_3":preload("res://world/rooms/hd_10002_3.tscn"),
	"hd_10003_1":preload("res://world/rooms/hd_10003_1.tscn"),
	"hd_10004_1":preload("res://world/rooms/hd_10004_1.tscn"),
	"ty_10001_1":preload("res://world/rooms/ty_10001_1.tscn"),
	"ty_10002_1":preload("res://world/rooms/ty_10002_1.tscn"),
	"hd_20001_1":preload("res://world/rooms/hd_20001_1.tscn"),
	"hd_20001_2":preload("res://world/rooms/hd_20001_2.tscn"),
	"hd_20001_3":preload("res://world/rooms/hd_20001_3.tscn"),
	"hd_20002_1":preload("res://world/rooms/hd_20002_1.tscn"),
	"hd_20002_2":preload("res://world/rooms/hd_20002_2.tscn"),
	"hd_20003_1":preload("res://world/rooms/hd_20003_1.tscn"),
	"nszc_10001_1":preload("res://world/rooms/nszc_10001_1.tscn"),
	"nszc_10002_1":preload("res://world/rooms/nszc_10002_1.tscn"),
	"nszc_10002_2":preload("res://world/rooms/nszc_10002_2.tscn"),
	"nszc_10003_1":preload("res://world/rooms/nszc_10003_1.tscn"),
	"final_battlefield":preload("res://world/rooms/final_battlefield.tscn")
}

func navigation() -> EnemyPlatformPursuit:
	return (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit

func quiet(node: Node) -> void:
	node.set_physics_process(false)
	for child: Node in node.get_children():
		quiet(child)

func run_case(kind: String, room: WorldRoom, graph: EnemyPlatformRoutes, a: int, b: int, limit: int) -> Dictionary:
	var probe: Node2D = Node2D.new()
	room.add_child(probe)
	actor = (ACTORS[kind] as PackedScene).instantiate() as ColorlessEntity
	actor.position = graph.points[a]
	actor.target = target
	probe.add_child(actor)
	actor.alert_to_target()
	target.position = graph.points[b]
	await ticks(2)
	var p: EnemyPlatformPursuit = navigation()
	p.graph = graph
	p.graph_mode = true
	p._graph_target = target.position
	var arrived: bool = false
	var last: Vector2 = actor.position
	var stationary: int = 0
	var max_stationary: int = 0
	var elapsed: int = 0
	for frame: int in range(limit):
		await ticks(1)
		elapsed = frame+1
		if actor.position.distance_to(last)>2:
			stationary = 0
			last = actor.position
		elif actor.state in [ColorlessEntity.State.CHASE,ColorlessEntity.State.IDLE] and p.cooldown<=0:
			stationary += 1
		max_stationary = maxi(max_stationary,stationary)
		var fighting: bool = actor.state in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE,ColorlessEntity.State.RECOVERY] and actor._can_see_target() and actor.position.distance_to(target.position)<=actor.config.ranged_range
		if actor.is_on_floor() and absf(actor.position.y-target.position.y)<5 and (absf(actor.position.x-target.position.x)<maxf(96,actor.config.melee_range) or fighting):
			arrived = true
			break
	var result: Dictionary = {"a":a,"b":b,"arrived":arrived and max_stationary<=120,"frames":elapsed,"max_stationary":max_stationary,"position":[actor.position.x,actor.position.y],"intent":p.intent}
	probe.queue_free()
	await ticks(2)
	simulations += 1
	return result

func create_room(name: String) -> WorldRoom:
	var scene_name: String = name.trim_suffix("_empty").trim_suffix("_open").trim_suffix("_return")
	var room: WorldRoom = (ROOM_SCENES[scene_name] as PackedScene).instantiate() as WorldRoom
	world.add_child(room)
	quiet(room)
	# Include the Boss's runtime staircase, which changes its geometry in combat.
	if room is BossRoom and not name.ends_with("_empty"):
		(room as BossRoom).summon_platforms()
	if room is FinalBattlefieldRoom:
		for point: Vector2 in (room as FinalBattlefieldRoom).battle.platform_positions:
			var platform: Node2D = (load("res://world/scenes/platform.tscn") as PackedScene).instantiate() as Node2D
			platform.position = point
			room.get_node("FinalPlatforms").add_child(platform)
	if room is CampWavesRoom and name.ends_with("_open"):
		(room as CampWavesRoom)._open_exits()
	if room is TrenchPassageRoom and (name.ends_with("_return") or name.ends_with("_open")):
		var events: Dictionary = {TrenchPassageRoom.CLEARED:true}
		if name.ends_with("_open"):
			events[TrenchPassageRoom.CHALLENGE] = true
			events[TrenchPassageRoom.FORWARD] = true
		(room as TrenchPassageRoom).refresh(events)
	if room is FinalBattlefieldRoom and name.ends_with("_open"):
		(room.get_node("LeftBoundary") as StaticBody2D).collision_layer = 0
	await ticks(2)
	return room

func survey(name: String, kind: String) -> void:
	var room: WorldRoom = await create_room(name)
	spawn(kind,room.config.entry_from_previous)
	actor.reparent(room)
	actor.set_physics_process(false)
	await ticks(2)
	var p: EnemyPlatformPursuit = navigation()
	var jump: float = (actor.config as MonochromeConfig).jump_speed if actor is MonochromeEntity else (actor.config as TianConfig).jump_speed
	var drop: float = (actor.config as MonochromeConfig).pursuit_max_drop if actor is MonochromeEntity else (actor.config as TianConfig).pursuit_max_drop
	var graph: EnemyPlatformRoutes = EnemyPlatformRoutes.obtain(actor,p,jump,drop)
	while not graph.ready:
		graph.advance(actor,p,10000)
		await ticks(1)
	actor.queue_free()
	await ticks(2)
	var n: int = graph.points.size()
	check(n>0,name+" "+kind+" exposes collision-supported survey points")
	var reachability: Array[Array] = []
	var selected: Dictionary = {}
	var inaccessible: Dictionary = {}
	var reachable_pairs: int = 0
	var unreachable_pairs: int = 0
	for a: int in range(n):
		var reached: Array[bool] = []
		reached.resize(n)
		reached.fill(false)
		reached[a] = true
		var queue: Array[int] = [a]
		while not queue.is_empty():
			var at: int = queue.pop_front()
			for edge: Dictionary in graph.edges[at]:
				var b: int = edge["b"]
				if not reached[b]:
					reached[b] = true
					queue.append(b)
		reachability.append(reached)
		var far: int = a
		var blocked_goal: int = -1
		for b: int in range(n):
			if a==b:
				continue
			pair_count += 1
			if reached[b]:
				reachable_pairs += 1
				if graph.points[a].distance_to(graph.points[b])>graph.points[a].distance_to(graph.points[far]):
					far = b
			else:
				unreachable_pairs += 1
				if blocked_goal<0 or graph.points[a].distance_to(graph.points[b])<graph.points[a].distance_to(graph.points[blocked_goal]):
					blocked_goal = b
		if far!=a:
			selected["%d:%d" % [a,far]] = Vector2i(a,far)
		if blocked_goal>=0:
			inaccessible["%d:%d" % [a,blocked_goal]] = Vector2i(a,blocked_goal)
	# Every point is also used as a destination from its farthest valid source.
	for b: int in range(n):
		var far: int = b
		for a: int in range(n):
			if reachability[a][b] and graph.points[a].distance_to(graph.points[b])>graph.points[far].distance_to(graph.points[b]):
				far = a
		if far!=b:
			selected["%d:%d" % [far,b]] = Vector2i(far,b)
	var failed: Array[Dictionary] = []
	print("SURVEY_BEGIN ",name," ",kind," nodes=",n," cases=",selected.size())
	var completed: int = 0
	var max_stall: int = 0
	var tested_pairs: Array = []
	for key: String in selected:
		if case_limit>0 and completed>=case_limit:
			break
		var ids: Vector2i = selected[key]
		var result: Dictionary = await run_case(kind,room,graph,ids.x,ids.y,2400)
		completed += 1
		max_stall = maxi(max_stall,int(result["max_stationary"]))
		tested_pairs.append([ids.x,ids.y])
		print("SURVEY_CASE ",name," ",kind," ",key," ",JSON.stringify(result))
		if not result["arrived"]:
			failed.append(result)
	var coordinates: Array = []
	var recovery_failed: Array[Dictionary] = []
	var recovery_count: int = 0
	if case_limit==0:
		for key: String in inaccessible:
			var ids: Vector2i = inaccessible[key]
			var result: Dictionary = await unreachable_case(kind,room,graph,ids.x,ids.y)
			recovery_count += 1
			if not result["recovered"]:
				recovery_failed.append(result)
	for point: Vector2 in graph.points:
		coordinates.append([point.x,point.y])
	var bitmaps: Array[String] = []
	for row: Array in reachability:
		var bits: String = ""
		for value: bool in row:
			bits += "1" if value else "0"
		bitmaps.append(bits)
	records.append({"room":name,"kind":kind,"points":coordinates,"reachability":bitmaps,"tested_pairs":tested_pairs,"max_stationary_frames":max_stall,"reachable_pairs":reachable_pairs,"unreachable_pairs":unreachable_pairs,"physical_cases":completed,"unreachable_recovery_cases":recovery_count,"recovery_failures":recovery_failed,"failures":failed})
	check(failed.is_empty(),name+" "+kind+" physical all-point start/goal coverage failures="+str(failed))
	check(recovery_failed.is_empty(),name+" "+kind+" unreachable targets retain live decisions and recover="+str(recovery_failed))
	print("SURVEY ",name," ",kind," nodes=",n," pairs=",n*(n-1)," cases=",selected.size()," failed=",failed.size())
	room.queue_free()
	await ticks(2)

func unreachable_case(kind: String, room: WorldRoom, graph: EnemyPlatformRoutes, a: int, b: int) -> Dictionary:
	var probe: Node2D = Node2D.new()
	room.add_child(probe)
	actor = (ACTORS[kind] as PackedScene).instantiate() as ColorlessEntity
	actor.position = graph.points[a]
	actor.target = target
	probe.add_child(actor)
	actor.alert_to_target()
	target.position = graph.points[b]
	await ticks(2)
	var p: EnemyPlatformPursuit = navigation()
	p.graph = graph
	p.graph_mode = true
	p._graph_target = target.position
	var live: bool = false
	for i: int in range(180):
		await ticks(1)
		if i>=120:
			var fighting: bool = actor.state in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE,ColorlessEntity.State.RECOVERY] and actor._can_see_target() and actor.position.distance_to(target.position)<=actor.config.ranged_range
			live = live or (p.graph_mode and not p.intent.is_empty()) or fighting
	for i: int in range(180):
		if actor.is_on_floor():
			break
		await ticks(1)
	target.position = actor.position
	var recovered: bool = false
	for i: int in range(240):
		await ticks(1)
		if actor.state in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE] and actor._can_see_target():
			recovered = true
			break
	var result: Dictionary = {"a":a,"b":b,"decision_live":live,"recovered":live and recovered,"intent":p.intent}
	probe.queue_free()
	await ticks(2)
	simulations += 1
	return result

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	var only: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			only = arg.trim_prefix("--room=")
		if arg.begins_with("--case-limit="):
			case_limit = int(arg.trim_prefix("--case-limit="))
	var layouts: Array[String] = ROOMS if layouts_override.is_empty() else layouts_override
	for index: int in range(layouts.size()):
		if (not only.is_empty() and layouts[index]!=only) or (only.is_empty() and layouts_override.is_empty() and index%4!=shard):
			continue
		for kind: String in ["monochrome_entity","tian_warrior"]:
			await survey(layouts[index],kind)
	var directory: String = ProjectSettings.globalize_path("res://").path_join("../outputs")
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(directory.path_join("pursuit_survey_%d.json" % shard),FileAccess.WRITE)
	file.store_string(JSON.stringify({"shard":shard,"records":records,"physical_simulations":simulations,"ordered_pairs":pair_count},"\t"))
	file.close()
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	# Accelerated simulation must still give the real audio mixer time to release
	# short warning streams after all players have been freed.
	OS.delay_msec(250)
	print("PURSUIT_SURVEY_%s_TESTS checks=%d failures=%d" % [String.chr(65+shard),checks,failures])
	quit(1 if failures else 0)
