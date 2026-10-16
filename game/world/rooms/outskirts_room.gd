class_name OutskirtsRoom
extends WorldRoom

func _draw() -> void:
	draw_rect(config.bounds,Color(0.08,0.09,0.10))
	for x: int in [160,640,1216,2080,2688]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,1280),Vector2(x+120,880),Vector2(x+168,992),Vector2(x+280,1280)]),Color(0.19,0.20,0.20))
	for x: int in [80,2720,2864]:
		draw_line(Vector2(x,1280),Vector2(x+32,1096),Color(0.31,0.32,0.29),6)
		draw_arc(Vector2(x+32,1152),64,0,TAU,24,Color(0.31,0.32,0.29),3)
