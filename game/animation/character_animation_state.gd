class_name CharacterAnimationState
extends RefCounted
## Pure projections. Timed visual events live in CharacterAnimator, never here.
static func result(name: String, facing: float, phase: String = "", progress: float = -1.0, variant: String = "", combo: int = 0) -> Dictionary:
	var key: String = name
	if not variant.is_empty(): key += "." + variant
	if combo > 0: key += ".%d" % combo
	if not phase.is_empty(): key += "." + phase
	return {"name": name, "key": key, "facing": facing, "phase": phase, "progress": progress, "variant": variant, "combo": combo}

static func progress(remaining: float, duration: float) -> float:
	return clampf(1.0 - remaining / maxf(duration, 0.00001), 0.0, 1.0)

static func player(actor: PlayerController, observer: Variant) -> Dictionary:
	var life: PlayerLife = actor.life
	var face: float = actor.facing
	match life.state:
		PlayerLife.State.DOWNED: return result("downed", face, "", progress(life.phase_remaining, life.config.downed_duration))
		PlayerLife.State.FADING: return result("fade", face, "", progress(life.phase_remaining, life.config.death_fade_duration))
		PlayerLife.State.DEATH_MENU: return result("dead", face)
	if life.hurt_remaining > 0.0:
		return result("hurt", face, "", progress(life.hurt_remaining, life.config.hurt_duration))
	if observer != null and observer.respawn_left > 0.0:
		return result("respawn", face, "", progress(observer.respawn_left, 0.25))
	var action: PlayerPossibility = actor.possibility
	if action.state == PlayerPossibility.State.HEALING:
		return result("heal", face)
	if action.busy():
		var phase: String = ["", "windup", "active", "recovery"][action.state]
		var duration: float = action.config.dodge_duration
		if action.state == PlayerPossibility.State.DODGE_WINDUP:
			duration = action.config.poor_windup if action.poor_dodge else action.config.dodge_windup
		elif action.state == PlayerPossibility.State.DODGE_RECOVERY:
			duration = action.config.dodge_recovery
		return result("poor_dodge" if action.poor_dodge else "dodge", action.dodge_direction, phase, progress(action.remaining, duration))
	var combat: PlayerCombat = actor.combat
	if combat.is_attacking():
		var phase: String = ["idle", "windup", "active", "recovery"][combat.phase]
		var duration: float = combat.config.active_duration
		if combat.phase == PlayerCombat.Phase.WINDUP: duration = combat.config.windup * combat._timing_multiplier
		if combat.phase == PlayerCombat.Phase.RECOVERY: duration = (combat.config.recovery_second if combat.combo_step == 2 else combat.config.recovery_first) * combat._timing_multiplier
		var direction: String = "up" if combat.direction.y < 0 else ("down" if combat.direction.y > 0 else "horizontal")
		var value: Dictionary = result("attack", face, phase, progress(combat._phase_remaining, duration), direction, combat.combo_step)
		value["airborne"] = not actor.is_on_floor()
		return value
	if actor.is_on_floor():
		if actor.landing_lock_remaining > 0.0:
			return result("hard_land", face, "", progress(actor.landing_lock_remaining, actor.movement.hard_landing_duration))
		if observer != null and observer.land_left > 0.0:
			return result("hard_land" if observer.hard_land else "land", face, "", progress(observer.land_left, observer.land_duration))
		if actor._turn_remaining > 0.0:
			return result("turn", face, "", -1.0, "run" if Input.is_action_pressed("run") else "walk")
		if absf(actor.velocity.x) > 1.0:
			return result("run" if Input.is_action_pressed("run") else "walk", face)
		return result("idle", face)
	if observer != null and observer.takeoff_left > 0.0 and actor.velocity.y < 0.0:
		return result("takeoff", face, "", progress(observer.takeoff_left, 0.06))
	# Wider than one gravity step: a real 60 Hz jump cannot skip the apex.
	if absf(actor.velocity.y) <= actor.movement.gravity / float(Engine.physics_ticks_per_second) * 1.5:
		return result("apex", face)
	return result("rise" if actor.velocity.y < 0.0 else "fall", face)

static func enemy(actor: ColorlessEntity) -> Dictionary:
	var phase: String = ["idle", "chase", "windup", "active", "recovery", "stun", "dead"][actor.state]
	if actor.state == ColorlessEntity.State.DEAD: return result("dead", actor.facing)
	if actor.state == ColorlessEntity.State.STUN: return result("hurt", actor.facing, "", progress(actor._remaining, actor.config.hit_stun))
	var variant: String = "ranged" if actor._ranged else "melee"
	var combo: int = 0
	var duration: float = actor.config.windup
	if actor.state == ColorlessEntity.State.ACTIVE: duration = actor.config.active_duration
	if actor.state == ColorlessEntity.State.RECOVERY: duration = actor.config.recovery
	if actor is MonochromeEntity:
		var mono: MonochromeEntity = actor as MonochromeEntity
		if mono.motion != MonochromeEntity.Motion.NONE:
			var dodge: bool = mono.motion == MonochromeEntity.Motion.DODGE
			return result("dodge" if dodge else "dash", actor.facing, "", progress(mono.motion_remaining, mono.tuning().dodge_duration if dodge else mono.tuning().dash_duration))
		variant += ".strong" if mono.strong_attack else ".light"
	if actor is TianWarrior:
		var tian: TianWarrior = actor as TianWarrior
		if tian.motion != TianWarrior.Motion.NONE:
			var name: String = ["", "dash", "blink", "guard"][tian.motion]
			var time: float = tian.tuning().dash_duration
			if tian.motion == TianWarrior.Motion.BLINK_WARNING: time = tian.tuning().blink_warning
			if tian.motion == TianWarrior.Motion.GUARD: time = tian.tuning().guard_duration
			return result(name, actor.facing, "", progress(tian.motion_remaining, time))
		variant = ["combo", "heavy", "ranged", "counter"][tian.attack_kind]
		combo = tian.combo_step if tian.attack_kind == TianWarrior.Attack.COMBO else 0
		if actor.state == ColorlessEntity.State.WINDUP:
			duration = {"heavy": tian.tuning().heavy_windup, "ranged": tian.tuning().ranged_windup, "counter": tian.tuning().counter_windup}.get(variant, tian.tuning().combo_gap if combo > 1 else actor.config.windup)
		if actor.state == ColorlessEntity.State.RECOVERY:
			duration = tian.tuning().heavy_recovery if variant == "heavy" else (tian.tuning().combo_recovery if variant == "combo" else actor.config.recovery)
	if actor.state in [ColorlessEntity.State.WINDUP, ColorlessEntity.State.ACTIVE, ColorlessEntity.State.RECOVERY]:
		return result("attack", actor.facing, phase, progress(actor._remaining, duration), variant, combo)
	return result("run" if actor.state == ColorlessEntity.State.CHASE else "idle", actor.facing)
