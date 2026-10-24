class_name CombatEffectConfig
extends Resource
## FX-001 tuning, one place. Values are the user's EXP-005 final (2026-10-23).
## Ordinary attack hit-stop: the blade is caught in the target for this long.
@export_range(0.0, 0.3, 0.01) var hit_stop_seconds: float = 0.10
## Struck targets shiver this far during the hit-stop (pixels).
@export var stop_jitter: float = 4.0
## Screen shake on an ordinary hit; 0 = none (kept for future heavy blows).
@export var hit_shake: float = 0.0
## Screen shake when the player is hurt (pixels).
@export var hurt_shake: float = 5.0
@export var shake_seconds: float = 0.2
