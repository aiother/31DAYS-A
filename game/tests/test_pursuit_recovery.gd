extends "res://tests/test_platform_pursuit.gd"

func navigation() -> EnemyPlatformPursuit:
	return (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit

func entry(kind: String, destination: Vector2) -> void:
	var room: WorldRoom = (load("res://world/rooms/hd_20001_1.tscn") as PackedScene).instantiate() as WorldRoom
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = destination
	spawn(kind,Vector2(1048,1152))
	var arrived: bool = false
	for i: int in range(1500):
		await ticks(1)
		if actor.is_on_floor() and absf(actor.position.y-target.position.y)<5 and absf(actor.position.x-target.position.x)<180:
			arrived = true
			break
	check(arrived,kind+" leaves raised block and follows multi-platform route to "+str(destination)+" actual="+str(actor.position)+" intent="+navigation().intent)
	if navigation().graph!=null:
		print("GRAPH nodes=",navigation().graph.points.size()," pending=",navigation().graph.pending.size()," ready=",navigation().graph.ready)
	await clean()
	room.queue_free()
	await ticks(2)

func pressure_and_return(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	target.position = Vector2(600,546)
	spawn(kind,Vector2(600,896))
	var attacks: Array[int] = [0]
	actor.attack_started.connect(func(_ranged: bool) -> void: attacks[0] += 1)
	var searching: bool = false
	for i: int in range(300):
		await ticks(1)
		searching = searching or navigation().no_path
	check(searching and attacks[0]>0,kind+" unreachable airborne target receives visible ranged pressure instead of idle lock")
	target.position = Vector2(900,896)
	var engaged: bool = false
	for i: int in range(480):
		await ticks(1)
		if actor.is_on_floor() and actor.position.distance_to(target.position)<190:
			engaged = true
			break
	check(engaged,kind+" resumes reachable pursuit when target returns to floor")
	await clean()

func stalled_route(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	solid(Vector2(520,736),Vector2(256,32))
	target.position = Vector2(520,720)
	spawn(kind,Vector2(300,896))
	await ticks(2)
	var p: EnemyPlatformPursuit = navigation()
	p.active = true
	p.airborne = false
	p.horizontal_speed = 0
	p.goal = Vector2(1000,720)
	p.travel_remaining = 100
	var reached: bool = false
	for i: int in range(600):
		await ticks(1)
		if actor.is_on_floor() and absf(actor.position.y-720)<5:
			reached = true
			break
	check(reached,kind+" watchdog escapes deliberately injected stationary route")
	await clean()

func jump_interrupt_and_loss(kind: String) -> void:
	var room: WorldRoom = (load("res://world/rooms/hd_20001_1.tscn") as PackedScene).instantiate() as WorldRoom
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = Vector2(1648,992)
	spawn(kind,Vector2(1048,1152))
	var jumped: bool = false
	for i: int in range(600):
		await ticks(1)
		if navigation().graph_mode and navigation().active and actor.velocity.y<0:
			jumped = true
			break
	check(jumped,kind+" starts a real graph-driven inter-platform jump")
	var before: Vector2 = actor.position
	var elapsed: float = navigation()._clock
	paused = true
	await ticks(5)
	check(actor.position==before and navigation()._clock==elapsed,kind+" pause freezes route and recovery deadlines")
	paused = false
	actor.hurtbox.receive_attack(1,Vector2(80,-40),target,19800)
	check(actor.state==ColorlessEntity.State.STUN and not navigation().active and not navigation().graph_mode,kind+" normal hit interrupts vulnerable traversal and cancels stale route")
	var reached: bool = false
	for i: int in range(1200):
		await ticks(1)
		if actor.is_on_floor() and absf(actor.position.y-992)<5:
			reached = true
			break
	check(reached,kind+" replans and resumes chase after real mid-jump damage")
	actor.target = null
	await ticks(2)
	check(not navigation().active and not navigation().graph_mode and actor.state==ColorlessEntity.State.IDLE,kind+" lost target clears route rather than retaining an orphaned pursuit")
	actor.target = target
	actor.alert_to_target()
	await ticks(90)
	check(actor.state!=ColorlessEntity.State.IDLE,kind+" re-acquires target after it returns")
	await clean()
	room.queue_free()
	await ticks(2)

func geometry_change(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	target.position = Vector2(744,544)
	spawn(kind,Vector2(300,896))
	var first: EnemyPlatformRoutes
	for i: int in range(180):
		await ticks(1)
		if navigation().graph!=null and navigation().graph.ready:
			first = navigation().graph
			break
	check(first!=null,kind+" creates bounded fallback graph for currently inaccessible geometry")
	solid(Vector2(520,736),Vector2(256,32))
	solid(Vector2(744,560),Vector2(256,32))
	var reached: bool = false
	for i: int in range(900):
		await ticks(1)
		if actor.is_on_floor() and absf(actor.position.y-544)<5:
			reached = true
			break
	check(reached and navigation().graph!=first,kind+" invalidates cached geometry and follows newly added platforms")
	await clean()

func corner_contact(kind: String) -> void:
	var room: WorldRoom = (load("res://world/rooms/hd_10002_2.tscn") as PackedScene).instantiate() as WorldRoom
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = Vector2(848,1056)
	spawn(kind,Vector2(990.2266,1060.6694))
	navigation().graph_mode = true
	var settled: bool = false
	for i: int in range(600):
		await ticks(1)
		if actor.is_on_floor() and navigation()._flat_contact(actor) and absf(actor.position.y-1056)<3:
			settled = true
			break
	check(settled,kind+" recovers a rounded capsule perched on an actual platform corner")
	await clean()
	room.queue_free()
	await ticks(2)

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	for kind: String in ["monochrome_entity","tian_warrior"]:
		for point: Vector2 in [Vector2(1424,1136),Vector2(1648,992),Vector2(1872,848)]:
			await entry(kind,point)
		await pressure_and_return(kind)
		await stalled_route(kind)
		await jump_interrupt_and_loss(kind)
		await geometry_change(kind)
		await corner_contact(kind)
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	OS.delay_msec(250)
	print("PURSUIT_RECOVERY_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
