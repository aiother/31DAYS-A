extends SceneTree
var _checks: int = 0
var _failures: int = 0
var _world: Node2D
var _player: PlayerController
var _combat: PlayerCombat
var _targets: Array[CombatHurtbox] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _release() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func _finish_attack() -> int:
	var ticks: int = 0
	while _combat.is_attacking() and ticks < 80:
		await _ticks(1)
		ticks += 1
	_check(not _combat.is_attacking(), "attack finishes within bounded duration")
	return ticks

func _reset(position: Vector2 = Vector2(224, 880)) -> void:
	_release()
	await _finish_attack()
	for target: CombatHurtbox in _targets:
		target.queue_free()
	_targets.clear()
	_combat.reset_combo()
	_player.global_position = position
	_player.velocity = Vector2.ZERO
	_player.facing = 1.0
	_player.landing_lock_remaining = 0.0
	await _ticks(8)

func _target(position: Vector2) -> CombatHurtbox:
	var packed: PackedScene = load("res://debug/combat_target.tscn") as PackedScene
	var target: CombatHurtbox = packed.instantiate() as CombatHurtbox
	_world.add_child(target)
	target.global_position = position
	_targets.append(target)
	return target

func _press() -> void:
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	_combat = _player.combat
	await _ticks(12)
	var target: CombatHurtbox = _target(Vector2(320, 848))
	await _ticks(2)
	await _press()
	_check(_combat.combo_step == 1 and _combat.phase == PlayerCombat.Phase.WINDUP, "first click starts first attack with windup")
	await _ticks(3)
	_check(int(target.get("hit_count")) == 0, "windup cannot deal damage")
	await _ticks(6)
	_check(int(target.get("hit_count")) == 1 and int(target.get("damage_total")) == 5, "active hit deals frozen 5 damage")
	await _ticks(2)
	_check(int(target.get("hit_count")) == 1, "same target hit only once over multiple active frames")
	var first_impulse: Vector2 = target.get("last_impulse")
	await _finish_attack()
	await _press()
	_check(_combat.combo_step == 2, "consecutive click starts second combo attack")
	await _ticks(8)
	var second_impulse: Vector2 = target.get("last_impulse")
	_check(second_impulse.length() > first_impulse.length(), "second attack has stronger knockback")
	_check(int(target.get("damage_total")) == 10, "second attack still deals 5 damage")
	_check(_combat.config.recovery_second > _combat.config.recovery_first, "second attack recovery longer than first")
	await _finish_attack()
	await _press()
	_check(_combat.combo_step == 1, "combo cycles back to first attack")
	await _finish_attack()
	await _ticks(30)
	await _press()
	_check(_combat.combo_step == 1, "long pause resets combo")
	await _reset()
	target = _target(Vector2(320, 848))
	await _ticks(2)
	Input.action_press("attack")
	await _ticks(60)
	_check(int(target.get("hit_count")) == 1, "holding attack does not auto-repeat")
	await _reset()
	var first: CombatHurtbox = _target(Vector2(320, 848))
	var second: CombatHurtbox = _target(Vector2(336, 848))
	var distant: CombatHurtbox = _target(Vector2(1000, 848))
	await _ticks(2)
	await _press()
	await _finish_attack()
	_check(int(first.get("hit_count")) == 1 and int(second.get("hit_count")) == 1, "one swing hits multiple targets once each")
	_check(int(distant.get("hit_count")) == 0, "out of reach target receives no damage")
	await _reset()
	first = _target(Vector2(320, 848))
	second = _target(Vector2(128, 848))
	await _ticks(2)
	await _press()
	Input.action_press("move_left")
	await _ticks(10)
	_check(_player.facing == -1.0 and _combat.direction == Vector2.RIGHT, "turning does not change active attack direction")
	_check(int(first.get("hit_count")) == 1 and int(second.get("hit_count")) == 0, "locked swing cannot hit behind player")
	await _reset()
	Input.action_press("run")
	Input.action_press("move_right")
	await _ticks(12)
	await _press()
	_check(absf(_player.velocity.x) <= _player.movement.run_speed * _combat.config.movement_scale + 0.1, "attack immediately reduces running speed")
	var x: float = _player.global_position.x
	Input.action_press("jump")
	await _ticks(4)
	_check(_player.is_on_floor() and _player.global_position.x > x, "attack permits slow movement but blocks jump cancel")
	await _reset()
	Input.action_press("aim_down")
	await _press()
	_check(not _combat.is_attacking(), "grounded down attack rejected")
	await _reset()
	target = _target(Vector2(224, 760))
	await _ticks(2)
	Input.action_press("aim_up")
	await _press()
	await _ticks(8)
	_check(_combat.direction == Vector2.UP and int(target.get("damage_total")) == 5, "up attack hits overhead target for 5")
	var up_impulse: Vector2 = target.get("last_impulse")
	_check(up_impulse.y < -first_impulse.length(), "up attack has stronger upward knockback")
	await _reset(Vector2(224, 500))
	Input.action_press("aim_down")
	var previous_velocity: float = _player.velocity.y
	await _press()
	_check(_combat.direction == Vector2.DOWN and _player.velocity.y > previous_velocity, "missed down attack leaves gravity unchanged")
	await _finish_attack()
	await _reset(Vector2(224, 500))
	target = _target(Vector2(224, _player.global_position.y + 100))
	await _ticks(2)
	Input.action_press("aim_down")
	await _press()
	var bounced: bool = false
	for i: int in range(14):
		await _ticks(1)
		if _player.velocity.y < 0.0:
			bounced = true
	_check(int(target.get("damage_total")) == 5 and bounced, "down hit deals 5 and bounces once")
	_check(int(target.get("hit_count")) == 1, "down hit cannot repeatedly bounce on same target")
	await _reset()
	_player.landing_lock_remaining = 0.44
	await _press()
	_check(not _combat.is_attacking(), "hard landing lock blocks new attack")
	await _reset()
	await _press()
	await _ticks(10)
	await _press()
	await _ticks(13)
	_check(_combat.attack_id > 0 and _combat.combo_step == 2, "late click buffers next combo during recovery")
	_release()
	await _finish_attack()
	_world.queue_free()
	await process_frame
	print("COMBAT_TESTS checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
