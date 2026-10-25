extends Node2D
@onready var entity: ColorlessEntity = get_parent() as ColorlessEntity

func _draw() -> void:
	if entity.state == ColorlessEntity.State.DEAD:
		for i: int in range(4):
			draw_rect(Rect2(-30 + i * 17, -8 - (i % 2) * 6, 12, 8), Color(0.42, 0.46, 0.48))
		return
	# The wind-up warning is the FX-002 cue drawn by CombatEffectDirector.
	var color: Color = Color(0.64, 0.69, 0.7).lerp(Color.WHITE, entity._flash)
	draw_rect(Rect2(-24, -80, 48, 80), color)
	draw_circle(Vector2(entity.facing * 12, -60), 4, Color(0.16, 0.2, 0.23))
	if entity.state == ColorlessEntity.State.ACTIVE and not entity._ranged:
		draw_rect(Rect2(Vector2(entity.facing * 48 - 36, -68), Vector2(72, 56)), Color(1, 0.5, 0.35, 0.5))
