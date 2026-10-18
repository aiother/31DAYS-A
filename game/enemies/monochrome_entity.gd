class_name MonochromeEntity
extends ColorlessEntity
enum Motion { NONE, DASH, DODGE }
const PROJECTILE: PackedScene = preload("res://enemies/monochrome_projectile.tscn")
var motion: Motion = Motion.NONE
var motion_remaining: float = 0.0
var dodge_cooldown_remaining: float = 0.0
var strong_attack: bool = false
var _dash_cooldown: float = 0.0
var platform_pursuit: EnemyPlatformPursuit = EnemyPlatformPursuit.new()
var air_pursuit: EnemyAirPursuit = EnemyAirPursuit.new()
var _motion_direction: Vector2 = Vector2.ZERO
var _attack_count: int = 0
var _light_windup: float
var _light_recovery: float
var _light_damage: int
var _watched_combat: WeakRef

func tuning() -> MonochromeConfig:
	return config as MonochromeConfig

func _ready() -> void:
	# Attack selection must never mutate the shared Resource or another actor.
	config = config.duplicate(true) as MonochromeConfig
	_light_windup = config.windup
	_light_recovery = config.recovery
	_light_damage = config.damage
	super._ready()

func _watch_target() -> void:
	var combat: PlayerCombat = (target as PlayerController).combat if is_instance_valid(target) and target is PlayerController else null
	var previous: PlayerCombat = _watched_combat.get_ref() as PlayerCombat if _watched_combat != null else null
	if previous == combat:
		return
	if is_instance_valid(previous) and previous.attack_started.is_connected(_on_player_attack):
		previous.attack_started.disconnect(_on_player_attack)
	_watched_combat = weakref(combat) if is_instance_valid(combat) else null
	if is_instance_valid(combat):
		combat.attack_started.connect(_on_player_attack)

func _physics_process(delta: float) -> void:
	_watch_target()
	air_pursuit.tick(delta)
	if not is_instance_valid(target) or (target is PlayerController and not (target as PlayerController).life.is_alive()):
		platform_pursuit.cancel()
		air_pursuit.cancel()
	dodge_cooldown_remaining = maxf(0,dodge_cooldown_remaining-delta)
	_dash_cooldown = maxf(0,_dash_cooldown-delta)
	platform_pursuit.tick(delta)
	if state == State.DEAD:
		return
	var player_dead: bool = is_instance_valid(target) and target is PlayerController and not (target as PlayerController).life.is_alive()
	if motion != Motion.NONE and (player_dead or state == State.STUN):
		_end_motion()
	if motion == Motion.NONE:
		super._physics_process(delta)
		return
	_flash = maxf(0,_flash-delta*4)
	_ranged_cooldown_remaining = maxf(0,_ranged_cooldown_remaining-delta)
	motion_remaining = maxf(0,motion_remaining-delta)
	velocity.x = _motion_direction.x*tuning().dash_speed
	if flying:
		velocity.y = _motion_direction.y*tuning().dash_speed
	else:
		velocity.y = minf(1500,velocity.y+config.gravity*delta)
	if not _safe_horizontal(signf(velocity.x),absf(velocity.x)*delta):
		velocity.x = 0
		motion_remaining = 0
	move_and_slide()
	if motion_remaining == 0:
		_end_motion()
	visual.queue_redraw()
	_update_status_label()

func _end_motion() -> void:
	motion = Motion.NONE
	motion_remaining = 0
	hurtbox.accepts_hits = state != State.DEAD
	_stop_horizontal()

