# verify-suite: {"name": "second trench negative-resource route and permanent passage", "path": "res://tests/test_trench_passage.gd", "marker": "TRENCH_PASSAGE_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TrenchPassageSession
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
func area() -> TrenchPassageRoom:
	return session.room as TrenchPassageRoom
func quiet() -> void:
	for enemy: Node in session.room.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func press(action: String, count: int = 1) -> void:
	Input.action_press(action)
	await ticks(count)
	Input.action_release(action)
	await ticks(2)
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
	directory = "user://tests/trench_passage_%d" % Time.get_ticks_usec()
	session = (load("res://world/trench_passage_session.tscn") as PackedScene).instantiate() as TrenchPassageSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchSession.TRENCH_CHECKPOINT
	snapshot["balance"] = -9
	snapshot["day"] = 3
	snapshot["events"][TianSession.TIAN_INTRO] = true
	snapshot["events"][ParasiteSession.DODGE_PENDING] = true
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false), "old trench checkpoint is compatible with passage session")
	await ticks(4)
	quiet()
	await place(Vector2(1776,848))
	quiet()
	check(area()!=null and area().config.region_id=="Region_NSZC" and area().config.scene_id=="Region_NSZC_Scene_10002", "actual upper exit enters correct second trench Room")
	check(session.data["checkpoint"]==TrenchPassageSession.PASSAGE_CHECKPOINT and session.store.load_slot(1)["checkpoint"]==TrenchPassageSession.PASSAGE_CHECKPOINT, "entry automatically saves formal second-Room checkpoint")
	check(session.player.position.distance_to(Vector2(224,2048))<2 and area().get_node("Enemies").get_child_count()==4 and session._pickups().is_empty(), "safe entrance has four approved enemies and no extra collectible")
	check(session.room.get_node("Enemies/GroundMonochrome") is MonochromeEntity and session.room.get_node("Enemies/TianUpper") is TianWarrior, "frozen enemy types use real implemented AI")
	await press("move_left",35)
	check(area()!=null and session.player.position.x>132 and not area().return_open, "uncleared return gate physically blocks departure")
	await place(Vector2(1856,944))
	check(not paused and area()!=null and not area().forward_open, "forward exit also rejects uncleared or unbroken bypass")
	await place(Vector2(1600,944))
	check(not area().challenge_earned and not area().challenge_saved, "entering far end without passage start does not earn challenge")
	await place(Vector2(1648,944))
	await press("move_right",30)
	check(session.player.position.x<1660 and not area().rubble.unlocked, "locked360px rubble wall blocks ordinary movement")
	await place(Vector2(224,2048))
	for point: Vector2 in [Vector2(448,1904),Vector2(672,1712),Vector2(448,1520),Vector2(672,1328),Vector2(448,1136),Vector2(672,944),Vector2(896,944)]:
		check(await jump_to(point), "negative-resource ordinary jump reaches %s" % point)
	check(area().challenge_armed and not area().challenge_earned, "upper route reaches actual passage start")
	# Wait in the safe entry bay, then walk across after the second falling column.
	await ticks(156)
	Input.action_press("move_right")
	for i: int in range(160):
		await ticks(1)
		if session.player.position.x>=1600:
			break
	Input.action_release("move_right")
	await ticks(2)
	check(area().challenge_saved and session.store.load_slot(1)["events"].get(TrenchPassageRoom.CHALLENGE,false), "real waiting and walking through hazard saves challenge completion")
	check(session.player.possibility.balance==-9 and session.player.life.health==3, "negative possibility route needs no dodge resource or damage tanking")
	check(not area().rubble.unlocked and not area().return_open, "challenge alone cannot replace enemy-clear prerequisite")
	# Use a real environmental kill for the first enemy, not a direct reward call.
	var mono: MonochromeEntity = area().get_node("Enemies/GroundMonochrome") as MonochromeEntity
	mono.health = 1
	var falling: FallingRock = FallingRock.new()
	falling.position = Vector2(1024,1850)
	area().get_node("Rocks").add_child(falling)
	await ticks(24)
	check(mono.health==0 and session.player.possibility.balance==-2, "environment kill credits real+7 through production session")
	for enemy: ColorlessEntity in area().get_node("Enemies").get_children():
		if enemy.health>0:
			enemy.hurtbox.receive_attack(enemy.health,Vector2.ZERO,session.player,7000+enemy.get_index())
	await ticks(2)
	check(area().return_open and area().rubble.unlocked and session.store.load_slot(1)["events"].get(TrenchPassageRoom.CLEARED,false), "last defeat persists clear and unlocks return and rubble attack")
	check(area().get_node("ReturnGate/CollisionShape2D").disabled and not area().get_node("ReturnGate/GateVisual").visible and session.player.possibility.balance==10, "opened return collision and capped normal rewards are consistent")
	await place(Vector2(1648,944))
	await press("interact")
	check(not area().forward_open, "E interaction alone cannot replace attacking rubble")
	session.player.facing = 1
	await press("attack")
	await ticks(32)
	check(area().rubble.health==5, "first real attack removes half rubble health")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await press("attack")
	await ticks(32)
	check(area().rubble.pending_break and not area().forward_open and not session.data["events"].has(TrenchPassageRoom.FORWARD) and not area().rubble.get_node("CollisionShape2D").disabled, "failed final save leaves broken request pending and actual wall closed")
	session.store.directory = real_directory
	await press("interact")
	check(area().forward_open and area().rubble.get_node("CollisionShape2D").disabled and session.store.load_slot(1)["events"].get(TrenchPassageRoom.FORWARD,false), "E retry atomically saves forward opening and removes rubble wall")
	await press("move_right",50)
	check(paused and session.ui.get("_mode")=="room_boundary" and area().config.next_room_id=="NSZC_10003_1", "actual opened road reaches center battlefield stage boundary")
	session.ui.call("resume_game")
	await place(Vector2(48,2048))
	quiet()
	check(session.room is TrenchRoom and session.player.position.distance_to(Vector2(1504,848))<2, "return lands safely on first trench upper platform")
	await place(Vector2(1776,848))
	quiet()
	check(area().return_open and area().challenge_saved and area().forward_open and (area().get_node("Enemies/GroundMonochrome") as MonochromeEntity).health==21, "revisit restores all permanent progress while ordinary enemies reset")
	session._set_balance(0)
	mono = area().get_node("Enemies/GroundMonochrome") as MonochromeEntity
	mono.hurtbox.receive_attack(21,Vector2.ZERO,session.player,7010)
	check(session.player.possibility.balance==7, "reset enemy still pays normal reward after permanent gates open")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TrenchPassageSession
	quiet()
	check(area()!=null and session.player.life.health==5 and session.player.possibility.balance==3 and session.player.life.protection_remaining>2.8, "death returns to second checkpoint with floor-half resources and protection")
	check(area().return_open and area().forward_open and area().challenge_saved and area().get_node("Rocks").get_child_count()==0, "death preserves permanent progress and removes transient debris")
	check(session.start_slot(1,false), "new checkpoint and gate save can load normally")
	await ticks(4)
	session = current_scene as TrenchPassageSession
	quiet()
	check(session.player.life.protection_remaining==0 and session.data["day"]==3 and session.player.possibility.balance==3 and area().forward_open, "normal load preserves resources day and gates without revive protection")
	# A second slot exercises all three rollback paths without damaging slot1.
	check(session.store.save_slot(2,snapshot) and session.start_slot(2,false), "second independent slot starts before new Room")
	await ticks(4)
	session = current_scene as TrenchPassageSession
	quiet()
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	session._mount_room(TrenchPassageSession.PASSAGE_ID)
	await place(Vector2(224,2048))
	quiet()
	check(not session.activate_checkpoint(TrenchPassageSession.PASSAGE_CHECKPOINT) and session.data["checkpoint"]==TrenchSession.TRENCH_CHECKPOINT and not session._checkpoint(TrenchPassageSession.PASSAGE_CHECKPOINT).active, "failed checkpoint write restores previous ID and inactive flag")
	session.store.directory = real_directory
	await press("interact")
	check(session.data["checkpoint"]==TrenchPassageSession.PASSAGE_CHECKPOINT, "checkpoint activation remains E-retryable")
	session.store.directory = real_directory.path_join("slot_2.json")
	for enemy: ColorlessEntity in area().get_node("Enemies").get_children():
		enemy.hurtbox.receive_attack(enemy.health,Vector2.ZERO,session.player,7100+enemy.get_index())
	check(not area().return_open and not session.data["events"].has(TrenchPassageRoom.CLEARED), "failed clear save leaves return gate closed and rolls back flag")
	session.store.directory = real_directory
	await press("interact")
	check(area().return_open and session.store.load_slot(2)["events"].get(TrenchPassageRoom.CLEARED,false), "clear save retries without killing enemies or paying rewards twice")
	await place(Vector2(880,944))
	session.store.directory = real_directory.path_join("slot_2.json")
	await place(Vector2(1600,944))
	check(area().challenge_earned and not area().challenge_saved and not area().rubble.unlocked and not session.data["events"].has(TrenchPassageRoom.CHALLENGE), "failed challenge save preserves earned retry while locking rubble")
	session.store.directory = real_directory
	await press("interact")
	check(area().challenge_saved and area().rubble.unlocked, "challenge persistence retries through E")
	area().rubble.hurtbox.receive_attack(5,Vector2.RIGHT,session.player,7200)
	check(area().rubble.health==5 and not area().forward_open, "partial rubble damage is still transient")
	check(session.start_slot(2,false), "partially damaged rubble save reloads")
	await ticks(4)
	session = current_scene as TrenchPassageSession
	quiet()
	check(area().rubble.health==10 and area().rubble.unlocked and not area().forward_open and not session._cleared(), "load resets partial rubble and enemies but preserves prerequisites")
	check(session.store.load_slot(1)["balance"]==3 and session.store.load_slot(1)["events"].get(TrenchPassageRoom.FORWARD,false) and session.player.possibility.maximum==10 and session.data["day"]==3, "other slot and frozen growth date remain unchanged")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for slot: int in [1,2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(directory.path_join("slot_%d.json"%slot)+suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("TRENCH_PASSAGE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
