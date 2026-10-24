# verify-suite: {"name":"combat feedback effects, hit-stop and shake from real actions","path":"res://tests/test_combat_effects.gd","marker":"COMBAT_EFFECTS_TESTS checks=","fixed_fps":60,"timeout":240}
extends SceneTree
## FX-001. Real player and enemy scenes, real input and physics frames. Effect
## records come from what CombatEffects actually drew (every primitive goes
## through a recording helper), never from the caller.
var checks: int = 0
var failures: int = 0
var lab: Node
var body: PlayerController
var director: CombatEffectDirector
var fx: CombatEffects
var camera: Camera2D
## Every record drawn since the last begin().
var records: Array[Dictionary] = []
var spawned: Array[Node] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(n: int = 1) -> void:
	for i: int in range(n):
		await physics_frame
		await process_frame
		records.append_array(fx.drawn)

func begin() -> void:
	records.clear()

func seen(kind: String) -> Array[Dictionary]:
	return records.filter(func(r: Dictionary) -> bool: return r["kind"] == kind and int(r["prims"]) > 0 and float(r["alpha"]) > 0.0)

func release_all() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func tap(action: StringName) -> void:
	Input.action_press(action)
	await frames(1)
	Input.action_release(action)

func chest() -> Vector2:
	return body.global_position + CombatEffects.CHEST

func reset(point: Vector2 = Vector2(400, 880)) -> void:
	release_all()
	for i: int in range(120):
		if not body.combat.is_attacking() and not body.possibility.busy() and HitStop.remaining(body) <= 0.0: break
		await frames(1)
	for node: Node in spawned:
		if is_instance_valid(node): node.queue_free()
	spawned.clear()
	body.global_position = point
	body.velocity = Vector2.ZERO
	body.facing = 1.0
	body.reset_kinematics()
	body.combat.reset_combo()
	body.life.start_new_run()
	body.life.health = 5
	body.possibility.balance = 10
	await frames(10)
	fx.clear()
	begin()

## An enemy standing still in front of the player (no AI), or chasing it.
func enemy(offset: Vector2, path: String = "res://enemies/colorless_entity.tscn", chase: bool = false) -> ColorlessEntity:
	var actor: ColorlessEntity = (load(path) as PackedScene).instantiate() as ColorlessEntity
	lab.get_node("Enemies").add_child(actor)
	actor.global_position = body.global_position + offset
	if chase:
		actor.target = body
		actor.alert_to_target()
	spawned.append(actor)
	return actor

## Physics frames of one whole attack from the press until it is over.
func attack_frames() -> int:
	Input.action_press(&"attack")
	await frames(1)
	Input.action_release(&"attack")
	var count: int = 1
	while (body.combat.is_attacking() or HitStop.remaining(body) > 0.0) and count < 200:
		await frames(1)
		count += 1
	return count

