extends SceneTree
var _world: Node2D
var _player: PlayerController
var _coordinator: EnemyAttackCoordinator
var _actors: Array[ColorlessEntity] = []
var _checks: int = 0
var _failures: int = 0
var _incoming: int = 0
var _incoming_damage: int = 0
var _defeats: int = 0
var _reward: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)

func _ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _spawn(position: Vector2, flying: bool = false) -> ColorlessEntity:
	var packed: PackedScene = load("res://enemies/colorless_entity.tscn") as PackedScene
	var actor: ColorlessEntity = packed.instantiate() as ColorlessEntity
	actor.config = actor.config.duplicate() as ColorlessConfig
	actor.config.windup = 0.20
	actor.config.recovery = 0.30
	actor.config.sight_range = 350.0
	actor.config.ranged_range = 160.0
	actor.target = _player
	actor.coordinator = _coordinator
	actor.position = position
	actor.flying = flying
	_world.add_child(actor)
	actor.defeated.connect(_on_defeated)
	_actors.append(actor)
	return actor

func _clean() -> void:
	for actor: ColorlessEntity in _actors:
		if is_instance_valid(actor):
			actor.queue_free()
	_actors.clear()
	for node: Node in _world.get_children():
		if node is ColorlessProjectile:
			node.queue_free()
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	_player.position = Vector2(224, 880)
	_player.velocity = Vector2.ZERO
	_player.landing_lock_remaining = 0.0
	_incoming = 0
	_incoming_damage = 0
	await _ticks(8)
	_player.life.start_new_run()
	_player.reset_kinematics()

