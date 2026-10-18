extends "res://tests/test_platform_pursuit.gd"

func navigation() -> EnemyPlatformPursuit:
	return (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit

func actual_entry(kind: String, on_top: bool, mirrored: bool = false, retarget: bool = false) -> void:
	var room: WorldRoom = (load("res://world/rooms/hd_20001_1.tscn") as PackedScene).instantiate() as WorldRoom
	if mirrored:
		room.position.x = 2560
		room.scale.x = -1
	world.add_child(room)
	for other: Node in room.get_node("Enemies").get_children():
		other.process_mode = Node.PROCESS_MODE_DISABLED
	target.position = Vector2(1000, 1152) if on_top else Vector2(672, 1280)
	if mirrored:
		target.position.x = 2560-target.position.x
	spawn(kind, Vector2(2560-1112.1 if mirrored else 1112.1, 1280))
	var backed_off: bool = false
	var on_block: bool = false
	var reached: bool = false
	var pause_checked: bool = false
	var switched: bool = false
	var solid_respected: bool = true
	for i: int in range(420):
		await ticks(1)
		var local_x: float = 2560-actor.position.x if mirrored else actor.position.x
		backed_off = backed_off or (actor.is_on_floor() and actor.position.y>1276 and local_x>1144)
		solid_respected = solid_respected and not (local_x>920 and local_x<1064 and actor.position.y>1156)
		if not pause_checked and navigation().approaching:
			pause_checked = true
			var before: Vector2 = actor.position
			var launch: Vector2 = navigation().launch
			paused = true
			await ticks(3)
			check(actor.position==before and navigation().launch==launch, kind+" pause freezes obstacle backstep")
			paused = false
		if retarget and not switched and actor.velocity.y<0:
			switched = true
			target.position = Vector2(672, 1280)
		if actor.is_on_floor() and absf(actor.position.y-1152)<4:
			on_block = true
		if actor.is_on_floor() and absf(actor.position.y-target.position.y)<4 and ((on_top and not retarget) or local_x<865):
			reached = true
			break
	check(backed_off and pause_checked, kind+" backs away from contacted TileMap wall before jumping")
	check(on_block and reached, kind+(" reaches player on actual entry block" if on_top else " climbs over actual entry block to same-height player")+" actual="+str(actor.position))
	check(solid_respected and (not retarget or switched), kind+" collision remains solid and moving target can return to lower floor")
	await clean()
	room.queue_free()
	await ticks(2)

func obstacle_safety(kind: String, tall: bool) -> void:
	if tall:
		solid(Vector2(960, 1300), Vector2(2200, 40))
		solid(Vector2(992, 850), Vector2(192, 860))
		target.position = Vector2(672, 1280)
	else:
		# Only 56px of supported ground behind the wall: no safe backstep.
		solid(Vector2(1116, 1300), Vector2(56, 40))
		solid(Vector2(992, 1216), Vector2(192, 128))
		target.position = Vector2(1000, 1152)
	spawn(kind, Vector2(1112.1, 1280))
	await ticks(60)
	check(actor.is_on_floor() and absf(actor.position.y-1280)<4 and actor.position.x>1110 and actor.position.x<1144, kind+(" refuses wall above jump height" if tall else " does not backstep into void to clear wall"))
	await clean()

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	for kind: String in ["monochrome_entity", "tian_warrior"]:
		await actual_entry(kind, true)
		await actual_entry(kind, false)
		await actual_entry(kind, true, true)
		await actual_entry(kind, false, true)
		await actual_entry(kind, true, false, true)
		await obstacle_safety(kind, true)
		await obstacle_safety(kind, false)
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("PLATFORM_OBSTACLES_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
