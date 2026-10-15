extends SceneTree
var checks: int = 0
var failures: int = 0
var player: PlayerController
var actions: PlayerPossibility

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

func fresh(balance: int = 10) -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	player.life.start_new_run()
	player.reset_kinematics()
	actions.balance = balance

func run() -> void:
	var world: Node2D = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	player = world.get_node("Player") as PlayerController
	actions = player.possibility
	await ticks(10)
	check(actions.balance == 3 and actions.config.maximum == 10, "initial possibility 3/10")
	actions.gain(20)
	check(actions.balance == 10, "gain caps at maximum")
	actions.balance = -9
	actions.gain(2)
	check(actions.balance == -7, "gain repays overdraft")
	# Deterministic component timing while body retains a real floor contact.
	player.set_physics_process(false)
	fresh()
	check(actions.try_dodge() and actions.balance == 9 and actions.chain == 1, "first dodge costs 1")
	check(not actions.try_dodge() and actions.balance == 9, "active action rejects duplicate spending")
	check(player.life.take_hit(1), "windup is vulnerable and hit cancels dodge")
	check(not actions.busy(), "damage clears dodge action")
	fresh()
	for expected: int in [9, 7, 4]:
		check(actions.try_dodge() and actions.balance == expected, "chain cost 1 then 2 then 3")
		actions.tick(0.05)
		check(actions.state == PlayerPossibility.State.DODGE_ACTIVE and not player.life.take_hit(1), "normal dodge active window blocks real damage")
		actions.tick(0.20)
		actions.tick(0.08)
	check(not actions.try_dodge() and actions.balance == 4, "fourth consecutive dodge rejected")
	actions.tick(0.96)
	check(actions.chain == 3, "chain remains before 1.3 seconds from last start")
	actions.tick(0.01)
	check(actions.chain == 0 and actions.try_dodge() and actions.balance == 3, "1.3 seconds since last start resets costs")
	fresh(0)
	check(actions.try_dodge() and actions.balance == -1 and actions.poor_dodge, "insufficient funds allow overdraft dodge")
	check(is_equal_approx(actions.remaining, 0.15), "poor dodge uses longer windup")
	actions.tick(0.15)
	check(is_equal_approx(actions.invincible_remaining, 0.08), "poor dodge uses fewer invincible frames")
	actions.tick(0.09)
	check(player.life.take_hit(1), "poor invulnerability expires before slide ends")
	fresh(-9)
	check(not actions.try_dodge() and actions.balance == -9, "floor refuses further dodge")
	fresh(-8)
	check(actions.try_dodge() and actions.balance == -9, "exact floor permitted")
	actions.cancel()
	check(not actions.try_dodge() and actions.balance == -9, "crossing floor rejected without partial charge")
	fresh()
	player.position.y -= 100
	player.set_physics_process(true)
	await ticks(1)
	check(not actions.try_dodge(), "air dodge prohibited")
	player.position = Vector2(224, 880)
	await ticks(10)
	player.set_physics_process(false)
	fresh(2)
	check(not actions.try_heal() and actions.balance == 2, "heal cannot overdraw")
	fresh()
	player.life.health = 5
	check(not actions.try_heal() and actions.balance == 10, "full health heal disabled")
	fresh()
	Input.action_press("recover")
	check(actions.try_heal() and actions.balance == 7, "heal charges 3 immediately")
	for i: int in range(167):
		actions.tick(1.0 / 60.0)
	check(player.life.health == 3 and actions.busy(), "heal does not pay out before 2.8 seconds")
	actions.tick(1.0 / 60.0)
	check(player.life.health == 5 and not actions.busy(), "heal pays 2 exactly at completion")
	fresh()
	player.life.health = 4
	Input.action_press("recover")
	actions.try_heal()
	actions.tick(2.8)
	check(player.life.health == 5, "healing cannot exceed max HP")
	fresh()
	Input.action_press("recover")
	actions.try_heal()
	Input.action_release("recover")
	actions.tick(0.1)
	check(not actions.busy() and actions.balance == 7 and player.life.health == 3, "early release retains cost without healing")
	fresh()
	Input.action_press("recover")
	actions.try_heal()
	player.life.take_hit(1)
	check(not actions.busy() and actions.balance == 7 and player.life.health == 2, "hit interrupts healing without refund")
	fresh()
	Input.action_press("recover")
	actions.try_heal()
	check(actions.try_dodge() and actions.balance == 6, "dodge cancels heal and pays own cost")
	fresh()
	player.combat.phase = PlayerCombat.Phase.ACTIVE
	check(not actions.try_heal(), "heal cannot cancel attack")
	check(actions.try_dodge() and not player.combat.is_attacking(), "dodge cancels attack")
	fresh()
	player.life.take_hit(3)
	check(not actions.try_dodge() and not actions.try_heal(), "death blocks both actions")
	fresh()
	player.set_physics_process(true)
	Input.action_press("recover")
	await ticks(1)
	var start_x: float = player.position.x
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("attack")
	await ticks(10)
	check(actions.state == PlayerPossibility.State.HEALING and absf(player.position.x - start_x) < 0.01 and not player.combat.is_attacking() and player.is_on_floor(), "held healing blocks movement jump and attacks")
	paused = true
	var before: float = actions.remaining
	await ticks(3)
	check(actions.remaining == before, "pause freezes action timing")
	paused = false
	fresh()
	Input.action_press("move_left")
	Input.action_press("dodge")
	await ticks(5)
	check(actions.dodge_direction == -1 and player.velocity.x < 0, "input starts left slide independently of facing")
	fresh()
	world.queue_free()
	await process_frame
	# Actual production reward wiring, including single-credit on repeated damage.
	world = (load("res://debug/enemy_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	player = world.get_node("Player") as PlayerController
	actions = player.possibility
	var enemy: ColorlessEntity = world.get_node("Enemies/GroundEntity") as ColorlessEntity
	var receiver: CombatHurtbox = enemy.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.receive_attack(20, Vector2.ZERO, player, 123)
	check(actions.balance == 5, "real colorless defeat credits 2 possibility")
	receiver.receive_attack(20, Vector2.ZERO, player, 124)
	check(actions.balance == 5, "dead enemy does not pay twice")
	world.queue_free()
	await process_frame
	await process_frame
	print("POSSIBILITY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
