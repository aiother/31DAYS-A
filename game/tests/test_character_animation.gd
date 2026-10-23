# verify-suite: {"name":"read-only character animation states and resource driven visual playback","path":"res://tests/test_character_animation.gd","marker":"CHARACTER_ANIMATION_TESTS checks=","fixed_fps":60,"timeout":180}
extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var body: PlayerController
var animator: CharacterAnimator
var seen: Array[String] = []

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
		if is_instance_valid(body):
			var state: Dictionary = body.animation_state()
			if seen.is_empty() or seen.back() != state.key: seen.append(state.key)

func release() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)

func reset(point: Vector2 = Vector2(224, 880)) -> void:
	release()
	body.life.start_new_run()
	body.possibility.reset_actions()
	body.combat.interrupt()
	body.position = point
	body.reset_kinematics()
	await ticks(20)
	seen.clear()

func has_sequence(values: Array[String]) -> bool:
	var index: int = 0
	for key: String in seen:
		if index < values.size() and key == values[index]: index += 1
	return index == values.size()

func player_cases() -> void:
	await reset()
	check(body.animation_state().name == "idle", "real grounded idle")
	Input.action_press("move_right")
	await ticks(8)
	check(body.animation_state().name == "walk", "real walking input")
	Input.action_press("run")
	await ticks(8)
	check(body.animation_state().name == "run", "real running input")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await ticks(1)
	check(body.animation_state().name == "turn" and body.animation_state().facing == body.facing, "turn keeps true facing until the gameplay turn finishes")
	await ticks(6)
	check(body.animation_state().facing == -1, "completed turn publishes the new facing")
	await reset()
	Input.action_press("jump")
	await ticks(4)
	Input.action_release("jump")
	await ticks(85)
	check(has_sequence(["takeoff", "rise", "apex", "fall", "land", "idle"]), "real jump phases stay ordered: " + str(seen))
	await reset(Vector2(224, 200))
	await ticks(100)
	check("hard_land" in seen, "real long fall produces hard landing")
	# Directions and both combo steps use physical input buffering, never assign phases.
	for direction: String in ["horizontal", "up", "down"]:
		await reset()
		if direction == "down":
			body.position = Vector2(224, 100)
			body.velocity = Vector2.ZERO
			await ticks(1)
		if direction != "horizontal": Input.action_press("aim_" + direction)
		Input.action_press("attack")
		await ticks(1)
		Input.action_release("attack")
		await ticks(16)
		Input.action_press("attack")
		await ticks(1)
		Input.action_release("attack")
		await ticks(45)
		for combo: int in [1, 2]:
			var prefix: String = "attack.%s.%d." % [direction, combo]
			check(has_sequence([prefix + "windup", prefix + "active", prefix + "recovery"]), "real " + prefix + "phase order: " + str(seen))
	for poor: bool in [false, true]:
		await reset()
		body.possibility.balance = 0 if poor else 10
		Input.action_press("dodge")
		await ticks(1)
		Input.action_release("dodge")
		await ticks(35)
		var prefix: String = "poor_dodge." if poor else "dodge."
		check(has_sequence([prefix + "windup", prefix + "active", prefix + "recovery"]), "dodge affordability is preserved: " + str(seen))
	await reset()
	body.life.health = 1
	body.possibility.balance = 10
	Input.action_press("recover")
	await ticks(15)
	check(body.animation_state().name == "heal" and animator.player.current_animation_position > 0, "healing loops in real frames")
	Input.action_release("recover")
	await ticks(2)
	check(body.animation_state().name == "idle" and body.life.health == 1, "releasing recovery interrupts animation without granting health")
	Input.action_press("recover")
	await ticks(2)
	body.life.health = 2
	body.life.take_hit(1)
	await ticks(1)
	check(body.animation_state().name == "hurt" and not body.possibility.busy(), "actual hurt interrupts healing without animation controlling the action")
	Input.action_release("recover")
	await ticks(30)
	body.life.take_hit(1)
	await ticks(1)
	check(body.animation_state().name == "downed", "lethal real hit selects downed")
	await ticks(240)
	check(has_sequence(["downed", "fade", "dead"]), "real death timing orders downed fade dead")
	body.life.revive()
	await ticks(1)
	check(body.animation_state().name == "respawn", "real revive signal selects respawn")
	await ticks(20)
	body.life.protection_remaining = 0
	body.life.take_hit(1)
	await ticks(1)
	check(body.animation_state().name == "hurt", "nonlethal real hit selects hurt")
	var sprite: Sprite2D = body.get_node("VisualRoot/PlaceholderSprite") as Sprite2D
	check(sprite.modulate.r > sprite.modulate.g, "old hurt tint remains on its original sprite")
	await reset()

