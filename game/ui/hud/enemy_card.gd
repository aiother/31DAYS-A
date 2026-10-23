class_name EnemyCard
extends PanelContainer
## UI-009 (BL-054): the enemy introduction card at the top right, EXP-004
## variant 2 chosen by the user: a dry ink band with the name in paper colour,
## a translucent block under it (kind line, tips), and a vermilion "首领"
## seal for Bosses. LifeUI slides it in and out by `position`; the hidden
## Label keeps the "title\n\ntips" text that sessions and older tests read.
const RIGHT: float = 1880.0
const TOP: float = 100.0
const WIDTH: float = 440.0
const BOSS_WIDTH: float = 480.0
const BAND: float = 78.0
const BOSS_BAND: float = 96.0
const INK_BAND: Color = Color(0.04, 0.03, 0.03, 0.9)
const INK_UNDER: Color = Color(0.04, 0.03, 0.03, 0.55)
const KINDS: Array[String] = ["普通敌人", "精英", "首领"]

var title: String = ""
var kind: String = KINDS[0]
var tips: String = ""
var font: Font
var text: Label
## What the last frame put on screen, each part returned by the call that drew it.
var drawn: Dictionary = {}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	font = UiTheme.font()
	text = Label.new()
	text.hide()
	add_child(text)
	position = Vector2(1920, TOP)
	# A hidden card does not draw; its record must not outlive it.
	visibility_changed.connect(func() -> void:
		if not visible:
			drawn = {})

func setup(card_title: String, card_kind: String, card_tips: String) -> void:
	title = card_title
	kind = card_kind
	tips = card_tips.strip_edges()
	text.text = title + ("\n\n" + tips if not tips.is_empty() else "")
	var width: float = BOSS_WIDTH if boss() else WIDTH
	var tips_height: float = font.get_multiline_string_size(tips, HORIZONTAL_ALIGNMENT_LEFT, width - 46, UiTheme.SIZE_SMALL).y if not tips.is_empty() else 0.0
	size = Vector2(width, band() + 50 + tips_height + 18)
	position.y = TOP
	queue_redraw()

func boss() -> bool:
	return kind == KINDS[2]

func band() -> float:
	return BOSS_BAND if boss() else BAND

## Where the card rests once it has slid in.
func settled_x() -> float:
	return RIGHT - size.x

func _process(_delta: float) -> void:
	# The record carries the on-screen rect, which moves while sliding.
	if visible:
		queue_redraw()

func _ink(at: Vector2, value: String, size_px: int, color: Color, width: float = -1.0) -> Dictionary:
	draw_multiline_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, width, size_px, -1, color)
	return {"text": value, "color": color}

func _fill(rect: Rect2, color: Color) -> Dictionary:
	draw_rect(rect, color)
	return {"rect": Rect2(global_position + rect.position, rect.size), "color": color}

func _draw() -> void:
	drawn = {}
	if not visible:
		return
	var record: Dictionary = {"rect": get_global_rect(), "kind_name": kind, "boss": boss()}
	var band_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(size.x, band()))
	record["band"] = _fill(band_rect, INK_BAND)
	# Dry brush ends on the left edge of the band.
	for i: int in range(6):
		var y: float = 6 + i * band_rect.size.y / 6.0
		InkDraw.rough_line(self, Vector2(-18 * InkDraw.noise(i, 974), y), Vector2(8, y), Color(INK_BAND, 0.7), 4.0, 975 + i, 2.0)
	record["title"] = _ink(Vector2(30, band_rect.size.y * 0.5 + 16), title, 44 if boss() else UiTheme.SIZE_TITLE - 6, DuskStyle.PAPER_DAY)
	if boss():
		var seal: Rect2 = Rect2(band_rect.end.x - 82, 14, 58, 68)
		var mark: Dictionary = _fill(seal, Color(DuskStyle.LIFE, 0.95))
		mark["text"] = _ink(seal.position + Vector2(8, 30), "首\n领", 22, DuskStyle.PAPER_DAY)["text"]
		record["seal"] = mark
	var under: Rect2 = Rect2(Vector2(18, band_rect.end.y), Vector2(size.x - 18, size.y - band_rect.size.y))
	record["under"] = _fill(under, INK_UNDER)
	record["kind"] = _ink(under.position + Vector2(14, 30), kind, UiTheme.SIZE_SMALL, DuskStyle.LIFE.lightened(0.2))
	record["tips"] = _ink(under.position + Vector2(14, 62), tips, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.9), under.size.x - 28)
	drawn = record
