class_name TianWarrior
extends ColorlessEntity
enum Motion { NONE, DASH, BLINK_WARNING, GUARD }
enum Attack { COMBO, HEAVY, RANGED, COUNTER }
@export_range(-1,1,2) var flank_side: int = 1
var motion: Motion = Motion.NONE
var motion_remaining: float = 0.0
var attack_kind: Attack = Attack.COMBO
var combo_total: int = 0
var combo_step: int = 0
var blink_offset: float = 0.0
var dash_cooldown_remaining: float = 0.0
var blink_cooldown_remaining: float = 0.0
var guard_cooldown_remaining: float = 0.0
var counter_remaining: float = 0.0
var _combo_count: int = 0
var _attack_serial: int = 0
var _motion_direction: float = 1.0
var platform_pursuit: EnemyPlatformPursuit = EnemyPlatformPursuit.new()

func tuning() -> TianConfig:
	return config as TianConfig

func _ready() -> void:
	config = config.duplicate(true) as TianConfig
	super._ready()
	hit_shape.shape = hit_shape.shape.duplicate()

func _safe_path(offset: float) -> bool:
	if test_move(global_transform,Vector2(offset,0)):
		return false
	if not is_on_floor():
		return false
	# A blink must have continuous ground, not merely a valid landing beyond a pit.
	var samples: int = maxi(1,ceili(absf(offset)/24.0))
	for i: int in range(1,samples+1):
		var distance: float = offset*i/float(samples)
		var start: Vector2 = global_position+Vector2(distance+signf(offset)*24,-4)
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start,start+Vector2(0,32),1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			return false
	return true

func _cancel_motion() -> void:
	motion = Motion.NONE
	motion_remaining = 0
	blink_offset = 0
	velocity.x = 0

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_flash = maxf(0,_flash-delta*4)
	_remaining = maxf(0,_remaining-delta)
	_ranged_cooldown_remaining = maxf(0,_ranged_cooldown_remaining-delta)
	dash_cooldown_remaining = maxf(0,dash_cooldown_remaining-delta)
	blink_cooldown_remaining = maxf(0,blink_cooldown_remaining-delta)
	guard_cooldown_remaining = maxf(0,guard_cooldown_remaining-delta)
	counter_remaining = maxf(0,counter_remaining-delta)
	platform_pursuit.tick(delta)
	velocity.y = minf(1500,velocity.y+config.gravity*delta)
	if not is_instance_valid(target) or (target is PlayerController and not (target as PlayerController).life.is_alive()):
		platform_pursuit.cancel()
		_release_slot()
		_cancel_motion()
		counter_remaining = 0
		state = State.IDLE
	elif motion != Motion.NONE:
		_tick_motion(delta)
	else:
		match state:
			State.STUN:
				velocity.x = move_toward(velocity.x,0,600*delta)
				if _remaining == 0:
					state = State.CHASE
			State.WINDUP:
				velocity.x = 0
				if _remaining == 0:
					state = State.ACTIVE
					_remaining = config.active_duration
					if attack_kind == Attack.RANGED:
						_spawn_projectile()
			State.ACTIVE:
				velocity.x = 0
				if _remaining == 0:
					if attack_kind == Attack.COMBO and combo_step<combo_total:
						combo_step += 1
						_prepare_strike(tuning().combo_gap)
					else:
						state = State.RECOVERY
						_remaining = tuning().heavy_recovery if attack_kind == Attack.HEAVY else (tuning().combo_recovery if attack_kind == Attack.COMBO else config.recovery)
						_release_slot()
			State.RECOVERY:
				velocity.x = 0
				if _remaining == 0:
					state = State.CHASE
			_:
				_seek_target()
	move_and_slide()
	if state == State.ACTIVE and attack_kind != Attack.RANGED:
		_melee_hits()
	visual.queue_redraw()
	_update_status_label()

func _tick_motion(delta: float) -> void:
	motion_remaining = maxf(0,motion_remaining-delta)
	velocity.x = 0
	if motion == Motion.DASH:
		var step: float = _motion_direction*tuning().dash_speed*delta
		if _safe_path(step):
			velocity.x = _motion_direction*tuning().dash_speed
		else:
			motion_remaining = 0
	if motion_remaining == 0:
		if motion == Motion.BLINK_WARNING and _safe_path(blink_offset):
			global_position.x += blink_offset
		_cancel_motion()