func snapshot() -> Array:
	return [body.position, body.velocity, body.facing, body.life.health, body.life.phase_remaining, body.life.hurt_remaining, body.combat.phase, body.combat._phase_remaining, body.combat.attack_id, body.possibility.balance, body.possibility.state, body.possibility.remaining, body.landing_lock_remaining]

func clip_for(scale: Vector2) -> Animation:
	var clip: Animation = Animation.new()
	clip.length = 1
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath(".:scale"))
	clip.track_insert_key(track, 0, scale)
	return clip

func resource_cases() -> void:
	await reset()
	var before: Array = snapshot()
	var state: Dictionary = body.animation_state()
	var repeatable: bool = true
	for i: int in range(100): repeatable = body.animation_state() == state and repeatable
	check(repeatable, "100 immediate queries return equal dictionaries")
	check(snapshot() == before, "100 queries do not mutate any gameplay field")
	var animation_time: float = animator.player.current_animation_position
	var visual_time: float = animator.elapsed
	paused = true
	await ticks(30)
	check(is_equal_approx(animator.elapsed, visual_time) and is_equal_approx(animator.player.current_animation_position, animation_time), "paused tree freezes observer and AnimationPlayer")
	check(snapshot() == before, "paused gameplay state also freezes")
	paused = false
	var original: CharacterAnimationMap = animator.mapping
	var replacement: CharacterAnimationMap = load("res://animation/tests/idle_override.tres") as CharacterAnimationMap
	# Copy the central mapping, change one entry using an independently loaded resource.
	var changed: CharacterAnimationMap = original.duplicate() as CharacterAnimationMap
	changed.clips = original.clips.duplicate()
	changed.clips["idle"] = replacement.clips["idle"]
	check(changed.resolve({"name": "walk", "key": "walk"}).clip == original.resolve({"name": "walk", "key": "walk"}).clip, "replacing idle preserves walk resource identity")
	animator.mapping = changed
	await ticks(2)
	check((body.get_node("VisualRoot") as Node2D).scale.is_equal_approx(Vector2(0.8, 1.2)), "loaded replacement resource actually drives the visual")
	check(body.scale == Vector2.ONE and body.get_node("BodyCollision").scale == Vector2.ONE, "animation never scales body or collision")
	Input.action_press("move_right")
	await ticks(8)
	check(animator.resolved.clip == original.clips["walk"], "next state still uses original walk clip")
	await reset()
	var missing: CharacterAnimationMap = CharacterAnimationMap.new()
	# Intentionally absent asset; constructed so the static reference checker
	# continues to validate every literal resource dependency in this file.
	missing.paths["idle"] = "res://" + "animation/not_installed.tres"
	animator.mapping = missing
	await ticks(2)
	check(animator.resolved.fallback and animator.player.is_playing(), "missing resource path falls back without loading error")
	var unsafe: Animation = clip_for(Vector2(9, 9))
	unsafe.track_set_path(0, NodePath("../..:scale"))
	missing.clips["idle"] = unsafe
	await ticks(2)
	check(animator.resolved.fallback and body.scale == Vector2.ONE, "escaping the visual subtree is rejected")
	unsafe = Animation.new()
	unsafe.add_track(Animation.TYPE_METHOD)
	missing.clips["idle"] = unsafe
	await ticks(2)
	check(animator.resolved.fallback, "callback tracks cannot drive gameplay")
	unsafe = clip_for(Vector2(9, 9))
	unsafe.track_set_path(0, NodePath(str(body.get_path()) + ":scale"))
	missing.clips["idle"] = unsafe
	await ticks(2)
	check(animator.resolved.fallback and body.scale == Vector2.ONE, "absolute paths cannot escape the visual subtree")
	animator.mapping = original
	await reset()

func spawn(path: String, point: Vector2 = Vector2(292, 896)) -> ColorlessEntity:
	var actor: ColorlessEntity = (load("res://" + "enemies/" + path + ".tscn") as PackedScene).instantiate() as ColorlessEntity
	actor.position = point
	actor.target = body
	world.add_child(actor)
	return actor

func observe(actor: ColorlessEntity, count: int) -> Array[String]:
	var keys: Array[String] = []
	for i: int in range(count):
		await ticks(1)
		var value: Dictionary = actor.animation_state()
		if not keys.has(value.key): keys.append(value.key)
	return keys

