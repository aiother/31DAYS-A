# verify-suite: {"name": "all-Room flying monochrome detours and recovery", "path": "res://tests/test_air_pursuit.gd", "marker": "AIR_PURSUIT_TESTS checks=", "fixed_fps": 60, "timeout": 180}
extends "res://tests/pursuit_survey.gd"
## Advanced flying unit: actual body traversal in every delivered layout.
var air_records: Array[Dictionary] = []

func dynamic_flight() -> void:
	var room: WorldRoom = await create_room("hd_20001_1")
	target.position = Vector2(32,96)
	var flyer: MonochromeEntity = (ACTORS["monochrome_entity"] as PackedScene).instantiate() as MonochromeEntity
	flyer.flying = true
	flyer.ranged_only = true
	flyer.position = Vector2(2528,1248)
	flyer.target = target
	room.add_child(flyer)
	flyer.alert_to_target()
	for i: int in range(600):
		await ticks(1)
		if not flyer.air_pursuit.path.is_empty():
			break
	check(not flyer.air_pursuit.path.is_empty(),"flying unit begins actual detour")
	var point: Vector2 = flyer.position
	var time: float = flyer.air_pursuit._clock
	paused = true
	await ticks(5)
	check(flyer.position==point and flyer.air_pursuit._clock==time,"pause freezes flying route and recovery deadlines")
	paused = false
	flyer.hurtbox.receive_attack(1,Vector2(80,-40),target,19783)
	check(flyer.state==ColorlessEntity.State.STUN and flyer.air_pursuit.path.is_empty(),"actual hit cancels vulnerable flying route")
	var body: StaticBody2D = solid(Vector2(2300,600),Vector2(80,32))
	body.reparent(room)
	var signature: int = flyer.air_pursuit._data["signature"]
	await ticks(70)
	check(int(flyer.air_pursuit._data["signature"])!=signature,"new solid platform invalidates flying occupancy cache")
	flyer.target = null
	await ticks(2)
	check(flyer.state==ColorlessEntity.State.IDLE and flyer.air_pursuit.path.is_empty(),"lost target clears flying route")
	target.position = Vector2(2528,1248)
	flyer.target = target
	flyer.alert_to_target()
	var resumed: bool = false
	for i: int in range(1200):
		await ticks(1)
		if flyer.state==ColorlessEntity.State.WINDUP and flyer._can_see_target():
			resumed = true
			break
	check(resumed,"reacquired moved target resumes actual flying attack")
	geometry.erase(body)
	room.queue_free()
	await ticks(2)

func flight_case(room: WorldRoom, from: Vector2, to: Vector2) -> Dictionary:
	target.position = to
	var flyer: MonochromeEntity = (ACTORS["monochrome_entity"] as PackedScene).instantiate() as MonochromeEntity
	flyer.flying = true
	flyer.ranged_only = true
	flyer.position = from
	flyer.target = target
	room.add_child(flyer)
	flyer.alert_to_target()
	var arrived: bool = false
	var physical: bool = true
	var stationary: int = 0
	var longest: int = 0
	var last: Vector2 = from
	var frames: int = 0
	for i: int in range(3600):
		var before: Vector2 = flyer.position
		var step: int = Engine.get_physics_frames()
		await ticks(1)
		frames = i+1
		physical = physical and flyer.position.distance_to(before)<=600.0*(Engine.get_physics_frames()-step)/60.0+2
		if flyer.position.distance_to(last)>2:
			last = flyer.position
			stationary = 0
		elif flyer.state in [ColorlessEntity.State.CHASE,ColorlessEntity.State.IDLE] and flyer.air_pursuit.intent!="规划空中路径":
			stationary += 1
		longest = maxi(longest,stationary)
		if flyer._can_see_target() and flyer.position.distance_to(target.position)<=flyer.config.ranged_range and flyer.state in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE]:
			arrived = true
			break
	var result: Dictionary = {"from":[from.x,from.y],"to":[to.x,to.y],"arrived":arrived,"physical":physical,"frames":frames,"max_stationary":longest,"position":[flyer.position.x,flyer.position.y],"intent":flyer.air_pursuit.intent}
	flyer.queue_free()
	await ticks(2)
	return result

