# verify-suite: {"name": "platform detours around wide overhangs and real ravine video regression", "path": "res://tests/test_platform_detour.gd", "marker": "PLATFORM_DETOUR_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends "res://tests/test_platform_pursuit.gd"

func navigation() -> EnemyPlatformPursuit:
	return (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit

func actual_ravine(kind: String, upper: bool, mirrored: bool = false) -> void:
	var room: WorldRoom = (load("res://world/rooms/hd_20001_3.tscn") as PackedScene).instantiate() as WorldRoom
	if mirrored:
		room.position.x = 1920
		room.scale.x = -1
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = Vector2(1120, 880) if upper else Vector2(700, 992)
	if mirrored:
		target.position.x = 1920-target.position.x
	spawn(kind, Vector2(target.position.x, 1280))
	var lower_landing: bool = false
	var middle_landing: bool = false
	var arrived: bool = false
	var walked_away: bool = false
	var continuous: bool = true
	var pause_checked: bool = false
	for i: int in range(780):
		var before: Vector2 = actor.position
		var frame: int = Engine.get_physics_frames()
		await ticks(1)
		continuous = continuous and absf(actor.position.x-before.x) <= actor.config.speed*(Engine.get_physics_frames()-frame)/Engine.physics_ticks_per_second+2
		if not pause_checked and navigation().approaching and absf(actor.position.x-target.position.x)>20:
			pause_checked = true
			var point: Vector2 = actor.position
			var launch: Vector2 = navigation().launch
			paused = true
			await ticks(3)
			check(actor.position == point and navigation().launch == launch, kind+" pause freezes committed walking detour")
			paused = false
		if actor.is_on_floor():
			var local_x: float = 1920-actor.position.x if mirrored else actor.position.x
			walked_away = walked_away or (actor.position.y>1276 and local_x<430)
			lower_landing = lower_landing or absf(actor.position.y-1136)<4
			middle_landing = middle_landing or absf(actor.position.y-992)<4
			if absf(actor.position.y-target.position.y)<4:
				arrived = true
				break
	check(walked_away, kind+" walks away from target projection to clear actual ravine overhang")
	check(lower_landing and middle_landing and arrived, kind+" reaches "+("third" if upper else "second")+" ravine platform via lower steps; actual="+str(actor.position))
	check(continuous, kind+" detour uses normal speed and continuous collision movement")
	await clean()
	room.queue_free()
	await ticks(2)

func retarget_and_interrupt(kind: String) -> void:
	solid(Vector2(960, 1300), Vector2(2200, 40))
	solid(Vector2(600, 1152), Vector2(768, 32))
	target.position = Vector2(600, 1136)
	spawn(kind, Vector2(600, 1280))
	await ticks(4)
	check(navigation().approaching, kind+" commits to clearing a wide overhang")
	target.position = actor.position
	await ticks(2)
	check(not navigation().approaching and not navigation().active, kind+" abandons walking detour when player returns to same floor")
	target.position = Vector2(600, 1136)
	for i: int in range(120):
		await ticks(1)
		if navigation().approaching:
			break
	check(navigation().approaching and actor.request_interrupt(ColorlessEntity.InterruptReason.STAGGER, Vector2.ZERO, 0.4) and not navigation().approaching, kind+" stagger interrupts walking detour")
	var before: Vector2 = actor.position
	await ticks(8)
	check(actor.position.distance_to(before)<3 and actor.state==ColorlessEntity.State.STUN, kind+" detour respects active stun")
	await clean()

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	for kind: String in ["monochrome_entity", "tian_warrior"]:
		await actual_ravine(kind, false)
		await actual_ravine(kind, true)
		await actual_ravine(kind, false, true)
		await retarget_and_interrupt(kind)
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("PLATFORM_DETOUR_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
