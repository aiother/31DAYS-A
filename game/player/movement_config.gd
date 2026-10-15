class_name MovementConfig
extends Resource
## 灰盒调校参数，不是新增的策划冻结数值。单位 px / s。
@export var walk_speed: float = 300.0
@export var run_speed: float = 520.0
@export var ground_acceleration: float = 2600.0
@export var ground_deceleration: float = 3400.0
@export var air_acceleration: float = 1100.0
@export var turn_delay: float = 0.06
@export var jump_speed: float = 850.0
@export var gravity: float = 1900.0
@export var held_gravity_scale: float = 0.65
@export var jump_hold_duration: float = 0.22
@export var jump_release_speed: float = 280.0
@export var fall_gravity_scale: float = 1.35
@export var max_fall_speed: float = 1500.0
@export var edge_grace_distance: float = 32.0
@export var edge_grace_time: float = 0.12
@export var hard_landing_distance: float = 320.0
@export var hard_landing_duration: float = 0.44

func maximum_jump_height(delta: float) -> float:
	# Match the held-jump ascent, including its reduced-gravity hold window.
	var speed: float = jump_speed
	var hold: float = jump_hold_duration
	var height: float = 0.0
	while speed > 0.0:
		var scale: float = held_gravity_scale if hold > 0.0 else 1.0
		speed -= gravity * scale * delta
		height += maxf(0.0, speed) * delta
		hold = maxf(0.0, hold - delta)
	return height

func ascent_speed_for_height(height: float, delta: float) -> float:
	if height <= 0.0:
		return 0.0
	# Invert the discrete ascent sum: H = dt * (n*v - g*dt*n*(n+1)/2).
	var step: float = gravity * delta
	var ticks: int = maxi(1, int(ceil((sqrt(1.0 + 8.0 * height / (step * delta)) - 1.0) * 0.5)))
	return (height / delta + step * float(ticks * (ticks + 1)) * 0.5) / float(ticks)
