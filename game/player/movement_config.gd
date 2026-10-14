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