func enemy_cases() -> void:
	await reset()
	body.life.health = 5
	body.life.protection_remaining = 1000
	for path: String in ["colorless_entity", "monochrome_entity", "tian_warrior"]:
		var distant: ColorlessEntity = spawn(path, Vector2(1800, 896))
		await ticks(4)
		check(distant.animation_state().name == "idle", path + " real unsighted idle")
		distant.alert_to_target()
		await ticks(4)
		check(distant.animation_state().name == "run", path + " real alerted pursuit")
		distant.queue_free()
		await ticks(2)
		var actor: ColorlessEntity = spawn(path)
		var keys: Array[String] = await observe(actor, 180)
		check(keys.any(func(key: String) -> bool: return key.ends_with("windup")), path + " actual AI windup")
		check(keys.any(func(key: String) -> bool: return key.ends_with("active")), path + " actual AI active")
		check(keys.any(func(key: String) -> bool: return key.ends_with("recovery")), path + " actual AI recovery")
		if actor is MonochromeEntity:
			check(keys.has("attack.melee.light.windup") and keys.has("attack.melee.strong.windup"), "monochrome light and strong attacks: " + str(keys))
		if actor is TianWarrior:
			check(keys.has("attack.combo.1.windup") and keys.has("attack.combo.2.windup"), "tian combo steps retain separate keys")
		var before: Array = [actor.position, actor.velocity, actor.health, actor.state, actor._remaining, actor.config.damage]
		for i: int in range(100): actor.animation_state()
		check(before == [actor.position, actor.velocity, actor.health, actor.state, actor._remaining, actor.config.damage], path + " query is side effect free")
		# Vertical attack bypasses Tian's real directional guard.
		while not actor.can_interrupt(): await ticks(1)
		actor.hurtbox.receive_attack(1, Vector2.UP, body, 7000)
		check(actor.animation_state().name == "hurt", path + " real damage produces stun animation")
		actor.hurtbox.receive_attack(1000, Vector2.UP, body, 7001)
		check(actor.animation_state().name == "dead", path + " real lethal damage selects death")
		actor.queue_free()
		await ticks(2)
	# Motion selections arise from AI and actual player attacks, not assigned enum fixtures.
	var mono: MonochromeEntity = spawn("monochrome_entity", Vector2(1200, 896)) as MonochromeEntity
	await ticks(4)
	mono.position.x = 500
	var keys: Array[String] = await observe(mono, 20)
	check(keys.has("dash"), "monochrome AI dash is visible: " + str(keys) + str(body.position))
	mono.queue_free()
	await ticks(2)
	mono = spawn("monochrome_entity") as MonochromeEntity
	await ticks(2)
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	check(mono.animation_state().name == "dodge", "monochrome reacts to true attack startup with dodge")
	mono.queue_free()
	await reset()
	body.life.protection_remaining = 1000
	var tian: TianWarrior = spawn("tian_warrior", Vector2(1200, 896)) as TianWarrior
	await ticks(4)
	tian.position.x = 500
	keys = await observe(tian, 20)
	check(keys.has("blink"), "tian AI blink warning is visible: " + str(keys) + str(body.position))
	tian.queue_free()
	await ticks(2)
	tian = spawn("tian_warrior", Vector2(1200, 896)) as TianWarrior
	await ticks(4)
	tian.position.x = 500
	tian.blink_cooldown_remaining = 100
	keys = await observe(tian, 20)
	check(keys.has("dash"), "tian safe-path AI dash is visible: " + str(keys) + str(body.position))
	tian.queue_free()
	await ticks(2)
	tian = spawn("tian_warrior") as TianWarrior
	await ticks(2)
	tian.hurtbox.receive_attack(1, Vector2.RIGHT * 100, body, 8000)
	check(tian.animation_state().name == "guard", "real directional block selects guard")
	keys = await observe(tian, 65)
	check(keys.has("attack.counter.windup") and keys.has("attack.counter.active") and keys.has("attack.counter.recovery"), "real guard leads through counter phases")
	for kind: TianWarrior.Attack in [TianWarrior.Attack.HEAVY, TianWarrior.Attack.RANGED]:
		# Invoke the real action entry, then let physics own every transition and timer.
		tian._start_attack(kind)
		keys = await observe(tian, 150)
		var prefix: String = "attack.heavy." if kind == TianWarrior.Attack.HEAVY else "attack.ranged."
		for phase: String in ["windup", "active", "recovery"]:
			check(keys.has(prefix + phase), "tian real action " + prefix + phase)
	tian.queue_free()
	await ticks(2)

func run() -> void:
	for path: String in ["res://player/player.tscn", "res://enemies/colorless_entity.tscn", "res://enemies/monochrome_entity.tscn", "res://enemies/tian_warrior.tscn"]:
		var actor: Node = (load(path) as PackedScene).instantiate()
		root.add_child(actor)
		check(actor.has_method("animation_state"), path + " exposes the read-only animation query")
		actor.queue_free()
		await ticks(2)
	world = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	body = world.get_node("Player") as PlayerController
	animator = body.get_node("VisualRoot/Animator") as CharacterAnimator
	await player_cases()
	await resource_cases()
	await enemy_cases()
	release()
	world.queue_free()
	await ticks(2)
	OS.delay_msec(500)
	print("CHARACTER_ANIMATION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
