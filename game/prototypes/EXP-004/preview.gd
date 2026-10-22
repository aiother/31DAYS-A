extends Control
## EXP-004 preview: dialogue box variants A/B/C, two ways to show the missed
## rescue (G-08) and two enemy card looks, over a stand-in field with a mock
## HUD. Everything is simulated; nothing touches real scenes, saves or input
## settings. Keys are listed on screen (H hides them).
const DIALOGUE: Script = preload("res://prototypes/EXP-004/dialogue_view.gd")
const CARD: Script = preload("res://prototypes/EXP-004/intro_card.gd")
const HELP: String = "EXP-004 原型（H 隐藏）\n1 / 2 / 3 / 8  对话方案 A / B / C / D\n4 / 5  G-08 呈现：对话一句 / 短提示\n6 / 7  介绍卡方案 1 / 2\nT 与7交谈 · L 离开麦秆镇（救助确认）\nK 强制剧情（隐藏 HUD）· M 走到已错失救助处\nC 普通敌人卡 · B Boss 名片 · W 战场波次提示\nE / RB 继续（长按加速）· Esc 暂停"
const TALK: Array[Dictionary] = [
	{"speaker": "7", "text": "你也是从荒地那边过来的吗？镇子里的人都病倒了，我一个人照顾不过来。"},
	{"speaker": "主角", "text": "需要我做什么？"},
	{"speaker": "7", "text": "镇子东边的井旁有草药，帮我带回来就好。拜托了，在天黑以前。"},
]
const LEAVE: Array[Dictionary] = [
	{"speaker": "7", "text": "你要走了吗？现在离开的话……这里的人就等不到草药了。"},
]
const STORY: Array[Dictionary] = [
	{"speaker": "10", "text": "别回头。夕阳落下以前，我们还能再往前走一段。"},
	{"speaker": "主角", "text": "……嗯。"},
]
const MISSED_LINE: Array[Dictionary] = [
	{"speaker": "", "text": "（屋里已经没有人了。如果更早来到这里……也许还能帮上忙。）", "tone": "aside"},
]
const MISSED_TAG: String = "此处曾有人需要帮助\n更早到来，或许还来得及"
const MISSED_SPOT: Vector2 = Vector2(1180, 820)

var dialogue: Control
var card: Control
## Drawn above the dialogue and the card.
var pause_layer: Control
var help: Label
var g08_mode: int = 0
var paused: bool = false
var missed_left: float = 0.0
var wave_left: float = 0.0
var last_choice: String = ""
var clock: float = 0.0
var font: Font
## What the last frame put on screen; read by the smoke test.
var drawn: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = UiTheme.font()
	dialogue = DIALOGUE.new()
	add_child(dialogue)
	dialogue.connect("departure_chosen", func(leave: bool) -> void: last_choice = "leave" if leave else "stay")
	card = CARD.new()
	add_child(card)
	pause_layer = Control.new()
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_layer.draw.connect(_draw_pause)
	add_child(pause_layer)
	help = Label.new()
	help.theme = UiTheme.get_theme()
	help.text = HELP
	help.position = Vector2(1430, 420)
	help.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	help.add_theme_color_override("font_color", Color(DuskStyle.PAPER_DAY, 0.85))
	help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	help.add_theme_constant_override("outline_size", 6)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)

func set_variant(index: int) -> void:
	dialogue.set("variant", index)

func set_card_variant(index: int) -> void:
	card.set("variant", index)

func talk() -> void:
	dialogue.call("start", TALK)

func leave_town() -> void:
	last_choice = ""
	dialogue.call("start", LEAVE, false, true)

func story() -> void:
	dialogue.call("start", STORY, true)

## G-08: at a place where the rescue can no longer happen.
func reach_missed() -> void:
	if g08_mode == 0:
		dialogue.call("start", MISSED_LINE)
	else:
		missed_left = 4.0

func ordinary_card() -> void:
	card.call("show_card", "无色实体", "普通敌人 · 首次遭遇", "这里不安全。\n观察攻击前摇，寻找反击或闪避机会。", false, 5.0)

func boss_card() -> void:
	card.call("show_card", "渴望俯视", "首领 · 首次遭遇", "留意落击提示。\n利用召唤平台接近高空目标。", true, 5.0)

func wave() -> void:
	wave_left = 2.0

func toggle_pause() -> void:
	paused = not paused
	dialogue.set("paused", paused)
	card.set("paused", paused)

func hud_visible() -> bool:
	return not bool(dialogue.get("forced")) or not bool(dialogue.get("active"))

