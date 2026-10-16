extends SceneTree
var checks: int = 0
var failures: int = 0
var session: ParasiteSession
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
func arena() -> ParasiteRoom:
	return session.room as ParasiteRoom
func boss() -> ParasiteBoss:
	return session.room.get_node("Boss") as ParasiteBoss
func fast_support() -> void:
	boss().config = boss().config.duplicate(true) as ParasiteConfig
	boss().config.support_initial_delay = 0.05
	boss().config.support_warning = 0.1
	boss().config.support_interval = 0.15
	boss().state = ParasiteBoss.State.RECOVERY
	boss().remaining = 1000
	arena().support_remaining = -1
	session.player.life.protection_remaining = 1000
func load_snapshot(snapshot: Dictionary) -> void:
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false), "support fixture loads with first intro already completed")
	await ticks(4)
	session = current_scene as ParasiteSession
func run() -> void:
	directory = "user://tests/parasite_support_%d" % Time.get_ticks_usec()
	session = (load("res://world/parasite_session.tscn") as PackedScene).instantiate() as ParasiteSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	base["day"] = 2
	base["events"][ParasiteSession.PARASITE_INTRO] = true
	await load_snapshot(base)
	check(boss().config.support_initial_delay==2 and boss().config.support_interval==6 and boss().config.support_warning==0.6 and boss().config.max_support==2, "default support timing and population are configurable and bounded")
	fast_support()
	await ticks(5)
	check(arena().support_pending and arena().living_support().is_empty(), "support warning appears before aerial enemy")
	var remaining: float = arena().support_remaining
	session.ui.call("show_pause")
	await ticks(8)
	check(arena().support_remaining==remaining and arena().living_support().is_empty(), "pause freezes support warning and spawning")
	session.ui.call("resume_game")
	await ticks(8)
	check(arena().living_support().size()==1, "warning produces one colorless support")
	var first: ColorlessEntity = arena().living_support()[0]
	check(first.flying and first.ranged_only and first.health==13 and first.target==session.player and first.coordinator==arena().get_node("AttackCoordinator") and first._seen, "support is existing flying ranged type and immediately targets player")
	var old_x: float = first.position.x
	await ticks(8)
	check(first.position.x<old_x, "far flying support pursues instead of waiting outside sight range")
	first.set_physics_process(false)
	await ticks(20)
	check(arena().living_support().size()==2, "periodic support reaches two living enemies")
	for enemy: ColorlessEntity in arena().living_support():
		enemy.set_physics_process(false)
	await ticks(50)
	check(arena().living_support().size()==2 and not arena().support_pending, "population cap prevents an accumulating aerial swarm")
	first.hurtbox.receive_attack(13,Vector2.ZERO,session.player,7000)
	check(session.player.possibility.balance==5 and session.store.load_slot(1)["balance"]==5, "support defeat grants and saves existing+2 possibility")
	first.hurtbox.receive_attack(13,Vector2.ZERO,session.player,7001)
	check(session.player.possibility.balance==5, "same support death cannot reward twice")
	await ticks(40)
	check(arena().living_support().size()==2, "killed support is replenished within bounded population")
	var survivor: ColorlessEntity = arena().living_support()[0]
	session.player.life.protection_remaining = 0
	session.player.life.take_hit(3)
	check(not survivor.hurtbox.accepts_hits and not arena().support_pending, "death immediately disables support hitboxes and pending warning")
	await ticks(90)
	check(arena().get_node("Enemies").get_child_count()==0 and session.data["balance"]==2, "death cleanup awards no support resources and preserves normal half settlement")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as ParasiteSession
	check(arena().living_support().is_empty() and not arena().support_pending and boss().health==80, "retry starts without stale support and resets Boss")
	await load_snapshot(base)
	fast_support()
	await ticks(40)
	check(arena().living_support().size()==2, "fresh battle can summon support again")
	boss().hurtbox.receive_attack(80,Vector2.ZERO,session.player,7002)
	await ticks(2)
	check(arena().living_support().is_empty() and not arena().support_pending and session.player.possibility.balance==3, "Boss victory clears support without fake kill rewards")
	await ticks(60)
	check(arena().get_node("Enemies").get_child_count()==0 and arena().opened and session.data["day"]==3, "defeated Boss never summons again and retains victory date")
	var intro: Dictionary = base.duplicate(true)
	intro["events"].erase(ParasiteSession.PARASITE_INTRO)
	await load_snapshot(intro)
	await ticks(30)
	check(session.intro_active and arena().living_support().is_empty() and not arena().support_pending, "first introduction contains no combat support")
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(directory.path_join("slot_1.json")+suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("PARASITE_SUPPORT_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
