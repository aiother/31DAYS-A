extends Polygon2D
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([-Vector2(24,0),Vector2(-28,-72),Vector2(0,-96),Vector2(28,-72),Vector2(24,0)]),Color(0.85,0.16,0.12))
	draw_line(Vector2(-42,0),Vector2(-42,-130),Color(0.65,0.55,0.5),6)
	draw_arc(Vector2(-26,-110),30,PI,TAU+0.4,16,Color(0.95,0.7,0.65),7)
	draw_line(Vector2(38,-6),Vector2(38,-94),Color(0.65,0.55,0.5),7)
	draw_rect(Rect2(18,-108,46,24),Color(0.9,0.55,0.48))
