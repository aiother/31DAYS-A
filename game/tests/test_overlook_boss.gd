extends SceneTree
var checks: int = 0
var failures: int = 0
var session: BossSession
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
	session = (load("res://world/boss_session.tscn") as PackedScene).instantiate() as BossSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
func close_session() -> void:
	paused = false
	session.queue_free()
	await ticks(2)
func boss() -> OverlookBoss:
	return session.room.get_node("Boss") as OverlookBoss
func arena() -> BossRoom:
	return session.room as BossRoom
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(2)
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
	directory = "user://tests/overlook_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for key: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER, "gate:HD_10003_1:return", "gate:HD_10003_1:forward"]:
		snapshot["events"][key] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "previous checkpoint save remains compatible")
	await ticks(3)
	session._on_room_exit(TowerSession.TOWER_ID)
	await ticks(4)
	session._on_room_exit(ExplorationSession.EXPLORATION_ID)
	await ticks(4)
	session._on_room_exit(ConnectionSession.CONNECTION_ID)
	await ticks(4)
	await place(Vector2(1488, 896))
	check(session.room.config.room_id == BossSession.BOSS_ID and session.room.config.next_room_id == "TY_10001_1", "actual connection gate reaches frozen Boss Room")
	check(session.data["checkpoint"] == BossSession.BOSS_CHECKPOINT and session.store.load_slot(1)["checkpoint"] == BossSession.BOSS_CHECKPOINT, "entry activates and saves numbered Boss checkpoint")
	check(session.intro_active and not session.player.life.can_control() and boss().state == OverlookBoss.State.WAITING, "first introduction locks control and suspends combat")
	check(session.data["events"].get(BossSession.BOSS_INTRO, false), "first intro recorded once before playback")
	check(not boss().hurtbox.receive_attack(5, Vector2.ZERO, session.player, 1), "Boss cannot be damaged during introduction")
	check(boss().get_node_or_null("HealthLabel") == null and session.ui.get("_enemy_intro").get_child(0).text.begins_with("渴望俯视"), "T7 name card without Boss health bar")
	var before_intro: float = session._boss_intro_remaining
	session.ui.call("show_pause")
	await ticks(5)
	check(session._boss_intro_remaining == before_intro, "pause freezes introduction")
	session.ui.call("resume_game")
	Input.action_press("jump")
	Input.action_press("move_right")
	await ticks(10)
	Input.action_release("jump")
	Input.action_release("move_right")
	check(absf(session.player.position.x - 224) < 2, "introduction ignores movement input")
	await ticks(6) # Finish the 0.2-second slide before checking its final edge.
	var card: PanelContainer = session.ui.get("_enemy_intro") as PanelContainer
	check(absf(card.position.x + card.size.x - 1920) < 1, "introduction card sits flush against right edge")
	await ticks(300)
	check(not session.intro_active and session.player.life.can_control() and boss().state == OverlookBoss.State.WINDUP, "introduction ends into first telegraphed attack")
	check((session.player.get_node("Camera2D") as Camera2D).offset == Vector2.ZERO, "intro camera returns to player without lingering shake")
	check(boss().health == 60 and is_equal_approx(boss().config.windup_duration, 0.6), "approved graybox health and warning parameters")
	var attack_time: float = boss().remaining
	var attack_position: Vector2 = boss().position
	session.ui.call("show_pause")
	await ticks(5)
	check(boss().remaining == attack_time and boss().position == attack_position, "pause freezes Boss attack timing and position")
	session.ui.call("resume_game")
	var before_hit: int = session.player.life.health
	for i: int in range(80):
		await ticks(1)
		if boss().state == OverlookBoss.State.RECOVERY:
			break
	check(session.player.life.health == before_hit - 1, "real AI landing deals exactly one damage")
	var after_hit: int = session.player.life.health
	await ticks(20)
	check(session.player.life.health == after_hit, "landing hit does not repeat during recovery")
	await ticks(60)
	check(boss().state == OverlookBoss.State.HOVER and arena().get_node("SummonedPlatforms").get_child_count() == 3, "AI flies upward and summons three fixed platforms")
	arena().summon_platforms()
	check(arena().get_node("SummonedPlatforms").get_child_count() == 3, "repeated hover does not accumulate platforms")
	for minion: ColorlessEntity in arena().living_reinforcements():
		minion.set_physics_process(false)
	boss().set_physics_process(false)
	session.player.possibility.balance = 0
	await place(Vector2(416, 1280))
	for point: Vector2 in [Vector2(608, 1136), Vector2(832, 992), Vector2(1056, 848)]:
		check(await jump_to(point), "ordinary jump reaches summoned platform %s; actual %s" % [point, session.player.position])
	check(session.player.possibility.balance == 0, "platform climb requires no possibility or dodge")
	boss().position = Vector2(1280, 816)
	await place(Vector2(1160, 848))
	Input.action_press("jump")
	Input.action_press("move_right")
	await ticks(10)
	Input.action_press("attack")
	await ticks(12)
	Input.action_release("attack")
	Input.action_release("jump")
	Input.action_release("move_right")
	check(boss().health == 55, "platform jump enables real airborne attack against hovering Boss")
	# Drive a real dodge and one landing query through normal player Hurtbox protection.
	session.player.combat.interrupt()
	session.player.possibility.gain(3)
	await place(Vector2(960, 1280))
	before_hit = session.player.life.health
	Input.action_press("dodge")
	await ticks(5)
	Input.action_release("dodge")
	boss().position = Vector2(session.player.position.x, 1280)
	boss()._impact()
	check(session.player.life.health == before_hit, "existing dodge invincibility avoids Boss landing")
	await ticks(30)
	# An undefeated death resets HP/platforms while preserving first intro.
	session.player.life.take_hit(5)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as BossSession
	check(session.room.config.room_id == BossSession.BOSS_ID and boss().health == 60, "undefeated death restarts at Boss checkpoint with full Boss health")
	check(not session.intro_active and boss().state != OverlookBoss.State.WAITING, "retry skips completed first introduction")
	check(arena().get_node("SummonedPlatforms").get_child_count() == 0, "battle reset removes summoned platforms")
	check(session.player.life.health == 5 and session.player.life.protection_remaining > 2.8, "retry retains existing full health and three second protection")
	boss().set_physics_process(false)
	session._on_room_exit(ConnectionSession.CONNECTION_ID)
	await ticks(2)
	check(session.room.config.room_id == BossSession.BOSS_ID, "undefeated Boss locks return connection")
	session._on_room_exit("TY_10001_1")
	check(not paused, "undefeated Boss locks field connection")
	var damage: int = session.player.combat.config.damage
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	boss().hurtbox.receive_attack(60, Vector2.ZERO, session.player, 900)
	check(session._victory_pending and not arena().opened and not session.data["events"].get(BossSession.BOSS_DEFEATED, false) and not session.player.combat.range_upgraded, "failed victory write leaves pending retry without unlock or combat upgrade")
	session.store.directory = real_directory
	# Simultaneous defeat priority: death settlement must include pending Boss victory.
	session.player.life.protection_remaining = 0
	session.player.life.take_hit(5)
	check(session.store.load_slot(1)["events"].get(BossSession.BOSS_DEFEATED, false) and arena().opened, "same-frame player death saves Boss victory before returning")
	check(session.data["events"].get(BossSession.BOSS_PASSAGE, false) and session.data["events"].get(BossSession.COMBAT_GROWTH, false) and not session.data["events"].has(BossSession.GROWTH_PENDING) and session.player.combat.range_upgraded, "victory atomically grants passage and permanent combat upgrade")
	check(session.player.combat.config.damage == damage and session.player.possibility.balance == 1, "Boss adds no undefined attribute buff or possibility reward")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as BossSession
	check(boss().state == OverlookBoss.State.DEAD and arena().opened and not session.intro_active, "defeated Boss and open skylight survive death")
	await place(Vector2(48, 1280))
	check(session.room.config.room_id == ConnectionSession.CONNECTION_ID, "victory permanently opens actual return trigger")
	await place(Vector2(1488, 896))
	check(session.room.config.room_id == BossSession.BOSS_ID and arena().opened and boss().health == 0, "Room revisit neither respawns Boss nor repeats introduction")
	await close_session()
	await open_session()
	check(session.start_slot(1, false), "Boss checkpoint slot accepted on normal load")
	await ticks(4)
	check(session.room.config.room_id == BossSession.BOSS_ID and arena().opened and boss().health == 0, "normal load restores permanent Boss victory")
	check(session.player.life.protection_remaining == 0, "normal load grants no respawn protection")
	await place(Vector2(416, 1280))
	for point: Vector2 in [Vector2(608, 1136), Vector2(832, 992), Vector2(1056, 848)]:
		check(await jump_to(point), "victory retains traversable exit platform %s" % point)
	Input.action_press("move_right")
	await ticks(100)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode") == "room_boundary", "ordinary climb and walk reach open skylight at unimplemented field boundary")
	session.ui.call("resume_game")
	# Reverse same-frame order: player dies first, then the already-active attack kills Boss.
	var second: Dictionary = session.store.fresh()
	second["checkpoint"] = BossSession.BOSS_CHECKPOINT
	second["events"][BossSession.BOSS_INTRO] = true
	session.store.save_slot(2, second)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as BossSession
	boss().set_physics_process(false)
	session.player.life.take_hit(3)
	boss().hurtbox.receive_attack(60, Vector2.ZERO, session.player, 901)
	check(session.store.load_slot(2)["events"].get(BossSession.BOSS_DEFEATED, false), "player-first simultaneous death also saves Boss victory")
	check(session.store.load_slot(2)["balance"] == 1 and session.store.load_slot(2)["health"] == 5, "late Boss victory preserves completed death resource settlement")
	await ticks(90)
	# A continued disk failure must not discard the only in-memory victory on retry.
	session.data["events"].erase(BossSession.BOSS_DEFEATED)
	session.data["events"].erase(BossSession.BOSS_PASSAGE)
	session.data["events"].erase(BossSession.GROWTH_PENDING)
	session._victory_pending = true
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	session.restart_challenge()
	await ticks(3)
	check(current_scene == session and session._victory_pending, "continued write failure blocks restart from losing pending victory")
	session.store.directory = real_directory
	session.restart_challenge()
	await ticks(4)
	session = current_scene as BossSession
	check(boss().health == 0 and arena().opened, "successful save retry resumes with permanent victory")
	await close_session()
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1, 2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("OVERLOOK_BOSS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
