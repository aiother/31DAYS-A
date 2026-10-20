extends Control
## Shared drawing helpers for the EXP-001 HUD variants.
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const LIFE: Color = Color(0.96, 0.9, 0.86)
const POSSIBILITY: Color = Color(0.45, 0.85, 1.0)
const GROWTH: Color = Color(1.0, 0.8, 0.4)
const OVERDRAFT: Color = Color(0.75, 0.12, 0.2)
const DENY: Color = Color(1.0, 0.2, 0.2)
const EMPTY: Color = Color(0.05, 0.06, 0.09, 0.65)
const INK: Color = Color(0.92, 0.94, 0.98)
const MUTED: Color = Color(0.7, 0.74, 0.82)

var state: RefCounted
var expanded: bool = false
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func title() -> String:
	return ""

## Where gained possibility flies to.
func gain_target() -> Vector2:
	return Vector2(160, 120)

func text(position: Vector2, value: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string_outline(font, position, value, align, width, size, 6, Color(0, 0, 0, 0.55))
	draw_string(font, position, value, align, width, size, color)

## 0..1 flashing strength while a short-of-possibility action is signalled (A-018).
func deny_flash() -> float:
	if state.deny_left <= 0.0:
		return 0.0
	return (0.5 + 0.5 * sin(state.clock * 28.0)) * clampf(state.denied() * 1.6, 0.0, 1.0)

func pulse() -> float:
	return clampf(state.gain_pulse / 0.35, 0.0, 1.0)

func heart(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(32):
		var t: float = TAU * i / 32.0
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y) * radius / 17.0)
	draw_colored_polygon(points, color)

func diamond(center: Vector2, size: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -size.y), center + Vector2(size.x, 0), center + Vector2(0, size.y), center + Vector2(-size.x, 0)]), color)

func cross(center: Vector2, size: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(size * 0.18, size * 0.5), Vector2(size * 0.36, size)), color)
	draw_rect(Rect2(center - Vector2(size * 0.5, size * 0.18), Vector2(size, size * 0.36)), color)

func pearl_row(origin: Vector2, radius: float) -> void:
	for i: int in range(HudState.PEARL_MAX):
		var center: Vector2 = origin + Vector2(i * radius * 2.6, 0)
		if i < state.pearls:
			draw_circle(center, radius, Color(0.95, 0.95, 1.0))
			draw_circle(center + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.3, Color(1, 1, 1, 0.9))
		else:
			draw_arc(center, radius, 0, TAU, 20, Color(1, 1, 1, 0.35), 2.0)

func medkit_row(origin: Vector2) -> void:
	if not state.show_medkit:
		return
	cross(origin, 22, Color(0.9, 0.35, 0.35))
	text(origin + Vector2(20, 9), "× %d" % state.medkits, 24, INK)
