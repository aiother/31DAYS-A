class_name RavineRescueRoom
extends WorldRoom
@export var dialogue: DialogueConfig

func refresh_rescue(completed: bool, failed: bool, prompt: bool) -> void:
	$Survivor/Prompt.text = ""
	$Survivor/Prompt.visible = prompt and not $Survivor/Prompt.text.is_empty()
	$Survivor/VisualRoot/Body.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(-24, -80), Vector2(24, -80), Vector2(24, 0)]) if completed else PackedVector2Array([Vector2(-36, 0), Vector2(-36, -40), Vector2(36, -40), Vector2(36, 0)])
	$Survivor/VisualRoot/Body.color = Color(0.6, 0.75, 0.55) if completed else Color(0.6, 0.55, 0.42)
	$Survivor/Name.text = "沟壑幸存者 · 已救助" if completed else ("沟壑幸存者 · 救助机会已失去" if failed else "沟壑幸存者")

func _draw() -> void:
	draw_rect(config.bounds, Color(0.06, 0.065, 0.08))
	for x: int in [0, 480, 1056, 1728]:
		draw_rect(Rect2(x, 0, 96, 1152), Color(0.13, 0.12, 0.115))
	for x: int in [352, 1360]:
		draw_circle(Vector2(x, 960), 58, Color(0.85, 0.34, 0.12, 0.10))
		draw_line(Vector2(x, 1000), Vector2(x, 936), Color(0.46, 0.25, 0.14), 5)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 944), Vector2(x, 902), Vector2(x + 12, 944)]), Color(0.8, 0.4, 0.18))
