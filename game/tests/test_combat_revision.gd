extends SceneTree
var _checks: int = 0
var _failures: int = 0
var _world: Node2D
var _player: PlayerController
var _combat: PlayerCombat

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

func _reset() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	await _ticks(65)
	_combat.reset_combo()
	_player.position = Vector2(224, 880)
	_player.velocity = Vector2.ZERO
	await _ticks(8)

func _press() -> void:
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")

func _measure_phases(running: bool, step: int) -> Vector3i:
	await _reset()
	if step == 2:
		await _press()
		await _ticks(23)
	if running:
		Input.action_press("run")
		Input.action_press("move_right")
	await _press()
	var counts: Vector3i = Vector3i.ZERO
	for i: int in range(80):
		match _combat.phase:
			PlayerCombat.Phase.WINDUP: counts.x += 1
			PlayerCombat.Phase.ACTIVE: counts.y += 1
			PlayerCombat.Phase.RECOVERY: counts.z += 1
			_: break
		if not _combat.is_attacking():
			break
		if running and i == 1:
			Input.action_release("run")
			Input.action_release("move_right")
		await _ticks(1)
	return counts

func _measure_bounce(multiplier: float, hold_jump: bool) -> float:
	await _reset()
	_player.position = Vector2(224, 500)
	await _ticks(1)
	_combat.config.down_bounce_height_multiplier = multiplier
	if hold_jump:
		Input.action_press("jump")
	_player.bounce_from_down_attack()
	var start: float = _player.position.y
	var highest: float = start
	for i: int in range(40):
		await _ticks(1)
		highest = minf(highest, _player.position.y)
		if _player.velocity.y >= 0.0:
			break
	return start - highest

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	_combat = _player.combat
	await _ticks(10)
	for step: int in [1, 2]:
		var normal: Vector3i = await _measure_phases(false, step)
		var running: Vector3i = await _measure_phases(true, step)
		_check(absi(running.x - normal.x * 2) <= 1, "running step %d doubles windup: %s / %s" % [step, running, normal])
		_check(absi(running.z - normal.z * 2) <= 1, "running step %d doubles recovery even after releasing run" % step)
		_check(running.y == normal.y, "running step %d preserves active duration" % step)
	for interval: int in [29, 30, 31]:
		await _reset()
		await _press()
		await _ticks(interval - 1)
		await _press()
		_check(_combat.combo_step == (2 if interval <= 30 else 1), "combo press interval %d frames respects inclusive 0.5s limit" % interval)
	# A running first attack exceeds 0.5s overall: eligibility uses press time,
	# not the later time at which a buffered second swing starts.
	await _reset()
	Input.action_press("run")
	Input.action_press("move_right")
	await _press()
	await _ticks(28)
	await _press()
	await _ticks(9)
	_check(_combat.combo_step == 2, "running combo accepts a timely buffered press after 0.5s execution delay")
	await _reset()
	Input.action_press("move_right")
	await _ticks(10)
	await _press()
	_check(absf(_player.velocity.x - _player.movement.walk_speed) < 1.0, "walking attack retains walking speed")
	await _reset()
	Input.action_press("run")
	await _press()
	_check(not _combat.running_attack, "run key without movement does not double attack timing")
	var old_height: float = await _measure_bounce(1.0, false)
	var new_height: float = await _measure_bounce(2.0, false)
	_check(new_height / old_height > 1.95 and new_height / old_height < 2.15, "bounce height roughly doubles at 60Hz: %.2f -> %.2f" % [old_height, new_height])
	var held_height: float = await _measure_bounce(2.0, true)
	_check(absf(new_height - held_height) < 0.1, "jump hold/release cannot alter hit bounce height")
	Input.action_release("jump")
	_world.queue_free()
	await process_frame
	print("COMBAT_REVISION_TESTS checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures else 0)
