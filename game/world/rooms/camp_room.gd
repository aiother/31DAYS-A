class_name CampRoom
extends WorldRoom

func _draw() -> void:
	draw_rect(config.bounds, Color(0.075, 0.065, 0.07))
	for x: int in [96, 672, 1280, 2064, 2656]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,1280),Vector2(x+144,848),Vector2(x+320,1280)]),Color(0.19,0.17,0.15))
		draw_line(Vector2(x+144,848),Vector2(x+144,1280),Color(0.3,0.25,0.19),5)
	for x: int in [48, 320, 448, 2592, 2720, 2848]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-8,1280),Vector2(x,1136),Vector2(x+8,1280)]),Color(0.26,0.20,0.15))
	for x: int in [560, 2448]:
		draw_circle(Vector2(x,1152),64,Color(0.8,0.26,0.1,0.09))
		draw_colored_polygon(PackedVector2Array([Vector2(x-16,1176),Vector2(x,1120),Vector2(x+16,1176)]),Color(0.75,0.32,0.12))
