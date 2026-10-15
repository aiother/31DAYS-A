class_name BossRoom
extends WorldRoom
var opened: bool = false
var summoned: bool = false
var light_strength: float = 0.0

func summon_platforms() -> void:
	if summoned:
		return
	summoned = true
	for point: Vector2 in [Vector2(608, 1152), Vector2(832, 1008), Vector2(1056, 864)]:
		var platform: Node2D = (preload("res://world/scenes/platform.tscn") as PackedScene).instantiate() as Node2D
		platform.position = point
		$SummonedPlatforms.add_child(platform)

func set_opened(value: bool) -> void:
	var changed: bool = opened != value
	opened = value
	$ExitLabel.text = "天窗已开启 · 向上前进" if value else "击败渴望俯视后开启"
	if value:
		summon_platforms()
		if changed:
			create_tween().tween_property(self, "light_strength", 1.0, 0.8)
	queue_redraw()

func _process(_delta: float) -> void:
	if opened:
		queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds, Color(0.065, 0.07, 0.10))
	for x: int in [64, 480, 960, 1440, 1824]:
		draw_rect(Rect2(x, 80, 32, 1200), Color(0.12, 0.13, 0.17))
	draw_line(Vector2(48, 1280), Vector2(48, 1080), Color(0.4, 0.8, 0.5) if opened else Color(0.8, 0.4, 0.3), 6)
	if opened:
		draw_colored_polygon(PackedVector2Array([Vector2(1488, 0), Vector2(1616, 0), Vector2(1696, 848), Vector2(1408, 848)]), Color(0.95, 0.8, 0.3, 0.17 * light_strength))
	else:
		draw_line(Vector2(1488, 848), Vector2(1616, 848), Color(0.7, 0.45, 0.3), 8)
