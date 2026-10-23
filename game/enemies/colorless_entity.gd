class_name ColorlessEntity
extends CharacterBody2D
signal attack_started(ranged: bool)
signal defeated(reward: int)
enum State { IDLE, CHASE, WINDUP, ACTIVE, RECOVERY, STUN, DEAD }
enum InterruptReason { HIT, STAGGER }
@export var config: ColorlessConfig
@export var target: Node2D
@export var coordinator: EnemyAttackCoordinator
@export var flying: bool = false
@export var ranged_only: bool = false
@onready var hurtbox: CombatHurtbox = $GameplayRoot/Hurtbox
@onready var hitbox: Area2D = $GameplayRoot/Hitbox
@onready var hit_shape: CollisionShape2D = $GameplayRoot/Hitbox/CollisionShape2D
@onready var visual: Node2D = $VisualRoot
@onready var health_label: Label = $HealthLabel
var state: State = State.IDLE
var health: int = 13
var facing: float = -1.0
var _seen: bool = false
var _remaining: float = 0.0
var _attack_direction: Vector2 = Vector2.LEFT
var _ranged: bool = false
var _attack_id: int = 0
var _hit_targets: Dictionary[int, bool] = {}
var _flash: float = 0.0
var _ranged_cooldown_remaining: float = 0.0

func _ready() -> void:
	assert(config != null)
	health = config.max_health
	health_label.text = "%d / %d" % [health, config.max_health]
	hurtbox.hit_received.connect(_on_hit)

func _exit_tree() -> void:
	_release_slot()

func alert_to_target() -> void:
	# Summoned combatants already know who called them into this encounter.
	_seen = is_instance_valid(target)

func _release_slot() -> void:
	if is_instance_valid(coordinator):
		coordinator.release(self)

func _can_see_target() -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -40), target.global_position + Vector2(0, -44), 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_flash = maxf(0.0, _flash - delta * 4.0)
	_remaining = maxf(0.0, _remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)
	if not flying:
		velocity.y = minf(1500.0, velocity.y + config.gravity * delta)
	if is_instance_valid(target) and target is PlayerController and not (target as PlayerController).life.is_alive():
		_release_slot()
		state = State.IDLE
		_stop_horizontal()
		move_and_slide()
		visual.queue_redraw()
		_update_status_label()
		return
	match state:
		State.STUN:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if flying:
				velocity.y = move_toward(velocity.y, 0.0, 500.0 * delta)
			if _remaining == 0.0:
				state = State.CHASE
		State.WINDUP:
			_stop_horizontal()
			if _remaining == 0.0:
				state = State.ACTIVE
				_remaining = config.active_duration
				if _ranged:
					_spawn_projectile()
		State.ACTIVE:
			_stop_horizontal()
			if _remaining == 0.0:
				state = State.RECOVERY
				_remaining = config.recovery
				_release_slot()
		State.RECOVERY:
			_stop_horizontal()
			if _remaining == 0.0:
				state = State.CHASE
		_:
			_seek_target()
	move_and_slide()
	if state == State.ACTIVE and not _ranged:
		_melee_hits()
	visual.queue_redraw()
	_update_status_label()

func _update_status_label() -> void:
	var status: String = ["待机", "追击", "投掷前摇" if _ranged else "近战前摇", "投掷出手" if _ranged else "近战判定", "后摇", "受击硬直", "已击败"][state]
	health_label.text = "%d / %d · %s" % [health, config.max_health, status]

func _stop_horizontal() -> void:
	velocity.x = 0.0
	if flying:
		velocity.y = 0.0

