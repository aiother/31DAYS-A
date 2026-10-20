# verify-suite: {"name": "monochrome enemy movement attacks dodge and reflection", "path": "res://tests/test_monochrome.gd", "marker": "MONOCHROME_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var player: PlayerController
var coordinator: EnemyAttackCoordinator
var actors: Array[MonochromeEntity] = []
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
func spawn(point: Vector2, flying: bool = false) -> MonochromeEntity:
	var actor: MonochromeEntity = (load("res://enemies/monochrome_entity.tscn") as PackedScene).instantiate() as MonochromeEntity
	actor.position = point
	actor.target = player
	actor.coordinator = coordinator
	actor.flying = flying
	world.add_child(actor)
	actor.defeated.connect(func(reward: int) -> void: rewards += reward)
	actors.append(actor)
	return actor
func clean() -> void:
	for actor: MonochromeEntity in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	for child: Node in world.get_children():
		if child is ColorlessProjectile:
			child.queue_free()
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	player.position = Vector2(224,896)
	player.life.start_new_run()
	player.life.health = 5
	player.reset_kinematics()
	player.combat.interrupt()
	await ticks(4)
func press_attack() -> void:
	player.combat.interrupt()
	player.facing = 1
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
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
	var actor: MonochromeEntity = spawn(Vector2(1000,896))
	check(actor.health==21 and actor.config.reward==7 and actor.config.speed==240, "frozen21HP/+7 and approved base speed")
	var other: MonochromeEntity = spawn(Vector2(1200,896))
	check(actor.config!=other.config and actor.config!=(load("res://data/enemies/monochrome_entity.tres") as MonochromeConfig), "each actor owns its mutable attack configuration")
	await ticks(5)
	check(actor.state==ColorlessEntity.State.IDLE, "outside sight stays idle")
	actor.position.x = 500
	await ticks(4)
	check(actor.motion==MonochromeEntity.Motion.DASH and absf(actor.velocity.x)==480 and actor.hurtbox.accepts_hits, "sighted target triggers fast vulnerable short dash")
	await ticks(12)
	check(actor.position.x>390 and actor.position.x<450 and actor.motion==MonochromeEntity.Motion.NONE, "short dash ends without teleporting to target")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(2)
	check(actor.state==ColorlessEntity.State.WINDUP and not actor.strong_attack and actor.config.windup==0.3 and player.life.health==5, "first light melee has0.3s telegraph")
	await ticks(14)
	check(player.life.health==5, "light startup causes no premature damage")
	await ticks(10)
	check(player.life.health==4, "light active hits once for1")
	for i: int in range(80):
		if actor.state==ColorlessEntity.State.WINDUP and actor.strong_attack:
			break
		await ticks(1)
	check(actor.strong_attack and actor.state==ColorlessEntity.State.WINDUP and actor.config.windup==0.8 and actor.config.damage==2, "second attack visibly switches to long strong windup and medium damage")
	await ticks(35)
	check(player.life.health==4, "strong attack remains harmless during long telegraph")
	await ticks(20)
	check(player.life.health==2, "strong melee deals2 with one hit per attack")
	check((load("res://data/enemies/monochrome_entity.tres") as MonochromeConfig).damage==1 and (load("res://data/enemies/colorless_entity.tres") as ColorlessConfig).damage==1, "strong selection does not mutate shared enemy defaults")
	await clean()
	actor = spawn(Vector2(292,896))
	await ticks(3)
	await press_attack()
	check(actor.motion==MonochromeEntity.Motion.DODGE and not actor.hurtbox.accepts_hits and actor.dodge_cooldown_remaining>1.9, "real visible player startup triggers first dodge with2s cooldown")
	var before: int = actor.health
	check(not actor.hurtbox.receive_attack(5,Vector2.ZERO,player,100) and actor.health==before, "dodge rejects damage rather than restoring HP afterward")
	var dodge_start: float = actor.position.x
	await ticks(10)
	check(actor.position.x>dodge_start+60 and actor.motion==MonochromeEntity.Motion.DODGE, "dodge physically retreats over its0.2s window")
	await ticks(4)
	check(actor.hurtbox.accepts_hits and actor.motion==MonochromeEntity.Motion.NONE, "dodge invulnerability ends and actor is punishable")
	actor.position = Vector2(292,896)
	actor.state = ColorlessEntity.State.CHASE
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.motion!=MonochromeEntity.Motion.DODGE, "rapid next attack cannot bypass dodge cooldown")
	actor.dodge_cooldown_remaining = 0
	actor.health = 7
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.dodge_cooldown_remaining==2, "exactly one-third HP retains normal dodge cooldown")
	actor._end_motion()
	actor.dodge_cooldown_remaining = 0
	actor.health = 6
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.dodge_cooldown_remaining==1, "below one-third own HP increases dodge frequency")
	actor._end_motion()
	actor.dodge_cooldown_remaining = 0
	actor.state = ColorlessEntity.State.CHASE
	player.life.health = 1
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.dodge_cooldown_remaining==1, "player exact HP does not alter defensive decision")
	actor._end_motion()
	actor.state = ColorlessEntity.State.CHASE
	actor.dodge_cooldown_remaining = 0
	player.combat.attack_started.emit(Vector2.LEFT,1)
	check(actor.motion==MonochromeEntity.Motion.NONE, "attack aimed away does not provoke a dodge")
	actor.hurtbox.receive_attack(1,Vector2.ZERO,player,101)
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.state==ColorlessEntity.State.STUN and actor.motion==MonochromeEntity.Motion.NONE, "hit stun cannot be cancelled into dodge")
	await clean()
	# A solid wall prevents both line-of-sight cheating and impossible retreats.
	var wall: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(24,180)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(380,806)
	world.add_child(wall)
	actor = spawn(Vector2(292,896))
	await ticks(3)
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.motion==MonochromeEntity.Motion.NONE and actor.hurtbox.accepts_hits, "blocked retreat does not grant stationary dodge immunity")
	wall.position.x = 260
	await ticks(2)
	actor.state = ColorlessEntity.State.IDLE
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(actor.motion==MonochromeEntity.Motion.NONE, "wall blocks defensive observation")
	wall.queue_free()
	await clean()
	actor = spawn(Vector2(674,768))
	player.position = Vector2(1800,896)
	actor.alert_to_target()
	await ticks(65)
	check(actor.is_on_floor() and absf(actor.position.y-896)<4 and actor.position.x>700, "ground pursuit safely descends to confirmed lower floor instead of freezing at edge")
	await clean()
	actor = spawn(Vector2(350,896))
	actor.alert_to_target()
	player.position = Vector2(560,768)
	await ticks(5)
	check(actor.velocity.y<0 and actor.position.y<890, "ground variant jumps toward an acquired elevated target")
	await clean()
	actor = spawn(Vector2(800,600),true)
	await ticks(4)
	check(actor.motion==MonochromeEntity.Motion.NONE and actor.velocity.length()>200 and actor.velocity.y>0, "air variant pursues in two dimensions without falling")
	actor.position = Vector2(500,650)
	await ticks(3)
	check(actor.motion==MonochromeEntity.Motion.DASH and actor.velocity.length()>470, "air variant can perform directional short dash")
	player.life.take_hit(5)
	await ticks(2)
	check(actor.motion==MonochromeEntity.Motion.NONE and actor.state==ColorlessEntity.State.IDLE and actor.velocity==Vector2.ZERO, "player death stops dash and future attacks")
	await clean()
	actor = spawn(Vector2(292,896))
	var blocker: Node = Node.new()
	world.add_child(blocker)
	check(coordinator.try_acquire(blocker), "fixture holds the existing shared attack slot")
	await ticks(6)
	check(actor.state==ColorlessEntity.State.CHASE, "monochrome obeys shared group attack budget")
	coordinator.release(blocker)
	await ticks(2)
	check(actor.state==ColorlessEntity.State.WINDUP, "released attack slot allows monochrome attack")
	player.combat.attack_started.emit(Vector2.RIGHT,1)
	check(coordinator.try_acquire(blocker), "dodge cancels windup and releases attack slot")
	coordinator.release(blocker)
	blocker.queue_free()
	actor._end_motion()
	for i: int in range(4):
		actor.hurtbox.receive_attack(5,Vector2.ZERO,player,200+i)
	check(actor.health==1 and rewards==0, "four normal hits leave21HP enemy alive")
	actor.hurtbox.receive_attack(5,Vector2.ZERO,player,204)
	actor.hurtbox.receive_attack(5,Vector2.ZERO,player,205)
	check(actor.state==ColorlessEntity.State.DEAD and rewards==7 and not actor.hurtbox.accepts_hits, "fifth hit defeats and pays+7 exactly once")
	await clean()
	# Projectile collision uses the real player's life component.
	for damage: int in [1,2]:
		player.life.health = 5
		player.life.protection_remaining = 0
		player.life.hurt_remaining = 0
		var projectile: MonochromeProjectile = (load("res://enemies/monochrome_projectile.tscn") as PackedScene).instantiate() as MonochromeProjectile
		projectile.position = Vector2(320,852)
		projectile.velocity = Vector2(-380,0)
		projectile.damage = damage
		world.add_child(projectile)
		await ticks(20)
		check(player.life.health==5-damage, "unreflected projectile collision deals selected damage%d" % damage)
	var projectile: MonochromeProjectile = (load("res://enemies/monochrome_projectile.tscn") as PackedScene).instantiate() as MonochromeProjectile
	projectile.position = Vector2(600,500)
	projectile.damage = 2
	world.add_child(projectile)
	check(not projectile.reflect(player,Vector2.DOWN), "down attack does not reflect monochrome projectile")
	check(projectile.reflect(player,Vector2.RIGHT) and not projectile.reflect(player,Vector2.RIGHT), "horizontal reflect works only once")
	actor = spawn(Vector2(700,896))
	actor.set_physics_process(false)
	projectile._deliver_hit(actor.hurtbox)
	check(actor.health==16, "strong projectile reflects for frozen5 damage")
	await clean()
	actor = spawn(Vector2(292,896))
	actor.ranged_only = true
	await ticks(24)
	var spawned: bool = false
	for node: Node in world.get_children():
		if node is MonochromeProjectile:
			spawned = true
	check(spawned or player.life.health==4, "AI ranged attack emits its own damaging projectile")
	await clean()
	actor = spawn(Vector2(500,896),true)
	actor.ranged_only = true
	actor._dash_cooldown = 100
	var strong_projectile: bool = false
	for i: int in range(150):
		await ticks(1)
		for node: Node in world.get_children():
			if node is MonochromeProjectile and (node as MonochromeProjectile).damage==2:
				strong_projectile = true
		if strong_projectile:
			break
	check(strong_projectile and actor.strong_attack, "AI alternates into a strong ranged shot with selected2 damage")
	await ticks(45)
	check(player.life.health==2, "real light and strong AI ranged shots both damage player")
	await clean()
	player.position = Vector2(224,500)
	actor = spawn(Vector2(340,500),true)
	await ticks(2)
	var flight_y: float = actor.position.y
	await press_attack()
	check(actor.motion==MonochromeEntity.Motion.DODGE, "flying variant also reacts to real nearby attack startup")
	await ticks(13)
	check(absf(actor.position.y-flight_y)<1 and actor.hurtbox.accepts_hits, "air dodge keeps altitude and restores vulnerability after0.2s")
	await clean()
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("MONOCHROME_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
