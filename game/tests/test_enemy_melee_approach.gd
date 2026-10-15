extends SceneTree
var _world: Node2D
var _player: PlayerController
var _actor: ColorlessEntity
var _checks: int = 0
var _failures: int = 0
var _melee: int = 0
var _ranged: int = 0

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

func _on_attack(ranged: bool) -> void:
	if ranged:
		_ranged += 1
	else:
		_melee += 1

func _spawn(position: Vector2) -> ColorlessEntity:
	var packed: PackedScene = load("res://enemies/colorless_entity.tscn") as PackedScene
	var actor: ColorlessEntity = packed.instantiate() as ColorlessEntity
	actor.target = _player
	actor.position = position
	_world.add_child(actor)
	actor.attack_started.connect(_on_attack)
	return actor

func _check_windup(ranged: bool) -> void:
	var actor: ColorlessEntity = _spawn(Vector2(340 if ranged else 292, 880))
	actor.ranged_only = ranged
	await _ticks(1)
	_check(actor.state == ColorlessEntity.State.WINDUP and actor._ranged == ranged, "production %s attack enters windup" % ("ranged" if ranged else "melee"))
	await _ticks(13)
	_check(actor.state == ColorlessEntity.State.WINDUP, "windup does not end prematurely")
	var ticks: int = 13
	while actor.state == ColorlessEntity.State.WINDUP and ticks < 60:
		await _ticks(1)
		ticks += 1
	_check(ticks >= 26 and ticks <= 27 and actor.state == ColorlessEntity.State.ACTIVE, "%s windup shortened by 1/3: %d frames at 60Hz" % ["ranged" if ranged else "melee", ticks])
	_check(is_equal_approx(actor.config.active_duration, 0.12) and is_equal_approx(actor.config.recovery, 0.75), "enemy active duration and recovery unchanged")
	actor.queue_free()
	await _ticks(2)

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	await _ticks(10)
	# Use production defaults, not the shortened ranges/timings of unit fixtures.
	_player.life.protection_remaining = 30.0
	_actor = _spawn(Vector2(624, 880))
	await _ticks(360)
	_check(_ranged >= 1, "ground enemy can still start a ranged attack")
	_check(_melee >= 1, "production AI approaches from 400px and initiates melee within six seconds")
	_check(absf(_actor.position.x - _player.position.x) <= _actor.config.melee_range + 2.0, "enemy reaches actual melee range instead of camping at ranged distance")
	_actor.queue_free()
	await _ticks(2)
	_actor = _spawn(Vector2(292, 880))
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")
	_check(_actor.state == ColorlessEntity.State.WINDUP and not _actor._ranged, "close enemy starts melee even during player attack windup")
	await _ticks(8)
	_check(_actor.state == ColorlessEntity.State.STUN and _actor.health == 8, "player hit can still interrupt committed melee")
	_actor.queue_free()
	await _ticks(30)
	_actor = _spawn(Vector2(340, 880))
	_actor.ranged_only = true
	var old_melee: int = _melee
	var old_ranged: int = _ranged
	await _ticks(120)
	_check(_melee == old_melee and _ranged > old_ranged, "ranged-only configuration remains ranged-only")
	_check(absf(_actor.position.x - 340.0) < 1.0, "ranged-only enemy holds firing position during cooldown")
	_actor.queue_free()
	await _ticks(2)
	await _check_windup(false)
	await _check_windup(true)
	_world.queue_free()
	await process_frame
	print("ENEMY_MELEE_TESTS checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures else 0)
