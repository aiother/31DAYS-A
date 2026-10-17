extends "res://tests/test_platform_pursuit.gd"

func pursuit() -> EnemyPlatformPursuit:
	return (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit

func descend(kind: String, direction: float) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	var upper_x: float = 600 if direction>0 else 1000
	solid(Vector2(upper_x,560),Vector2(256,32))
	solid(Vector2(upper_x+direction*224,736),Vector2(256,32))
	target.position = Vector2(upper_x+direction*440,896)
	spawn(kind,Vector2(upper_x,544))
	var middle: bool = false
	var bottom: bool = false
	var no_hop: bool = true
	var pause_checked: bool = false
	var physical: bool = true
	for i: int in range(360):
		var before: Vector2 = actor.position
		var frame: int = Engine.get_physics_frames()
		await ticks(1)
		physical = physical and absf(actor.position.x-before.x)<=actor.config.speed*(Engine.get_physics_frames()-frame)/Engine.physics_ticks_per_second+2
		no_hop = no_hop and actor.position.y>=540 and actor.velocity.y>=-1
		if not pause_checked and pursuit().descending and not actor.is_on_floor():
			pause_checked = true
			var point: Vector2 = actor.position
			var remaining: float = pursuit().travel_remaining
			paused = true
			await ticks(3)
			check(actor.position==point and pursuit().travel_remaining==remaining,kind+" pause freezes descent and route timeout")
			paused = false
		if actor.is_on_floor() and absf(actor.position.y-720)<4: middle = true
		if actor.is_on_floor() and absf(actor.position.y-896)<4:
			bottom = true
			break
	check(middle and bottom,kind+" descends via intermediate landing to lower target side=%s actual=%s" % [direction,actor.position])
	check(no_hop and physical,kind+" steps off naturally without upward jump or teleport")
	await ticks(20)
	check(actor.is_on_floor() and absf(actor.position.y-896)<4 and actor.state!=ColorlessEntity.State.IDLE,kind+" resumes existing chase/combat on lower floor")
	await clean()

func directly_below(kind: String) -> void:
	solid(Vector2(960,740),Vector2(2200,40))
	solid(Vector2(600,560),Vector2(256,32))
	# Only 14px of clearance over the standing body: descent must not hop.
	solid(Vector2(600,434),Vector2(1200,32))
	target.position = Vector2(600,720)
	spawn(kind,Vector2(600,544))
	var reached: bool = false
	var natural: bool = true
	for i: int in range(240):
		await ticks(1)
		natural = natural and actor.position.y>=540
		if actor.is_on_floor() and absf(actor.position.y-720)<4:
			reached = true
			break
	check(reached and natural,kind+" leaves edge for target directly below despite low ceiling; actual "+str(actor.position))
	await clean()

func safe_drop(kind: String, with_floor: bool) -> void:
	solid(Vector2(600,560),Vector2(256,32))
	if with_floor: solid(Vector2(960,1020),Vector2(2200,40))
	target.position = Vector2(1000,1000)
	spawn(kind,Vector2(600,544))
	await ticks(90)
	check(actor.is_on_floor() and actor.position.y<548 and actor.position.x<730,kind+" rejects "+("456px drop beyond configured limit" if with_floor else "void without lower landing"))
	await clean()

func cancel_route(kind: String) -> void:
	solid(Vector2(960,740),Vector2(2200,40))
	solid(Vector2(600,560),Vector2(256,32))
	target.position = Vector2(950,720)
	spawn(kind,Vector2(600,544))
	await ticks(3)
	check(pursuit().active and pursuit().descending and actor.is_on_floor(),kind+" plans lower landing before crossing edge")
	target.position = Vector2(600,544)
	await ticks(2)
	check(not pursuit().descending and actor.is_on_floor(),kind+" abandons grounded descent when target returns to same height")
	await clean()
	solid(Vector2(960,740),Vector2(2200,40))
	solid(Vector2(600,560),Vector2(256,32))
	target.position = Vector2(950,720)
	spawn(kind,Vector2(600,544))
	await ticks(3)
	check(pursuit().active and actor.request_interrupt(ColorlessEntity.InterruptReason.STAGGER,Vector2.ZERO,0.4) and not pursuit().active,kind+" stagger cancels active lower route using existing interrupt hook")
	var before: Vector2 = actor.position
	await ticks(8)
	check(actor.position.distance_to(before)<3 and actor.state==ColorlessEntity.State.STUN,kind+" descent does not override hit stun")
	await clean()

func configured_drop(kind: String) -> void:
	solid(Vector2(960,740),Vector2(2200,40))
	solid(Vector2(600,560),Vector2(256,32))
	target.position = Vector2(950,720)
	spawn(kind,Vector2(600,544))
	if actor is MonochromeEntity: (actor.config as MonochromeConfig).pursuit_max_drop = 128
	else: (actor.config as TianConfig).pursuit_max_drop = 128
	await ticks(60)
	check(actor.is_on_floor() and absf(actor.position.y-544)<4,kind+" respects per-actor drop tuning below step height")
	if actor is MonochromeEntity: (actor.config as MonochromeConfig).pursuit_max_drop = 256
	else: (actor.config as TianConfig).pursuit_max_drop = 256
	var reached: bool = false
	for i: int in range(150):
		await ticks(1)
		if actor.is_on_floor() and absf(actor.position.y-720)<4:
			reached = true
			break
	check(reached,kind+" replans and descends when safe drop tuning permits landing")
	await clean()

func actual_trench(kind: String) -> void:
	var room: WorldRoom = (load("res://world/rooms/nszc_10002_1.tscn") as PackedScene).instantiate() as WorldRoom
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = Vector2(448,1792)
	spawn(kind,Vector2(1344,1008))
	var landed: Dictionary = {}
	var reached: bool = false
	for i: int in range(540):
		await ticks(1)
		if actor.is_on_floor():
			landed[roundi(actor.position.y)] = true
			if absf(actor.position.y-1792)<4:
				reached = true
				break
	check(reached,kind+" follows lower target down actual trench platforms to TileMap floor; actual "+str(actor.position))
	check(landed.size()>=4,kind+" uses multiple real Room landings instead of falling past the staircase")
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
		await descend(kind,1)
		await descend(kind,-1)
		await directly_below(kind)
		await safe_drop(kind,false)
		await safe_drop(kind,true)
		await cancel_route(kind)
		await configured_drop(kind)
		await actual_trench(kind)
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("PLATFORM_DESCENT_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
