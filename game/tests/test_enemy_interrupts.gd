# verify-suite: {"name": "protected enemy actions and future stagger interrupt hook", "path": "res://tests/test_enemy_interrupts.gd", "marker": "ENEMY_INTERRUPTS_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var player: PlayerController
var coordinator: EnemyAttackCoordinator
var actors: Array[ColorlessEntity] = []
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
func spawn(path: String) -> ColorlessEntity:
	var actor: ColorlessEntity = (load(path) as PackedScene).instantiate() as ColorlessEntity
	actor.position = Vector2(292,896)
	actor.target = player
	actor.coordinator = coordinator
	world.add_child(actor)
	actor.defeated.connect(func(value: int) -> void: rewards += value)
	actors.append(actor)
	return actor
func clean() -> void:
	for actor: ColorlessEntity in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	for node: Node in world.get_children():
		if node is ColorlessProjectile:
			node.queue_free()
	player.position = Vector2(224,896)
	player.life.start_new_run()
	player.life.protection_remaining = 1000
	player.reset_kinematics()
	player.combat.interrupt()
	await ticks(4)
func run() -> void:
	world = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player") as PlayerController
	coordinator = EnemyAttackCoordinator.new()
	world.add_child(coordinator)
	await clean()
	var normal: ColorlessEntity = spawn("res://enemies/colorless_entity.tscn")
	await ticks(2)
	normal.hurtbox.receive_attack(5,Vector2.RIGHT*150,player,9000)
	check(normal.health==8 and normal.state==ColorlessEntity.State.STUN and normal.velocity.x==150 and coordinator._owners.is_empty(), "ordinary attack still takes damage knockback stun and releases slot")
	await clean()
	var mono: MonochromeEntity = spawn("res://enemies/monochrome_entity.tscn") as MonochromeEntity
	mono._attack_count = 1
	await ticks(2)
	check(mono.strong_attack and mono.state==ColorlessEntity.State.WINDUP, "fixture reaches actual strong startup")
	var phase_time: float = mono._remaining
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(mono.motion==MonochromeEntity.Motion.NONE and mono._remaining==phase_time, "player startup cannot make strong attack cancel itself into dodge")
	for phase: ColorlessEntity.State in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE,ColorlessEntity.State.RECOVERY]:
		mono.state = phase
		mono._remaining = 0.5
		mono.velocity = Vector2(0,17)
		var hp: int = mono.health
		var owners: int = coordinator._owners.size()
		check(mono.hurtbox.receive_attack(5,Vector2.UP*300,player,9001+phase) and mono.health==hp-5, "strong phase%d remains damageable" % phase)
		check(mono.state==phase and mono._remaining==0.5 and mono.velocity==Vector2(0,17) and coordinator._owners.size()==owners, "strong phase%d preserves action timing motion and attack ownership" % phase)
	check(mono._flash>0, "uninterrupted hits retain damage feedback")
	check(mono.request_interrupt(ColorlessEntity.InterruptReason.STAGGER,Vector2.LEFT*100,0.8) and mono.state==ColorlessEntity.State.STUN and mono._remaining==0.8 and mono.velocity.x==-100 and coordinator._owners.is_empty(), "future explicit stagger can break protected strong action with custom stun")
	check(mono.health==6, "stagger API changes interruption without changing HP or awarding reward")
	await clean()
	mono = spawn("res://enemies/monochrome_entity.tscn") as MonochromeEntity
	mono._attack_count = 1
	await ticks(2)
	mono.hurtbox.receive_attack(5,Vector2.RIGHT*200,player,9010)
	await ticks(60)
	check(mono.health==16 and mono.state==ColorlessEntity.State.RECOVERY, "damaged strong attack actually executes and reaches its original recovery")
	await clean()
	mono = spawn("res://enemies/monochrome_entity.tscn") as MonochromeEntity
	await ticks(2)
	player.facing = 1
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	check(mono.motion==MonochromeEntity.Motion.DODGE and not mono.hurtbox.accepts_hits, "actual dodge retains existing invulnerability")
	check(not mono.request_interrupt() and mono.motion==MonochromeEntity.Motion.DODGE, "ordinary interruption request cannot cancel dodge")
	check(mono.request_interrupt(ColorlessEntity.InterruptReason.STAGGER) and mono.motion==MonochromeEntity.Motion.NONE and mono.hurtbox.accepts_hits and mono.state==ColorlessEntity.State.STUN, "explicit future stagger cleans dodge and restores hurtbox")
	await clean()
	var tian: TianWarrior = spawn("res://enemies/tian_warrior.tscn") as TianWarrior
	coordinator.try_acquire(tian)
	tian._start_attack(TianWarrior.Attack.HEAVY)
	for phase: ColorlessEntity.State in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE,ColorlessEntity.State.RECOVERY]:
		tian.state = phase
		tian._remaining = 0.5
		var hp: int = tian.health
		tian.hurtbox.receive_attack(5,Vector2.UP*300,player,9020+phase)
		check(tian.health==hp-5 and tian.state==phase and tian._remaining==0.5, "Tian heavy phase%d accepts damage without action interruption" % phase)
	check(not tian.request_interrupt() and tian.request_interrupt(ColorlessEntity.InterruptReason.STAGGER) and tian.state==ColorlessEntity.State.STUN and coordinator._owners.is_empty(), "Tian heavy distinguishes normal hit from future stagger interruption")
	await clean()
	tian = spawn("res://enemies/tian_warrior.tscn") as TianWarrior
	await ticks(2)
	check(not tian.hurtbox.receive_attack(5,Vector2.RIGHT,player,9030) and tian.health==31, "successful frontal defense still blocks its triggering hit")
	var guard_time: float = tian.motion_remaining
	var counter_time: float = tian.counter_remaining
	tian.hurtbox.receive_attack(5,Vector2.UP*300,player,9031)
	check(tian.health==26 and tian.motion==TianWarrior.Motion.GUARD and tian.motion_remaining==guard_time and tian.counter_remaining==counter_time, "up attack damages defense but does not cancel guard or queued counter")
	var blocker: Node = Node.new()
	world.add_child(blocker)
	coordinator.try_acquire(blocker)
	await ticks(18)
	counter_time = tian.counter_remaining
	tian.hurtbox.receive_attack(5,Vector2.UP*300,player,9032)
	check(tian.health==21 and tian.state==ColorlessEntity.State.CHASE and tian.counter_remaining==counter_time and counter_time>0, "hit cannot erase pending counter while shared slot is occupied")
	coordinator.release(blocker)
	blocker.queue_free()
	await ticks(2)
	check(tian.attack_kind==TianWarrior.Attack.COUNTER and tian.state==ColorlessEntity.State.WINDUP, "protected pending counter still waits for and acquires legal attack slot")
	for phase: ColorlessEntity.State in [ColorlessEntity.State.WINDUP,ColorlessEntity.State.ACTIVE,ColorlessEntity.State.RECOVERY]:
		tian.state = phase
		tian._remaining = 0.5
		var hp: int = tian.health
		tian.hurtbox.receive_attack(5,Vector2.UP*300,player,9040+phase)
		check(tian.health==hp-5 and tian.state==phase and tian._remaining==0.5, "counter phase%d remains uninterrupted by damage" % phase)
	check(tian.request_interrupt(ColorlessEntity.InterruptReason.STAGGER) and tian.counter_remaining==0 and tian.motion==TianWarrior.Motion.NONE and coordinator._owners.is_empty(), "future stagger clears counter action and attack budget cleanly")
	await clean()
	tian = spawn("res://enemies/tian_warrior.tscn") as TianWarrior
	await ticks(2)
	tian.hurtbox.receive_attack(5,Vector2.RIGHT,player,9050)
	check(tian.request_interrupt(ColorlessEntity.InterruptReason.STAGGER) and tian.motion==TianWarrior.Motion.NONE and tian.counter_remaining==0, "future stagger can also cancel active defense itself")
	await clean()
	mono = spawn("res://enemies/monochrome_entity.tscn") as MonochromeEntity
	mono._attack_count = 1
	await ticks(2)
	mono.hurtbox.receive_attack(21,Vector2.ZERO,player,9060)
	check(mono.state==ColorlessEntity.State.DEAD and rewards==7 and not mono.request_interrupt(ColorlessEntity.InterruptReason.STAGGER), "lethal damage overrides protected strong action and cannot be revived by interrupt API")
	await clean()
	tian = spawn("res://enemies/tian_warrior.tscn") as TianWarrior
	await ticks(2)
	tian.hurtbox.receive_attack(5,Vector2.RIGHT,player,9070)
	tian.hurtbox.receive_attack(31,Vector2.UP,player,9071)
	check(tian.state==ColorlessEntity.State.DEAD and tian.motion==TianWarrior.Motion.NONE and tian.counter_remaining==0 and rewards==18, "lethal damage clears protected guard and counter and pays once")
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("ENEMY_INTERRUPTS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
