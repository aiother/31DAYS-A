# verify-suite: {"name": "Boss ordinary monochrome lifecycle and summon separation", "path": "res://tests/test_boss_ordinary.gd", "marker": "BOSS_ORDINARY_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: ParasiteSession
var directory: String

func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func ordinary() -> BossOrdinaryEnemies:
	return session.room.get_node("OrdinaryEnemies") as BossOrdinaryEnemies
func load_snapshot(snapshot: Dictionary) -> void:
	check(session.store.save_slot(1, snapshot) and session.start_slot(1, false), "Boss fixture loads")
	await ticks(3)
	session = current_scene as ParasiteSession
	session.player.life.protection_remaining = 1000
func run() -> void:
	directory = "user://tests/boss_ordinary_%d" % Time.get_ticks_usec()
	session = (load("res://world/parasite_session.tscn") as PackedScene).instantiate() as ParasiteSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	for flying: bool in [false, true]:
		var snapshot: Dictionary = session.store.fresh()
		var intro: String = ParasiteSession.PARASITE_INTRO if flying else BossSession.BOSS_INTRO
		var defeated: String = ParasiteSession.PARASITE_DEFEATED if flying else BossSession.BOSS_DEFEATED
		snapshot["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT if flying else BossSession.BOSS_CHECKPOINT
		await load_snapshot(snapshot)
		check(session.intro_active and ordinary().get_child_count() == 0, "first intro contains no ordinary combatant")
		if flying:
			session._end_parasite_intro(true)
		else:
			session._end_boss_intro(true)
		check(ordinary().get_child_count() == 1, "intro completion adds exactly one ordinary combatant")
		var enemy: MonochromeEntity = ordinary().get_child(0) as MonochromeEntity
		check(enemy.health == 21 and enemy.config.reward == 7 and enemy.flying == flying and enemy.ranged_only == flying, "ground/aerial monochrome uses frozen health reward and movement")
		check(enemy.target == session.player and enemy.coordinator == session.room.get_node("AttackCoordinator") and enemy._seen, "ordinary combatant immediately pursues using shared attack budget")
		var initial: Vector2 = enemy.position
		await ticks(12)
		check(enemy.position.distance_to(initial) > 1, "ordinary combatant physically pursues")
		enemy.set_physics_process(false)
		(session.room.get_node("Boss") as Node2D).set_physics_process(false)
		if flying:
			check((session.room as ParasiteRoom).living_support().is_empty(), "ordinary aerial unit consumes no colorless support slot")
		else:
			check((session.room as BossRoom).living_reinforcements().is_empty(), "ordinary ground unit consumes no colorless summon slot")
		var coordinator: EnemyAttackCoordinator = enemy.coordinator
		coordinator.release(enemy)
		var other: Node = Node.new()
		root.add_child(other)
		check(coordinator.try_acquire(enemy) and not coordinator.try_acquire(other), "ordinary and summons share one attack reservation")
		coordinator.release(enemy)
		other.queue_free()
		enemy.hurtbox.receive_attack(21, Vector2.ZERO, session.player, 9000)
		check(session.player.possibility.balance == 10 and session.store.load_slot(1)["balance"] == 10, "actual kill grants and saves exactly seven possibility")
		enemy.hurtbox.receive_attack(21, Vector2.ZERO, session.player, 9001)
		(session.room as Node).call("start_ordinary", session.player)
		check(session.player.possibility.balance == 10 and ordinary().get_child_count() == 1, "repeat hit and combat start cannot farm another ordinary combatant")
		snapshot["events"][intro] = true
		await load_snapshot(snapshot)
		check(not session.intro_active and ordinary().get_child_count() == 1, "undefeated saved intro resets ordinary combatant on load")
		enemy = ordinary().get_child(0) as MonochromeEntity
		session.player.life.protection_remaining = 0
		session.player.life.take_hit(99)
		check(not enemy.hurtbox.accepts_hits, "player death immediately disables ordinary hurtbox")
		await ticks(3)
		check(ordinary().get_child_count() == 0 and session.data["balance"] == 1, "death cleanup pays no kill reward")
		await ticks(90)
		session.ui.call("restart_challenge")
		await ticks(4)
		session = current_scene as ParasiteSession
		check(ordinary().get_child_count() == 1 and (ordinary().get_child(0) as MonochromeEntity).health == 21, "checkpoint retry restores a fresh ordinary combatant")
		await load_snapshot(snapshot)
		enemy = ordinary().get_child(0) as MonochromeEntity
		enemy.set_physics_process(false)
		var projectile: Node2D = (load("res://enemies/monochrome_projectile.tscn") as PackedScene).instantiate() as Node2D
		ordinary().add_child(projectile)
		projectile.set_physics_process(false)
		var real_directory: String = session.store.directory
		session.store.directory = real_directory.path_join("slot_1.json")
		if flying:
			(session.room.get_node("Boss") as ParasiteBoss).hurtbox.receive_attack(80, Vector2.ZERO, session.player, 9002)
		else:
			(session.room.get_node("Boss") as OverlookBoss).hurtbox.receive_attack(60, Vector2.ZERO, session.player, 9002)
		check(not enemy.hurtbox.accepts_hits and not session.data["events"].get(defeated, false), "victory clears ordinary immediately even when persistence fails")
		await ticks(3)
		check(ordinary().get_child_count() == 0 and session.player.possibility.balance == 3, "victory cleanup removes projectiles and grants no ordinary reward")
		session.room.call("start_ordinary", session.player)
		check(ordinary().get_child_count() == 0, "pending victory cannot respawn ordinary enemy")
		session.store.directory = real_directory
		check(session.save_current() and session.data["events"].get(defeated, false) and session.room.get("opened"), "victory save retry opens passage without extra clear requirement")
		var won: Dictionary = session.store.load_slot(1)
		await load_snapshot(won)
		check(ordinary().get_child_count() == 0 and session.room.get("opened"), "defeated save and revisit contain no combatants")
		var old: Dictionary = snapshot.duplicate(true)
		old["events"][defeated] = true
		await load_snapshot(old)
		check(ordinary().get_child_count() == 0, "old defeated save never gains ordinary combatants")
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(directory.path_join("slot_1.json") + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("BOSS_ORDINARY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
