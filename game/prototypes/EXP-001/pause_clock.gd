extends Control
## Right side of the prototype pause menu: clock-style time and three-day progress.
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const INK: Color = Color(0.92, 0.94, 0.98)
const MUTED: Color = Color(0.7, 0.74, 0.82)
const WARM: Color = Color(1.0, 0.75, 0.45)

var state: RefCounted
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func text(position: Vector2, value: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, position, value, align, width, font_size, color)

func _draw() -> void:
	var center: Vector2 = Vector2(size.x * 0.5, 330)
	var radius: float = 190.0
	draw_circle(center, radius + 14, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, Color(0.08, 0.08, 0.11, 0.9))
	draw_arc(center, radius, 0, TAU, 96, Color(1, 1, 1, 0.35), 3.0, true)
	for i: int in range(60):
		var angle: float = -PI / 2.0 + TAU * i / 60.0
		var inner: float = radius - (22.0 if i % 5 == 0 else 10.0)
		draw_line(center + Vector2.from_angle(angle) * inner, center + Vector2.from_angle(angle) * (radius - 4), Color(1, 1, 1, 0.6 if i % 5 == 0 else 0.25), 3.0 if i % 5 == 0 else 1.5)
	var minutes: int = mini(state.clock_minutes(), 24 * 60 - 1)
	var hour_angle: float = -PI / 2.0 + TAU * fmod(minutes / 60.0, 12.0) / 12.0
	var minute_angle: float = -PI / 2.0 + TAU * (minutes % 60) / 60.0
	draw_line(center, center + Vector2.from_angle(hour_angle) * radius * 0.5, INK, 8.0, true)
	draw_line(center, center + Vector2.from_angle(minute_angle) * radius * 0.78, INK, 4.0, true)
	draw_circle(center, 9, WARM)
	text(Vector2(center.x - 200, center.y + radius + 70), state.clock_text(), 56, INK, HORIZONTAL_ALIGNMENT_CENTER, 400)
	text(Vector2(center.x - 300, center.y + radius + 114), "第 %d 日 · 末日前 %d 天" % [state.day, state.days_left()], 28, WARM, HORIZONTAL_ALIGNMENT_CENTER, 600)
	_draw_days(Vector2(center.x - 330, center.y + radius + 160), 660.0)
	text(Vector2(center.x - 330, center.y + radius + 320), "当前任务：前往营地与幸存者会合（原型占位文字）", 20, Color(MUTED, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 660)

func _draw_days(origin: Vector2, width: float) -> void:
	var gap: float = 14.0
	var segment: float = (width - gap * 2.0) / 3.0
	for i: int in range(3):
		var rect: Rect2 = Rect2(origin + Vector2(i * (segment + gap), 0), Vector2(segment, 14))
		draw_rect(rect, Color(1, 1, 1, 0.12))
		var fill: float = 1.0 if i + 1 < state.day else (state.day_progress() if i + 1 == state.day else 0.0)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y)), WARM if i + 1 == state.day else Color(WARM, 0.45))
		text(rect.position + Vector2(0, 44), "第 %d 日" % (i + 1), 20, INK if i + 1 == state.day else MUTED, HORIZONTAL_ALIGNMENT_CENTER, segment)
	if state.day < 3:
		var left: int = int(ceil(state.day_remaining))
		text(origin + Vector2(0, 82), "距下一日 %02d:%02d" % [int(left / 60.0), left % 60], 20, MUTED, HORIZONTAL_ALIGNMENT_CENTER, width)
	else:
		text(origin + Vector2(0, 82), "最后一日", 20, Color(1.0, 0.6, 0.5), HORIZONTAL_ALIGNMENT_CENTER, width)
