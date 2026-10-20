extends RefCounted
## Simulated HUD state shared by every EXP-001 variant. Numbers mirror the
## graybox configs (life 5, possibility 0..10 with overdraft to -9, heal cost 3,
## pearl +5% reach, 1800 s day); growth step is a prototype assumption.
signal gained(amount: int)
signal day_changed(day: int)

const MAX_HEALTH: int = 5
const BASE_MAX: int = 10
const FLOOR: int = -9
const HEAL_COST: int = 3
const HEAL_AMOUNT: int = 2
const GROWTH_STEP: int = 2
const MAX_GROWTH: int = 2
const PEARL_MAX: int = 4
const PEARL_BONUS: float = 0.05
const MEDKIT_MAX: int = 3
const DAY_SECONDS: float = 1800.0
const FINAL_SECONDS: float = 900.0
const WARNING_SECONDS: float = 180.0
const ACCELERATE_SECONDS: float = 2.5
const DENY_SECONDS: float = 0.9

var health: int = MAX_HEALTH
var balance: int = 3
var growth: int = 0
var pearls: int = 0
var show_medkit: bool = false
var medkits: int = 2
var day: int = 1
var day_remaining: float = DAY_SECONDS
var time_scale: float = 1.0
var paused: bool = false
var deny_left: float = 0.0
var deny_kind: String = ""
var gain_pulse: float = 0.0
var final_active: bool = false
var final_remaining: float = 0.0
var final_from: float = 0.0
var accelerate_left: float = 0.0
var clock: float = 0.0
## Capture only: hold every animation still.
var frozen: bool = false

func maximum() -> int:
	return BASE_MAX + growth * GROWTH_STEP

func overdraft() -> int:
	return maxi(0, -balance)

func reach_percent() -> int:
	return 100 + roundi(pearls * PEARL_BONUS * 100.0)

func days_left() -> int:
	return 4 - day

func day_progress() -> float:
	return clampf(1.0 - day_remaining / DAY_SECONDS, 0.0, 1.0)

## Maps the real-time day onto a 06:00-24:00 in-game clock (prototype choice).
func clock_minutes() -> int:
	return 6 * 60 + int(day_progress() * 18.0 * 60.0)

func clock_text() -> String:
	var minutes: int = mini(clock_minutes(), 24 * 60 - 1)
	return "%02d:%02d" % [int(minutes / 60.0), minutes % 60]

func warning_active() -> bool:
	return not final_active and day < 3 and day_remaining <= WARNING_SECONDS

func denied() -> float:
	return deny_left / DENY_SECONDS

func tick(delta: float) -> void:
	if frozen:
		return
	clock += delta
	deny_left = maxf(0.0, deny_left - delta)
	gain_pulse = maxf(0.0, gain_pulse - delta)
	if accelerate_left > 0.0:
		accelerate_left = maxf(0.0, accelerate_left - delta)
		return
	if paused:
		return
	var step: float = delta * time_scale
	if final_active:
		final_remaining = maxf(0.0, final_remaining - step)
		return
	day_remaining -= step
	if day_remaining <= 0.0:
		if day < 3:
			day += 1
			day_remaining += DAY_SECONDS
			day_changed.emit(day)
		else:
			day_remaining = 0.0

func hurt() -> void:
	health = maxi(1, health - 1)

func reset() -> void:
	health = MAX_HEALTH
	balance = 3
	growth = 0
	pearls = 0
	medkits = 2
	show_medkit = false
	day = 1
	day_remaining = DAY_SECONDS
	final_active = false
	accelerate_left = 0.0
	deny_left = 0.0

func gain(amount: int) -> void:
	balance = mini(maximum(), balance + amount)
	gained.emit(amount)

func spend(amount: int) -> void:
	balance = maxi(FLOOR, balance - amount)

func try_heal() -> bool:
	if balance < HEAL_COST:
		_deny("恢复")
		return false
	balance -= HEAL_COST
	health = mini(MAX_HEALTH, health + HEAL_AMOUNT)
	return true

## A dodge still happens when short of possibility (it overdraws), but A-018
## asks the container to flash because it was not fully paid for.
func try_dodge() -> bool:
	if balance - 1 < FLOOR:
		_deny("闪避")
		return false
	if balance < 1:
		_deny("闪避")
	balance -= 1
	return true

func cycle_growth() -> void:
	growth = (growth + 1) % (MAX_GROWTH + 1)
	balance = mini(balance, maximum())

func add_pearls(amount: int) -> void:
	pearls = clampi(pearls + amount, 0, PEARL_MAX)

func cycle_medkits() -> void:
	medkits = (medkits + 1) % (MEDKIT_MAX + 1)

func jump_to_warning() -> void:
	if day < 3:
		day_remaining = WARNING_SECONDS - 2.0

func next_day() -> void:
	if day < 3:
		day_remaining = 0.01

## Starts the final countdown from a given third-day remainder (A-016).
func start_final(third_day_remaining: float) -> void:
	day = 3
	day_remaining = third_day_remaining
	final_active = true
	final_from = third_day_remaining
	if third_day_remaining > FINAL_SECONDS:
		final_remaining = FINAL_SECONDS
		accelerate_left = ACCELERATE_SECONDS
	else:
		final_remaining = third_day_remaining
		accelerate_left = 0.0

func stop_final() -> void:
	final_active = false
	accelerate_left = 0.0

func _deny(kind: String) -> void:
	deny_kind = kind
	deny_left = DENY_SECONDS
