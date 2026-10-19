extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var component: RemnantPossibilitySpawner
var serial: int = 40000

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)

func ticks(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func prepare(id: String, coop: bool = false) -> void:
	session.data = session.store.fresh()
	DayClock.normalize(session.data)
	FinalClock.normalize(session.data)
	session.data["events"][StartRoomSession.BIRTH] = true
	session._death_settled = false
	session._mount_room(id)
	session.intro_active = false
	session.dialogue_ui.dismiss()
	session.player.life.scripted_control_locked = false
	session.player.life.state = PlayerLife.State.ALIVE
	session.player.life.health = 5
	session.player.life.protection_remaining = 1000
	session.player.possibility.maximum = 10
	session.player.possibility.balance = 3
	session.player.position = Vector2(960, session.room.config.floor_row * 64)
	session.player.reset_kinematics()
	session.player.set_physics_process(false)
	session.room.set_physics_process(false)
	if session.room is BossRoom:
		(session.room.get_node("Boss") as OverlookBoss).start_combat()
	if session.room is ParasiteRoom:
		(session.room.get_node("Boss") as ParasiteBoss).start_combat()
	if session.room is CampWavesRoom:
		(session.room as CampWavesRoom).phase = CampWavesRoom.Phase.ACTIVE
	if session.room is FinalBattlefieldRoom:
		var area: FinalBattlefieldRoom = session.room as FinalBattlefieldRoom
		area.victory = false
		area.started = true
		area.stopped = false
		area.completed = false
		if coop:
			area.start_coop()
			area.started = true
		else:
			area.phase = RescueBattlefieldRoom.Phase.OPENING
	for container: String in ["Enemies", "OrdinaryEnemies", "Allies"]:
		if session.room.has_node(container):
			for actor: Node in session.room.get_node(container).get_children():
				actor.set_physics_process(false)
	if session.room.has_node("Boss"):
		session.room.get_node("Boss").set_physics_process(false)
	component = session.room.get_node_or_null("RemnantPossibility") as RemnantPossibilitySpawner
	if component != null:
		component.set_physics_process(false)
		component.clear_entities()
		component.rng.seed = 912
	await ticks()

func spawn_batch() -> void:
	component.remaining = -1
	component.tick(0)
	check(component.remaining >= 10 and component.remaining <= 15, "new low-resource countdown is in approved 10-15s range")
	var interval: float = component.remaining
	var before: int = component.living().size()
	component.tick(interval - 0.01)
	check(component.living().size() == before, "no early spawn before the sampled interval")
	component.tick(0.011)

func kill(entity: RemnantPossibilityEntity) -> void:
	serial += 1
	check(entity.hurtbox.receive_attack(entity.health, Vector2.ZERO, session.player, serial), "live remnant accepts player damage")

func encounter(id: String, coop: bool = false) -> void:
	await prepare(id, coop)
	check(component != null and component.encounter_active(), "approved encounter is wired: %s coop=%s" % [id, coop])
	if component == null:
		return
	var children: int = session.room.get_child_count()
	session._bind_room()
	check(session.room.get_child_count() == children, "repeated room binding does not duplicate the component")
	await spawn_batch()
	check(component.living().size() in [1, 2], "first batch has 1-2 remnants")
	for entity: RemnantPossibilityEntity in component.living():
		check(entity.get_parent() == component and not session.room.get_node("Enemies").is_ancestor_of(entity), "remnant is outside wave/summon enemy container")
		check(entity.health == 13 and entity.config.reward == 2 and entity.flying and entity.coordinator == null, "13 HP +2 flying remnant has no attack reservation")
		var offset: Vector2 = entity.global_position - session.player.global_position
		check(offset.y <= -160 and offset.y >= -240 and absf(offset.x) <= 240, "spawn uses approved player-relative height and width")
		check(session.room.config.bounds.encloses(Rect2(entity.position - Vector2(24, 80), Vector2(48, 80))), "whole spawn body stays within room bounds")
		for other: RemnantPossibilityEntity in component.living():
			if other != entity:
				check(not Rect2(entity.position - Vector2(24, 80), Vector2(48, 80)).intersects(Rect2(other.position - Vector2(24, 80), Vector2(48, 80))), "same-frame batch does not spawn bodies inside each other")
	for i: int in range(3):
		await spawn_batch()
		check(component.living().size() <= 3, "repeated batches never exceed three living remnants")
	check(component.living().size() == 3, "available positions can fill all three slots")
	var retained: RemnantPossibilityEntity = component.living()[0]
	session.player.possibility.balance = 5
	component.tick(30)
	check(component.remaining == -1 and component.living().size() == 3, "exact 50% stops and resets countdown, retaining existing entities")
	# A grown maximum must have real source flags to remain a valid save fixture.
	for key: String in ["TY_10001_1_N005", "TY_10002_1_N002:completed", "TY_10001_1_N002", "rescue:HD_20001_2:completed"]:
		session.data["events"][key] = true
	session.player.possibility.maximum = 13
	session.player.possibility.balance = 7
	component.tick(0)
	check(component.remaining == -1, "above half of a grown odd maximum does not start timer")
	session.player.possibility.balance = 6
	component.tick(0)
	check(component.remaining >= 10, "6 of 13 uses current maximum without rounding threshold down")
	session.player.possibility.balance = -9
	kill(retained)
	check(session.player.possibility.balance == -7, "negative balance receives exactly +2 debt repayment")
	retained._on_hit(100, Vector2.ZERO, session.player, serial + 1)
	check(session.player.possibility.balance == -7, "repeated lethal hit cannot pay twice")
	check(session.store.load_slot(1)["balance"] == -7, "reward uses existing resource persistence")
	var last: RemnantPossibilityEntity = component.living()[0]
	session.player.possibility.balance = 12
	kill(last)
	check(session.player.possibility.balance == 13, "retained remnant reward truncates to current maximum")
	var balance: int = session.player.possibility.balance
	component.clear_entities()
	check(component.living().is_empty() and session.player.possibility.balance == balance, "explicit cleanup grants no reward")
	session.player.possibility.balance = -9
	await spawn_batch()
	check(component.living().size() in [1, 2], "negative balance also starts a new spawn cycle")
	component.clear_entities()

func pause_and_collision() -> void:
	await prepare(BossSession.BOSS_ID)
	await spawn_batch()
	var entity: RemnantPossibilityEntity = component.living()[0]
	component.remaining = 7
	paused = true
	component.tick(20)
	check(component.remaining == 7 and not entity.movement_enabled and not entity.hurtbox.accepts_hits, "pause freezes countdown and makes existing remnants inert")
	var point: Vector2 = entity.position
	await ticks()
	check(entity.position == point, "paused tree does not drift existing remnants")
	paused = false
	session.player.life.scripted_control_locked = true
	component.tick(20)
	check(component.remaining == 7 and not entity.movement_enabled, "scripted story freezes the countdown")
	session.player.life.scripted_control_locked = false
	session.dialogue_ui.confirming = true
	component.tick(20)
	check(component.remaining == 7, "dialogue confirmation also freezes the countdown")
	session.dialogue_ui.confirming = false
	component.tick(1)
	check(component.remaining == 6 and entity.movement_enabled, "resume continues remaining time without a burst")
	var health: int = session.player.life.health
	var attacks: Array[int] = []
	entity.attack_started.connect(func(_ranged: bool) -> void: attacks.append(1))
	for i: int in range(30):
		entity._physics_process(0.1)
	check(entity.position.distance_to(point) > 0.1 and entity.position.distance_to(point) < 60, "remnant drifts slowly near its spawn")
	check(attacks.is_empty() and session.player.life.health == health and entity.config.damage == 0, "drift never attacks or damages the player")
	var coordinator: EnemyAttackCoordinator = session.room.get_node("AttackCoordinator") as EnemyAttackCoordinator
	check(coordinator._owners.is_empty(), "remnants never occupy coordinator attack slots")
	# Use the real player's four-direction collision query, with no mock receiver.
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		for action: String in ["aim_up", "aim_down"]:
			Input.action_release(action)
		session.player.position = Vector2(700, 900)
		session.player.facing = direction.x if direction.x != 0 else 1.0
		session.player.possibility.cancel()
		session.player.combat.interrupt()
		if direction.y != 0:
			Input.action_press("aim_up" if direction.y < 0 else "aim_down")
		session.player.combat._start_attack()
		var hitbox: Area2D = session.player.combat.hitbox
		entity.position = hitbox.global_position + Vector2(0, 40)
		entity.set_physics_process(false)
		entity.health = 13
		await ticks()
		session.player.combat.phase = PlayerCombat.Phase.ACTIVE
		session.player.combat.resolve_hits()
		check(entity.health == 8, "real player attack hits remnant in direction %s" % direction)
		session.player.combat.resolve_hits()
		check(entity.health == 8, "same swing cannot damage remnant twice")
	for action: String in ["aim_up", "aim_down"]:
		Input.action_release(action)
	session.player.combat.interrupt()
	component.clear_entities()
	# A solid box covering the entire candidate rectangle must prevent generation.
	session.player.position = Vector2(960, 1280)
	var block: StaticBody2D = StaticBody2D.new()
	block.collision_layer = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(600, 300)
	shape.shape = rectangle
	block.position = session.player.position + Vector2(0, -220)
	block.add_child(shape)
	session.room.add_child(block)
	await ticks()
	await spawn_batch()
	check(component.living().is_empty(), "blocked candidate region skips spawn instead of clipping into solids")
	block.queue_free()
	await ticks()
	session.player.position = Vector2(12, 1280)
	await spawn_batch()
	for spawned: RemnantPossibilityEntity in component.living():
		check(spawned.position.x >= 24, "edge-of-room candidates keep the body within bounds")
	component.clear_entities()
	session.player.position = Vector2(960, 1280)
	component.remaining = 0.01
	component.set_physics_process(true)
	await ticks(3)
	component.set_physics_process(false)
	check(not component.living().is_empty(), "normal physics frames drive generation without a manual tick call")
	component.clear_entities()

func endings_and_exclusions() -> void:
	await prepare(CampWavesSession.WAVES_ID)
	await spawn_batch()
	var area: CampWavesRoom = session.room as CampWavesRoom
	check(area.living().is_empty(), "live remnants do not enter camp wave living count")
	area.wave = area.waves.counts.size()
	area._on_defeated(0)
	component.tick(0)
	check(area.phase == CampWavesRoom.Phase.COMPLETE and component.living().is_empty(), "camp can complete with remnants present; completion clears them")
	await prepare(BossSession.BOSS_ID)
	await spawn_batch()
	check((session.room as BossRoom).living_reinforcements().is_empty(), "remnants do not consume Overlook summon capacity")
	var balance: int = session.player.possibility.balance
	(session.room as BossRoom).set_opened(true)
	component.tick(0)
	check(component.living().is_empty() and session.player.possibility.balance == balance, "Boss victory clears remnants without reward")
	await prepare(ParasiteSession.PARASITE_ID)
	await spawn_batch()
	check((session.room as ParasiteRoom).living_support().is_empty(), "remnants do not consume Parasite support capacity")
	(session.room.get_node("Boss") as ParasiteBoss).mark_defeated()
	component.tick(0)
	check(component.living().is_empty(), "Boss death clears remnants before victory save")
	await prepare(BattlefieldSession.BATTLEFIELD_ID)
	await spawn_batch()
	var battlefield: FinalBattlefieldRoom = session.room as FinalBattlefieldRoom
	for enemy: Node in battlefield.get_node("Enemies").get_children():
		if enemy is ColorlessEntity:
			enemy.health = 0
	battlefield.arrivals = 2
	# Avoid invoking the rescue cinematic in this isolated completion assertion.
	for connection: Dictionary in battlefield.stage_completed.get_connections():
		battlefield.stage_completed.disconnect(connection["callable"])
	battlefield._physics_process(0)
	check(battlefield.completed, "battlefield completion ignores live remnants")
	component.tick(0)
	check(component.living().is_empty(), "completed opening stage clears remnants")
	await prepare(BattlefieldSession.BATTLEFIELD_ID, true)
	await spawn_batch()
	battlefield = session.room as FinalBattlefieldRoom
	var previous: int = component.living().size()
	battlefield.wave_state = FinalBattlefieldRoom.WaveState.WARNING
	component.tick(0)
	check(component.living().size() == previous, "final wave warning does not end the encounter or discard remnants")
	battlefield.set_victory()
	component.tick(0)
	check(component.living().is_empty(), "final victory clears remnants without adding wave enemies")
	await prepare(BossSession.BOSS_ID)
	await spawn_batch()
	var old: WeakRef = weakref(component.living()[0])
	session.player.life.hit_interceptor = Callable()
	session.player.life.protection_remaining = 0
	session.player.life.hurt_remaining = 0
	session.player.life.take_hit(100)
	check(component.living().is_empty(), "player death synchronously clears remnants")
	var death_balance: int = session.player.possibility.balance
	component.tick(100)
	check(component.living().is_empty() and session.player.possibility.balance == death_balance, "death/menu cannot generate or award remnants")
	await ticks()
	check(old.get_ref() == null, "death frees transient entities")
	await prepare(BossSession.BOSS_ID)
	await spawn_batch()
	old = weakref(component)
	var normalized: Dictionary = session.store.fresh()
	DayClock.normalize(normalized)
	FinalClock.normalize(normalized)
	var keys: Array = normalized.keys()
	session._mount_room(TrenchSession.TRENCH_ID)
	await ticks()
	check(old.get_ref() == null and not session.room.has_node("RemnantPossibility"), "leaving frees component; trench has no remnant generator")
	session._mount_room(TrenchPassageSession.PASSAGE_ID)
	check(not session.room.has_node("RemnantPossibility"), "second trench also has no remnant generator")
	session._mount_room(TwoRoomSession.ENTRY_ID)
	check(not session.room.has_node("RemnantPossibility"), "ordinary encounter is excluded")
	for key: String in session.data:
		check(keys.has(key), "feature introduces no save key: " + key)
	await prepare(BossSession.BOSS_ID)
	await spawn_batch()
	old = weakref(component)
	session.data["checkpoint"] = BossSession.BOSS_CHECKPOINT
	session.data["events"][BossSession.BOSS_INTRO] = true
	check(session.save_current(), "existing session save succeeds with live remnants")
	check(session.start_slot(1, false), "existing slot reload starts")
	await ticks(4)
	session = current_scene as FinalBattleSession
	session.set_physics_process(false)
	session.player.set_physics_process(false)
	component = session.room.get_node("RemnantPossibility") as RemnantPossibilitySpawner
	component.set_physics_process(false)
	check(old.get_ref() == null and component.living().is_empty(), "normal reload discards entities and creates fresh component")
	check(component.remaining < 0 or component.remaining >= 9, "reload does not restore an elapsed spawn countdown")

func run() -> void:
	directory = "user://tests/remnant_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "isolated remnant test slot starts")
	session.data["events"][StartRoomSession.BIRTH] = true
	session.set_physics_process(false)
	for id: String in [CampWavesSession.WAVES_ID, BossSession.BOSS_ID, ParasiteSession.PARASITE_ID, BattlefieldSession.BATTLEFIELD_ID]:
		await encounter(id)
	await encounter(BattlefieldSession.BATTLEFIELD_ID, true)
	await pause_and_collision()
	await endings_and_exclusions()
	paused = false
	session.queue_free()
	await ticks(3)
	current_scene = null
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path):
				check(DirAccess.remove_absolute(path) == OK, "temporary remnant save removed")
	check(DirAccess.remove_absolute(directory) == OK, "temporary remnant save directory removed")
	print("REMNANT_POSSIBILITY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