func air_layout(name: String) -> void:
	var room: WorldRoom = await create_room(name)
	var flyer: MonochromeEntity = (ACTORS["monochrome_entity"] as PackedScene).instantiate() as MonochromeEntity
	flyer.flying = true
	flyer.target = target
	flyer.position = room.config.entry_from_previous
	room.add_child(flyer)
	flyer.set_physics_process(false)
	var p: EnemyAirPursuit = flyer.air_pursuit
	p._data = p._obtain(flyer)
	while not p._data["ready"]:
		p._advance(flyer)
		await ticks(1)
	var grid: AStarGrid2D = p._data["grid"]
	var free: Array[Vector2i] = []
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			if not grid.is_point_solid(Vector2i(x,y)):
				free.append(Vector2i(x,y))
	var selected: Dictionary = {}
	# Extremes and points separated by actual platforms/walls. Only connected
	# full-body free cells are route cases; sealed gates retain their collision.
	var anchors: Array[Vector2i] = [free[0],free[-1]]
	var rects: Array[Rect2] = []
	EnemyPlatformRoutes.new()._collect_shapes(room,rects)
	for rect: Rect2 in rects:
		var above: Vector2i = Vector2i((Vector2(rect.get_center().x,rect.position.y-32)-grid.offset)/32)
		var below: Vector2i = Vector2i((Vector2(rect.get_center().x,rect.end.y+96)-grid.offset)/32)
		if grid.is_in_boundsv(above) and grid.is_in_boundsv(below) and not grid.is_point_solid(above) and not grid.is_point_solid(below):
			if not grid.get_id_path(above,below).is_empty():
				selected[Vector4i(above.x,above.y,below.x,below.y)] = true
				selected[Vector4i(below.x,below.y,above.x,above.y)] = true
	for a: Vector2i in anchors:
		var far: Vector2i = a
		for b: Vector2i in free:
			if a.distance_squared_to(b)>a.distance_squared_to(far) and not grid.get_id_path(a,b).is_empty():
				far = b
		if far!=a:
			selected[Vector4i(a.x,a.y,far.x,far.y)] = true
	flyer.queue_free()
	await ticks(2)
	var cases: Array[Dictionary] = []
	for pair: Vector4i in selected.keys():
		var result: Dictionary = await flight_case(room,grid.get_point_position(Vector2i(pair.x,pair.y)),grid.get_point_position(Vector2i(pair.z,pair.w)))
		cases.append(result)
		if not result["arrived"] or not result["physical"] or int(result["max_stationary"])>120:
			print("AIR_FAILURE ",name," ",JSON.stringify(result))
	var passed: bool = not cases.is_empty()
	for result: Dictionary in cases:
		passed = passed and result["arrived"] and result["physical"] and int(result["max_stationary"])<=120
	check(passed,name+" flying monochrome bypasses platforms with continuous physical movement: "+str(cases.size())+" cases")
	air_records.append({"room":name,"free_cells":free.size(),"cases":cases,"passed":passed})
	room.queue_free()
	await ticks(2)

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	target = Node2D.new()
	world.add_child(target)
	var layouts: Array[String] = ROOMS.duplicate()
	layouts.append_array(["hd_20002_2_open","nszc_10002_2_return","nszc_10002_2_open","final_battlefield_open"])
	for name: String in layouts:
		await air_layout(name)
	var dynamic_before: int = checks
	await dynamic_flight()
	var output: String = ProjectSettings.globalize_path("res://../outputs/pursuit_air.json")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file: FileAccess = FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"records":air_records,"dynamic_checks":checks-dynamic_before,"failures":failures},"\t"))
	file.close()
	world.queue_free()
	await ticks(2)
	OS.delay_msec(250)
	print("AIR_PURSUIT_TESTS checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
