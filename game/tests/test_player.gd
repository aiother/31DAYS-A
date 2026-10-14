extends SceneTree
## Run with --headless --path game --script res://tests/test_player.gd
var _failures: int = 0
var _checks: int = 0
var _player: PlayerController
var _world: Node2D
var _hard_lands: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _release_inputs() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func _reset(position: Vector2 = Vector2(224, 880)) -> void:
	_release_inputs()
	_player.global_position = position
	_player.velocity = Vector2.ZERO
	_player.landing_lock_remaining = 0.0
	await _ticks(8)

func _jump_height(held_ticks: int) -> float:
	await _reset()
	var start_y: float = _player.global_position.y
	var min_y: float = start_y
	Input.action_press("jump")
	for i: int in range(90):
		if i == held_ticks:
			Input.action_release("jump")
		await _ticks(1)
		min_y = minf(min_y, _player.global_position.y)
	Input.action_release("jump")
	return start_y - min_y

func _on_landed(_speed: float, hard: bool) -> void:
	if hard:
		_hard_lands += 1

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	_player.landed.connect(_on_landed)
	await _ticks(20)
	_check(_player.is_on_floor(), "TileMapLayer ground supports player")
	_check(absf(_player.global_position.y - 896.0) < 2.0, "feet stop at ground surface")
	_check(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) == 60, "60 Hz physics")
	_check(_player.get_node("VisualRoot/PlaceholderSprite") is Sprite2D, "placeholder renders without Spine")
	for path: String in ["Hitbox", "Hurtbox", "InteractionArea"]:
		var area: Area2D = _player.get_node("GameplayRoot/" + path) as Area2D
		_check(not area.monitoring and not area.monitorable, "reserved " + path + " inactive")
	var enemy_scene: PackedScene = load("res://enemies/colorless_entity.tscn") as PackedScene
	var enemy: Node = enemy_scene.instantiate()
	_check(enemy.has_node("GameplayRoot/Hitbox") and enemy.has_node("VisualRoot"), "colorless structure loads")
	enemy.free()
	Input.action_press("move_right")
	await _ticks(16)
	_check(absf(_player.velocity.x - _player.movement.walk_speed) < 1.0, "walk reaches configured speed")
	Input.action_press("run")
	await _ticks(10)
	_check(absf(_player.velocity.x - _player.movement.run_speed) < 1.0, "run exceeds walk speed")
	_release_inputs()
	await _ticks(16)
	_check(absf(_player.velocity.x) < 1.0, "release stops horizontal motion")
	var short_height: float = await _jump_height(1)
	var long_height: float = await _jump_height(22)
	_check(long_height > short_height + 100.0, "held jump higher than tap: %.1f / %.1f" % [long_height, short_height])
	await _reset()
	Input.action_press("move_right")
	await _ticks(14)
	Input.action_press("jump")
	await _ticks(3)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await _ticks(1)
	_check(_player.velocity.x > 0.0, "air reversal retains momentum on first tick")
	await _ticks(4)
	_check(_player.facing == -1.0, "facing changes after turn windup")
	await _ticks(18)
	_check(_player.velocity.x < 0.0, "air reversal accelerates toward new direction")
	_release_inputs()
	await _reset()
	Input.action_press("jump")
	await _ticks(14)
	Input.action_release("jump")
	await _ticks(1)
	var before: float = _player.velocity.y
	Input.action_press("jump")
	await _ticks(1)
	_check(_player.velocity.y > before, "second press cannot jump in midair")
	_release_inputs()
	await _reset(Vector2(224, 300))
	var landed_hard: bool = false
	for i: int in range(90):
		await _ticks(1)
		if i == 25:
			_check(_player.velocity.y <= _player.movement.max_fall_speed, "terminal velocity bounded")
		if _player.landing_lock_remaining > 0.0:
			landed_hard = true
			break
	_check(landed_hard and _hard_lands > 0, "high fall emits hard landing and locks controls")
	Input.action_press("move_right")
	Input.action_press("jump")
	await _ticks(2)
	_check(_player.is_on_floor() and absf(_player.velocity.x) < 1.0, "hard landing blocks jump and movement")
	_release_inputs()
	await _ticks(20)
	_check(_player.landing_lock_remaining == 0.0, "hard landing lock expires")
	# Leaving a modular platform grants grace within 1/3 of the 96px body.
	await _reset(Vector2(650, 768))
	Input.action_press("move_right")
	Input.action_press("run")
	var left_edge: bool = false
	for i: int in range(30):
		await _ticks(1)
		if not _player.is_on_floor():
			left_edge = true
			break
	_check(left_edge, "walks off modular platform")
	Input.action_press("jump")
	await _ticks(1)
	_check(_player.velocity.y < -600.0, "edge grace permits jump just off platform")
	_release_inputs()
	await _reset(Vector2(650, 768))
	Input.action_press("move_right")
	Input.action_press("run")
	await _ticks(24)
	Input.action_press("jump")
	await _ticks(1)
	_check(_player.velocity.y > 0.0, "expired edge grace rejects midair jump")
	_release_inputs()
	print("PLAYER_TESTS checks=%d failures=%d" % [_checks, _failures])
	_world.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)
