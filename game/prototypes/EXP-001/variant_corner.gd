extends "res://prototypes/EXP-001/variant_base.gd"
## 方案一：信息集中在左上角；日内时间常驻右下角（A-015 ①）。
const ORIGIN: Vector2 = Vector2(56, 52)
const CELL: Vector2 = Vector2(30, 22)
const GAP: float = 5.0
const SKEW: float = 8.0
const GROWTH_GAP: float = 14.0

func title() -> String:
	return "方案一 · 左上角集中 + 时间常驻右下角（A-015 ①）"

func _cell_x(index: int) -> float:
	return ORIGIN.x + index * (CELL.x + GAP) + (GROWTH_GAP if index >= HudState.BASE_MAX else 0.0)

func gain_target() -> Vector2:
	var index: int = clampi(state.balance - 1, 0, state.maximum() - 1)
	return Vector2(_cell_x(index) + CELL.x * 0.5 + SKEW * 0.5, ORIGIN.y + 74 + CELL.y * 0.5)

func _draw() -> void:
	_draw_life()
	_draw_possibility()
	pearl_row(ORIGIN + Vector2(10, 148), 9)
	text(ORIGIN + Vector2(110, 156), "攻击范围 %d%%" % state.reach_percent(), 22, MUTED)
	medkit_row(ORIGIN + Vector2(300, 148))
	_draw_time()

func _draw_life() -> void:
	# Only current life is shown, never the empty maximum (T7-B).
	for i: int in range(state.health):
		var center: Vector2 = ORIGIN + Vector2(20 + i * 48, 20)
		heart(center + Vector2(2, 3), 19, Color(0, 0, 0, 0.45))
		heart(center, 19, LIFE if state.health > 1 else Color(1.0, 0.45, 0.45))

func _draw_possibility() -> void:
	var y: float = ORIGIN.y + 74
	var total: int = state.maximum()
	var flash: float = deny_flash()
	var glow: float = pulse()
	for i: int in range(total):
		var x: float = _cell_x(i)
		var poly: PackedVector2Array = PackedVector2Array([Vector2(x + SKEW, y), Vector2(x + CELL.x + SKEW, y), Vector2(x + CELL.x, y + CELL.y), Vector2(x, y + CELL.y)])
		var growth_cell: bool = i >= HudState.BASE_MAX
		draw_colored_polygon(poly, EMPTY)
		var fill: Color = Color(0, 0, 0, 0)
		if i < state.balance:
			fill = POSSIBILITY.lerp(Color.WHITE, glow * 0.5)
		elif i >= total - state.overdraft():
			# Overdraft drains from the far side, in reverse (T7-B).
			fill = OVERDRAFT
		if fill.a > 0.0:
			draw_colored_polygon(poly, fill.lerp(DENY, flash * 0.6))
		var outline: Color = (GROWTH if growth_cell else Color(0.75, 0.88, 1.0, 0.7)).lerp(DENY, flash)
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, outline, 2.0 + flash * 2.0)
	if state.overdraft() > 0:
		text(Vector2(_cell_x(total - 1) + CELL.x + 22, y + 20), "透支", 20, Color(1.0, 0.55, 0.55))

func _draw_time() -> void:
	var box: Rect2 = Rect2(size.x - 300, size.y - 120, 250, 76)
	draw_rect(box, Color(0.02, 0.03, 0.05, 0.55))
	draw_rect(box, Color(1, 1, 1, 0.18), false, 1.5)
	text(box.position + Vector2(18, 28), "第 %d 日 · 末日前 %d 天" % [state.day, state.days_left()], 18, MUTED)
	text(box.position + Vector2(18, 64), state.clock_text(), 34, INK)
	# Daylight progress strip.
	var strip: Rect2 = Rect2(box.position + Vector2(130, 50), Vector2(100, 6))
	draw_rect(strip, Color(1, 1, 1, 0.15))
	draw_rect(Rect2(strip.position, Vector2(strip.size.x * state.day_progress(), strip.size.y)), Color(1.0, 0.75, 0.4, 0.8))
