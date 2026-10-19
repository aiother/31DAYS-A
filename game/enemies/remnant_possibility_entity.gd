class_name RemnantPossibilityEntity
extends ColorlessEntity
## Reuse the ordinary hurtbox/visual/death signal, never its attack or pursuit AI.
var remnant: RemnantPossibilityConfig
var movement_enabled: bool = true
var arena_bounds: Rect2
var _anchor: Vector2
var _drift_time: float = 0.0

func _ready() -> void:
	config = config.duplicate() as ColorlessConfig
	config.max_health = remnant.max_health
	config.reward = remnant.reward
	config.damage = 0
	flying = true
	coordinator = null
	super._ready()
	_anchor = position
	_update_status_label()

func _physics_process(delta: float) -> void:
	if state == State.DEAD or not movement_enabled:
		return
	_flash = maxf(0.0, _flash - delta * 4.0)
	_drift_time += delta
	var destination: Vector2 = _anchor + Vector2(sin(_drift_time), sin(_drift_time * 0.7)) * remnant.drift_extent
	destination.x = clampf(destination.x, arena_bounds.position.x + 24, arena_bounds.end.x - 24)
	destination.y = clampf(destination.y, arena_bounds.position.y + 80, arena_bounds.end.y)
	velocity = (destination - position).limit_length(remnant.drift_speed)
	move_and_slide()
	visual.queue_redraw()
	_update_status_label()

func _update_status_label() -> void:
	health_label.text = "%d / %d · 残存可能性" % [health, config.max_health]

func _on_hit(damage: int, impulse: Vector2, source: Node2D, attack_id: int) -> void:
	super._on_hit(damage, impulse, source, attack_id)
	if state == State.DEAD:
		queue_free()