func _seek_target() -> void:
	if not is_instance_valid(target):
		_seen = false
		state = State.IDLE
		_stop_horizontal()
		return
	var offset: Vector2 = target.global_position - global_position
	var visible: bool = _can_see_target()
	if not _seen and offset.length() <= config.sight_range and visible:
		_seen = true
	if not _seen:
		_stop_horizontal()
		return
	state = State.CHASE
	if not is_zero_approx(offset.x):
		facing = signf(offset.x)
	var close: bool = absf(offset.x) <= config.melee_range and absf(offset.y) <= 65.0
	var in_range: bool = offset.length() <= config.ranged_range and (flying or absf(offset.y) <= 65.0)
	var wants_melee: bool = close and not ranged_only
	var wants_ranged: bool = in_range and _ranged_cooldown_remaining <= 0.0 and (ranged_only or not close)
	if visible and (wants_melee or wants_ranged):
		if not is_instance_valid(coordinator) or coordinator.try_acquire(self):
			_ranged = ranged_only or not close
			_attack_direction = offset.normalized() if _ranged else Vector2(facing, 0)
			if _attack_direction.is_zero_approx():
				_attack_direction = Vector2(facing, 0)
			state = State.WINDUP
			_remaining = config.windup
			_attack_id += 1
			_hit_targets.clear()
			hitbox.position.x = facing * 48.0
			attack_started.emit(_ranged)
			_stop_horizontal()
			return
	# Hybrid ground enemies close the distance between throws, even if another
	# attacker owns the slot. Ranged-only instances hold their firing position.
	if (visible and close and not ranged_only) or (visible and in_range and ranged_only):
		_stop_horizontal()
		return
	if flying:
		velocity = offset.normalized() * config.speed
	else:
		velocity.x = facing * config.speed
		if is_on_floor():
			var ahead: Vector2 = global_position + Vector2(facing * 34.0, -4.0)
			var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 24), 1)
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				velocity.x = 0.0

func _melee_hits() -> void:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape.shape
	query.transform = hit_shape.global_transform
	query.collision_mask = 64
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var receiver: CombatHurtbox = result["collider"] as CombatHurtbox
		if receiver == null or _hit_targets.has(receiver.get_instance_id()):
			continue
		_hit_targets[receiver.get_instance_id()] = true
		receiver.receive_attack(config.damage, _attack_direction * 100.0, self, _attack_id)

func _spawn_projectile() -> void:
	_ranged_cooldown_remaining = 0.0 if ranged_only else config.ranged_cooldown
	var packed: PackedScene = load("res://enemies/colorless_projectile.tscn") as PackedScene
	var projectile: ColorlessProjectile = packed.instantiate() as ColorlessProjectile
	projectile.source = self
	projectile.velocity = _attack_direction * config.projectile_speed
	projectile.position = get_parent().to_local(global_position + Vector2(facing * 36.0, -40))
	get_parent().add_child(projectile)

func _protected_action() -> bool:
	return false

func can_interrupt(reason: InterruptReason = InterruptReason.HIT) -> bool:
	return health>0 and state!=State.DEAD and (reason==InterruptReason.STAGGER or not _protected_action())

func _interrupt_action() -> void:
	pass

func request_interrupt(reason: InterruptReason = InterruptReason.HIT, impulse: Vector2 = Vector2.ZERO, duration: float = -1.0) -> bool:
	# Future stagger accumulation calls this explicitly after its threshold breaks.
	# Ordinary damage never grants itself the STAGGER reason.
	if not can_interrupt(reason):
		return false
	_interrupt_action()
	_release_slot()
	state = State.STUN
	_remaining = config.hit_stun if duration<0 else duration
	velocity = impulse
	return true

func _on_hit(damage: int, impulse: Vector2, _source: Node2D, _id: int) -> void:
	if state == State.DEAD:
		return
	health = maxi(0, health - damage)
	health_label.text = "%d / %d" % [health, config.max_health]
	_flash = 1.0
	if health == 0:
		state = State.DEAD
		_interrupt_action()
		_release_slot()
		velocity = Vector2.ZERO
		hurtbox.accepts_hits = false
		hurtbox.set_deferred("monitorable", false)
		$BodyCollision.set_deferred("disabled", true)
		visual.queue_redraw()
		health_label.hide()
		defeated.emit(config.reward)
		if is_instance_valid(coordinator) and not coordinator.keep_corpse(self):
			queue_free()
		return
	request_interrupt(InterruptReason.HIT,impulse)

## SYS-010: read-only visual projection; never advances gameplay.
func animation_state() -> Dictionary:
	return CharacterAnimationState.enemy(self)
