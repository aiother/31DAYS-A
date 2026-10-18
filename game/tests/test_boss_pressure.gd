extends SceneTree
var checks: int = 0
var failures: int = 0
var session: BossSession
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
func run() -> void:
	var directory: String = "user://tests/boss_pressure_%d" % Time.get_ticks_usec()
	session = (load("res://world/boss_session.tscn") as PackedScene).instantiate() as BossSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	snapshot["events"][BossSession.BOSS_INTRO] = true
	session.store.save_slot(1, snapshot)
	session.start_slot(1, false)
	var arena: BossRoom = session.room as BossRoom
	var actor: OverlookBoss = arena.get_node("Boss") as OverlookBoss
	session.player.life.protection_remaining = 100
	check(actor.config.recovery_duration == 0.45 and actor.config.hover_duration == 4.0 and actor.config.rise_speed == 900, "shorter recovery and hover with faster ascent")
	check(actor.config.windup_duration == 0.6 and actor.config.damage == 1 and actor.health == 60, "readable landing warning and existing damage/health preserved")
	check(arena.living_reinforcements().is_empty(), "no add appears before summon skill")
	check(arena.get_node("OrdinaryEnemies").get_child_count() == 1, "ordinary monochrome is present before summons without occupying their slots")
	for i: int in range(150):
		await ticks(1)
		if arena.summon_pending:
			break
	check(arena.summon_pending and arena.living_reinforcements().is_empty(), "real AI starts visible summon warning before spawning")
	check(arena.summon_position.distance_to(session.player.position) > 240, "warning starts at a ground anchor away from player")
	var timer: float = actor.summon_remaining
	session.ui.call("show_pause")
	await ticks(6)
	check(actor.summon_remaining == timer and arena.living_reinforcements().is_empty(), "pause freezes summon countdown and spawning")
	session.ui.call("resume_game")
	await ticks(40)
	check(arena.living_reinforcements().size() == 1, "AI summons first colorless entity after warning")
	var add: ColorlessEntity = arena.living_reinforcements()[0]
	check(add.health == 13 and add.target == session.player and add.coordinator == arena.get_node("AttackCoordinator"), "summon uses existing health target and attack coordinator")
	var before_motion: Vector2 = add.position
	await ticks(10)
	check(add.position.distance_to(before_motion) > 1, "distant summoned enemy immediately pursues beyond normal sight range")
	session.player.position.x = 1200
	session.player.reset_kinematics()
	await ticks(60)
	check(add.position.distance_to(before_motion) > 1 or add.state in [ColorlessEntity.State.WINDUP, ColorlessEntity.State.ACTIVE, ColorlessEntity.State.RECOVERY], "summoned enemy runs real combat AI: state=%d" % add.state)
	var landings: int = 0
	var previous: OverlookBoss.State = actor.state
	for i: int in range(600):
		await ticks(1)
		if actor.state == OverlookBoss.State.RECOVERY and previous != actor.state:
			landings += 1
		previous = actor.state
	check(landings >= 2, "Boss resumes at least two landing attacks within ten seconds")
	check(arena.living_reinforcements().size() == 2, "repeated real summon cycles respect two living add cap")
	var balance: int = session.player.possibility.balance
	add.hurtbox.receive_attack(13, Vector2.ZERO, session.player, 700)
	check(session.player.possibility.balance == balance + 2, "summoned colorless defeat awards existing +2 possibility")
	add._on_hit(13, Vector2.ZERO, session.player, 701)
	check(session.player.possibility.balance == balance + 2, "dead summoned instance cannot pay twice")
	for i: int in range(400):
		await ticks(1)
		if arena.living_reinforcements().size() == 2:
			break
	check(arena.living_reinforcements().size() == 2, "later skill replenishes a defeated add without exceeding cap")
	# Pending warnings and projectiles are transient combat state, never save events.
	arena.prepare_reinforcement()
	var projectile: Node2D = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as Node2D
	projectile.position = Vector2(1800, 400)
	arena.get_node("Enemies").add_child(projectile)
	balance = session.player.possibility.balance
	actor.hurtbox.receive_attack(60, Vector2.ZERO, session.player, 702)
	await ticks(3)
	check(arena.get_node("Enemies").get_child_count() == 0 and not arena.summon_pending, "Boss defeat clears summoned enemies projectiles and warnings")
	check(session.player.possibility.balance == balance, "cleanup grants no kill rewards")
	arena.prepare_reinforcement()
	arena.spawn_reinforcement()
	check(arena.living_reinforcements().is_empty(), "defeated Boss cannot summon again")
	# A fresh undefeated battle clears adds on player death and starts clean on retry.
	var second: Dictionary = snapshot.duplicate(true)
	session.store.save_slot(2, second)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as BossSession
	arena = session.room as BossRoom
	actor = arena.get_node("Boss") as OverlookBoss
	arena.prepare_reinforcement()
	arena.spawn_reinforcement()
	check(arena.living_reinforcements().size() == 1, "fresh undefeated battle can summon")
	arena.prepare_reinforcement()
	session.player.life.take_hit(3)
	await ticks(3)
	check(arena.get_node("Enemies").get_child_count() == 0 and not arena.summon_pending, "player death clears summons and pending warning")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as BossSession
	arena = session.room as BossRoom
	check(arena.living_reinforcements().is_empty() and not arena.summon_pending, "death retry begins with no stale summons")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1, 2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("BOSS_PRESSURE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
