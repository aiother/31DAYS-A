class_name ColorlessConfig
extends Resource
## T3: 13 HP, 1 light damage, +2 reward. Other values are graybox tuning.
@export var max_health: int = 13
@export var damage: int = 1
@export var reward: int = 2
@export var speed: float = 120.0
@export var gravity: float = 1900.0
@export var sight_range: float = 700.0
@export var melee_range: float = 92.0
@export var ranged_range: float = 420.0
@export var windup: float = 0.65 * 2.0 / 3.0
@export var active_duration: float = 0.12
@export var recovery: float = 0.75
@export var hit_stun: float = 0.30
@export var projectile_speed: float = 300.0
@export var ranged_cooldown: float = 4.0 # Hybrid enemies; ranged-only keeps its existing cadence.
