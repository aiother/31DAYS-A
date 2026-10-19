class_name RemnantPossibilityConfig
extends Resource
## SYS-002 approved graybox values; independent of ordinary enemy day scaling.
@export var interval_min: float = 10.0
@export var interval_max: float = 15.0
@export var batch_min: int = 1
@export var batch_max: int = 2
@export var live_limit: int = 3
@export var max_health: int = 13
@export var reward: int = 2
@export var height_min: float = 160.0
@export var height_max: float = 240.0
@export var horizontal_range: float = 240.0
@export var spawn_attempts: int = 32
@export var drift_speed: float = 24.0
@export var drift_extent: Vector2 = Vector2(24, 12)
