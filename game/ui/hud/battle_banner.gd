class_name BattleBanner
extends Control
## UI-009: battlefield stage and wave notices as a short ink band at the top
## centre, apart from the enemy card in the top-right corner (EXP-004
## suggestion). First line is the heading, the rest a smaller line under it.
## It fades in and out, stops while paused, and keeps clear of what `avoid`
## returns (HUD as drawn, dialogue, area name, interaction prompt, enemy card,
## save error): it tries a few heights and, when none is clear, gives way for
## that frame without stopping its clock.
const WIDTH: float = 680.0
const TOPS: Array[float] = [196.0, 330.0, 430.0]
const FADE: float = 0.25
const INK_BAND: Color = Color(0.04, 0.03, 0.03, 0.86)

var avoid: Callable
var heading: String = ""
var line: String = ""
var duration: float = 0.0
var age: float = -1.0
var font: Font
## What the last frame put on screen, each part returned by the call that drew it.
var drawn: Dictionary = {}

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

func show_text(seconds: float, value: String) -> void:
	var parts: PackedStringArray = value.split("\n", false)
	heading = parts[0] if parts.size() > 0 else ""
	line = "\n".join(parts.slice(1))
	duration = seconds
	age = 0.0
	queue_redraw()

func clear() -> void:
	age = -1.0
	drawn = {}
	queue_redraw()

func showing() -> bool:
	return age >= 0.0 and age < duration

func alpha() -> float:
	if not showing():
		return 0.0
	return clampf(minf(age / FADE, (duration - age) / FADE), 0.0, 1.0)

func box_height() -> float:
	var under: float = font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, WIDTH - 60, UiTheme.SIZE_SMALL).y if not line.is_empty() else 0.0
	return 62.0 + under + (14.0 if under > 0.0 else 0.0)

## The first clear spot, or an empty rect when every one is taken.
func place() -> Rect2:
	var others: Array[Rect2] = avoid.call() if avoid.is_valid() else []
	var view: float = size.x if size.x > 0.0 else 1920.0
	for top: float in TOPS:
		var rect: Rect2 = Rect2(Vector2((view - WIDTH) * 0.5, top), Vector2(WIDTH, box_height()))
		var clear_spot: bool = true
		for other: Rect2 in others:
			clear_spot = clear_spot and not rect.intersects(other)
		if clear_spot:
			return rect
	return Rect2()

func _process(delta: float) -> void:
	if get_tree().paused:
		queue_redraw()
		return
	if age >= 0.0:
		age += delta
		if age >= duration:
			age = -1.0
	queue_redraw()

func _fill(rect: Rect2, color: Color) -> Dictionary:
	draw_rect(rect, color)
	return {"rect": rect, "color": color}

func _ink(at: Vector2, value: String, size_px: int, color: Color, width: float) -> Dictionary:
	draw_multiline_string(font, at, value, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, -1, color)
	return {"text": value, "color": color}

func _draw() -> void:
	drawn = {}
	if not showing():
		return
	var rect: Rect2 = place()
	if rect.size == Vector2.ZERO:
		return
	var a: float = alpha()
	var band: Dictionary = _fill(rect, Color(INK_BAND, INK_BAND.a * a))
	InkDraw.rough_line(self, rect.position + Vector2(24, 8), rect.position + Vector2(rect.size.x - 24, 8), Color(DuskStyle.LIFE, 0.8 * a), 2.0, 980, DuskStyle.WOBBLE)
	var record: Dictionary = {"rect": rect, "alpha": a, "band": band}
	record["heading"] = _ink(rect.position + Vector2(0, 46), heading, UiTheme.SIZE_HEADING - 2, Color(DuskStyle.PAPER_DAY, a), rect.size.x)
	if not line.is_empty():
		record["line"] = _ink(rect.position + Vector2(30, 80), line, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.85 * a), rect.size.x - 60)
	drawn = record
