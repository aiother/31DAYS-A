extends SceneTree
var checks: int = 0
var failures: int = 0
var session: OutskirtsSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func enter() -> void:
	await place(Vector2(1552,1056))
	for enemy: Node in session.room.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(30)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = point.x-session.player.position.x
		if absf(dx)>10:
			Input.action_press("move_right" if dx>0 else "move_left")
		await ticks(1)
		if i>4 and session.player.is_on_floor():
			reached = absf(session.player.position.y-point.y)<2 and absf(session.player.position.x-point.x)<110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func run() -> void:
	directory = "user://tests/outskirts_%d" % Time.get_ticks_usec()
	session = (load("res://world/outskirts_session.tscn") as PackedScene).instantiate() as OutskirtsSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	base["day"] = 3
	base["balance"] = 0
	for key: String in [ParasiteSession.PARASITE_INTRO,ParasiteSession.PARASITE_DEFEATED,ParasiteSession.PARASITE_PASSAGE,ParasiteSession.DODGE_PENDING]:
		base["events"][key] = true
	check(session.store.save_slot(1,base) and session.start_slot(1,false), "saved parasite victory remains loadable in extended session")
	await ticks(4)
	await enter()
	check(session.room is OutskirtsRoom and session.room.config.region_id=="Region_NSZC" and session.room.config.scene_id=="Region_NSZC_Scene_10001", "actual opened hole enters new region and correct scene")
	check(session.room.config.next_room_id=="NSZC_10002_1" and session.get_node("Instructions/Title").text.contains("逆时战场"), "next trench identifier and region HUD are correct")
	check(session._all_checkpoints().is_empty() and session._pickups().is_empty() and not session.room.has_node("Survivor"), "approved partial scope adds no checkpoint pearl or NPC")
	check(session.data["checkpoint"]==ParasiteSession.PARASITE_CHECKPOINT and session.data["day"]==3 and session.player.possibility.balance==0, "cross-region entry preserves checkpoint date and resources")
	await place(Vector2(768,1280))
	check(await jump_to(Vector2(1024,1152)), "zero-resource jump crosses main high ground")
	Input.action_press("move_right")
	await ticks(35)
	Input.action_release("move_right")
	await ticks(30)
	for point: Vector2 in [Vector2(1424,1136),Vector2(1648,992),Vector2(1872,848)]:
		check(await jump_to(point), "ordinary jump reaches optional upper approach %s" % point)
	await place(Vector2(2112,848))
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(50)
	Input.action_release("move_right")
	Input.action_release("run")
	check(session.player.position.x<2220 and session.room.get_node("AbilityGate/CollisionShape2D").disabled==false, "unfinished ability gate remains physically closed")
	check(session.player.possibility.maximum==10 and session.data["events"]==base["events"], "gate approach creates no rescue growth or unlock event")
	await place(Vector2(2400,1280))
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(120)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode")=="room_boundary", "main road bypasses closed optional gate and reaches trench boundary")
	check(session.player.possibility.balance==0 and session.data["day"]==3, "main road requires neither possibility nor additional date progression")
	session.ui.call("resume_game")
	await place(Vector2(48,1280))
	check(session.room is ParasiteRoom and session.player.position.distance_to(Vector2(1344,1056))<2 and session.data["day"]==3, "return uses safe parasite upper landing without date rollback")
	await enter()
	var enemy: ColorlessEntity = session.room.get_node("Enemies/LowerEntity") as ColorlessEntity
	enemy.hurtbox.receive_attack(13,Vector2.ZERO,session.player,8000)
	check(session.player.possibility.balance==2, "existing outskirts enemy gives+2")
	await place(Vector2(48,1280))
	await enter()
	enemy = session.room.get_node("Enemies/LowerEntity") as ColorlessEntity
	check(enemy.health==13, "returning resets ordinary enemies")
	enemy.hurtbox.receive_attack(13,Vector2.ZERO,session.player,8001)
	check(session.player.possibility.balance==4, "reset enemy still gives+2")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as OutskirtsSession
	check(session.room is ParasiteRoom and session.player.life.health==5 and session.player.possibility.balance==2 and session.player.life.protection_remaining>2.8 and session.data["day"]==3, "death returns to defeated Boss checkpoint with ordinary settlement and day3")
	check(session.start_slot(1,false), "normal slot can reload outskirts progress")
	await ticks(4)
	session = current_scene as OutskirtsSession
	check(session.room is ParasiteRoom and session.player.life.protection_remaining==0 and session.player.possibility.balance==2, "normal load keeps resources without revive protection")
	await enter()
	check(not session.room.has_node("Survivor") and session.room.has_node("AbilityGate"), "revisit does not invent missing NPC or bypass gate")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(directory.path_join("slot_1.json")+suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("OUTSKIRTS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
