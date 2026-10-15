class_name PlayerPossibility
extends Node
signal balance_changed(current: int, maximum: int)
enum State { IDLE, DODGE_WINDUP, DODGE_ACTIVE, DODGE_RECOVERY, HEALING }
@export var config: PossibilityConfig
@onready var player: PlayerController = get_parent().get_parent() as PlayerController
var balance: int = 3
var state: State = State.IDLE
var remaining: float = 0.0
var chain: int = 0
var since_dodge: float = 100.0
var poor_dodge: bool = false
var dodge_direction: float = 1.0
var invincible_remaining: float = 0.0

func _ready() -> void:
	assert(config != null)
	balance = config.initial

func gain(amount: int) -> void:
	if amount <= 0 or not player.life.is_alive():
		return
	balance = mini(config.maximum, balance + amount)
	balance_changed.emit(balance, config.maximum)

func busy() -> bool:
	return state != State.IDLE

func cancel() -> void:
	state = State.IDLE
	remaining = 0.0
	invincible_remaining = 0.0

func reset_actions() -> void:
	cancel()
	chain = 0
	since_dodge = 100.0

func try_dodge() -> bool:
	if not player.life.can_control() or player.landing_lock_remaining > 0.0:
		return false
	if state != State.IDLE and state != State.HEALING:
		return false
	if since_dodge + 0.00001 >= config.combo_reset:
		chain = 0
	var cost: int = chain + 1
	if chain >= 3 or balance - cost < config.floor_balance:
		return false
	poor_dodge = balance < cost
	balance -= cost
	balance_changed.emit(balance, config.maximum)
	chain += 1
	since_dodge = 0.0
	var axis: float = Input.get_axis("move_left", "move_right")
	dodge_direction = signf(axis) if not is_zero_approx(axis) else player.facing
	player.combat.interrupt()
	state = State.DODGE_WINDUP
	remaining = config.poor_windup if poor_dodge else config.dodge_windup
	return true

func try_heal() -> bool:
	if busy() or not player.life.can_control() or not player.is_on_floor() or player.landing_lock_remaining > 0.0 or player.combat.is_attacking():
		return false
	if balance < config.heal_cost or player.life.health >= player.life.config.max_health:
		return false
	balance -= config.heal_cost
	balance_changed.emit(balance, config.maximum)
	player.combat.reset_combo()
	state = State.HEALING
	remaining = config.heal_duration
	return true

# Explicitly ticked before ordinary movement/combat. Costs are never refunded.
func tick(delta: float) -> void:
	since_dodge += delta
	invincible_remaining = maxf(0.0, invincible_remaining - delta)
	if since_dodge + 0.00001 >= config.combo_reset:
		chain = 0
	if not player.life.can_control():
		cancel()
		return
	if Input.is_action_just_pressed("dodge") and try_dodge():
		return
	if Input.is_action_just_pressed("recover") and try_heal():
		return
	if state == State.HEALING and (not Input.is_action_pressed("recover") or not player.is_on_floor()):
		cancel()
		return
	if not busy():
		return
	remaining -= delta
	if remaining > 0.00001:
		return
	match state:
		State.HEALING:
			player.life.heal(config.heal_amount)
			cancel()
		State.DODGE_WINDUP:
			state = State.DODGE_ACTIVE
			remaining = config.dodge_duration
			invincible_remaining = config.poor_invincible_duration if poor_dodge else config.invincible_duration
		State.DODGE_ACTIVE:
			state = State.DODGE_RECOVERY
			remaining = config.dodge_recovery
		State.DODGE_RECOVERY:
			cancel()

func horizontal_speed() -> float:
	return dodge_direction * config.dodge_speed if state == State.DODGE_ACTIVE else 0.0
