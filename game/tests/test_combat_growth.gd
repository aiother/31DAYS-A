extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func quiet() -> void:
	if session.room.has_node("Boss"): session.room.get_node("Boss").set_physics_process(false)
func load_slot(selected: int) -> void:
	check(session.start_slot(selected,false),"selected growth slot loads")
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
func prepare(direction: Vector2, upgraded: bool) -> void:
	for action: String in ["aim_up","aim_down","run","move_right","move_left"]: Input.action_release(action)
	session.player.set_physics_process(true)
	session.player.position = Vector2(300,900)
	session.player.reset_kinematics()
	await ticks(2)
	session.player.set_physics_process(false)
	session.player.combat.range_upgraded = upgraded
	session.player.facing = direction.x if direction.x!=0 else 1.0
	if direction.y!=0: Input.action_press("aim_up" if direction.y<0 else "aim_down")
	session.player.combat._start_attack()
func geometry(direction: Vector2, upgraded: bool) -> void:
	await prepare(direction,upgraded)
	var combat: PlayerCombat = session.player.combat
	var multiplier: float = 1.2 if upgraded else 1.0
	var expected: Vector2 = (combat.config.side_size if direction.y==0 else combat.config.vertical_size)*multiplier
	check((combat.hit_shape.shape as RectangleShape2D).size.is_equal_approx(expected),"four-direction size scales exactly once: %s upgraded=%s" % [direction,upgraded])
	check(combat.hitbox.position.is_equal_approx(Vector2(direction.x*76*multiplier,-48+direction.y*64*multiplier)),"offset scales around fixed chest origin")
	check(combat.phase==PlayerCombat.Phase.WINDUP and is_equal_approx(combat._phase_remaining,0.08),"upgrade keeps actual windup")
	var receiver: CombatHurtbox = CombatHurtbox.new()
	receiver.collision_layer = 16
	receiver.collision_mask = 0
	receiver.monitoring = false
	var collider: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(8,8)
	collider.shape = rectangle
	receiver.add_child(collider)
	session.add_child(receiver)
	receiver.global_position = session.player.global_position+Vector2(0,-48)+direction*(145 if direction.y==0 else 125)
	var hits: Array[int] = []
	receiver.hit_received.connect(func(damage: int,_impulse: Vector2,_source: Node2D,_id: int) -> void: hits.append(damage))
	await ticks(2)
	combat.phase = PlayerCombat.Phase.ACTIVE
	combat.resolve_hits()
	combat.resolve_hits()
	check(hits==([5] if upgraded else []),"real query hits new reach only after upgrade;5 damage once")
	combat._advance_phase()
	check(combat.phase==PlayerCombat.Phase.RECOVERY and is_equal_approx(combat._phase_remaining,0.14),"upgrade keeps actual recovery")
	receiver.queue_free()
	combat.interrupt()
	await ticks(2)
func projectile(direction: Vector2, upgraded: bool) -> void:
	await prepare(direction,upgraded)
	var object: ColorlessProjectile = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as ColorlessProjectile
	session.add_child(object)
	object.set_physics_process(false)
	object.position = session.player.position+Vector2(0,-48)+direction*(150 if direction.y==0 else 130)
	await ticks(2)
	session.player.combat.phase = PlayerCombat.Phase.ACTIVE
	session.player.combat.resolve_hits()
	check(object.reflected==(upgraded and direction.y<=0),"real projectile uses expanded range and existing downward no-reflect rule")
	object.queue_free()
	session.player.combat.interrupt()
	await ticks(2)
func run() -> void:
	directory = "user://tests/combat_growth_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = BossSession.BOSS_CHECKPOINT
	base["events"][BossSession.BOSS_INTRO] = true
	var old: Dictionary = base.duplicate(true)
	old["events"][BossSession.BOSS_DEFEATED] = true
	old["events"][BossSession.BOSS_PASSAGE] = true
	old["events"][BossSession.GROWTH_PENDING] = true
	check(session.store.save_slot(1,base) and session.store.save_slot(2,old),"base and old pending slots remain valid")
	await load_slot(1)
	check(not session.player.combat.range_upgraded,"unearned slot uses base reach")
	for upgraded: bool in [false,true]:
		for direction: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]: await geometry(direction,upgraded)
		for direction: Vector2 in [Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: await projectile(direction,upgraded)
	session.player.set_physics_process(true)
	await load_slot(2)
	check(session.player.combat.range_upgraded and session.store.load_slot(2)["events"].get(BossSession.COMBAT_GROWTH,false) and not session.data["events"].has(BossSession.GROWTH_PENDING),"old defeated pending save grants and consumes marker once")
	var config: AttackConfig = session.player.combat.config
	check(config.side_size==Vector2(112,72) and config.vertical_size==Vector2(80,100) and config.side_offset==76 and config.vertical_offset==64 and config.enhanced_range_multiplier==1.2,"shared Resource retains base geometry")
	check(config.damage==5 and config.combo_timeout==0.5 and config.running_timing_multiplier==2 and config.down_bounce_jump_height_ratio==0.5 and config.active_duration==0.1 and config.recovery_second==0.28,"damage combo running timings and bounce remain frozen")
	check(session.player.life.health==3 and session.player.possibility.balance==3 and session.data["day"]==1,"migration adds no resources health or date")
	check(session.save_current() and session.save_current() and session.player.combat.range_upgraded,"repeat saves do not stack range")
	session.player.life.take_hit(5)
	await ticks(90)
	session.restart_challenge()
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.player.combat.range_upgraded and session.player.life.health==5,"death and checkpoint restore keep combat growth")
	await load_slot(1)
	check(not session.player.combat.range_upgraded and config.side_size==Vector2(112,72),"slot switch resets runtime flag without Resource leakage")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	session._restore(old,false)
	quiet()
	check(not session.player.combat.range_upgraded and session.data["events"].get(BossSession.GROWTH_PENDING,false) and not session.data["events"].has(BossSession.COMBAT_GROWTH),"failed old migration rolls back claim and runtime effect")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.player.combat.range_upgraded and session.store.load_slot(1)["events"].get(BossSession.COMBAT_GROWTH,false),"E retries failed migration and persists upgrade")
	var invalid: Dictionary = session.data.duplicate(true)
	invalid["events"].erase(BossSession.BOSS_DEFEATED)
	check(not session.store.valid(invalid),"claim requires Boss victory")
	invalid = session.data.duplicate(true)
	invalid["events"][BossSession.GROWTH_PENDING] = true
	check(not session.store.valid(invalid),"pending and claimed cannot coexist")
	var isolated: Dictionary = base.duplicate(true)
	isolated["events"][BossSession.GROWTH_PENDING] = true
	check(session.store.save_slot(3,isolated),"isolated old pending marker remains loadable")
	await load_slot(3)
	check(not session.player.combat.range_upgraded,"pending without victory cannot grant combat power")
	check(session.start_slot(2,true),"new game resets grown slot")
	await ticks(3)
	session = current_scene as FinalBattleSession
	check(not session.player.combat.range_upgraded and not session.data["events"].has(BossSession.COMBAT_GROWTH),"new game clears combat upgrade")
	for action: String in ["aim_up","aim_down"]: Input.action_release(action)
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("COMBAT_GROWTH_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
