class_name FieldRoom
extends WorldRoom
@export var dialogue: DialogueConfig
var wave_time: float = 0.0
var player_position: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	wave_time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds, Color(0.35, 0.36, 0.32))
	draw_rect(Rect2(0, 0, 2560, 360), Color(0.15, 0.18, 0.2))
	for x: int in [320, 1100, 1950]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 200), Vector2(x + 80, 200), Vector2(x + 420, 896), Vector2(x - 180, 896)]), Color(0.95, 0.85, 0.5, 0.16))
	for x: int in range(80, 2520, 32):
		var nearby: float = maxf(0, 1.0 - absf(player_position.x - x) / 96.0)
		var bend: float = sin(wave_time * 2 + x * 0.025) * 12 + nearby * 18
		draw_line(Vector2(x, 896), Vector2(x + bend, 810), Color(0.72, 0.60, 0.29), 3)
		draw_circle(Vector2(x + bend, 808), 5, Color(0.86, 0.72, 0.36))
	# Distant workers and hoe are visual placeholders only, without new NPC logic.
	for x: int in [440, 920, 2120]:
		draw_circle(Vector2(x, 590), 9, Color(0.27, 0.29, 0.25))
		draw_line(Vector2(x, 600), Vector2(x - 8, 648), Color(0.27, 0.29, 0.25), 10)
	var hoe: Vector2 = Vector2(1776, 824)
	draw_line(hoe, hoe + Vector2(58, -52 + sin(wave_time * 2) * 20), Color(0.32, 0.26, 0.19), 5)
