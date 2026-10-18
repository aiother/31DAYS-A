extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TrenchSession
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
func quiet() -> void:
	for enemy: Node in session.room.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
func run() -> void:
	directory = "user://tests/trench_%d" % Time.get_ticks_usec()
	session = (load("res://world/trench_session.tscn") as PackedScene).instantiate() as TrenchSession
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
	check(session.store.save_slot(1,base) and session.start_slot(1,false), "old victory save remains compatible")
	await ticks(4)
	await enter()
	await place(Vector2(2928,1280))
	quiet()
	check(session.room is TrenchRoom and session.room.config.scene_id=="Region_NSZC_Scene_10002" and session.room.config.region_id=="Region_NSZC", "actual outskirts exit enters trench with correct region and scene")
	check(session.data["checkpoint"]==TrenchSession.TRENCH_CHECKPOINT and session.store.load_slot(1)["checkpoint"]==TrenchSession.TRENCH_CHECKPOINT, "entry automatically persists numbered checkpoint")
	check(session.player.position.distance_to(Vector2(224,1792))<2 and session.get_node("Instructions/Title").text.contains("堑壕"), "safe entry and region HUD")
	check(session._all_checkpoints().size()==1 and session._pickups().size()==1 and not session.room.has_node("Survivor") and not session.room.has_node("AbilityGate"), "room scope contains one pearl and formal checkpoint without NPC or ability gate")
	for point: Vector2 in [Vector2(448,1648),Vector2(672,1488),Vector2(896,1328),Vector2(1120,1168),Vector2(1344,1008),Vector2(1568,848)]:
		check(await jump_to(point), "zero-resource ordinary jump reaches %s" % point)
	Input.action_press("move_right")
	await ticks(60)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode")=="room_boundary", "upper road is reachable with enemies alive and stops at next-room boundary")
	session.ui.call("resume_game")
	check(session.player.possibility.balance==0 and session.data["day"]==3, "traversal consumes no resources and does not advance date")
	await place(Vector2(704,1792))
	var pearl: RoomPickup = session._pickups()[0]
	var key: String = pearl.config.persistence_key
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.collect_pickup(pearl) and not session.data["events"].has(key) and pearl.can_collect(session.player), "failed pearl save leaves pickup and event retryable")
	session.store.directory = real_directory
	check(session.collect_pickup(pearl) and session.store.load_slot(1)["events"].get(key,false), "pearl ownership persists")
	check(not session.collect_pickup(pearl) and session.player.possibility.maximum==10 and session.player.possibility.balance==0 and session.player.combat.pearl_count==1 and is_equal_approx(session.player.combat.range_multiplier(),1.05), "pearl adds5% reach exactly once without possibility changes")
	var enemy: ColorlessEntity = session.room.get_node("Enemies/DownAttackEntity") as ColorlessEntity
	enemy.hurtbox.receive_attack(13,Vector2.ZERO,session.player,9000)
	check(session.player.possibility.balance==2, "trench enemy rewards two possibility")
	await place(Vector2(48,1792))
	check(session.room is OutskirtsRoom and session.player.position.distance_to(Vector2(2752,1280))<2, "return reaches safe outskirts landing without immediate bounce")
	await place(Vector2(2928,1280))
	quiet()
	check(not session._pickups()[0].can_collect(session.player) and session.data["events"].get(key,false), "pearl remains owned across room reset")
	enemy = session.room.get_node("Enemies/DownAttackEntity") as ColorlessEntity
	check(enemy.health==13, "ordinary enemies reset on revisit")
	enemy.hurtbox.receive_attack(13,Vector2.ZERO,session.player,9001)
	check(session.player.possibility.balance==4, "reset enemy still rewards two")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TrenchSession
	quiet()
	check(session.room is TrenchRoom and session.player.life.health==5 and session.player.possibility.balance==2 and session.player.life.protection_remaining>2.8, "death returns to trench checkpoint with settled resources and revive protection")
	check(session.data["day"]==3 and session.data["events"].get(key,false) and session.data["events"].get(ParasiteSession.DODGE_GROWTH,false) and session.player.possibility.dodge_upgraded, "death preserves date pearl and granted Boss dodge upgrade")
	check(session.start_slot(1,false), "new checkpoint save can be loaded normally")
	await ticks(4)
	session = current_scene as TrenchSession
	quiet()
	check(session.room is TrenchRoom and session.player.life.protection_remaining==0 and session.player.possibility.balance==2, "normal load selects trench without revive protection")
	# Mount without crossing to simulate a failed first checkpoint write.
	session.data["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	session._update_flags()
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.activate_checkpoint(TrenchSession.TRENCH_CHECKPOINT) and session.data["checkpoint"]==ParasiteSession.PARASITE_CHECKPOINT and not session._checkpoint(TrenchSession.TRENCH_CHECKPOINT).active, "failed checkpoint save restores previous selection and inactive flag")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.data["checkpoint"]==TrenchSession.TRENCH_CHECKPOINT and session.store.load_slot(1)["checkpoint"]==TrenchSession.TRENCH_CHECKPOINT, "E retries failed checkpoint transaction")
	check(not session.data["events"].has("NSZC_10002_1_N001") and session.player.possibility.maximum==10, "no fabricated Tian introduction or new growth")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(directory.path_join("slot_1.json")+suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("TRENCH_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
