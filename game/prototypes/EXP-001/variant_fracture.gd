extends "res://prototypes/EXP-001/variant_base.gd"
## 方案三（可选，偏离 T7）：可能性不是格子容器而是随数值变形的光团；
## 生命为左侧竖排碎片；最后1点生命时 HUD 本身破裂；时间是横贯底部的地平线。
const BLOB: Vector2 = Vector2(130, 120)
const SHARD_X: float = 34.0

func title() -> String:
	return "方案三 · 偏离规格的表现力方案（可选，偏离点见说明）"

func gain_target() -> Vector2:
	return BLOB

func _blob_radius() -> float:
	return 22.0 + 6.0 * maxf(0.0, state.balance)

func _draw() -> void:
	_draw_blob()
	_draw_life()
	_draw_pearls()
	medkit_row(BLOB + Vector2(150, 70))
	_draw_horizon()
	if state.health == 1:
		_draw_cracks()

func _draw_blob() -> void:
	var flash: float = deny_flash()
	var glow: float = pulse()
	var points: PackedVector2Array = PackedVector2Array()
	var overdrawn: bool = state.balance < 0
	var radius: float = _blob_radius() if not overdrawn else 18.0 + 4.0 * state.overdraft()
	for i: int in range(48):
		var angle: float = TAU * i / 48.0
		var wobble: float = sin(angle * 5.0 + state.clock * 2.4) * 4.0 + sin(angle * 3.0 - state.clock * 1.7) * 3.0
		if overdrawn:
			# Overdraft turns the glow into an inward spiked shard.
			wobble = (8.0 if i % 2 == 0 else -10.0) + sin(state.clock * 6.0 + i) * 2.0
		points.append(BLOB + Vector2.from_angle(angle) * (radius + wobble))
	var color: Color = (OVERDRAFT if overdrawn else POSSIBILITY.lerp(Color.WHITE, glow * 0.5)).lerp(DENY, flash * 0.7)
	if state.balance == 0:
		color = Color(0.3, 0.35, 0.42)
	draw_colored_polygon(points, Color(color, 0.85))
	# Growth shows as orbit rings the glow can expand into.
	for g: int in range(state.growth):
		draw_arc(BLOB, 22.0 + 6.0 * (HudState.BASE_MAX + (g + 1) * HudState.GROWTH_STEP), 0, TAU, 64, Color(GROWTH, 0.5), 2.0, true)
	draw_arc(BLOB, 22.0 + 6.0 * HudState.BASE_MAX, 0, TAU, 64, Color(1, 1, 1, 0.12 + flash * 0.6), 1.5 + flash * 2.0, true)

func _draw_life() -> void:
	var color: Color = LIFE if state.health > 1 else Color(1.0, 0.45, 0.45)
	for i: int in range(state.health):
		var top: float = 300.0 + i * 74.0
		draw_colored_polygon(PackedVector2Array([Vector2(SHARD_X - 6, top), Vector2(SHARD_X + 8, top + 8), Vector2(SHARD_X + 4, top + 62), Vector2(SHARD_X - 8, top + 54)]), color)

func _draw_pearls() -> void:
	var orbit: float = _blob_radius() * 0.6 + 40.0 * state.reach_percent() / 100.0
	for i: int in range(state.pearls):
		var angle: float = state.clock * 0.8 + TAU * i / HudState.PEARL_MAX
		draw_circle(BLOB + Vector2.from_angle(angle) * orbit, 6, Color(0.95, 0.95, 1.0))
	if state.pearls > 0:
		text(BLOB + Vector2(150, 20), "范围 %d%%" % state.reach_percent(), 20, MUTED)

func _draw_horizon() -> void:
	var y: float = size.y - 36
	draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.18), 2.0)
	var x: float = size.x * state.day_progress()
	draw_line(Vector2(0, y), Vector2(x, y), Color(1.0, 0.7, 0.4, 0.6), 2.0)
	draw_circle(Vector2(x, y), 8, Color(1.0, 0.75, 0.4))
	text(Vector2(clampf(x - 40, 10, size.x - 260), y - 16), "第%d日 %s" % [state.day, state.clock_text()], 20, INK)

func _draw_cracks() -> void:
	var color: Color = Color(1.0, 0.85, 0.85, 0.55)
	var lines: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0, 40), Vector2(90, 70), Vector2(150, 40), Vector2(260, 95), Vector2(330, 60)]),
		PackedVector2Array([Vector2(150, 40), Vector2(170, 160), Vector2(120, 240), Vector2(150, 330)]),
		PackedVector2Array([Vector2(90, 70), Vector2(40, 180), Vector2(70, 260)]),
	]
	for line: PackedVector2Array in lines:
		draw_polyline(line, color, 2.0, true)
