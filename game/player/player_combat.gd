class_name PlayerCombat
extends Node
signal attack_started(direction: Vector2, combo_step: int)
signal attack_finished
signal hit_confirmed(target: CombatHurtbox, damage: int, impulse: Vector2)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }
@export var config: AttackConfig
@onready var player: PlayerController = get_parent().get_parent() as PlayerController
@onready var hitbox: Area2D = get_parent().get_node("Hitbox") as Area2D
@onready var hit_shape: CollisionShape2D = hitbox.get_node("CollisionShape2D") as CollisionShape2D
var phase: Phase = Phase.IDLE
var direction: Vector2 = Vector2.RIGHT
var combo_step: int = 0
var attack_id: int = 0
var _phase_remaining: float = 0.0
var _combo_remaining: float = 0.0
var _buffer_remaining: float = 0.0
var _last_combo_step: int = 0
var _hit_targets: Dictionary[int, bool] = {}
var _bounced: bool = false

func _ready() -> void:
	assert(config != null, "Assign AttackConfig")
	hit_shape.shape = hit_shape.shape.duplicate() as Shape2D

func is_attacking() -> bool:
	return phase != Phase.IDLE

func reset_combo() -> void:
	_last_combo_step = 0
	_combo_remaining = 0.0
	_buffer_remaining = 0.0

## The physical player explicitly calls this; execution order is deterministic.
func tick(delta: float) -> void:
	_buffer_remaining = maxf(0.0, _buffer_remaining - delta)
	if phase == Phase.IDLE:
		_combo_remaining = maxf(0.0, _combo_remaining - delta)
		if _combo_remaining == 0.0:
			_last_combo_step = 0
	if Input.is_action_just_pressed("attack") and player.landing_lock_remaining <= 0.0:
		_buffer_remaining = config.input_buffer
	if phase != Phase.IDLE:
		_phase_remaining -= delta
		if _phase_remaining <= 0.0:
			_advance_phase()
	if phase == Phase.IDLE and _buffer_remaining > 0.0:
		_buffer_remaining = 0.0
		if player.landing_lock_remaining <= 0.0:
			_start_attack()

func _start_attack() -> void:
	if Input.is_action_pressed("aim_down"):
		if player.is_on_floor():
			return
		direction = Vector2.DOWN
	elif Input.is_action_pressed("aim_up"):
		direction = Vector2.UP
	else:
		direction = Vector2(player.facing, 0.0)
	combo_step = 2 if _last_combo_step == 1 else 1
	_last_combo_step = combo_step
	attack_id += 1
	_hit_targets.clear()
	_bounced = false
	phase = Phase.WINDUP
	_phase_remaining = config.windup
	var shape: RectangleShape2D = hit_shape.shape as RectangleShape2D
	shape.size = config.side_size if direction.y == 0.0 else config.vertical_size
	hitbox.position = Vector2(direction.x * config.side_offset, -48.0 + direction.y * config.vertical_offset)
	attack_started.emit(direction, combo_step)

func _advance_phase() -> void:
	match phase:
		Phase.WINDUP:
			phase = Phase.ACTIVE
			_phase_remaining = config.active_duration
		Phase.ACTIVE:
			phase = Phase.RECOVERY
			_phase_remaining = config.recovery_second if combo_step == 2 else config.recovery_first
		Phase.RECOVERY:
			phase = Phase.IDLE
			_combo_remaining = config.combo_timeout
			attack_finished.emit()

## Query the Hitbox geometry after move_and_slide, only during active frames.
## Area monitoring stays off, avoiding delayed enter/exit signals and stale hits.
func resolve_hits() -> void:
	if phase != Phase.ACTIVE:
		return
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape.shape
	query.transform = hit_shape.global_transform
	query.collision_mask = hitbox.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results: Array[Dictionary] = player.get_world_2d().direct_space_state.intersect_shape(query, 128)
	for result: Dictionary in results:
		var target: CombatHurtbox = result["collider"] as CombatHurtbox
		if target == null or not is_instance_valid(target):
			continue
		var target_id: int = target.get_instance_id()
		if _hit_targets.has(target_id):
			continue
		# Register before callbacks so the same swing cannot reenter a receiver.
		_hit_targets[target_id] = true
		var strength: float = config.second_knockback if combo_step == 2 else config.first_knockback
		if direction == Vector2.UP:
			strength = config.up_knockback
		var impulse: Vector2 = direction * strength
		if target.receive_attack(config.damage, impulse, player, attack_id):
			hit_confirmed.emit(target, config.damage, impulse)
			if direction == Vector2.DOWN and not _bounced:
				_bounced = true
				player.bounce_from_down_attack()
