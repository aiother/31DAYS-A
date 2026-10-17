extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func quiet() -> void:
	if session.room.has_node("Boss"):
		session.room.get_node("Boss").set_physics_process(false)
func load_slot(selected: int) -> void:
	check(session.start_slot(selected,false),"selected slot loads")
	await ticks(4)
	session = current_scene as FinalBattleSession
	quiet()
func actual_dodge(air: bool, poor: bool, speed: float) -> void:
	session.player.possibility.reset_actions()
	session.player.combat.interrupt()
	session.player.landing_lock_remaining = 0
	session.player.position = Vector2(300,1250 if air else 1536)
	session.player.reset_kinematics()
	session._set_balance(0 if poor else 9)
	session.player.facing = 1
	await ticks(2)
	check(session.player.possibility.try_dodge(),"actual dodge starts air=%s poor=%s" % [air,poor])
	for i: int in range(15):
		if session.player.possibility.state==PlayerPossibility.State.DODGE_ACTIVE: break
		await ticks(1)
	var possibility: PlayerPossibility = session.player.possibility
	check(possibility.state==PlayerPossibility.State.DODGE_ACTIVE and possibility.poor_dodge==poor and possibility.horizontal_speed()==speed,"active speed matches granted ability in both resource states")
	var start: Vector2 = session.player.position
	await ticks(5)
	check(session.player.position.x-start.x>=speed*4/60 and session.player.position.x-start.x<=speed*7/60,"actual body moves at granted dodge speed")
	if air:
		check(session.player.position.y>start.y,"air upgrade preserves gravity instead of hovering")
	check(possibility.balance==(-1 if poor else 8) and possibility.chain==1,"upgrade retains first dodge cost and chain")
	await ticks(25)
	check(not possibility.busy(),"upgrade retains bounded active and recovery time")

func run() -> void:
	directory = "user://tests/dodge_growth_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	base["events"][ParasiteSession.PARASITE_INTRO] = true
	check(session.store.save_slot(1,base),"unearned base slot stored")
	var old: Dictionary = base.duplicate(true)
	old["day"] = 3
	old["events"][ParasiteSession.PARASITE_DEFEATED] = true
	old["events"][ParasiteSession.PARASITE_PASSAGE] = true
	old["events"][ParasiteSession.DODGE_PENDING] = true
	check(session.store.save_slot(2,old),"old defeated pending slot remains valid")
	await load_slot(1)
	check(not session.player.possibility.dodge_upgraded,"unearned slot retains base speed")
	await actual_dodge(false,false,720)
	await load_slot(2)
	check(session.player.possibility.dodge_upgraded and session.store.load_slot(2)["events"].get(ParasiteSession.DODGE_GROWTH,false) and not session.data["events"].has(ParasiteSession.DODGE_PENDING),"old defeated save grants and persists one-time upgrade while consuming pending marker")
	var config: PossibilityConfig = session.player.possibility.config
	check(config.dodge_speed==720 and config.enhanced_dodge_speed==900 and config.dodge_duration==0.2 and config.invincible_duration==0.16 and config.poor_invincible_duration==0.08 and config.combo_reset==1.3 and config.dodge_windup==0.05 and config.poor_windup==0.15 and config.dodge_recovery==0.08,"shared Resource keeps all original costs and timings")
	for air: bool in [false,true]:
		for poor: bool in [false,true]:
			await actual_dodge(air,poor,900)
	session.player.possibility.cancel()
	session.player.life.protection_remaining = 0
	session.player.life.take_hit(5)
	await ticks(90)
	session.restart_challenge()
	await ticks(4)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.player.possibility.dodge_upgraded and session.player.life.health==5,"death and checkpoint restore preserve upgrade")
	await load_slot(1)
	check(not session.player.possibility.dodge_upgraded and session.player.possibility.config.dodge_speed==720,"switching to unearned slot resets ability without Resource mutation")
	# Old migration write failure must not grant unsaved power. Use another fixture
	# store so the current store can point at an existing file instead of a folder.
	check(session.store.save_slot(3,old),"migration retry fixture stored")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	session._restore(old,false)
	quiet()
	check(not session.player.possibility.dodge_upgraded and session.data["events"].get(ParasiteSession.DODGE_PENDING,false) and not session.data["events"].has(ParasiteSession.DODGE_GROWTH),"failed migration rolls back claim and runtime speed")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.player.possibility.dodge_upgraded and session.store.load_slot(1)["events"].get(ParasiteSession.DODGE_GROWTH,false),"E retry grants exactly once after storage recovery")
	var claimed: Dictionary = session.data.duplicate(true)
	check(session.save_current() and session.player.possibility.config.enhanced_dodge_speed==900,"repeated save does not multiply speed")
	claimed["events"].erase(ParasiteSession.PARASITE_DEFEATED)
	check(not session.store.valid(claimed),"claim without Boss victory is rejected")
	claimed = session.data.duplicate(true)
	claimed["events"][ParasiteSession.DODGE_PENDING] = true
	check(not session.store.valid(claimed),"simultaneous pending and claimed records are rejected")
	check(session.start_slot(1,true),"confirmed new game resets grown slot")
	await ticks(4)
	session = current_scene as FinalBattleSession
	check(not session.player.possibility.dodge_upgraded and not session.data["events"].has(ParasiteSession.DODGE_GROWTH),"new game starts with base ability and no claimed marker")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("DODGE_GROWTH_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
