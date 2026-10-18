extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var base_bounce_velocity: float = 0.0

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
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
	session.player.set_physics_process(false)

func load_slot(selected: int, fresh: bool = false) -> void:
	check(session.start_slot(selected, fresh), "normal slot selection succeeds")
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()

func geometry(direction: Vector2, count: int, boss: bool) -> void:
	var combat: PlayerCombat = session.player.combat
	combat.interrupt()
	combat.pearl_count = count
	combat.range_upgraded = boss
	for action: String in ["aim_up", "aim_down", "run", "move_right", "move_left"]: Input.action_release(action)
	session.player.position = Vector2(1000, 400)
	session.player.reset_kinematics()
	session.player.set_physics_process(true)
	await ticks(2)
	session.player.set_physics_process(false)
	session.player.facing = direction.x if direction.x != 0 else 1.0
	if direction.y != 0: Input.action_press("aim_up" if direction.y < 0 else "aim_down")
	combat._start_attack()
	var reach: float = 1.0 + count * 0.05 + (0.2 if boss else 0.0)
	check(is_equal_approx(combat.range_multiplier(), reach), "additive reach count=%d boss=%s" % [count, boss])
	check((combat.hit_shape.shape as RectangleShape2D).size.is_equal_approx((combat.config.side_size if direction.y == 0 else combat.config.vertical_size) * reach) and combat.hitbox.position.is_equal_approx(Vector2(direction.x * 76 * reach, -48 + direction.y * 64 * reach)), "real four-direction shape and chest-relative offset %s" % direction)
	var hits: Array[int] = []
	var targets: Array[CombatHurtbox] = []
	var edge: float = (132.0 if direction.y == 0 else 114.0) * reach
	for distance: float in [edge - 2, edge + 6]:
		var receiver: CombatHurtbox = CombatHurtbox.new()
		receiver.collision_layer = 16
		receiver.monitoring = false
		var collider: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(4, 4)
		collider.shape = shape
		receiver.add_child(collider)
		session.add_child(receiver)
		receiver.position = session.player.position + Vector2(0, -48) + direction * distance
		receiver.hit_received.connect(func(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void: hits.append(damage))
		targets.append(receiver)
	await ticks(2)
	combat.phase = PlayerCombat.Phase.ACTIVE
	combat.resolve_hits()
	combat.resolve_hits()
	check(hits == [5], "actual expanded query hits inside edge once for 5, misses outside")
	if direction == Vector2.DOWN:
		if base_bounce_velocity == 0.0: base_bounce_velocity = session.player.velocity.y
		check(session.player.velocity.y < 0 and is_equal_approx(session.player.velocity.y, base_bounce_velocity), "real down-attack bounce is identical for every pearl/Boss combination")
	var projectile: ColorlessProjectile = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as ColorlessProjectile
	session.add_child(projectile)
	projectile.set_physics_process(false)
	projectile.position = session.player.position + Vector2(0, -48) + direction * (edge - 2)
	await ticks(2)
	combat.resolve_hits()
	check(projectile.reflected == (direction.y <= 0), "expanded projectile query preserves downward no-reflect")
	projectile.queue_free()
	for receiver: CombatHurtbox in targets: receiver.queue_free()
	combat.interrupt()
	await ticks(2)

func run() -> void:
	directory = "user://tests/pearl_growth_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for key: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER]: base["events"][key] = true
	var old: Dictionary = base.duplicate(true)
	for key: String in ExplorationSession.PEARL_KEYS: old["events"][key] = true
	old["events"][BossSession.BOSS_DEFEATED] = true
	old["events"][BossSession.GROWTH_PENDING] = true
	var partial: Dictionary = base.duplicate(true)
	partial["events"][ExplorationSession.PEARL_KEYS[2]] = true
	partial["events"][ExplorationSession.PEARL_KEYS[0]] = false
	partial["events"]["item:unknown:pearl_01"] = true
	check(session.store.save_slot(1, base) and session.store.save_slot(2, old) and session.store.save_slot(3, partial), "legacy version1 saves require no new field or migration")
	await load_slot(1)
	check(session.player.combat.pearl_count == 0 and session.player.combat.range_multiplier() == 1.0, "uncollected slot starts at base reach")
	for count: int in range(5):
		for boss: bool in [false, true]:
			for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: await geometry(direction, count, boss)
	await load_slot(2)
	check(session.player.combat.pearl_count == 4 and is_equal_approx(session.player.combat.range_multiplier(), 1.4) and session.player.combat.range_upgraded, "old four-pearl save and old Boss pending reward combine automatically")
	check(session.player.possibility.balance == 3 and session.player.possibility.maximum == 10 and session.player.life.health == 3 and session.data["day"] == 1, "legacy effect grants no health possibility cap or date")
	check(session.save_current() and session.save_current() and is_equal_approx(session.player.combat.range_multiplier(), 1.4), "repeated saves never compound growth")
	var config: AttackConfig = session.player.combat.config
	check(config.damage == 5 and config.side_size == Vector2(112,72) and config.vertical_size == Vector2(80,100) and config.side_offset == 76 and config.vertical_offset == 64 and config.enhanced_range_multiplier == 1.2 and config.pearl_range_bonus == 0.05, "shared Resource remains unchanged by all combinations")
	check(config.windup == 0.08 and config.active_duration == 0.1 and config.recovery_first == 0.14 and config.recovery_second == 0.28 and config.running_timing_multiplier == 2 and config.combo_timeout == 0.5 and config.down_bounce_jump_height_ratio == 0.5, "timings combo and bounce remain unchanged")
	await ticks(2)
	check(str(session.ui.get("_health").text).contains("珍珠 4 / 4 · 近战范围 140%"), "HUD reports combined real reach")
	# A swing snapshots geometry; permanent changes only affect the next swing.
	for action: String in ["aim_up", "aim_down"]: Input.action_release(action)
	session.player.combat._start_attack()
	var current_shape: Vector2 = (session.player.combat.hit_shape.shape as RectangleShape2D).size
	session.player.combat.pearl_count = 0
	check((session.player.combat.hit_shape.shape as RectangleShape2D).size == current_shape, "current swing keeps its starting geometry")
	session.player.combat.interrupt()
	session.player.combat._start_attack()
	check((session.player.combat.hit_shape.shape as RectangleShape2D).size.is_equal_approx(config.side_size * 1.2), "next swing takes new source snapshot")
	session.player.combat.interrupt()
	session._sync_pearl_growth()
	session.player.set_physics_process(true)
	check(session.player.life.take_hit(5), "real lethal hit begins normal death settlement")
	await ticks(90)
	session.restart_challenge()
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.player.combat.pearl_count == 4 and is_equal_approx(session.player.combat.range_multiplier(), 1.4) and session.player.life.health == 5, "death and checkpoint reload retain both permanent sources")
	await load_slot(3)
	check(session.player.combat.pearl_count == 1 and is_equal_approx(session.player.combat.range_multiplier(), 1.05) and not session.player.combat.range_upgraded, "slot isolation counts only true known pearl sources")
	await load_slot(1)
	check(session.player.combat.pearl_count == 0 and session.player.combat.range_multiplier() == 1.0, "switching to empty slot clears previous pearl effects")
	# All four production pickups: failed write cannot grant reach; actual E grants once.
	var rooms: Array[String] = [ExplorationSession.EXPLORATION_ID, RavineDepthSession.DEPTH_ID, CampSession.CAMP_ID, TrenchSession.TRENCH_ID]
	for index: int in range(rooms.size()):
		session._change_room(rooms[index])
		quiet()
		var pickup: RoomPickup = session._pickups()[0]
		check(pickup.config.persistence_key == ExplorationSession.PEARL_KEYS[index], "production pickup matches stable old key")
		session.player.position = pickup.position + Vector2(0,44)
		session.player.reset_kinematics()
		var saved_directory: String = session.store.directory
		session.store.directory = saved_directory.path_join("slot_1.json")
		check(not session.collect_pickup(pickup) and pickup.visible and session.player.combat.pearl_count == index and not session.data["events"].has(pickup.config.persistence_key), "failed write rolls ownership back without granting range")
		session.store.directory = saved_directory
		Input.action_press("interact")
		await ticks(1)
		Input.action_release("interact")
		await ticks(2)
		check(not pickup.visible and session.player.combat.pearl_count == index + 1 and session.store.load_slot(1)["events"].get(pickup.config.persistence_key,false) and is_equal_approx(session.player.combat.range_multiplier(), 1.0+(index+1)*0.05), "actual E grants saved pearl reach immediately")
		check(not session.collect_pickup(pickup) and session.player.combat.pearl_count == index + 1 and str(session.ui.get("_error_label").text).is_empty(), "duplicate cannot stack and successful retry clears error")
		session._mount_room(TwoRoomSession.ENTRY_ID)
		quiet()
		session._mount_room(rooms[index])
		quiet()
		check(not session._pickups()[0].visible and session.player.combat.pearl_count == index + 1, "Room unload and revisit preserve exact effect")
	await load_slot(1)
	check(session.player.combat.pearl_count == 4 and is_equal_approx(session.player.combat.range_multiplier(), 1.2) and not session.player.combat.range_upgraded, "four pearls alone persist at120% through normal reload")
	await load_slot(1, true)
	check(session.player.combat.pearl_count == 0 and session.player.combat.range_multiplier() == 1.0 and session.store.load_slot(2)["events"].get(ExplorationSession.PEARL_KEYS[0],false), "new game clears its pearls without touching another slot")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("PEARL_GROWTH_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
