extends Control
## EXP-004 enemy introduction card at the top right (T5.4 §3.2, G-04), in the
## same family as the Boss name card. Two looks; each slides in, stays, then
## leaves. Ordinary enemies get the small card, Bosses the larger one.
const VARIANTS: Array[String] = ["1 · 纸签名片", "2 · 墨条横幅"]
const RIGHT: float = 1880.0
const TOP: float = 100.0
const SLIDE: float = 0.35

var variant: int = 0
var font: Font
var title: String = ""
var kind: String = "普通敌人"
var tips: String = ""
var boss: bool = false
var duration: float = 0.0
var age: float = 0.0
var paused: bool = false
## What the last frame put on screen; read by the smoke test.
var drawn: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

func show_card(card_title: String, card_kind: String, card_tips: String, is_boss: bool, seconds: float) -> void:
	title = card_title
	kind = card_kind
	tips = card_tips
	boss = is_boss
	duration = seconds
	age = 0.0

func showing() -> bool:
	return duration > 0.0 and age < duration

func size_now() -> Vector2:
	return Vector2(480, 250) if boss else Vector2(440, 196)

## 0 = off screen to the right, 1 = in place.
func slide() -> float:
	if not showing():
		return 0.0
	var t: float = minf(age / SLIDE, (duration - age) / SLIDE)
	return clampf(t, 0.0, 1.0)

func phase() -> String:
	if not showing():
		return "hidden"
	if age < SLIDE:
		return "entering"
	if age > duration - SLIDE:
		return "leaving"
	return "staying"

func card_rect() -> Rect2:
	var card: Vector2 = size_now()
	var settled: float = RIGHT - card.x
	var x: float = lerpf(1920.0 + 20.0, settled, ease(slide(), -2.0))
	return Rect2(Vector2(x, TOP), card)

func _process(delta: float) -> void:
	if not paused and showing():
		age += delta
	queue_redraw()

func _ink(at: Vector2, text: String, size_px: int, color: Color, width: float = -1.0) -> Dictionary:
	draw_multiline_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, size_px, -1, color)
	return {"text": text, "color": color}

func _draw() -> void:
	drawn = {"phase": phase()}
	if not showing():
		return
	var rect: Rect2 = card_rect()
	var record: Dictionary = {"phase": phase(), "rect": rect, "variant": VARIANTS[variant], "boss": boss, "settled": Rect2(Vector2(RIGHT - size_now().x, TOP), size_now())}
	var alpha: float = slide()
	match variant:
		0:
			InkDraw.paper(self, rect, Color(DuskStyle.PAPER_DAY, 0.95 * alpha), 970, DuskStyle.WOBBLE, 6)
			InkDraw.rough_rect(self, rect, Color(DuskStyle.LIFE if boss else DuskStyle.INK, 0.9 * alpha), 2.6 if boss else 1.8, 971, DuskStyle.WOBBLE)
			if boss:
				InkDraw.rough_rect(self, rect.grow(-8), Color(DuskStyle.LIFE, 0.5 * alpha), 1.2, 972, DuskStyle.WOBBLE)
			record["kind"] = _ink(rect.position + Vector2(28, 40), kind, UiTheme.SIZE_SMALL, Color(DuskStyle.LIFE, alpha))
			record["title"] = _ink(rect.position + Vector2(28, 92 if boss else 84), title, 48 if boss else UiTheme.SIZE_TITLE - 4, Color(DuskStyle.INK, alpha))
			InkDraw.rough_line(self, rect.position + Vector2(28, 108 if boss else 98), rect.position + Vector2(220, 108 if boss else 98), Color(DuskStyle.LIFE, 0.8 * alpha), 2.2, 973, DuskStyle.WOBBLE)
			record["tips"] = _ink(rect.position + Vector2(28, 144 if boss else 132), tips, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.85 * alpha), rect.size.x - 56)
		_:
			# A dry ink brush band; paper-coloured name, a vermilion seal for Bosses.
			var band: Rect2 = Rect2(rect.position, Vector2(rect.size.x, 96 if boss else 78))
			draw_rect(band, Color(0.04, 0.03, 0.03, 0.9 * alpha))
			for i: int in range(6):
				var y: float = band.position.y + 6 + i * band.size.y / 6.0
				InkDraw.rough_line(self, Vector2(band.position.x - 18 * InkDraw.noise(i, 974), y), Vector2(band.position.x + 8, y), Color(0.04, 0.03, 0.03, 0.7 * alpha), 4.0, 975 + i, 2.0)
			record["title"] = _ink(band.position + Vector2(30, band.size.y * 0.5 + 16), title, 44 if boss else UiTheme.SIZE_TITLE - 6, Color(DuskStyle.PAPER_DAY, alpha))
			if boss:
				var seal: Rect2 = Rect2(band.end.x - 82, band.position.y + 14, 58, 68)
				draw_rect(seal, Color(DuskStyle.LIFE, 0.95 * alpha))
				_ink(seal.position + Vector2(8, 30), "首\n领", 22, Color(DuskStyle.PAPER_DAY, alpha))
			var under: Rect2 = Rect2(Vector2(band.position.x + 18, band.end.y), Vector2(band.size.x - 18, rect.size.y - band.size.y))
			draw_rect(under, Color(0.04, 0.03, 0.03, 0.55 * alpha))
			record["kind"] = _ink(under.position + Vector2(14, 30), kind, UiTheme.SIZE_SMALL, Color(DuskStyle.LIFE.lightened(0.2), alpha))
			record["tips"] = _ink(under.position + Vector2(14, 62), tips, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.9 * alpha), under.size.x - 28)
	drawn = record
