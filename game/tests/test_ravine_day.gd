extends SceneTree
var checks: int = 0
var failures: int = 0
var session: RavineSession
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
	session = (load("res://world/ravine_session.tscn") as PackedScene).instantiate() as RavineSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
func close_session() -> void:
	paused = false
	session.queue_free()
	await ticks(2)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func enter_from_boss() -> void:
	await place(Vector2(1552, 848))
	await place(Vector2(2480, 896))
	await place(Vector2(1824, 896))
func disable_enemies() -> void:
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
func lower_enemy() -> ColorlessEntity:
	return session.room.get_node("Enemies/LowerEntity") as ColorlessEntity
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(30)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = point.x - session.player.position.x
		if absf(dx) > 10:
			Input.action_press("move_right" if dx > 0 else "move_left")
		await ticks(1)
		if i > 4 and session.player.is_on_floor():
			reached = absf(session.player.position.y - point.y) < 2 and absf(session.player.position.x - point.x) < 110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func run() -> void:
	directory = "user://tests/ravine_%d" % Time.get_ticks_usec()
	await open_session()
	var legacy: Dictionary = session.store.fresh()
	legacy.erase("day")
	legacy["checkpoint"] = BossSession.BOSS_CHECKPOINT
	legacy["balance"] = 7
	for key: String in [BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE]:
		legacy["events"][key] = true
	check(session.store.save_slot(1, legacy) and session.store.load_slot(1)["day"] == 1, "legacy save without day loads as first day")
	check(session.start_slot(1, false), "old Boss checkpoint remains loadable")
	await ticks(3)
	await enter_from_boss()
	check(session.room.config.room_id == RavineSession.RAVINE_ID and session.room.config.scene_id == "Region_HD_Scene_20001", "actual town cliff enters configured ravine Room")
	check(session.data["checkpoint"] == RavineSession.RAVINE_CHECKPOINT and session._all_checkpoints().size() == 1, "entry activates formally numbered ravine checkpoint")
	check(session.data["day"] == 2 and session.store.load_slot(1)["day"] == 2 and session.store.load_slot(1)["checkpoint"] == RavineSession.RAVINE_CHECKPOINT, "completed Seven story advances day and checkpoint in one saved snapshot")
	check(session.player.life.health == 3 and session.player.possibility.balance == 7, "checkpoint and date event preserve live player resources")
	check(session.get_node("DayUI/Day").text == "第 2 日" and session.get_node("DayUI").visible, "current date appears in HUD")
	check(session.room.get_node("Enemies").get_child_count() == 3 and lower_enemy().health == 13 and session.room.get_node("Enemies/GroundMonochrome") is MonochromeEntity, "frozen composition keeps two colorless and adds existing ground monochrome")
	var saved: Dictionary = session.store.load_slot(1)
	check(not session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT), "same checkpoint and day activation is idempotent")
	await ticks(4)
	check(session.store.load_slot(1) == saved and session.data["day"] == 2, "repeat activation performs no day increment or duplicate write")
	disable_enemies()
	var hazard: RoomRockfall = session.room.environment_hazard
	await place(hazard.config.switch_position+Vector2(0,44))
	check(session.activate_environment_switch(),"existing geometry route can first use real permanent hazard shutdown")
	check(hazard.disabled and session.store.load_slot(1)["events"].get(hazard.config.persistence_key,false),"route fixture closes trap through saved interaction rather than bypassing damage")
	session.player.possibility.balance = 0
	session.player.possibility.balance_changed.emit(0, 10)
	await place(Vector2(768, 1280))
	check(await jump_to(Vector2(960, 1152)), "ordinary jump crosses raised central ledge: %s" % session.player.position)
	Input.action_press("move_right")
	await ticks(45)
	Input.action_release("move_right")
	await ticks(30)
	for point: Vector2 in [Vector2(1424, 1136), Vector2(1648, 992), Vector2(1872, 848)]:
		check(await jump_to(point), "ordinary jump reaches ravine platform %s; actual %s" % [point, session.player.position])
	Input.action_press("move_right")
	await ticks(120)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode") == "room_boundary", "platform route reaches next ravine Room boundary")
	check(session.player.possibility.balance == 0 and session.data["day"] == 2, "main route requires no possibility or down-attack bounce")
	session.ui.call("resume_game")
	await place(Vector2(1200, 1126))
	Input.action_press("aim_down")
	Input.action_press("attack")
	var bounced: bool = false
	for i: int in range(30):
		await ticks(1)
		if lower_enemy().health < 13:
			bounced = session.player.velocity.y < 0
			break
	Input.action_release("attack")
	Input.action_release("aim_down")
	check(lower_enemy().health == 8 and bounced, "lower practice route permits real down-attack damage and bounce")
	lower_enemy().hurtbox.receive_attack(8, Vector2.ZERO, session.player, 900)
	await ticks(2)
	check(session.player.possibility.balance == 2, "colorless defeat grants existing +2 resource reward")
	await place(Vector2(48, 1280))
	check(session.room.config.room_id == TownSession.TOWN_ID and session.player.position.distance_to(Vector2(1664, 896)) < 2 and session.data["day"] == 2, "return restores safe town cliff landing without date rollback")
	await place(Vector2(1824, 896))
	disable_enemies()
	check(lower_enemy().health == 13 and session.data["day"] == 2, "revisit resets enemies but not date")
	lower_enemy().hurtbox.receive_attack(13, Vector2.ZERO, session.player, 901)
	check(session.player.possibility.balance == 4, "reset enemy still pays +2 on repeat defeat")
	session.player.possibility.gain(3)
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RavineSession
	check(session.room.config.room_id == RavineSession.RAVINE_ID and session.player.position.distance_to(Vector2(224, 1280)) < 2, "death respawns at new checkpoint inside ravine")
	check(session.player.life.health == 5 and session.player.possibility.balance == 3 and session.player.life.protection_remaining > 2.8, "death retains floor half resource full health and protection")
	check(session.data["day"] == 2 and session.data["events"].get(FieldSession.RESCUE_DONE, false), "death keeps current date and completed rescue")
	await close_session()
	await open_session()
	check(session.start_slot(1, false), "new checkpoint and date slot reload")
	await ticks(4)
	check(session.room.config.room_id == RavineSession.RAVINE_ID and session.data["day"] == 2 and session.player.life.protection_remaining == 0, "normal load restores date and room without respawn protection")
	var later: Dictionary = session.store.load_slot(1)
	later["day"] = 3
	session.store.save_slot(2, later)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as RavineSession
	check(session.data["day"] == 3 and not session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT), "later day never rolls backward on second-day checkpoint")
	await place(Vector2(48, 1280))
	await place(Vector2(1824, 896))
	check(session.data["day"] == 3 and session.store.load_slot(2)["day"] == 3, "day-three revisit remains monotonic")
	var without_story: Dictionary = session.store.fresh()
	without_story["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	session.store.save_slot(3, without_story)
	session.start_slot(3, false)
	await ticks(4)
	session = current_scene as RavineSession
	check(session.data["day"] == 1 and session.data["events"].get(RavineSession.RAVINE_CHECKPOINT, false), "checkpoint alone cannot advance date without completed Seven story")
	# Establish a pending checkpoint/date transaction with a valid previously saved Boss snapshot.
	var pending: Dictionary = legacy.duplicate(true)
	pending["day"] = 1
	session.store.save_slot(3, pending)
	session._restore(pending, false)
	session._mount_room(RavineSession.RAVINE_ID)
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	check(not session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT) and session.data["day"] == 1 and session.data["checkpoint"] == BossSession.BOSS_CHECKPOINT and not session.data["events"].get(RavineSession.RAVINE_CHECKPOINT, false), "failed write rolls back checkpoint day and node event together")
	check(not session._all_checkpoints()[0].active, "failed checkpoint does not display saved activation")
	await ticks(4)
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.data["day"] == 2 and session.data["checkpoint"] == RavineSession.RAVINE_CHECKPOINT and session.store.load_slot(3)["day"] == 2, "E retry commits both checkpoint and date after write recovery")
	check(str(session.ui.get("_error_label").text).is_empty(), "successful checkpoint retry clears stale error")
	# Unfinished rescue must still be explicitly abandoned at the newly traversable TY exit.
	var unfinished: Dictionary = legacy.duplicate(true)
	unfinished["events"].erase(FieldSession.RESCUE_DONE)
	unfinished["day"] = 1
	session.store.save_slot(2, unfinished)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as RavineSession
	await enter_from_boss()
	check(session.room.config.room_id == TownSession.TOWN_ID and session.dialogue_ui.confirming and session.data["day"] == 1, "new actual region exit warns before unfinished rescue is lost")
	session.cancel_departure()
	check(session.room.config.room_id == TownSession.TOWN_ID and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "cancel keeps rescue and current date")
	session._on_room_exit(RavineSession.RAVINE_ID)
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	check(not session.confirm_departure() and session.data["day"] == 1 and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "failed departure write neither advances day nor abandons rescue")
	session.store.directory = real_directory
	check(session.confirm_departure(), "explicit departure confirmation accepted")
	await ticks(4)
	check(session.room.config.room_id == RavineSession.RAVINE_ID and session.data["day"] == 2 and session.store.load_slot(2)["events"].get(FieldSession.RESCUE_FAILED, false), "confirmed actual departure saves failure then activates second-day checkpoint")
	for bad: Variant in [0, 4, -1, 1.5, true, "2"]:
		var invalid: Dictionary = session.store.fresh()
		invalid["day"] = bad
		check(not session.store.valid(invalid), "invalid date rejected: %s" % str(bad))
	var grown: Dictionary = later.duplicate(true)
	grown["day"] = 2
	grown["maximum"] = 12
	grown["balance"] = 11
	grown["events"][TownSession.GAZE] = true
	session.store.save_slot(3, grown)
	session.start_slot(3, false)
	await ticks(4)
	session = current_scene as RavineSession
	check(session.data["day"] == 2 and session.player.possibility.maximum == 12 and session.player.possibility.balance == 11, "new date field remains compatible with permanent growth")
	session.start_slot(3, true)
	await ticks(4)
	session = current_scene as RavineSession
	check(session.data["day"] == 1 and session.data["checkpoint"] == StartRoomSession.CHECKPOINT, "new game resets date and checkpoint")
	await close_session()
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1, 2, 3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("RAVINE_DAY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
