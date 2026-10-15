extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TowerSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func open_session() -> void:
	session = (load("res://world/tower_session.tscn") as PackedScene).instantiate() as TowerSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)

func enemies() -> Array[Node]:
	return session.room.get_node("Enemies").get_children()

func disable_enemies() -> void:
	for actor: Node in enemies():
		actor.set_physics_process(false)

func jump_to(target: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(2)
	Input.action_press("jump")
	var landed: bool = false
	for i: int in range(100):
		var dx: float = target.x - session.player.position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(dx) > 10:
			Input.action_press("move_right" if dx > 0 else "move_left")
		await ticks(1)
		if i > 4 and session.player.is_on_floor():
			landed = absf(session.player.position.y - target.y) < 2 and absf(session.player.position.x - target.x) < 110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return landed

func kill(actor: ColorlessEntity) -> void:
	var receiver: CombatHurtbox = actor.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.receive_attack(20, Vector2.ZERO, session.player, 200)

func run() -> void:
	directory = "user://tests/tower_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["events"][StartRoomSession.GUIDE] = true
	snapshot["events"][TwoRoomSession.ENCOUNTER] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "existing entry checkpoint save loads into extended session")
	await ticks(3)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID, "normal load enters previous checkpoint Room")
	session.player.position = Vector2(1810, 896)
	await ticks(4)
	check(session.room.config.room_id == TowerSession.TOWER_ID and not paused, "real road enters delivered Room2 rather than boundary panel")
	check(session.player.position.distance_to(Vector2(128, 1536)) < 2, "Room2 uses lower entrance from Resource")
	check(session.room.config.scene_id == "Region_HD_Scene_10002" and session.room.config.previous_room_id == TwoRoomSession.ENTRY_ID and session.room.config.next_room_id == "HD_10002_3", "Room2 identity and connections match frozen T5")
	check(session._all_checkpoints().is_empty() and session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "producer choice: Room2 keeps entry checkpoint without invented Node")
	check(enemies().size() == 2 and (enemies()[0] as ColorlessEntity).health == 13 and (enemies()[1] as ColorlessEntity).flying, "Room2 reuses ground and airborne colorless configuration")
	check(enemies()[0].is_physics_processing() and enemies()[1].is_physics_processing(), "ordinary Room2 enemies activate without another introduction")
	check(not (session.ui.get("_enemy_intro") as PanelContainer).visible, "Room2 does not repeat first encounter card")
	var camera: Camera2D = session.player.get_node("Camera2D") as Camera2D
	check(camera.limit_bottom == 1728 and camera.limit_right == 1920, "camera adopts vertical Room bounds")
	disable_enemies()
	session.player.possibility.balance = 0
	session.player.possibility.balance_changed.emit(0, 10)
	session.player.position = Vector2(192, 1536)
	session.player.reset_kinematics()
	await ticks(4)
	for destination: Vector2 in [Vector2(400, 1376), Vector2(624, 1216), Vector2(848, 1056), Vector2(1072, 896), Vector2(1296, 736), Vector2(1580, 640)]:
		var reached: bool = await jump_to(destination)
		check(reached, "ordinary jump reaches vertical landing %s; actual %s" % [destination, session.player.position])
		if not reached:
			break
	check(session.player.possibility.balance == 0, "entire upward route needs no dodge resource")
	check(session.player.position.y < 700 and camera.get_screen_center_position().y < 1200, "camera follows climb without leaving Room")
	Input.action_press("move_right")
	await ticks(65)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode") == "room_boundary" and session.room.config.room_id == TowerSession.TOWER_ID, "upper passage reaches future Room3 boundary")
	session.ui.call("resume_game")
	# Verify real attacks separately from resource-free route traversal.
	session.player.position = Vector2(1050, 1536)
	session.player.reset_kinematics()
	var ground_enemy: ColorlessEntity = enemies()[0] as ColorlessEntity
	ground_enemy.set_physics_process(true)
	await ticks(40)
	check(session.player.life.health < 3, "ground colorless performs real melee damage in Room2")
	session.player.life.start_new_run()
	ground_enemy.set_physics_process(false)
	session.player.position = Vector2(1620, 640)
	session.player.reset_kinematics()
	var air_enemy: ColorlessEntity = enemies()[1] as ColorlessEntity
	air_enemy.set_physics_process(true)
	await ticks(65)
	check(session.player.life.health < 3, "air colorless throw can damage player on upper route")
	session.player.life.start_new_run()
	disable_enemies()
	session.player.possibility.balance = 0
	kill(ground_enemy)
	kill(air_enemy)
	check(session.player.possibility.balance == 4, "two colorless defeats each award 2")
	# Actual lower return road, preserving resources and checkpoint.
	session.player.position = Vector2(48, 1536)
	session.player.reset_kinematics()
	await ticks(4)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.life.health == 3 and session.player.possibility.balance == 4, "lower return road restores entry Room without refilling resources")
	check((session.player.get_node("Camera2D") as Camera2D).limit_bottom == 1080, "return restores previous camera bounds")
	session._on_room_exit(TowerSession.TOWER_ID)
	await ticks(4)
	check(enemies().size() == 2 and (enemies()[0] as ColorlessEntity).health == 13, "revisit resets both ordinary enemies")
	disable_enemies()
	kill(enemies()[0] as ColorlessEntity)
	check(session.player.possibility.balance == 6, "repeated Room2 kill remains rewarded")
	session.player.life.take_hit(5)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TowerSession
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.position.distance_to(Vector2(288, 896)) < 2, "death in Room2 returns to agreed entry checkpoint")
	check(session.player.life.health == 5 and session.player.possibility.balance == 3 and session.player.life.protection_remaining > 2.8, "death preserves full health half possibility and protection rules")
	check(session.data["events"].get(TwoRoomSession.ENCOUNTER, false) and not session.intro_active, "death preserves completed introduction and birth")
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	paused = false
	session.queue_free()
	await process_frame
	await process_frame
	var cleanup: SlotStore = SlotStore.new()
	cleanup.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(cleanup.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("TOWER_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
