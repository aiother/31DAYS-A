class_name TrenchRoom
extends WorldRoom

func _draw() -> void:
	draw_rect(config.bounds, Color(0.065, 0.075, 0.08))
	for x: int in [48, 880, 1808]:
		draw_rect(Rect2(x, 160, 64, 1632), Color(0.13, 0.15, 0.15))
	for y: int in [448, 960, 1472]:
		draw_line(Vector2(80, y), Vector2(1840, y - 32), Color(0.20, 0.22, 0.21), 5)
	for x: int in [96, 152]:
		draw_line(Vector2(x, 1792), Vector2(x + 24, 1680), Color(0.31, 0.32, 0.29), 4)
