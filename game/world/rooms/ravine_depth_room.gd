class_name RavineDepthRoom
extends WorldRoom
const GATES: String = "gate:HD_20001_3:cleared"

func refresh(completed: bool, failed: bool, opened: bool) -> void:
	$Survivor/Body.polygon = PackedVector2Array([Vector2(-24,0), Vector2(-24,-80), Vector2(24,-80), Vector2(24,0)]) if completed else PackedVector2Array([Vector2(-36,0), Vector2(-36,-40), Vector2(36,-40), Vector2(36,0)])
	$Survivor/Body.color = Color(0.6,0.75,0.55) if completed else Color(0.6,0.55,0.42)
	$Survivor/Name.text = "幸存者 · 已救助" if completed else ("幸存者 · 救助机会已失去" if failed else "幸存者 · 清敌救助")
	$Gates.visible = not opened

func _draw() -> void:
	draw_rect(config.bounds, Color(0.055,0.06,0.075))
	for x: int in [0,480,1056,1728]:
		draw_rect(Rect2(x,0,96,1280), Color(0.13,0.12,0.115))
	for x: int in [352,1360]:
		draw_circle(Vector2(x,1100),58,Color(0.85,0.34,0.12,0.1))
		draw_line(Vector2(x,1160),Vector2(x,1080),Color(0.46,0.25,0.14),5)
		draw_colored_polygon(PackedVector2Array([Vector2(x-12,1090),Vector2(x,1048),Vector2(x+12,1090)]),Color(0.8,0.4,0.18))
