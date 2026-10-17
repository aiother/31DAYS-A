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
var running_attack: bool = false
var range_upgraded: bool = false
var _clock: float = 0.0
var _last_press_time: float = -1000.0
var _buffer_press_time: float = -1000.0
var _buffer_combo_step: int = 1
var _timing_multiplier: float = 1.0
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
	_last_press_time = -1000.0
	_buffer_remaining = 0.0

func interrupt() -> void:
	var was_attacking: bool = is_attacking()
	phase = Phase.IDLE
	_phase_remaining = 0.0
	_hit_targets.clear()
	reset_combo()
	if was_attacking:
		attack_finished.emit()

## The physical player explicitly calls this; execution order is deterministic.
func tick(delta: float) -> void:
	if not player.life.can_control() or player.possibility.busy():
		interrupt()
		return
	_clock += delta
	_buffer_remaining = maxf(0.0, _buffer_remaining - delta)
	if Input.is_action_just_pressed("attack") and player.landing_lock_remaining <= 0.0:
		_buffer_press_time = _clock
		var in_combo_window: bool = _buffer_press_time - _last_press_time <= config.combo_timeout + 0.00001
		_buffer_combo_step = 2 if _last_combo_step == 1 and in_combo_window else 1
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
	combo_step = _buffer_combo_step
	_last_press_time = _buffer_press_time
	_last_combo_step = combo_step
	# Snapshot on starting the swing; releasing run cannot shorten its recovery.
	running_attack = Input.is_action_pressed("run") and not is_zero_approx(Input.get_axis("move_left", "move_right"))
	_timing_multiplier = config.running_timing_multiplier if running_attack else 1.0
	attack_id += 1
	_hit_targets.clear()
	_bounced = false
	phase = Phase.WINDUP
	_phase_remaining = config.windup * _timing_multiplier
	var shape: RectangleShape2D = hit_shape.shape as RectangleShape2D
	var reach: float = config.enhanced_range_multiplier if range_upgraded else 1.0
	shape.size = (config.side_size if direction.y == 0.0 else config.vertical_size) * reach
	# Scale around the combat origin, keeping the player's body/feet unchanged.
	hitbox.position = Vector2(direction.x * config.side_offset * reach, -48.0 + direction.y * config.vertical_offset * reach)
	attack_started.emit(direction, combo_step)

func _advance_phase() -> void:
	match phase:
		Phase.WINDUP:
			phase = Phase.ACTIVE
			_phase_remaining = config.active_duration
		Phase.ACTIVE:
			phase = Phase.RECOVERY
			_phase_remaining = (config.recovery_second if combo_step == 2 else config.recovery_first) * _timing_multiplier
		Phase.RECOVERY:
			phase = Phase.IDLE
			attack_finished.emit()

## Query the Hitbox geometry after move_and_slide, only during active frames.
## Area monitoring stays off, avoiding delayed enter/exit signals and stale hits.
func resolve_hits() -> void:
	if phase != Phase.ACTIVE or not player.life.can_control():
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