func _process(delta: float) -> void:
	clock += delta
	if not paused:
		missed_left = maxf(0.0, missed_left - delta)
		wave_left = maxf(0.0, wave_left - delta)
	queue_redraw()
	pause_layer.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if paused:
		return
	if event.is_action_pressed("interact") and bool(dialogue.get("active")):
		dialogue.call("press")
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_1, KEY_2, KEY_3: set_variant((event as InputEventKey).keycode - KEY_1)
		KEY_8: set_variant(3)
		KEY_4, KEY_5: g08_mode = (event as InputEventKey).keycode - KEY_4
		KEY_6, KEY_7: set_card_variant((event as InputEventKey).keycode - KEY_6)
		KEY_T: talk()
		KEY_L: leave_town()
		KEY_K: story()
		KEY_M: reach_missed()
		KEY_C: ordinary_card()
		KEY_B: boss_card()
		KEY_W: wave()
		KEY_H: help.visible = not help.visible
		_: return
	get_viewport().set_input_as_handled()

func _ink(at: Vector2, text: String, size_px: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Dictionary:
	draw_multiline_string(font, at, text, align, width, size_px, -1, color)
	return {"text": text, "color": color}

func _draw() -> void:
	var record: Dictionary = {}
	# Stand-in field at a second-day dusk.
	var time: Dictionary = {"day": 2, "day_progress": 0.5}
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), DuskStyle.DUSK_TOP.darkened(0.5).lerp(Color("4a5a68"), 0.4), DuskStyle.DUSK_BOTTOM.darkened(0.3))
	draw_rect(Rect2(0, 880, size.x, 200), Color(0.16, 0.13, 0.14))
	draw_rect(Rect2(380, 790, 44, 90), Color(0.5, 0.85, 0.85))
	draw_rect(Rect2(760, 800, 40, 80), Color(0.85, 0.7, 0.45))
	_ink(Vector2(760, 786), "7", UiTheme.SIZE_SMALL, DuskStyle.PAPER_DAY)
	draw_rect(Rect2(MISSED_SPOT.x - 30, MISSED_SPOT.y - 40, 60, 100), Color(0.25, 0.22, 0.24))
	# Mock HUD: emblem, hint tag and horizon (hidden in forced story scenes).
	record["hud"] = hud_visible()
	if hud_visible():
		InkDraw.paper_disc(self, Vector2(180, 180), 140, Color(DuskStyle.paper_color(time), 0.85), 980, DuskStyle.WOBBLE)
		InkDraw.rough_circle(self, Vector2(180, 180), 140, Color(DuskStyle.INK, 0.8), 2.0, 981, DuskStyle.WOBBLE)
		_ink(Vector2(110, 192), "（HUD）", UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.6))
		InkDraw.rough_line(self, Vector2(40, 1040), Vector2(size.x - 40, 1040), Color(DuskStyle.SUN, 0.8), 2.0, 982, 0.8)
	# G-08 as a short tag by the place: no input lock, fades out.
	if missed_left > 0.0:
		var alpha: float = clampf(missed_left / 0.6, 0.0, 1.0)
		var tag: Rect2 = Rect2(MISSED_SPOT + Vector2(-190, -180), Vector2(380, 92))
		InkDraw.paper(self, tag, Color(DuskStyle.PAPER_DAY, 0.9 * alpha), 983, DuskStyle.WOBBLE, 0)
		InkDraw.rough_rect(self, tag, Color(DuskStyle.INK, 0.7 * alpha), 1.4, 984, DuskStyle.WOBBLE)
		var shown: Dictionary = _ink(tag.position + Vector2(0, 36), MISSED_TAG, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, alpha), tag.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		shown["rect"] = tag
		record["missed_tag"] = shown
	# Battlefield wave notices stay their own small top-centre line, so the
	# enemy card is only ever about an enemy.
	if wave_left > 0.0:
		var alpha: float = clampf(wave_left / 0.4, 0.0, 1.0)
		var band: Rect2 = Rect2(Vector2((size.x - 520) * 0.5, 450), Vector2(520, 56))
		draw_rect(band, Color(0.03, 0.02, 0.03, 0.7 * alpha))
		var shown: Dictionary = _ink(band.position + Vector2(0, 38), "敌方第 2 波即将进入", UiTheme.SIZE_BODY, Color(DuskStyle.PAPER_DAY, alpha), band.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		shown["rect"] = band
		record["wave"] = shown
	drawn = record

func _draw_pause() -> void:
	drawn.erase("pause")
	if not paused:
		return
	pause_layer.draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.03, 0.55))
	var text: String = "暂停（原型示意）· Esc 返回，对话保持原处"
	pause_layer.draw_string(font, Vector2(0, 560), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY)
	drawn["pause"] = text
