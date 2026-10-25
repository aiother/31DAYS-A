extends Node2D
@onready var entity: MonochromeEntity = get_parent() as MonochromeEntity

func _draw() -> void:
	if entity.state == ColorlessEntity.State.DEAD:
		for i: int in range(4):
			draw_rect(Rect2(-30+i*17,-8-(i%2)*6,12,8),Color(0.42,0.25,0.55))
		return
	var color: Color = Color(0.65,0.35,0.9).lerp(Color.WHITE,entity._flash)
	if entity.motion == MonochromeEntity.Motion.DODGE:
		color.a = 0.35
		draw_line(Vector2(-entity.facing*70,-40),Vector2(0,-40),Color(0.8,0.55,1,0.5),6)
	elif entity.motion == MonochromeEntity.Motion.DASH:
		draw_line(Vector2(-entity.facing*85,-40),Vector2(0,-40),Color(0.8,0.55,1,0.5),4)
	# The wind-up warning (ordinary / strong) is the FX-002 cue.
	draw_colored_polygon(PackedVector2Array([Vector2(0,-86),Vector2(26,-64),Vector2(22,0),Vector2(-22,0),Vector2(-26,-64)]),color)
	draw_circle(Vector2(entity.facing*12,-60),4,Color(0.15,0.07,0.2))
	if entity.state == ColorlessEntity.State.ACTIVE and not entity._ranged:
		draw_rect(Rect2(Vector2(entity.facing*48-36,-68),Vector2(72,56)),Color(1,0.3,0.6,0.5))
