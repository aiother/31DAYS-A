class_name PlayerLife
extends Node
signal health_changed(current: int, maximum: int)
signal damaged(amount: int, impulse: Vector2)
signal died
signal death_menu_ready
signal respawned
enum State { ALIVE, DOWNED, FADING, DEATH_MENU }
@export var config: PlayerLifeConfig
var health: int = 3
var state: State = State.ALIVE
var hurt_remaining: float = 0.0
var protection_remaining: float = 0.0
var phase_remaining: float = 0.0
var scripted_control_locked: bool = false
# Optional encounter-owned interception, after ordinary immunity checks and before death.
var hit_interceptor: Callable

func _ready() -> void:
	assert(config != null)
	start_new_run()

func is_alive() -> bool:
	return state == State.ALIVE

func can_control() -> bool:
	return is_alive() and hurt_remaining <= 0.0 and not scripted_control_locked

func take_hit(amount: int, impulse: Vector2 = Vector2.ZERO) -> bool:
	var actions: PlayerPossibility = get_parent().get_node_or_null("Possibility") as PlayerPossibility
	if actions != null and actions.invincible_remaining > 0.0:
		return false
	if not is_alive() or protection_remaining > 0.0 or hurt_remaining > 0.0 or amount <= 0:
		return false
	if hit_interceptor.is_valid() and bool(hit_interceptor.call(amount)):
		return false
	health = maxi(0, health - amount)
	hurt_remaining = config.hurt_duration
	protection_remaining = config.hurt_duration
	if health == 0:
		state = State.DOWNED
		phase_remaining = config.downed_duration
	damaged.emit(amount, impulse)
	health_changed.emit(health, config.max_health)
	if health == 0:
		died.emit()
	return true

func heal(amount: int) -> void:
	if not is_alive() or amount <= 0:
		return
	health = mini(config.max_health, health + amount)
	health_changed.emit(health, config.max_health)

func tick(delta: float) -> void:
	protection_remaining = maxf(0.0, protection_remaining - delta)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	if state == State.DOWNED or state == State.FADING:
		phase_remaining = maxf(0.0, phase_remaining - delta)
		if phase_remaining == 0.0:
			if state == State.DOWNED:
				state = State.FADING
				phase_remaining = config.death_fade_duration
			else:
				state = State.DEATH_MENU
				death_menu_ready.emit()

func start_new_run() -> void:
	health = config.initial_health
	_reset_state()
	health_changed.emit(health, config.max_health)

func revive() -> void:
	health = config.max_health
	_reset_state()
	protection_remaining = config.respawn_protection
	health_changed.emit(health, config.max_health)
	respawned.emit()

func _reset_state() -> void:
	scripted_control_locked = false
	state = State.ALIVE
	hurt_remaining = 0.0
	protection_remaining = 0.0
	phase_remaining = 0.0
