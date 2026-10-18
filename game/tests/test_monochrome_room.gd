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
func quiet() -> void:
	for actor: Node in session.room.get_node("Enemies").get_children():
		actor.set_physics_process(false)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func run() -> void:
	directory = "user://tests/monochrome_room_%d" % Time.get_ticks_usec()
	session = (load("res://world/trench_session.tscn") as PackedScene).instantiate() as TrenchSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchSession.TRENCH_CHECKPOINT
	snapshot["balance"] = -9
	snapshot["day"] = 3
	snapshot["events"][ParasiteSession.DODGE_PENDING] = true
	# This fixture already starts on day three; include the current NPC deadlines
	# so the later no-new-events assertion isolates combat rather than migration.
	WorldDayRules.sync(snapshot)
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false), "old trench checkpoint loads with new enemy composition")
	await ticks(4)
	quiet()
	var ground: MonochromeEntity = session.room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
	var air: MonochromeEntity = session.room.get_node("Enemies/FlyingMonochrome") as MonochromeEntity
	check(ground.health==21 and air.health==21 and air.flying and air.ranged_only, "approved Room contains ground and flying monochrome variants")
	check(ground.target==session.player and air.coordinator==session.room.get_node("AttackCoordinator"), "session binds target and shared attack coordinator")
	check(session.room.get_node("Enemies/DownAttackEntity") is ColorlessEntity and session.room.get_node("Enemies/UpperEntity") is ColorlessEntity, "existing two colorless entities remain present")
	await place(Vector2(1356,1792))
	ground.set_physics_process(true)
	await ticks(2)
	session.player.facing = 1
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	check(ground.motion==MonochromeEntity.Motion.DODGE, "production Room enemy actually dodges player attack")
	var position_before: Vector2 = ground.position
	var cooldown_before: float = ground.dodge_cooldown_remaining
	paused = true
	await ticks(12)
	check(ground.position==position_before and ground.dodge_cooldown_remaining==cooldown_before, "pause freezes dodge displacement and cooldown")
	paused = false
	await ticks(14)
	check(ground.hurtbox.accepts_hits, "resuming completes dodge vulnerability window")
	ground.set_physics_process(false)
	session.player.combat.interrupt()
	ground.hurtbox.receive_attack(21,Vector2.ZERO,session.player,3000)
	check(session.player.possibility.balance==-2 and session.store.load_slot(1)["balance"]==-2, "real defeat immediately pays and saves+7 against negative balance")
	ground.hurtbox.receive_attack(21,Vector2.ZERO,session.player,3001)
	check(session.player.possibility.balance==-2, "corpse cannot pay twice")
	await place(Vector2(48,1792))
	quiet()
	check(session.room is OutskirtsRoom, "existing trench return still reaches outskirts")
	await place(Vector2(2928,1280))
	quiet()
	ground = session.room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
	check(ground.health==21 and ground.dodge_cooldown_remaining==0 and ground._attack_count==0, "revisit resets HP defense and attack cadence")
	ground.hurtbox.receive_attack(21,Vector2.ZERO,session.player,3002)
	check(session.player.possibility.balance==5, "reset monochrome still rewards+7")
	air = session.room.get_node("Enemies/FlyingMonochrome") as MonochromeEntity
	air.hurtbox.receive_attack(21,Vector2.ZERO,session.player,3003)
	check(session.player.possibility.balance==10, "flying reward truncates overflow to current possibility maximum")
	check(session.data["day"]==3 and session.data["events"]==snapshot["events"] and session._all_checkpoints().size()==1 and session._pickups().size()==1, "enemy addition creates no new story growth checkpoint or pickup")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TrenchSession
	quiet()
	ground = session.room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
	check(ground.health==21 and session.player.life.health==5 and session.player.possibility.balance==5 and session.player.life.protection_remaining>2.8, "death resets new enemy and preserves existing resource settlement and protection")
	check(session.start_slot(1,false), "saved new enemy rewards remain normally loadable")
	await ticks(4)
	session = current_scene as TrenchSession
	quiet()
	check(session.room is TrenchRoom and session.player.life.protection_remaining==0 and session.data["day"]==3 and session.player.possibility.balance==5, "normal load keeps checkpoint date and balance without revive protection")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(directory.path_join("slot_1.json")+suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("MONOCHROME_ROOM_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