func _seek_target() -> void:
	var offset: Vector2 = target.global_position-global_position
	var visible: bool = _can_see_target()
	if visible and offset.length()<=config.sight_range:
		_seen = true
	if not _seen:
		velocity.x = 0
		state = State.IDLE
		return
	state = State.CHASE
	if platform_pursuit.chase(self,tuning().jump_speed,tuning().jump_cooldown,tuning().pursuit_max_drop):
		return
	if platform_pursuit.graph_mode and platform_pursuit.no_path:
		if visible and offset.length()<=config.ranged_range and _ranged_cooldown_remaining==0 and _acquire():
			_start_attack(Attack.RANGED)
		return
	if absf(offset.x)>1:
		facing = signf(offset.x)
	var level: bool = absf(offset.y)<=65
	var ready: bool = visible and level
	if counter_remaining>0 and ready and absf(offset.x)<=tuning().heavy_range and _acquire():
		_start_attack(Attack.COUNTER)
		return
	if ready and absf(offset.x)<=config.melee_range and _acquire():
		var kind: Attack = Attack.COMBO if _attack_serial%3==0 else (Attack.HEAVY if _attack_serial%3==1 else Attack.RANGED)
		_start_attack(kind)
		return
	if ready and absf(offset.x)<=tuning().heavy_range and _acquire():
		_start_attack(Attack.HEAVY)
		return
	# The ally who cannot acquire the slot moves to its assigned flank.
	if ready and absf(offset.x)<520 and _slot_occupied():
		_move_to_flank()
		return
	if ready and absf(offset.x)>180 and absf(offset.x)<440 and blink_cooldown_remaining == 0:
		var wanted: float = target.global_position.x+flank_side*100-global_position.x
		var step: float = clampf(wanted,-tuning().blink_distance,tuning().blink_distance)
		if absf(step)>32 and _safe_path(step):
			motion = Motion.BLINK_WARNING
			motion_remaining = tuning().blink_warning
			blink_offset = step
			blink_cooldown_remaining = tuning().blink_cooldown
			velocity.x = 0
			return
	if ready and absf(offset.x)>200 and absf(offset.x)<520 and dash_cooldown_remaining == 0 and _safe_path(facing*tuning().dash_speed*tuning().dash_duration):
		motion = Motion.DASH
		motion_remaining = tuning().dash_duration
		_motion_direction = facing
		dash_cooldown_remaining = tuning().dash_cooldown
		return
	if ready and offset.length()<=config.ranged_range and _ranged_cooldown_remaining == 0 and _acquire():
		_start_attack(Attack.RANGED)
		return
	_move_to_flank()

func _acquire() -> bool:
	return not is_instance_valid(coordinator) or coordinator.try_acquire(self)

func _slot_occupied() -> bool:
	if not is_instance_valid(coordinator):
		return false
	if coordinator.try_acquire(self):
		coordinator.release(self)
		return false
	return true

func _move_to_flank() -> void:
	var dx: float = target.global_position.x+flank_side*tuning().flank_distance-global_position.x
	velocity.x = signf(dx)*config.speed if absf(dx)>16 and _safe_path(signf(dx)*8) else 0

func _start_attack(kind: Attack) -> void:
	attack_kind = kind
	_attack_serial += 1
	counter_remaining = 0
	combo_step = 1
	combo_total = 2+_combo_count%2 if kind == Attack.COMBO else 1
	if kind == Attack.COMBO:
		_combo_count += 1
	config.damage = tuning().heavy_damage if kind == Attack.HEAVY else 1
	_ranged = kind == Attack.RANGED
	var shape: RectangleShape2D = hit_shape.shape as RectangleShape2D
	shape.size = Vector2(160,64) if kind == Attack.HEAVY else Vector2(72,56)
	var windup: float = tuning().heavy_windup if kind == Attack.HEAVY else (tuning().ranged_windup if kind == Attack.RANGED else (tuning().counter_windup if kind == Attack.COUNTER else config.windup))
	_prepare_strike(windup)

func _prepare_strike(windup: float) -> void:
	var offset: Vector2 = target.global_position-global_position
	if absf(offset.x)>1:
		facing = signf(offset.x)
	_attack_direction = offset.normalized() if attack_kind == Attack.RANGED else Vector2(facing,0)
	hitbox.position.x = facing*(100 if attack_kind == Attack.HEAVY else 48)
	state = State.WINDUP
	_remaining = windup
	_attack_id += 1
	_hit_targets.clear()
	velocity.x = 0
	attack_started.emit(attack_kind == Attack.RANGED)

func try_block(impulse: Vector2, source: Node2D) -> bool:
	if not is_physics_processing() or not is_instance_valid(source) or not is_instance_valid(target) or guard_cooldown_remaining>0 or motion!=Motion.NONE or absf(impulse.y)>0.01 or absf(impulse.x)<1:
		return false
	if state not in [State.IDLE,State.CHASE,State.WINDUP] or (state == State.WINDUP and attack_kind != Attack.COMBO):
		return false
	var offset: Vector2 = source.global_position-global_position
	if absf(offset.y)>100 or offset.x*facing<=0 or absf(offset.x)>220 or not _can_see_target():
		return false
	_release_slot()
	state = State.CHASE
	motion = Motion.GUARD
	motion_remaining = tuning().guard_duration
	guard_cooldown_remaining = tuning().guard_cooldown
	counter_remaining = tuning().counter_lifetime
	GameAudio.emit_from(self, &"combat.block", global_position)
	velocity.x = 0
	return true

func _protected_action() -> bool:
	return motion == Motion.GUARD or counter_remaining>0 or (attack_kind in [Attack.HEAVY,Attack.COUNTER] and state in [State.WINDUP,State.ACTIVE,State.RECOVERY])

func _interrupt_action() -> void:
	platform_pursuit.cancel()
	_cancel_motion()
	counter_remaining = 0

func _update_status_label() -> void:
	super._update_status_label()
	if state == State.DEAD:
		return
	var action: String = ["连击%d/%d" % [combo_step,combo_total],"重击","投掷","反击"][attack_kind]
	if motion!=Motion.NONE:
		action = ["","冲刺","瞬移预警","格挡"][motion]
	else:
		action += "·"+health_label.text.get_slice("·",1).strip_edges()
		if state==State.CHASE and not platform_pursuit.intent.is_empty():
			action = platform_pursuit.intent
	health_label.text = "天人 %d / %d · %s" % [health,config.max_health,action]