func _safe_horizontal(direction: float, distance: float) -> bool:
	if test_move(global_transform,Vector2(direction*distance,0)):
		return false
	if flying or not is_on_floor():
		return true
	var ahead: Vector2 = global_position+Vector2(direction*(distance+24),-4)
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ahead,ahead+Vector2(0,32),1)
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _on_player_attack(direction: Vector2, _combo_step: int) -> void:
	# React to visible attack startup, never to player HP or a future input.
	if not is_physics_processing() or not can_interrupt() or state not in [State.IDLE,State.CHASE,State.WINDUP] or motion != Motion.NONE or dodge_cooldown_remaining > 0 or not is_instance_valid(target):
		return
	var offset: Vector2 = global_position-target.global_position
	if offset.length()>tuning().dodge_range or absf(offset.y)>100 or not _can_see_target():
		return
	if direction.dot(offset.normalized())<0.25:
		return
	var away: float = signf(offset.x) if absf(offset.x)>1 else -direction.x
	if is_zero_approx(away) or not _safe_horizontal(away,tuning().dash_speed*tuning().dodge_duration):
		return
	_seen = true
	_release_slot()
	state = State.CHASE
	_remaining = 0
	motion = Motion.DODGE
	motion_remaining = tuning().dodge_duration
	_motion_direction = Vector2(away,0)
	hurtbox.accepts_hits = false
	dodge_cooldown_remaining = tuning().low_health_dodge_cooldown if health*3<config.max_health else tuning().dodge_cooldown
	visual.queue_redraw()
	_update_status_label()

func _seek_target() -> void:
	if is_instance_valid(target):
		var offset: Vector2 = target.global_position-global_position
		var visible: bool = _can_see_target()
		if visible and offset.length()<=config.sight_range:
			_seen = true
		if flying and air_pursuit.chase(self):
			state = State.CHASE
			return
		if platform_pursuit.chase(self,tuning().jump_speed,tuning().jump_cooldown,tuning().pursuit_max_drop):
			state = State.CHASE
			return
		if platform_pursuit.graph_mode and platform_pursuit.no_path:
			state = State.CHASE
			if visible and offset.length()<=config.ranged_range and _ranged_cooldown_remaining==0 and (not is_instance_valid(coordinator) or coordinator.try_acquire(self)):
				strong_attack = false
				config.windup = _light_windup
				config.recovery = _light_recovery
				config.damage = _light_damage
				_ranged = true
				_attack_direction = offset.normalized()
				facing = signf(offset.x) if absf(offset.x)>1 else facing
				state = State.WINDUP
				_remaining = config.windup
				_attack_id += 1
				_hit_targets.clear()
				_stop_horizontal()
				attack_started.emit(true)
			return
		if _seen and visible and _dash_cooldown == 0 and offset.length()>220 and offset.length()<520 and (flying or (is_on_floor() and absf(offset.y)<65)):
			var direction: Vector2 = offset.normalized() if flying else Vector2(signf(offset.x),0)
			if _safe_horizontal(direction.x,tuning().dash_speed*tuning().dash_duration):
				motion = Motion.DASH
				motion_remaining = tuning().dash_duration
				_motion_direction = direction
				_dash_cooldown = tuning().dash_cooldown
				state = State.CHASE
				facing = signf(offset.x)
				return
	strong_attack = _attack_count%2 == 1
	config.windup = tuning().strong_windup if strong_attack else _light_windup
	config.recovery = tuning().strong_recovery if strong_attack else _light_recovery
	config.damage = tuning().strong_damage if strong_attack else _light_damage
	super._seek_target()
	if state == State.WINDUP:
		_attack_count += 1

func _spawn_projectile() -> void:
	_ranged_cooldown_remaining = 0 if ranged_only else config.ranged_cooldown
	var projectile: MonochromeProjectile = PROJECTILE.instantiate() as MonochromeProjectile
	projectile.source = self
	projectile.damage = config.damage
	projectile.velocity = _attack_direction*config.projectile_speed
	projectile.position = get_parent().to_local(global_position+Vector2(facing*36,-40))
	get_parent().add_child(projectile)

func _protected_action() -> bool:
	return motion == Motion.DODGE or (strong_attack and state in [State.WINDUP,State.ACTIVE,State.RECOVERY])

func _interrupt_action() -> void:
	platform_pursuit.cancel()
	air_pursuit.cancel()
	_end_motion()

func _update_status_label() -> void:
	super._update_status_label()
	if state == State.DEAD:
		return
	var action: String = "闪避" if motion == Motion.DODGE else "冲刺"
	if motion == Motion.NONE:
		action = ("强力·" if strong_attack else "轻击·")+health_label.text.get_slice("·",1).strip_edges()
		if state==State.CHASE and not platform_pursuit.intent.is_empty():
			action = platform_pursuit.intent
		if flying and state==State.CHASE and not air_pursuit.intent.is_empty():
			action = air_pursuit.intent
	health_label.text = "单色 %d / %d · %s" % [health,config.max_health,action]
