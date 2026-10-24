class_name PlayerController
extends CharacterBody2D
## Gameplay owns all displacement. VisualRoot must never move the body.
signal landed(impact_speed: float, hard: bool)
signal facing_changed(direction: float)

@export var movement: MovementConfig
@onready var combat: PlayerCombat = $GameplayRoot/Combat
@onready var life: PlayerLife = $GameplayRoot/Life
@onready var possibility: PlayerPossibility = $GameplayRoot/Possibility
var facing: float = 1.0
var landing_lock_remaining: float = 0.0
var _turn_remaining: float = 0.0
var _pending_facing: float = 1.0
var _hold_remaining: float = 0.0
var _edge_remaining: float = 0.0
var _last_floor_x: float = 0.0
var _jump_consumed: bool = false
var _fall_start_y: float = 0.0
var _was_descending: bool = false
var _bounce_rising: bool = false
## A jump pressed during a hit-stop, taken on the first frame after it.
var _jump_held_press: bool = false

func _ready() -> void:
	assert(movement != null, "Assign MovementConfig before running player")
	_fall_start_y = global_position.y
	_last_floor_x = global_position.x
	life.damaged.connect(_on_damaged)
	life.respawned.connect(reset_kinematics)

func _physics_process(delta: float) -> void:
	if HitStop.held(self, delta):
		_held_step()
		return
	var jump_pressed: bool = Input.is_action_just_pressed("jump") or _jump_held_press
	_jump_held_press = false
	life.tick(delta)
	possibility.tick(delta)
	if not life.can_control():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta) if life.is_alive() else 0.0
		velocity.y = minf(velocity.y + movement.gravity * movement.fall_gravity_scale * delta, movement.max_fall_speed)
		move_and_slide()
		return
	if possibility.busy():
		var was_grounded: bool = is_on_floor()
		velocity.x = possibility.horizontal_speed()
		_edge_remaining = 0.0
		_apply_gravity(delta)
		_move_with_landing(was_grounded)
		return
	var grounded: bool = is_on_floor()
	landing_lock_remaining = maxf(0.0, landing_lock_remaining - delta)
	if grounded:
		_bounce_rising = false
		_edge_remaining = movement.edge_grace_time
		_last_floor_x = global_position.x
		_jump_consumed = false
	else:
		_edge_remaining = maxf(0.0, _edge_remaining - delta)
	var axis: float = Input.get_axis("move_left", "move_right")
	if landing_lock_remaining > 0.0:
		axis = 0.0
	_update_facing(axis, delta)
	combat.tick(delta)
	var speed: float = movement.run_speed if Input.is_action_pressed("run") else movement.walk_speed
	var target: float = axis * speed
	if _turn_remaining > 0.0:
		target = 0.0
	var acceleration: float = movement.air_acceleration
	if grounded:
		acceleration = movement.ground_deceleration if is_zero_approx(target) else movement.ground_acceleration
	velocity.x = move_toward(velocity.x, target, acceleration * delta)
	var edge_allowed: bool = _edge_remaining > 0.0 and absf(global_position.x - _last_floor_x) <= movement.edge_grace_distance
	if jump_pressed and not _jump_consumed and (grounded or edge_allowed) and landing_lock_remaining <= 0.0:
		if not combat.is_attacking():
			combat.reset_combo()
		velocity.y = -movement.jump_speed
		_bounce_rising = false
		_hold_remaining = movement.jump_hold_duration
		_jump_consumed = true
		_edge_remaining = 0.0
	_apply_gravity(delta)
	_move_with_landing(grounded)
	combat.resolve_hits()

func _apply_gravity(delta: float) -> void:
	if velocity.y < 0.0:
		if not _bounce_rising and not Input.is_action_pressed("jump"):
			velocity.y = maxf(velocity.y, -movement.jump_release_speed)
			_hold_remaining = 0.0
		var gravity_scale: float = movement.held_gravity_scale if _hold_remaining > 0.0 and Input.is_action_pressed("jump") else 1.0
		velocity.y += movement.gravity * gravity_scale * delta
		_hold_remaining = maxf(0.0, _hold_remaining - delta)
	else:
		_bounce_rising = false
		velocity.y = minf(velocity.y + movement.gravity * movement.fall_gravity_scale * delta, movement.max_fall_speed)

func _move_with_landing(grounded: bool) -> void:
	var descending: bool = velocity.y > 0.0 and not grounded
	if descending and not _was_descending:
		_fall_start_y = global_position.y
	_was_descending = descending
	var impact_speed: float = velocity.y
	move_and_slide()
	if is_on_ceiling():
		_bounce_rising = false
		_hold_remaining = 0.0
	if is_on_floor() and not grounded and impact_speed > 0.0:
		var hard: bool = global_position.y - _fall_start_y >= movement.hard_landing_distance
		landing_lock_remaining = movement.hard_landing_duration if hard else 0.0
		_was_descending = false
		landed.emit(impact_speed, hard)

## FX-001 hit-stop: the body and every timer stay put (no time passes for the
## player). Presses made meanwhile are not lost: an attack goes into the
## combat buffer, a dodge cancels the attack at once and runs after the stop,
## a jump is taken on the first frame after it.
func _held_step() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_held_press = true
	possibility.tick(0.0)
	if not possibility.busy():
		combat.tick(0.0)

func bounce_from_down_attack() -> void:
	if not life.can_control():
		return
	# Derive from the full held jump, not the release-cut jump speed.
	var delta: float = 1.0 / float(Engine.physics_ticks_per_second)
	var height: float = movement.maximum_jump_height(delta) * combat.config.down_bounce_jump_height_ratio
	velocity.y = -movement.ascent_speed_for_height(height, delta)
	_bounce_rising = true
	_hold_remaining = 0.0
	_jump_consumed = true
	_edge_remaining = 0.0

func _on_damaged(_amount: int, impulse: Vector2) -> void:
	possibility.cancel()
	combat.interrupt()
	velocity.x = clampf(impulse.x, -life.config.max_knockback, life.config.max_knockback)
	_hold_remaining = 0.0
	_bounce_rising = false

func reset_kinematics() -> void:
	possibility.reset_actions()
	combat.interrupt()
	velocity = Vector2.ZERO
	landing_lock_remaining = 0.0
	_hold_remaining = 0.0
	_edge_remaining = 0.0
	_turn_remaining = 0.0
	_pending_facing = facing
	_jump_consumed = false
	_was_descending = false
	_bounce_rising = false
	_fall_start_y = global_position.y
	_last_floor_x = global_position.x

func _update_facing(axis: float, delta: float) -> void:
	var desired: float = signf(axis)
	if is_zero_approx(desired) or desired == facing:
		_turn_remaining = 0.0
		_pending_facing = facing
		return
	if desired != _pending_facing:
		_pending_facing = desired
		_turn_remaining = movement.turn_delay
	_turn_remaining = maxf(0.0, _turn_remaining - delta)
	if _turn_remaining <= 0.0:
		facing = desired
		facing_changed.emit(facing)

## SYS-010: read-only visual projection; never advances gameplay.
func animation_state() -> Dictionary:
	return CharacterAnimationState.player(self, get_node_or_null("VisualRoot/Animator"))
