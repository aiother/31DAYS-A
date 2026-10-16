class_name RavineRoom
extends WorldRoom
func _draw() -> void:
	draw_rect(config.bounds, Color(0.06, 0.065, 0.08))
	for x: int in [0, 560, 1240, 1760, 2416]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 150, 0), Vector2(x + 100, 1100), Vector2(x - 32, 1280)]), Color(0.13, 0.12, 0.115))
	for x: int in [448, 1136, 1792, 2384]:
		draw_circle(Vector2(x, 1100), 58, Color(0.85, 0.34, 0.12, 0.10))
		draw_line(Vector2(x, 1160), Vector2(x, 1080), Color(0.46, 0.25, 0.14), 5)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 1090), Vector2(x, 1048), Vector2(x + 12, 1090)]), Color(0.8, 0.4, 0.18))
	draw_line(Vector2(2368, 848), Vector2(2368, 608), Color(0.45, 0.42, 0.37), 8)
