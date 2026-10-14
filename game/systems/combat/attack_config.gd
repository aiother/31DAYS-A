class_name AttackConfig
extends Resource
## T3 damage is frozen. Timing, reach and knockback are graybox tuning values.
@export var damage: int = 5
@export var windup: float = 0.08
@export var active_duration: float = 0.10
@export var recovery_first: float = 0.14
@export var recovery_second: float = 0.28
@export var combo_timeout: float = 0.40
@export var input_buffer: float = 0.18
@export var movement_scale: float = 0.25
@export var first_knockback: float = 140.0
@export var second_knockback: float = 230.0
@export var up_knockback: float = 280.0
@export var side_size: Vector2 = Vector2(112, 72)
@export var vertical_size: Vector2 = Vector2(80, 100)
@export var side_offset: float = 76.0
@export var vertical_offset: float = 64.0
