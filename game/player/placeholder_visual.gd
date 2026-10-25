extends Node2D
## Replace only this visual subtree when integrating Spine.
@onready var player: PlayerController = get_parent() as PlayerController
@onready var sprite: Sprite2D = $PlaceholderSprite
@onready var combat: PlayerCombat = get_parent().get_node("GameplayRoot/Combat") as PlayerCombat
var _feedback: Tween
var _pulse: float = 0.0
var _hurt_flash: float = 0.0
@onready var life: PlayerLife = get_parent().get_node("GameplayRoot/Life") as PlayerLife

func _ready() -> void:
	player.landed.connect(_on_landed)
	player.facing_changed.connect(_on_facing_changed)
	life.damaged.connect(_on_damaged)
	life.died.connect(_on_died)
	life.respawned.connect(_on_respawned)

func _on_damaged(_amount: int, _impulse: Vector2) -> void:
	_hurt_flash = 0.2

func _on_died() -> void:
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2.ONE
	_feedback = create_tween()
	_feedback.tween_property(sprite, "rotation", -PI * 0.5, 0.18)
	_feedback.parallel().tween_property(sprite, "position:y", -18.0, 0.18)

func _on_respawned() -> void:
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	sprite.position = Vector2(0, -48)
	_hurt_flash = 0.0

func _process(delta: float) -> void:
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	sprite.modulate = Color(1, 0.4, 0.35) if _hurt_flash > 0.0 else Color.WHITE
	# Hurt protection still blinks the body; dodge, healing and invulnerability
	# are shown by the FX-001 effects (EffectDirector), not by tinting it.
	sprite.modulate.a = 0.45 if life.is_alive() and life.protection_remaining > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0 else 1.0
	_pulse = maxf(0.0, _pulse - delta * 2.8)
	queue_redraw()

func _on_facing_changed(direction: float) -> void:
	sprite.flip_h = direction < 0.0

func _on_landed(_impact_speed: float, hard: bool) -> void:
	if not life.is_alive():
		return
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2(1.25, 0.72) if hard else Vector2(1.12, 0.87)
	_pulse = 1.0 if hard else 0.5
	_feedback = create_tween()
	_feedback.tween_property(sprite, "scale", Vector2.ONE, player.movement.hard_landing_duration if hard else 0.12)

func _draw() -> void:
	if _pulse > 0.0:
		draw_line(Vector2(-65.0 * (1.1 - _pulse), -2.0), Vector2(65.0 * (1.1 - _pulse), -2.0), Color(0.5, 0.85, 0.9, _pulse), 4.0)