func run() -> void:
	lab = (load("res://debug/enemy_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for child: Node in lab.get_node("Enemies").get_children():
		child.queue_free()
	body = lab.get_node("Player") as PlayerController
	director = body.get_node("EffectDirector") as CombatEffectDirector
	fx = director.effects
	camera = body.get_node("Camera2D") as Camera2D
	await frames(6)
	check(director.config.hit_stop_seconds == 0.10 and director.config.hit_shake == 0.0 and director.config.hurt_shake == 5.0, "configured values are the EXP-005 final")
	check(not "_reward_flash" in body.get_node("VisualRoot"), "the graybox reward ring is gone from the player visual")
	await swing_cases()
	await hit_stop_cases()
	await reaction_cases()
	await player_cases()
	await clock_case()
	# Let the graybox hit and warning sounds finish before the mixer closes.
	for i: int in range(40): await process_frame
	print("COMBAT_EFFECTS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func swing_cases() -> void:
	await reset()
	await tap(&"attack")
	await frames(3)
	var side: Array[Dictionary] = seen("swing")
	check(not side.is_empty() and (side[0]["centroid"] as Vector2).x > chest().x + 20.0, "a real horizontal attack draws a swing on the facing side")
	await reset()
	Input.action_press(&"aim_up")
	await tap(&"attack")
	await frames(3)
	Input.action_release(&"aim_up")
	var up: Array[Dictionary] = seen("swing")
	check(not up.is_empty() and (up[0]["centroid"] as Vector2).y < chest().y - 20.0, "W + attack draws the swing above")
	await reset()
	await tap(&"jump")
	await frames(6)
	Input.action_press(&"aim_down")
	await tap(&"attack")
	await frames(3)
	Input.action_release(&"aim_down")
	var down: Array[Dictionary] = seen("swing")
	check(not down.is_empty() and (down[0]["centroid"] as Vector2).y > chest().y + 20.0, "S + attack in the air draws the swing below")
	var glow: bool = down.any(func(r: Dictionary) -> bool: return (r["glow"] as Color).a > 0.0)
	check(glow, "the fused swing keeps its warm glow under the brush")

func hit_stop_cases() -> void:
	# A miss: no stop, baseline length.
	await reset()
	var stops: int = director.stops
	var miss: int = await attack_frames()
	check(director.stops == stops and seen("hit").is_empty(), "a swing that meets nothing does not stop")
	# A hit on a real enemy: the player and the target stop together for 0.10 s.
	await reset()
	var target: ColorlessEntity = enemy(Vector2(70, 0))
	var bystander: ColorlessEntity = enemy(Vector2(700, 0), "res://enemies/colorless_entity.tscn", true)
	await frames(2)
	begin()
	var rest: Vector2 = target.get_node("VisualRoot").position
	var stun_frames: Array[int] = [0]
	var shivered: Array[bool] = [false]
	# Physics frames of the player's stop in which the bystander moved.
	var moving: Array[int] = [0, 0]
	var last_x: Array[float] = [bystander.global_position.x]
	# Frames since the target's stop ended, and whether it was back in place.
	var released: Array[int] = [-1]
	var back: Array[bool] = [false]
	var watch: Callable = func() -> void:
		if target.state == ColorlessEntity.State.STUN: stun_frames[0] += 1
		var held: bool = HitStop.remaining(target) > HitStop.EPSILON
		if held and target.get_node("VisualRoot").position != rest: shivered[0] = true
		if held: released[0] = 0
		elif released[0] >= 0:
			released[0] += 1
			if released[0] == 3: back[0] = target.get_node("VisualRoot").position == rest and target.state == ColorlessEntity.State.STUN
		if HitStop.remaining(body) > HitStop.EPSILON:
			moving[1] += 1
			if bystander.global_position.x != last_x[0]: moving[0] += 1
		last_x[0] = bystander.global_position.x
	physics_frame.connect(watch)
	var hit: int = await attack_frames()
	for i: int in range(40): await frames(1)
	physics_frame.disconnect(watch)
	var expected: int = roundi(director.config.hit_stop_seconds * Engine.physics_ticks_per_second)
	check(director.stops == stops + 1, "a landed swing starts exactly one stop")
	check(hit - miss == expected, "the player's attack lasts exactly the stop longer (%d vs %d frames), nothing shortened" % [hit, miss])
	var stun: int = roundi(target.config.hit_stun * Engine.physics_ticks_per_second)
	check(absi(stun_frames[0] - (stun + expected)) <= 1, "the target's stun runs in full after its stop (%d frames)" % stun_frames[0])
	check(not seen("hit").is_empty() and not seen("enemy_hurt").is_empty(), "the hit and the target's flash are drawn")
	check(records.any(func(r: Dictionary) -> bool: return r["kind"] == "swing" and r["held"]), "the swing trail is held where it met the target")
	check(shivered[0] and back[0], "the target shivers during the stop and is back in place right after, still stunned")
	check(moving[1] >= 5 and moving[0] >= moving[1] - 1, "an enemy that was not hit keeps moving during the stop (%d of %d frames)" % [moving[0], moving[1]])
	check(camera.offset == Vector2.ZERO and director.last_shake.is_empty(), "an ordinary hit does not shake the screen")
	# Two targets in one swing: one stop, both held.
	await reset()
	var first: ColorlessEntity = enemy(Vector2(70, 0))
	var second: ColorlessEntity = enemy(Vector2(76, 0))
	await frames(2)
	stops = director.stops
	Input.action_press(&"attack")
	var both: bool = false
	for i: int in range(20):
		await frames(1)
		Input.action_release(&"attack")
		if HitStop.remaining(first) > 0.0 and HitStop.remaining(second) > 0.0: both = true
	check(director.stops == stops + 1 and both, "a swing meeting two targets stops both but the player only once")
	# The pause menu freezes the stop.
	await reset()
	enemy(Vector2(70, 0))
	await frames(2)
	Input.action_press(&"attack")
	for i: int in range(20):
		await frames(1)
		Input.action_release(&"attack")
		if HitStop.remaining(body) > 0.0: break
	await frames(1)
	var left: float = HitStop.remaining(body)
	paused = true
	for i: int in range(10): await frames(1)
	var frozen: bool = left > 0.0 and is_equal_approx(HitStop.remaining(body), left)
	paused = false
	for i: int in range(12): await frames(1)
	check(frozen and HitStop.remaining(body) == 0.0, "pausing freezes the stop, it ends after resuming")
	# A projectile knocked back is not a body: no stop.
	await reset()
	var projectile: ColorlessProjectile = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as ColorlessProjectile
	lab.add_child(projectile)
	spawned.append(projectile)
	projectile.global_position = chest() + Vector2(75, 0)
	projectile.set_physics_process(false)
	stops = director.stops
	await tap(&"attack")
	await frames(8)
	check(projectile.reflected and not seen("reflect").is_empty() and director.stops == stops, "a reflected projectile draws its flash without a stop")
	# A down attack on a target: the rebound ring.
	await reset()
	enemy(Vector2(0, 0))
	await tap(&"jump")
	await frames(5)
	Input.action_press(&"aim_down")
	for i: int in range(40):
		Input.action_press(&"attack")
		await frames(1)
		Input.action_release(&"attack")
		if not seen("bounce").is_empty(): break
	Input.action_release(&"aim_down")
	check(not seen("bounce").is_empty(), "a down attack that lands draws the rebound")
	# Defeat: the burst.
	await reset()
	var weak: ColorlessEntity = enemy(Vector2(70, 0))
	await frames(2)
	weak.health = 1
	await attack_frames()
	await frames(4)
	check(not seen("enemy_death").is_empty(), "defeating an enemy draws its burst")

func reaction_cases() -> void:
	# Input pressed during the stop is not lost.
	await reset()
	enemy(Vector2(70, 0))
	await frames(2)
	Input.action_press(&"attack")
	for i: int in range(20):
		await frames(1)
		Input.action_release(&"attack")
		if HitStop.remaining(body) > 0.0: break
	# Pressed during the stop: kept in the attack buffer exactly as a press at
	# the moment of the hit (no attack time passes during the stop).
	var phase_left: float = body.combat._phase_remaining
	await tap(&"attack")
	check(HitStop.remaining(body) > 0.0 and is_equal_approx(body.combat._buffer_remaining, body.combat.config.input_buffer) and body.combat._phase_remaining == phase_left, "an attack pressed during the stop is buffered and no attack time passes")
	# The two-step combo still connects across a stop: press again in the recovery.
	for i: int in range(30):
		await frames(1)
		if HitStop.remaining(body) <= 0.0 and body.combat.phase == PlayerCombat.Phase.RECOVERY: break
	await tap(&"attack")
	var second: bool = false
	for i: int in range(40):
		await frames(1)
		if body.combat.combo_step == 2 and body.combat.is_attacking(): second = true
	check(second, "pressing again in the recovery after a stop gives the second swing")
	await reset()
	enemy(Vector2(70, 0))
	await frames(2)
	Input.action_press(&"attack")
	for i: int in range(20):
		await frames(1)
		Input.action_release(&"attack")
		if HitStop.remaining(body) > 0.0: break
	var y: float = body.global_position.y
	await tap(&"jump")
	var rose: bool = false
	for i: int in range(20):
		await frames(1)
		if body.global_position.y < y - 4.0: rose = true
	check(rose, "a jump pressed during the stop is taken after it")
	# A real enemy attack on the player: hurt effect and a light shake.
	await reset()
	var attacker: ColorlessEntity = enemy(Vector2(60, 0), "res://enemies/colorless_entity.tscn", true)
	var shook: float = 0.0
	for i: int in range(180):
		await frames(1)
		shook = maxf(shook, camera.offset.length())
		if not seen("hurt").is_empty() and director.shake_left == 0.0: break
	check(not seen("hurt").is_empty(), "a real enemy hit draws the hurt effect")
	check(director.last_shake.get("power", 0.0) == 5.0 and shook > 0.0 and shook <= 5.01, "being hurt shakes the screen lightly (peak %.2f px)" % shook)
	for i: int in range(20): await frames(1)
	check(camera.offset == Vector2.ZERO, "the camera is back after the shake")
	attacker.queue_free()

func player_cases() -> void:
	# Possibility set directly, then a dodge: spending, never the gain effect
	# (the SYS-010 G4 observation).
	await reset()
	body.possibility.balance = 10
	await frames(2)
	await tap(&"dodge")
	await frames(6)
	check(not seen("spend").is_empty() and not seen("dodge").is_empty() and seen("gain").is_empty(), "a dodge after a direct balance write spends and never shows the gain effect")
	check(not seen("invuln").is_empty(), "the dodge's invulnerability is shown")
	await reset()
	body.possibility.balance = 0
	await tap(&"dodge")
	await frames(6)
	check(not seen("poor_dodge").is_empty() and seen("dodge").is_empty(), "an overdraft dodge draws the vermilion after-images")
	await reset()
	body.possibility.balance = 0
	var source: Vector2 = chest() + Vector2(200, -30)
	body.possibility.gain(3, source)
	await frames(3)
	var gain: Array[Dictionary] = seen("gain")
	check(not gain.is_empty() and (gain[0]["at"] as Vector2) == source, "gaining possibility draws motes at its source")
	# Healing to the end, then an interrupted heal.
	await reset()
	body.life.health = 3
	Input.action_press(&"recover")
	for i: int in range(200):
		await frames(1)
		if not seen("heal_done").is_empty(): break
	Input.action_release(&"recover")
	check(not seen("heal_loop").is_empty() and not seen("heal_done").is_empty() and not fx.active("heal_loop"), "a finished heal loops then closes")
	await reset()
	body.life.health = 3
	Input.action_press(&"recover")
	await frames(30)
	Input.action_release(&"recover")
	await frames(40)
	check(not seen("heal_loop").is_empty() and seen("heal_done").is_empty() and not fx.active("heal_loop"), "an interrupted heal stops its loop without the completion")
	# Revival.
	await reset()
	body.life.revive()
	await frames(3)
	check(not seen("revive").is_empty(), "reviving draws the rising light")
	# Every finite effect ends and leaves nothing behind.
	await frames(200)
	check(fx.entries.all(func(e: Dictionary) -> bool: return e["kind"] in CombatEffects.LOOPS), "finite effects end and leave nothing behind")
	for kind: String in CombatEffects.LIFE.keys():
		fx.spawn(kind, chest())
	await frames(3)
	var drawn_kinds: Array = fx.drawn.map(func(r: Dictionary) -> String: return r["kind"] if int(r["prims"]) > 0 else "")
	check(CombatEffects.LIFE.keys().all(func(k: String) -> bool: return k in drawn_kinds), "every kind draws real primitives")
	await frames(60)
	check(fx.entries.all(func(e: Dictionary) -> bool: return e["kind"] in CombatEffects.LOOPS), "all of them end within one second")

## The day clock (and the final-battle budget, fed from it) keeps running
## through a stop: T4 only pauses it for the menu, story and death menu.
## Graybox sounds still playing when their scene goes would be left to the
## mixer (a reported leak); stop them first.
func silence(scene: Node) -> void:
	for player: Node in scene.find_children("*", "AudioStreamPlayer", true, false):
		(player as AudioStreamPlayer).stop()
		(player as AudioStreamPlayer).stream = null

func clock_case() -> void:
	silence(lab)
	lab.queue_free()
	await process_frame
	var directory: String = "user://tests/fx001_%d" % Time.get_ticks_usec()
	var session: FinalBattleSession = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "a new game starts for the clock check")
	session.intro_active = false
	session.data["events"][StartRoomSession.BIRTH] = true
	session.player.life.scripted_control_locked = false
	session.player.position = session._checkpoint(StartRoomSession.CHECKPOINT).config.spawn_position
	session.player.reset_kinematics()
	body = session.player
	fx = (body.get_node("EffectDirector") as CombatEffectDirector).effects
	for i: int in range(12):
		await physics_frame
		await process_frame
	var target: ColorlessEntity = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
	session.room.add_child(target)
	target.global_position = body.global_position + Vector2(70, 0)
	for i: int in range(3):
		await physics_frame
		await process_frame
	Input.action_press(&"attack")
	var started: float = -1.0
	var counted: int = 0
	for i: int in range(40):
		await physics_frame
		await process_frame
		Input.action_release(&"attack")
		if HitStop.remaining(body) > 0.0 and started < 0.0:
			started = DayClock.remaining(session.data)
		elif started >= 0.0:
			counted += 1
			if HitStop.remaining(body) <= 0.0: break
	var spent: float = started - DayClock.remaining(session.data)
	check(started > 0.0 and is_equal_approx(snappedf(spent, 0.001), snappedf(counted / float(Engine.physics_ticks_per_second), 0.001)), "the day clock runs through the stop (%.3f s over %d frames)" % [spent, counted])
	silence(session)
	session.queue_free()
	for i: int in range(2): await process_frame
	# The mixer thread may still hold a just-stopped WAV (as test_day_clock_session).
	OS.delay_msec(250)
	var dir: DirAccess = DirAccess.open(directory)
	if dir != null:
		for file: String in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
