extends SceneTree
var checks: int = 0
var failures: int = 0
var player: PlayerController
var finished: int = 0
var landings: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func fresh(position: Vector2 = Vector2(224, 880)) -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	player.life.start_new_run()
	player.reset_kinematics()
	player.possibility.balance = 10
	player.position = position
	await ticks(8)
	player.landing_lock_remaining = 0.0
	finished = 0
	landings = 0

func run() -> void:
	var world: Node = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate()
	root.add_child(world)
	player = world.get_node("Player") as PlayerController
	player.combat.attack_finished.connect(func() -> void: finished += 1)
	player.landed.connect(func(_speed: float, _hard: bool) -> void: landings += 1)
	await ticks(10)
	for phase: int in [PlayerCombat.Phase.WINDUP, PlayerCombat.Phase.ACTIVE, PlayerCombat.Phase.RECOVERY]:
		await fresh()
		Input.action_press("attack")
		await ticks(1)
		Input.action_release("attack")
		var timeout: int = 0
		while player.combat.phase != phase and timeout < 50:
			await ticks(1)
			timeout += 1
		check(player.combat.phase == phase, "reached attack phase %d" % phase)
		var attack_id: int = player.combat.attack_id
		var old_remaining: float = player.combat._phase_remaining
		Input.action_press("jump")
		await ticks(1)
		check(player.velocity.y < 0 and not player.is_on_floor(), "jump works in attack phase %d" % phase)
		check(player.combat.attack_id == attack_id and player.combat.phase == phase and player.combat._phase_remaining < old_remaining and finished == 0, "jump preserves attack phase timer and identity")
		check(player.combat._last_combo_step == 1, "jump during attack preserves combo history")
		await ticks(40)
		check(finished == 1 and not player.combat.is_attacking(), "attack finishes once on original schedule")
	await fresh()
	var target: CombatHurtbox = (load("res://debug/combat_target.tscn") as PackedScene).instantiate() as CombatHurtbox
	world.add_child(target)
	target.position = Vector2(284, 760)
	Input.action_press("attack")
	Input.action_press("jump")
	await ticks(1)
	check(player.combat.is_attacking() and player.velocity.y < 0, "same-frame attack and jump both start")
	Input.action_release("attack")
	await ticks(20)
	check(int(target.get("hit_count")) == 1 and int(target.get("damage_total")) == 5, "jumping attack retains actual hit detection and single-hit registry")
	target.queue_free()
	Input.action_press("attack")
	await ticks(1)
	check(player.combat.combo_step == 2, "airborne second attack retains half-second combo window")
	await fresh()
	Input.action_press("dodge")
	await ticks(1)
	Input.action_release("dodge")
	check(player.possibility.balance == 9, "ground dodge costs 1")
	await ticks(22)
	Input.action_press("jump")
	await ticks(3)
	Input.action_press("move_right")
	Input.action_press("dodge")
	await ticks(1)
	Input.action_release("dodge")
	check(not player.is_on_floor() and player.possibility.balance == 7 and player.possibility.chain == 2, "ground and air dodge share consecutive costs")
	await ticks(5)
	check(player.velocity.x > 700 and player.velocity.y < 0, "air dodge moves sideways while retaining ascent")
	check(not player.life.take_hit(1), "air dodge invulnerability uses real damage pipeline")
	await fresh(Vector2(224, 400))
	Input.action_press("move_left")
	Input.action_press("dodge")
	await ticks(5)
	Input.action_release("dodge")
	check(player.velocity.x < -700 and player.velocity.y > 0, "falling air dodge retains gravity and left direction")
	Input.action_press("jump")
	await ticks(1)
	check(player.velocity.y > 0, "air dodge does not grant another jump")
	await fresh(Vector2(224, 700))
	player.velocity.y = 900
	Input.action_press("dodge")
	await ticks(16)
	check(player.is_on_floor() and landings == 1, "landing during dodge emits normal landing feedback once")
	await fresh(Vector2(224, 500))
	player.possibility.balance = 0
	check(player.possibility.try_dodge() and player.possibility.poor_dodge and player.possibility.balance == -1, "air dodge supports same overdraft")
	player.possibility.cancel()
	player.possibility.balance = -9
	check(not player.possibility.try_dodge(), "air dodge cannot bypass balance floor")
	await fresh(Vector2(224, 500))
	player.combat.phase = PlayerCombat.Phase.ACTIVE
	check(player.possibility.try_dodge() and not player.combat.is_attacking(), "air dodge cancels attack")
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	world.queue_free()
	await process_frame
	await process_frame
	print("AIR_ACTION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
