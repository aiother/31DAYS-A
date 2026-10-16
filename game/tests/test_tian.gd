extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var player: PlayerController
var coordinator: EnemyAttackCoordinator
var actors: Array[TianWarrior] = []
var rewards: int = 0
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
func spawn(point: Vector2) -> TianWarrior:
	var actor: TianWarrior = (load("res://enemies/tian_warrior.tscn") as PackedScene).instantiate() as TianWarrior
	actor.position = point
	actor.target = player
	actor.coordinator = coordinator
	world.add_child(actor)
	actor.defeated.connect(func(reward: int) -> void: rewards += reward)
	actors.append(actor)
	return actor
func clean() -> void:
	for actor: TianWarrior in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	for node: Node in world.get_children():
		if node is ColorlessProjectile or node is StaticBody2D:
			node.queue_free()
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	player.life.start_new_run()
	player.life.health = 5
	player.position = Vector2(224,896)
	player.reset_kinematics()
	player.combat.interrupt()
	await ticks(4)
func run() -> void:
	world = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player") as PlayerController
	var receiver: CombatHurtbox = player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.monitorable = true
	(receiver.get_node("CollisionShape2D") as CollisionShape2D).disabled = false
	coordinator = EnemyAttackCoordinator.new()
	world.add_child(coordinator)
	await clean()
	var actor: TianWarrior = spawn(Vector2(292,896))
	await ticks(2)
	check(actor.health==31 and actor.config.reward==11 and actor.config.speed==300, "frozen31HP/+11 and approved movement300")
	check(actor.state==ColorlessEntity.State.WINDUP and actor.combo_total==2 and actor.combo_step==1 and actor.config.windup==0.25, "first close encounter starts two-hit combo with0.25s startup")
	await ticks(10)
	check(player.life.health==5, "combo telegraph does not damage early")
	await ticks(30)
	check(actor.combo_step==2 and player.life.health==3, "two combo strikes each deal1 and use separate hit registration")
	for i: int in range(8):
		if actor.state==ColorlessEntity.State.RECOVERY:
			break
		await ticks(1)
	check(actor.state==ColorlessEntity.State.RECOVERY, "finished combo exposes recovery window")
	actor.state = ColorlessEntity.State.CHASE
	check(actor._acquire(), "fixture acquires shared slot for next combo")
	actor._start_attack(TianWarrior.Attack.COMBO)
	check(actor.combo_total==3, "next combo alternates to three strikes")
	player.life.protection_remaining = 1000
	await ticks(60)
	check(actor.combo_step==3 and actor.state==ColorlessEntity.State.RECOVERY and player.life.health==3, "three-hit sequence completes without bypassing player protection")
	await clean()
	actor = spawn(Vector2(370,896))
	await ticks(2)
	check(actor.attack_kind==TianWarrior.Attack.HEAVY and actor._remaining>1 and actor.config.damage==3, "long-range heavy telegraphs1.1s and selects3 damage")
	await ticks(40)
	check(player.life.health==5, "heavy windup remains harmless")
	await ticks(30)
	for i: int in range(8):
		if actor.state==ColorlessEntity.State.RECOVERY:
			break
		await ticks(1)
	check(player.life.health==2 and actor.state==ColorlessEntity.State.RECOVERY and actor._remaining>1, "heavy reaches beyond ordinary melee and exposes1.2s recovery")
	check(actor.hurtbox.receive_attack(5,Vector2.RIGHT,player,4000) and actor.health==26, "heavy recovery cannot guard away punishment")
	var other: TianWarrior = spawn(Vector2(1000,896))
	check(actor.config!=other.config and actor.hit_shape.shape!=other.hit_shape.shape and (other.hit_shape.shape as RectangleShape2D).size==Vector2(72,56), "runtime damage and heavy hitbox do not contaminate another actor")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	check(not actor.hurtbox.receive_attack(5,Vector2.RIGHT*100,player,4001) and actor.health==31 and actor.motion==TianWarrior.Motion.GUARD, "front horizontal attack is blocked without fake HP restoration")
	check(coordinator._owners.is_empty(), "guard cancellation releases its attack slot")
	await ticks(16)
	for i: int in range(4):
		if actor.state==ColorlessEntity.State.WINDUP:
			break
		await ticks(1)
	check(actor.attack_kind==TianWarrior.Attack.COUNTER and actor.state==ColorlessEntity.State.WINDUP, "successful block attempts telegraphed counter after guard window")
	await ticks(12)
	check(player.life.health==5, "counter has no instant untelegraphed damage")
	await ticks(15)
	check(player.life.health==4, "counter active delivers one light hit")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	actor.hurtbox.receive_attack(5,Vector2.RIGHT,player,3999)
	var blocker: Node = Node.new()
	world.add_child(blocker)
	check(coordinator.try_acquire(blocker), "another attacker may take the slot released by guard")
	await ticks(30)
	check(actor.state==ColorlessEntity.State.CHASE and actor.counter_remaining>0, "pending counter waits instead of exceeding attack budget")
	coordinator.release(blocker)
	await ticks(2)
	check(actor.attack_kind==TianWarrior.Attack.COUNTER and actor.state==ColorlessEntity.State.WINDUP, "counter may start after shared slot is released")
	blocker.queue_free()
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	actor.hurtbox.receive_attack(5,Vector2.RIGHT,player,4002)
	check(actor.hurtbox.receive_attack(5,Vector2.RIGHT,player,4003) and actor.health==26 and actor.counter_remaining>0 and actor.motion==TianWarrior.Motion.GUARD, "guard cooldown allows damage while defense and pending counter remain uninterrupted")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	check(actor.hurtbox.receive_attack(5,Vector2.UP*100,player,4004) and actor.health==26, "up attack bypasses frontal guard")
	await ticks(15)
	check(actor.hurtbox.receive_attack(5,Vector2.DOWN*100,player,4005) and actor.health==21, "down attack bypasses frontal guard")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	player.position.x = 360
	check(actor.hurtbox.receive_attack(5,Vector2.LEFT,player,4006) and actor.health==26, "rear attack bypasses guard facing")
	await clean()
	actor = spawn(Vector2(1200,896))
	await ticks(4)
	actor.position.x = 500
	await ticks(1)
	var start: float = actor.position.x
	check(actor.motion==TianWarrior.Motion.BLINK_WARNING and absf(actor.blink_offset)<=180, "short blink announces valid destination before displacement")
	await ticks(8)
	check(actor.position.x==start, "blink cannot relocate during0.2s warning")
	await ticks(5)
	check(absf(actor.position.x-start)>100 and absf(actor.position.x-start)<=180.1 and actor.blink_cooldown_remaining>3.7, "warned blink relocates at most180 and starts cooldown")
	await clean()
	actor = spawn(Vector2(1200,896))
	await ticks(4)
	actor.position.x = 500
	await ticks(1)
	actor.hurtbox.receive_attack(5,Vector2.ZERO,player,4007)
	await ticks(10)
	check(actor.position.x==500 and actor.state==ColorlessEntity.State.STUN and actor.health==26, "blink warning is vulnerable and can be interrupted")
	await clean()
	actor = spawn(Vector2(1200,896))
	await ticks(4)
	actor.position.x = 500
	actor.blink_cooldown_remaining = 10
	await ticks(3)
	check(actor.motion==TianWarrior.Motion.DASH and absf(actor.velocity.x)==600, "short dash provides fast movement while blink cools down")
	var dash_start: float = actor.position.x
	await ticks(10)
	check(actor.motion==TianWarrior.Motion.NONE and absf(actor.position.x-dash_start)<=100, "dash ends after bounded physical travel")
	await clean()
	var wall: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(24,200)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(400,796)
	world.add_child(wall)
	actor = spawn(Vector2(500,896))
	actor.alert_to_target()
	await ticks(5)
	check(not actor._safe_path(-180) and actor.motion!=TianWarrior.Motion.BLINK_WARNING, "solid wall rejects entire blink path")
	await ticks(35)
	check(actor.position.x>430 and player.life.health==5, "dash pursuit cannot tunnel through wall or attack through it")
	await clean()
	actor = spawn(Vector2(674,768))
	player.position = Vector2(1800,896)
	actor.alert_to_target()
	await ticks(10)
	check(actor.is_on_floor() and actor.position.x<690 and not actor._safe_path(180), "ground destination validation rejects platform-edge blink and dash")
	await clean()
	player.position = Vector2(800,896)
	player.life.protection_remaining = 1000
	actor = spawn(Vector2(732,896))
	actor.flank_side = -1
	other = spawn(Vector2(868,896))
	other.flank_side = 1
	var counts: Array[int] = [0,0]
	actor.attack_started.connect(func(_ranged: bool) -> void: counts[0] += 1)
	other.attack_started.connect(func(_ranged: bool) -> void: counts[1] += 1)
	var budget_ok: bool = true
	var flanked: bool = false
	for i: int in range(300):
		await ticks(1)
		var attackers: int = 0
		for warrior: TianWarrior in [actor,other]:
			if warrior.state in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE]:
				attackers += 1
		budget_ok = budget_ok and attackers<=1
		flanked = flanked or (actor.position.x<player.position.x and other.position.x>player.position.x+110)
	check(budget_ok and counts[0]>0 and counts[1]>0, "two warriors trade attacks without exceeding shared one-attacker budget")
	check(flanked, "waiting warrior physically occupies opposite flank")
	player.life.protection_remaining = 0
	player.life.take_hit(5)
	await ticks(2)
	check(actor.state==ColorlessEntity.State.IDLE and other.state==ColorlessEntity.State.IDLE and coordinator._owners.is_empty(), "player death cancels both warriors and releases shared budget")
	await clean()
	actor = spawn(Vector2(292,896))
	for i: int in range(6):
		actor.hurtbox.receive_attack(5,Vector2.ZERO,player,4100+i)
	check(actor.health==1 and rewards==0, "six normal hits leave31HP enemy alive")
	actor.hurtbox.receive_attack(5,Vector2.ZERO,player,4106)
	actor.hurtbox.receive_attack(5,Vector2.ZERO,player,4107)
	check(actor.state==ColorlessEntity.State.DEAD and rewards==11 and not actor.hurtbox.accepts_hits, "seventh hit pays+11 once and disables corpse damage")
	await clean()
	actor = spawn(Vector2(1200,896))
	await ticks(4)
	actor.position.x = 550
	actor.blink_cooldown_remaining = 10
	actor.dash_cooldown_remaining = 10
	await ticks(75)
	check(actor.attack_kind==TianWarrior.Attack.RANGED and player.life.health==4, "actual ranged AI throws damaging reflectable projectile")
	var projectile: ColorlessProjectile = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as ColorlessProjectile
	projectile.position = Vector2(900,500)
	world.add_child(projectile)
	check(projectile.reflect(player,Vector2.UP) and not projectile.reflect(player,Vector2.UP), "Tian projectile uses existing single-reflection contract")
	actor.set_physics_process(false)
	projectile._deliver_hit(actor.hurtbox)
	check(actor.health==26, "reflected shot delivers frozen5 damage")
	await clean()
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("TIAN_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
