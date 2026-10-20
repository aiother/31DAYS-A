# verify-suite: {"name": "Tian first introduction freedom rewards and save retries", "path": "res://tests/test_tian_room.gd", "marker": "TIAN_ROOM_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TianSession
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
func quiet(only_others: bool = false) -> void:
	for actor: Node in session.room.get_node("Enemies").get_children():
		if not only_others or not actor is TianWarrior:
			actor.set_physics_process(false)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func card() -> Control:
	return session.ui.get("_enemy_intro") as Control
func run() -> void:
	directory = "user://tests/tian_room_%d" % Time.get_ticks_usec()
	session = (load("res://world/tian_session.tscn") as PackedScene).instantiate() as TianSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchSession.TRENCH_CHECKPOINT
	snapshot["balance"] = -9
	snapshot["day"] = 3
	snapshot["events"][ParasiteSession.DODGE_PENDING] = true
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false), "old trench save loads in Tian-enabled main scene")
	await ticks(4)
	quiet(true)
	var first: TianWarrior = session.room.get_node("Enemies/TianFront") as TianWarrior
	var second: TianWarrior = session.room.get_node("Enemies/TianRear") as TianWarrior
	check(first.health==31 and second.health==31 and first.flank_side==-1 and second.flank_side==1, "two warriors occupy opposite assigned flanks")
	check(not first.is_physics_processing() and not second.is_physics_processing() and not card().visible, "first encounter waits for designated trigger rather than charging checkpoint")
	check(first.target==session.player and second.coordinator==first.coordinator and session._all_checkpoints().size()==1 and session._pickups().size()==1, "existing target budget checkpoint and pearl wiring preserved")
	await place(Vector2(704,1792))
	check(session.data["events"].get(TianSession.TIAN_INTRO,false) and session.store.load_slot(1)["events"].get(TianSession.TIAN_INTRO,false), "real encounter range persists numbered first introduction")
	check(card().visible and (card().get_child(0) as Label).text.contains("天人战士") and first.is_physics_processing() and second.is_physics_processing(), "intro card displays and normal combat starts")
	quiet()
	check(not session.intro_active and not session.player.life.scripted_control_locked and session.player.life.can_control(), "introduction does not lock player controls")
	var before_x: float = session.player.position.x
	Input.action_press("move_right")
	await ticks(10)
	Input.action_release("move_right")
	check(session.player.position.x>before_x+15, "real movement works while introduction card remains on screen")
	var remaining: float = float(session.ui.get("_enemy_intro_remaining"))
	paused = true
	await ticks(10)
	check(float(session.ui.get("_enemy_intro_remaining"))==remaining, "pause freezes introduction timer")
	paused = false
	session.ui.call("hide_enemy_intro")
	first.hurtbox.receive_attack(31,Vector2.ZERO,session.player,5000)
	check(session.player.possibility.balance==2 and session.store.load_slot(1)["balance"]==2, "Tian defeat credits and saves+11 from negative balance")
	first.hurtbox.receive_attack(31,Vector2.ZERO,session.player,5001)
	check(session.player.possibility.balance==2, "same warrior corpse cannot pay twice")
	await place(Vector2(48,1792))
	quiet()
	check(session.room is OutskirtsRoom, "existing return remains open")
	await place(Vector2(2928,1280))
	quiet()
	first = session.room.get_node("Enemies/TianFront") as TianWarrior
	check(first.health==31 and first.combo_step==0 and first.guard_cooldown_remaining==0, "revisit resets HP combo and guard state")
	await place(Vector2(704,1792))
	check(not card().visible and session.data["events"].get(TianSession.TIAN_INTRO,false), "revisit preserves first encounter and does not replay card")
	first.hurtbox.receive_attack(31,Vector2.ZERO,session.player,5002)
	check(session.player.possibility.balance==10, "reset warrior again pays+11 truncated at current maximum")
	check(session.data["day"]==3 and session.data["events"].get(ParasiteSession.DODGE_PENDING,false) and session.player.possibility.maximum==10, "new enemy does not advance day or claim pending growth")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TianSession
	quiet()
	check(session.room is TrenchRoom and session.player.possibility.balance==5 and session.player.life.health==5 and session.player.life.protection_remaining>2.8, "death restores formal checkpoint health half balance and protection")
	check(session.data["events"].get(TianSession.TIAN_INTRO,false) and not card().visible and (session.room.get_node("Enemies/TianFront") as TianWarrior).health==31, "death preserves introduction while resetting normal warriors")
	check(session.start_slot(1,false), "normal slot remains loadable")
	await ticks(4)
	session = current_scene as TianSession
	quiet()
	check(session.player.life.protection_remaining==0 and session.data["day"]==3 and session.player.possibility.balance==5, "normal load preserves day resources without revive protection")
	# A second slot has never met Tian warriors; simulate unwritable saves.
	check(session.store.save_slot(2,snapshot) and session.start_slot(2,false), "fresh second slot remains independent of first introduction")
	await ticks(4)
	session = current_scene as TianSession
	quiet(true)
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	await place(Vector2(1008,1792))
	first = session.room.get_node("Enemies/TianFront") as TianWarrior
	check(not session.data["events"].has(TianSession.TIAN_INTRO) and session._tian_intro_retry and not card().visible and not first.is_physics_processing(), "failed intro save rolls back event and remains retryable")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.data["events"].get(TianSession.TIAN_INTRO,false) and card().visible and first.is_physics_processing() and not session._tian_intro_retry, "E retry persists card and enables warriors without locking controls")
	quiet()
	check(session.player.life.can_control() and session.store.load_slot(1)["balance"]==5 and session.store.load_slot(2)["balance"]==-9, "failed-write recovery keeps separate slots and control state intact")
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
	print("TIAN_ROOM_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
