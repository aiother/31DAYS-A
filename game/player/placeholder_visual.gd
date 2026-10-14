extends Node2D
## Replace only this visual subtree when integrating Spine.
@onready var player: PlayerController = get_parent() as PlayerController
@onready var sprite: Sprite2D = $PlaceholderSprite
var _feedback: Tween
var _pulse: float = 0.0

func _ready() -> void:
	player.landed.connect(_on_landed)
	player.facing_changed.connect(_on_facing_changed)

func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 2.8)
	queue_redraw()

func _on_facing_changed(direction: float) -> void:
	sprite.flip_h = direction < 0.0

func _on_landed(_impact_speed: float, hard: bool) -> void:
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2(1.25, 0.72) if hard else Vector2(1.12, 0.87)
	_pulse = 1.0 if hard else 0.5
	_feedback = create_tween()
	_feedback.tween_property(sprite, "scale", Vector2.ONE, player.movement.hard_landing_duration if hard else 0.12)

func _draw() -> void:
	if _pulse > 0.0:
		draw_line(Vector2(-65.0 * (1.1 - _pulse), -2.0), Vector2(65.0 * (1.1 - _pulse), -2.0), Color(0.5, 0.85, 0.9, _pulse), 4.0)
