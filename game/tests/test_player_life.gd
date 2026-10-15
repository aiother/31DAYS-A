extends SceneTree
var _checks: int = 0
var _failures: int = 0
var _world: Node2D
var _player: PlayerController
var _life: PlayerLife
var _receiver: CombatHurtbox
var _death_events: int = 0

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

func _release() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func _fresh() -> void:
	_release()
	_life.start_new_run()
	_player.position = Vector2(224, 880)
	_player.reset_kinematics()
	await _ticks(8)

func _on_died() -> void:
	_death_events += 1

func _run() -> void:
	var packed: PackedScene = load("res://debug/movement_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	_player = _world.get_node("Player") as PlayerController
	_life = _player.life
	_receiver = _player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	_life.died.connect(_on_died)
	await _ticks(10)
	_check(_life.health == 3 and _life.config.max_health == 5, "new run starts at frozen 3/5 HP")
	_check(not _receiver.receive_attack(0, Vector2.ZERO, _player, 0), "zero damage rejected")
	_check(_receiver.receive_attack(1, Vector2.RIGHT * 100, _player, 1) and _life.health == 2, "light hit removes one health")
	_check(not _receiver.receive_attack(3, Vector2.LEFT * 100, _player, 2) and _life.health == 2, "same-window hit rejected without minimum damage")
	_check(_player.velocity.x > 0 and not _life.can_control(), "accepted hit applies slight knockback and stun")
	Input.action_press("move_left")
	Input.action_press("jump")
	Input.action_press("attack")
	await _ticks(3)
	_check(_player.velocity.x >= 0 and _player.velocity.y >= 0 and not _player.combat.is_attacking(), "stun blocks direction override jump and attack")
	_release()
	await _ticks(15)
	_check(_life.can_control(), "control returns after hurt stun")
	_check(_receiver.receive_attack(1, Vector2.ZERO, _player, 3) and _life.health == 1, "hit accepted after protection expires")
	await _fresh()
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")
	_check(_player.combat.is_attacking(), "test attack starts before hit interruption")
	_receiver.receive_attack(2, Vector2.LEFT * 100, _player, 4)
	_check(_life.health == 1 and not _player.combat.is_attacking(), "medium hit removes two and interrupts ongoing attack")
	await _fresh()
	_check(_life.take_hit(2) and _life.health == 1, "environment damage uses same life and protection pipeline")
	_check(not _life.take_hit(2), "environment cannot bypass protection")
	await _fresh()
	_receiver.receive_attack(3, Vector2.RIGHT * 100, _player, 5)
	_check(_life.health == 0 and _life.state == PlayerLife.State.DOWNED, "heavy hit reaches zero and enters downed state")
	_check(_death_events == 1, "death event emitted exactly once")
	_check(not _receiver.receive_attack(1, Vector2.ZERO, _player, 6) and _death_events == 1, "dead player refuses further damage and duplicate death")
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("attack")
	var start: Vector2 = _player.position
	await _ticks(30)
	_check(_life.state == PlayerLife.State.DOWNED and not _player.combat.is_attacking() and absf(_player.position.x - start.x) < 0.1, "death blocks input and does not skip 1 second downed stage")
	await _ticks(33)
	_check(_life.state == PlayerLife.State.FADING, "downed stage transitions to death fade")
	await _ticks(26)
	_check(_life.state == PlayerLife.State.DEATH_MENU, "fade completes before death menu becomes ready")
	_release()
	_life.revive()
	_check(_life.health == 5 and _life.is_alive() and is_equal_approx(_life.protection_remaining, 3.0), "revive restores full 5 HP and 3 seconds protection")
	_check(_player.velocity.is_zero_approx() and not _player.combat.is_attacking(), "revive clears old motion and attack")
	Input.action_press("attack")
	await _ticks(1)
	Input.action_release("attack")
	_check(_player.combat.is_attacking() and _life.protection_remaining > 2.9, "attacking after revive preserves protection")
	_check(not _receiver.receive_attack(3, Vector2.ZERO, _player, 7), "revive protection prevents damage")
	await _ticks(175)
	_check(_life.protection_remaining > 0.0, "protection remains until 3 seconds elapse")
	await _ticks(7)
	_check(_receiver.receive_attack(1, Vector2.ZERO, _player, 8) and _life.health == 4, "damage works again after revive protection expires")
	_world.queue_free()
	await process_frame
	# UI/restart integration: real scene reload resets enemies, corpses and shots.
	packed = load("res://debug/enemy_lab.tscn") as PackedScene
	_world = packed.instantiate() as Node2D
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node("Player") as PlayerController
	_life = _player.life
	await _ticks(10)
	var ui: Node = _world.get_node("LifeUI")
	ui.call("show_pause")
	var paused_position: Vector2 = _player.position
	await _ticks(4)
	_check(paused and _player.position == paused_position, "pause menu freezes physical game progress")
	ui.call("show_settings")
	_check(paused, "settings retains pause")
	ui.call("resume_game")
	_check(not paused, "resume returns to game")
	_life.take_hit(3)
	ui.call("show_pause")
	var downed_remaining: float = _life.phase_remaining
	await _ticks(4)
	_check(paused and _life.phase_remaining == downed_remaining, "menu remains usable after lethal hit and pauses death timing")
	ui.call("resume_game")
	await _ticks(90)
	_check(paused and _life.state == PlayerLife.State.DEATH_MENU, "death menu appears and pauses scene after downed and fade")
	var old_world_id: int = _world.get_instance_id()
	ui.call("restart_challenge")
	await _ticks(8)
	_world = current_scene as Node2D
	_player = _world.get_node("Player") as PlayerController
	_life = _player.life
	_check(_world.get_instance_id() != old_world_id and not paused, "restart reloads the challenge and resumes")
	_check(_life.health == 5 and _life.protection_remaining > 2.7, "new challenge player starts full with revive protection")
	var enemies: Node = _world.get_node("Enemies")
	_check(enemies.get_child_count() == 2 and (enemies.get_child(0) as ColorlessEntity).health == 13, "restart restores fresh enemy instances")
	_check(_player.position.distance_to(Vector2(224, 896)) < 2.0, "restart returns to graybox spawn")
	_world.queue_free()
	await process_frame
	print("PLAYER_LIFE_TESTS checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures else 0)
