extends "res://prototypes/EXP-001/variant_base.gd"
## 方案二：生命与可能性合成一个徽记；右下角常驻简要时间，按 Tab 展开（A-015 ③）。
const CENTER: Vector2 = Vector2(150, 148)
const RING: float = 88.0
const OUTER: float = 110.0
const WIDTH: float = 15.0
const START: float = -PI / 2.0

func title() -> String:
	return "方案二 · 整体徽记 + 简要时间，按住 Tab 展开（A-015 ③）"

func _segment_angle(index: int, count: int) -> float:
	return START + TAU * (index + 0.5) / count

func gain_target() -> Vector2:
	var index: int = clampi(state.balance - 1, 0, HudState.BASE_MAX - 1)
	return CENTER + Vector2.from_angle(_segment_angle(index, HudState.BASE_MAX)) * RING

func _draw() -> void:
	_draw_ring()
	_draw_life()
	_draw_pearls()
	medkit_row(CENTER + Vector2(OUTER + 40, 50))
	_draw_time()

func _arc(radius: float, index: int, count: int, color: Color, width: float) -> void:
	var span: float = TAU / count
	var from: float = START + span * index + 0.06
	draw_arc(CENTER, radius, from, from + span - 0.12, 10, color, width, true)

func _draw_ring() -> void:
	var flash: float = deny_flash()
	var glow: float = pulse()
	draw_circle(CENTER, RING + WIDTH, Color(0.02, 0.03, 0.05, 0.55))
	var base: int = HudState.BASE_MAX
	for i: int in range(base):
		_arc(RING, i, base, EMPTY.lerp(DENY, flash * 0.2), WIDTH)
		if i < state.balance:
			_arc(RING, i, base, POSSIBILITY.lerp(Color.WHITE, glow * 0.5).lerp(DENY, flash * 0.6), WIDTH - 3)
		elif i >= base - state.overdraft():
			# Overdraft runs counter-clockwise from the top: the opposite side.
			_arc(RING, i, base, OVERDRAFT.lerp(DENY, flash * 0.6), WIDTH - 3)
	# Growth capacity is an extra outer ring segment set.
	var extra: int = state.growth * HudState.GROWTH_STEP
	for i: int in range(extra):
		var filled: bool = state.balance > base + i
		_arc(OUTER, i, base, GROWTH if filled else Color(GROWTH, 0.35), 8)
	draw_arc(CENTER, RING + WIDTH * 0.5 + 2, 0, TAU, 64, Color(1, 1, 1, 0.15 + flash * 0.6), 1.5 + flash * 2.0, true)

func _draw_life() -> void:
	var count: int = state.health
	var color: Color = LIFE if count > 1 else Color(1.0, 0.45, 0.45)
	var spacing: float = 24.0
	var left: float = CENTER.x - (count - 1) * spacing * 0.5
	for i: int in range(count):
		diamond(Vector2(left + i * spacing, CENTER.y), Vector2(9, 26), color)

func _draw_pearls() -> void:
	for i: int in range(HudState.PEARL_MAX):
		var angle: float = PI * 0.5 + (i - 1.5) * 0.28
		var center: Vector2 = CENTER + Vector2.from_angle(angle) * (OUTER + 26)
		if i < state.pearls:
			draw_circle(center, 7, Color(0.95, 0.95, 1.0))
		else:
			draw_arc(center, 7, 0, TAU, 16, Color(1, 1, 1, 0.35), 1.5)
	text(CENTER + Vector2(OUTER + 40, 8), "范围 %d%%" % state.reach_percent(), 22, MUTED)

func _draw_time() -> void:
	var anchor: Vector2 = Vector2(size.x - 70, size.y - 70)
	if expanded:
		var box: Rect2 = Rect2(anchor - Vector2(330, 120), Vector2(360, 150))
		draw_rect(box, Color(0.02, 0.03, 0.05, 0.75))
		draw_rect(box, Color(1, 1, 1, 0.25), false, 1.5)
		text(box.position + Vector2(20, 40), "第 %d 日" % state.day, 26, INK)
		text(box.position + Vector2(130, 40), "末日前 %d 天" % state.days_left(), 22, Color(1.0, 0.75, 0.55))
		text(box.position + Vector2(20, 92), state.clock_text(), 44, INK)
		var left: int = int(ceil(state.day_remaining))
		text(box.position + Vector2(20, 132), "距下一日 %02d:%02d" % [int(left / 60.0), left % 60] if state.day < 3 else "最后一日", 20, MUTED)
		return
	# Compact: sun dial plus hour only.
	draw_circle(anchor, 30, Color(0.02, 0.03, 0.05, 0.6))
	draw_arc(anchor, 26, PI, TAU, 24, Color(1, 1, 1, 0.3), 2.0)
	var sun: Vector2 = anchor + Vector2.from_angle(PI + PI * state.day_progress()) * 26
	draw_circle(sun, 6, Color(1.0, 0.75, 0.4))
	text(anchor + Vector2(-110, 10), "%d时" % int(state.clock_minutes() / 60.0), 26, INK)
	text(anchor + Vector2(-150, 44), "Tab 展开", 16, Color(MUTED, 0.6))