func _on_player_hit(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	_incoming += 1
	_incoming_damage += damage

func _on_defeated(reward: int) -> void:
	_defeats += 1
	_reward += reward

func _projectile(position: Vector2, velocity: Vector2) -> ColorlessProjectile:
	var packed: PackedScene = load("res://enemies/colorless_projectile.tscn") as PackedScene
	var projectile: ColorlessProjectile = packed.instantiate() as ColorlessProjectile
	projectile.position = position
	projectile.velocity = velocity
	_world.add_child(projectile)
	return projectile

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	var receiver: CombatHurtbox = _player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.monitorable = true
	(receiver.get_node("CollisionShape2D") as CollisionShape2D).disabled = false
	receiver.hit_received.connect(_on_player_hit)
	_coordinator = EnemyAttackCoordinator.new()
	_world.add_child(_coordinator)
	await _ticks(10)
	var actor: ColorlessEntity = _spawn(Vector2(1000, 880))
	await _ticks(8)
	_check(actor.state == ColorlessEntity.State.IDLE, "outside sight remains idle")
	actor.position.x = 500
	await _ticks(5)
	_check(actor.state == ColorlessEntity.State.CHASE and actor.velocity.x < 0, "sight acquires player and chases")
	_check(actor.config.speed < _player.movement.walk_speed, "colorless moves slower than player walk")
	_player.position.x = 1800
	await _ticks(2)
	_check(actor._seen and actor.state == ColorlessEntity.State.CHASE, "acquired target remains pursued beyond initial sight")
	await _clean()
	var wall: StaticBody2D = StaticBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(32, 128)
	collision.shape = rectangle
	wall.add_child(collision)
	wall.position = Vector2(400, 832)
	_world.add_child(wall)
	actor = _spawn(Vector2(500, 880))
	await _ticks(6)
	_check(actor.state == ColorlessEntity.State.IDLE, "solid wall blocks initial sight acquisition")
	wall.queue_free()
	await _clean()
	_player.position = Vector2(1800, 880)
	actor = _spawn(Vector2(674, 768))
	actor._seen = true
	await _ticks(8)
	_check(actor.is_on_floor() and actor.position.x < 690, "non-jumping ground variant stops at platform edge")
	await _clean()
	actor = _spawn(Vector2(292, 880))
	await _ticks(5)
	_check(actor.state == ColorlessEntity.State.WINDUP and _incoming == 0, "melee telegraphs without premature damage")
	await _ticks(18)
	_check(_incoming == 1 and _incoming_damage == 1, "melee active window delivers exactly one light hit")
	await _clean()
	actor = _spawn(Vector2(292, 880))
	await _ticks(5)
	actor.hurtbox.receive_attack(5, Vector2.RIGHT * 140, _player, 1)
	_check(actor.health == 8 and actor.state == ColorlessEntity.State.STUN, "hit deducts frozen 5 damage and interrupts windup")
	_check(actor.velocity.x > 0, "hit applies knockback")
	await _ticks(10)
	_check(_incoming == 0 and actor.position.x > 292, "interrupted attack cannot hit while enemy is knocked back")
	actor.hurtbox.receive_attack(5, Vector2.RIGHT * 230, _player, 2)
	_check(actor.health == 3, "two ordinary hits leave 3 of 13 HP")
	actor.hurtbox.receive_attack(5, Vector2.RIGHT * 140, _player, 3)
	_check(actor.health == 0 and actor.state == ColorlessEntity.State.DEAD, "third ordinary hit defeats colorless")
	_check(_defeats == 1 and _reward == 2, "defeat emits one pending +2 reward event")
	_check(not actor.hurtbox.receive_attack(5, Vector2.ZERO, _player, 4), "dead enemy refuses further hits")
	_check(_defeats == 1, "corpse cannot grant repeated reward")
	await _clean()
	actor = _spawn(Vector2(320, 880))
	actor.target = null
	await _ticks(3)
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")
	await _ticks(10)
	_check(actor.health == 8 and actor.state == ColorlessEntity.State.STUN, "actual player hitbox strikes enemy hurtbox once")
	await _ticks(20)
	await _clean()
	actor = _spawn(Vector2(292, 880))
	var other: ColorlessEntity = _spawn(Vector2(300, 880))
	await _ticks(4)
	_check((actor.state == ColorlessEntity.State.WINDUP) != (other.state == ColorlessEntity.State.WINDUP), "shared attack budget permits only one windup")
	actor.hurtbox.receive_attack(5, Vector2.LEFT * 140, _player, 1)
	await _ticks(2)
	_check(other.state == ColorlessEntity.State.WINDUP, "interrupted attacker releases its slot")
	await _clean()
	actor = _spawn(Vector2(340, 880))
	actor.ranged_only = true
	await _ticks(19)
	var shots: int = 0
	for node: Node in _world.get_children():
		if node is ColorlessProjectile:
			shots += 1
	_check(shots == 1, "ranged attack spawns one projectile after windup")
	await _ticks(25)
	_check(_incoming == 1, "ranged projectile hits player once")
	await _clean()
	actor = _spawn(Vector2(700, 500), true)
	actor.config.sight_range = 1000
	actor.config.ranged_range = 100
	await _ticks(4)
	_check(actor.velocity.x < 0 and actor.velocity.y > 0, "air colorless approaches freely without ground gravity")
	await _clean()
	var shot: ColorlessProjectile = _projectile(Vector2(300, 848), Vector2.LEFT * 300)
	await _ticks(1)
	_check(not shot.hurtbox.receive_attack(5, Vector2.DOWN * 140, _player, 1), "down attack cannot reflect thrown object")
	_check(shot.hurtbox.receive_attack(5, Vector2.RIGHT * 140, _player, 2) and shot.velocity.x > 0, "horizontal attack reverses projectile")
	_check(not shot.hurtbox.receive_attack(5, Vector2.RIGHT, _player, 3), "projectile reflects only once")
	actor = _spawn(Vector2(380, 880))
	actor.target = null
	await _ticks(30)
	_check(actor.health == 8 and _incoming == 0, "reflected projectile deals 5 to enemy and cannot hit player")
	await _clean()
	shot = _projectile(Vector2(300, 848), Vector2.LEFT * 300)
	_check(shot.hurtbox.receive_attack(5, Vector2.UP * 280, _player, 4), "up attack can reflect thrown object")
	await _ticks(80)
	_check(not is_instance_valid(shot), "reflected projectile expires or falls into terrain")
	await _clean()
	shot = _projectile(Vector2(1900, 848), Vector2.RIGHT * 300)
	await _ticks(10)
	_check(not is_instance_valid(shot), "projectile hits terrain instead of passing through wall")
	await _clean()
	shot = _projectile(Vector2(320, 848), Vector2.LEFT * 100)
	await _ticks(1)
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")
	await _ticks(8)
	_check(is_instance_valid(shot) and shot.reflected, "actual player swing reflects projectile through hurtbox query")
	await _ticks(20)
	await _clean()
	_coordinator.corpse_limit = 1
	actor = _spawn(Vector2(1000, 880))
	other = _spawn(Vector2(1200, 880))
	actor.hurtbox.receive_attack(20, Vector2.ZERO, _player, 1)
	other.hurtbox.receive_attack(20, Vector2.ZERO, _player, 2)
	await _ticks(2)
	_check(is_instance_valid(actor) and not is_instance_valid(other), "corpse cap keeps first corpse and removes excess new death")
	await _clean()
	_world.queue_free()
	await process_frame
	print("COLORLESS_TESTS checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures else 0)
