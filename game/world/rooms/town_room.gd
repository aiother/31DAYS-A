class_name TownRoom
extends WorldRoom
@export var dialogue: DialogueConfig

func refresh_rescue(completed: bool, failed: bool, prompt: bool) -> void:
	$Survivor/Prompt.text = ""
	$Survivor/Prompt.visible = prompt and not $Survivor/Prompt.text.is_empty()
	$Survivor/VisualRoot/Body.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(-24, -80), Vector2(24, -80), Vector2(24, 0)]) if completed else PackedVector2Array([Vector2(-36, 0), Vector2(-36, -40), Vector2(36, -40), Vector2(36, 0)])
	$Survivor/VisualRoot/Body.color = Color(0.6, 0.75, 0.55) if completed else Color(0.6, 0.55, 0.42)
	$Survivor/Name.text = "幸存者 · 已救助" if completed else ("幸存者 · 救助机会已失去" if failed else "幸存者")

func _draw() -> void:
	draw_rect(config.bounds, Color(0.31, 0.33, 0.29))
	draw_rect(Rect2(0, 0, 1920, 360), Color(0.23, 0.27, 0.28))
	for x: int in [160, 600, 1200, 1640]:
		draw_rect(Rect2(x, 560, 240, 336), Color(0.4, 0.37, 0.28))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 24, 560), Vector2(x + 120, 456), Vector2(x + 264, 560)]), Color(0.56, 0.47, 0.28))
		draw_rect(Rect2(x + 80, 756, 72, 140), Color(0.22, 0.25, 0.22))
