extends Control
## EXP-002 pause menu: EXP-001 variant four layout (options left, clock and
## three-day progress right, secondary pages cover the clock) on paper and ink.
const Ink = preload("res://prototypes/EXP-002/ink.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")
const InkButton = preload("res://prototypes/EXP-002/ink_button.gd")
const LEFT_WIDTH: float = 560.0

var state: RefCounted
var style: RefCounted
var font: Font
var mode: String = ""
var was_paused: bool = false
var buttons: Array[Button] = []
var page_buttons: Array[Button] = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(84, 380)
	menu.add_theme_constant_override("separation", 14)
	add_child(menu)
	var entries: Array = [["继续游戏", close], ["设置", show_settings], ["保存并退出", show_confirm]]
	for i: int in range(entries.size()):
		var button: Button = InkButton.new()
		button.call("setup", entries[i][0], 30, 300 + i, style)
		button.pressed.connect(entries[i][1])
		buttons.append(button)
		menu.add_child(button)

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func text(position: Vector2, value: String, font_size: int, color: Color = Style.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, position, value, align, width, font_size, color)

func clock_visible() -> bool:
	return visible and mode.is_empty()

func open() -> void:
	was_paused = state.paused
	state.paused = true
	visible = true
	_back_to_clock()
	buttons[0].grab_focus()

func close() -> void:
	visible = false
	_clear_page()
	mode = ""
	state.paused = was_paused

func back() -> void:
	if mode.is_empty():
		close()
		return
	var previous: String = mode
	_back_to_clock()
	buttons[1 if previous == "settings" else 2].grab_focus()

func _back_to_clock() -> void:
	mode = ""
	_clear_page()

func _clear_page() -> void:
	for button: Button in page_buttons:
		button.queue_free()
	page_buttons.clear()

func _page_button(value: String, action: Callable, position: Vector2, seed: int) -> Button:
	var button: Button = InkButton.new()
	button.call("setup", value, 26, seed, style)
	button.position = position
	button.custom_minimum_size = Vector2(300, 54)
	button.pressed.connect(action)
	add_child(button)
	page_buttons.append(button)
	return button

func show_settings() -> void:
	_clear_page()
	mode = "settings"
	_page_button("返回", back, Vector2(LEFT_WIDTH + 170, 820), 410).grab_focus()

func show_confirm() -> void:
	_clear_page()
	mode = "confirm"
	_page_button("确认（原型中只关闭菜单）", close, Vector2(LEFT_WIDTH + 170, 600), 420)
	_page_button("取消", back, Vector2(LEFT_WIDTH + 170, 670), 421).grab_focus()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.62))
	Ink.wash(self, Rect2(Vector2.ZERO, size), Color(Style.DUSK_TOP, 0.25 * style.dusk(state)), Color(Style.DUSK_BOTTOM, 0.2 * style.dusk(state)))
	var sheet: Rect2 = Rect2(36, 40, LEFT_WIDTH - 70, size.y - 80)
	style.panel(self, sheet, state, 201)
	text(Vector2(84, 340), "暂停", 46)
	Ink.rough_line(self, Vector2(84, 356), Vector2(250, 356), Color(Style.LIFE, 0.8), 2.4, 202, style.wobble())
	text(Vector2(84, size.y - 90), "第 %d 日 · 末日前 %d 天" % [state.day, state.days_left()], 20, Color(Style.INK, 0.7))
	if mode.is_empty():
		_draw_clock(Vector2(LEFT_WIDTH + (size.x - LEFT_WIDTH) * 0.5, 360))
	elif mode == "settings":
		_draw_settings()
	else:
		_draw_confirm()

func _draw_clock(center: Vector2) -> void:
	var radius: float = 190.0
	Ink.glow(self, center, radius * 0.9, Style.DUSK_BOTTOM, style.glow_strength(state) * style.breath(state))
	Ink.paper_disc(self, center, radius + 16, Color(style.paper_color(state), style.panel_alpha()), 501, style.wobble())
	var g: float = style.glass(state)
	if g > 0.0:
		Ink.paper_disc(self, center, radius + 14, Color(Style.DUSK_TOP.lerp(Style.DUSK_BOTTOM, 0.55), 0.3 * g), 502, 0.0)
	Ink.rough_circle(self, center, radius + 16, Color(Style.INK, 0.9), style.ink_width() + 0.6, 503, style.wobble())
	Ink.rough_circle(self, center, radius - 4, Color(Style.INK, 0.4), 1.4, 504, style.wobble())
	for i: int in range(12):
		var angle: float = -PI / 2.0 + TAU * i / 12.0
		Ink.rough_line(self, center + Vector2.from_angle(angle) * (radius - 30), center + Vector2.from_angle(angle) * (radius - 8), Color(Style.INK, 0.8), 2.4, 510 + i, 0.8)
	var minutes: int = mini(state.clock_minutes(), 24 * 60 - 1)
	var hour_angle: float = -PI / 2.0 + TAU * fmod(minutes / 60.0, 12.0) / 12.0
	var minute_angle: float = -PI / 2.0 + TAU * (minutes % 60) / 60.0
	Ink.rough_line(self, center, center + Vector2.from_angle(hour_angle) * radius * 0.5, Style.INK, 7.0, 530, 0.8)
	Ink.rough_line(self, center, center + Vector2.from_angle(minute_angle) * radius * 0.78, Style.INK, 3.5, 531, 0.8)
	draw_circle(center, 9, Style.SUN)
	var label: Rect2 = Rect2(center + Vector2(-330, radius + 40), Vector2(660, 250))
	style.panel(self, label, state, 540)
	text(label.position + Vector2(0, 64), state.clock_text(), 54, Style.INK, HORIZONTAL_ALIGNMENT_CENTER, label.size.x)
	text(label.position + Vector2(0, 104), "第 %d 日 · 末日前 %d 天" % [state.day, state.days_left()], 26, Style.LIFE, HORIZONTAL_ALIGNMENT_CENTER, label.size.x)
	_draw_days(label.position + Vector2(40, 132), label.size.x - 80)
	text(label.position + Vector2(0, 236), "当前任务：前往营地与幸存者会合（原型占位文字）", 18, Color(Style.INK, 0.7), HORIZONTAL_ALIGNMENT_CENTER, label.size.x)

func _draw_days(origin: Vector2, width: float) -> void:
	var gap: float = 16.0
	var segment: float = (width - gap * 2.0) / 3.0
	for i: int in range(3):
		var a: Vector2 = origin + Vector2(i * (segment + gap), 0)
		Ink.rough_line(self, a, a + Vector2(segment, 0), Color(Style.INK, 0.25), 8.0, 550 + i, 1.0)
		var fill: float = 1.0 if i + 1 < state.day else (state.day_progress() if i + 1 == state.day else 0.0)
		if fill > 0.0:
			Ink.rough_line(self, a, a + Vector2(segment * fill, 0), Style.SUN if i + 1 == state.day else Color(Style.DUSK_BOTTOM, 0.7), 8.0, 560 + i, 1.0)
		text(a + Vector2(0, 38), "第 %d 日" % (i + 1), 20, Style.INK if i + 1 == state.day else Color(Style.INK, 0.5), HORIZONTAL_ALIGNMENT_CENTER, segment)
	if state.day < 3:
		var left: int = int(ceil(state.day_remaining))
		text(origin + Vector2(0, 72), "距下一日 %02d:%02d" % [int(left / 60.0), left % 60], 19, Color(Style.INK, 0.75), HORIZONTAL_ALIGNMENT_CENTER, width)
	else:
		text(origin + Vector2(0, 72), "最后一日", 19, Style.LIFE, HORIZONTAL_ALIGNMENT_CENTER, width)

func _page(title: String) -> Rect2:
	var sheet: Rect2 = Rect2(LEFT_WIDTH + 120, 120, size.x - LEFT_WIDTH - 240, 800)
	style.panel(self, sheet, state, 600)
	text(sheet.position + Vector2(50, 78), title, 38)
	Ink.rough_line(self, sheet.position + Vector2(50, 94), sheet.position + Vector2(220, 94), Color(Style.LIFE, 0.8), 2.4, 601, style.wobble())
	return sheet

func _draw_settings() -> void:
	var sheet: Rect2 = _page("设置")
	var rows: Array = [["总音量", 0.7], ["效果音量", 0.6], ["背景音量", 0.5], ["分辨率", "1920 × 1080"], ["显示模式", "全屏 / 窗口"], ["帧率", "60"], ["按键列表", "（自定义按键在 V0.1 之后）"]]
	for i: int in range(rows.size()):
		var y: float = sheet.position.y + 160 + i * 64
		text(Vector2(sheet.position.x + 60, y), rows[i][0], 26)
		var value: Variant = rows[i][1]
		if value is float:
			var a: Vector2 = Vector2(sheet.position.x + 260, y - 9)
			Ink.rough_line(self, a, a + Vector2(360, 0), Color(Style.INK, 0.3), 6.0, 610 + i, 0.8)
			Ink.rough_line(self, a, a + Vector2(360 * float(value), 0), Style.POSSIBILITY, 6.0, 620 + i, 0.8)
			draw_circle(a + Vector2(360 * float(value), 0), 9, Style.SUN)
		else:
			text(Vector2(sheet.position.x + 260, y), str(value), 24, Color(Style.INK, 0.85))
	text(Vector2(sheet.position.x + 60, sheet.end.y - 40), "原型占位：二级界面打开时覆盖右侧时钟；正式内容见 BL-047（A-017）", 17, Color(Style.INK, 0.6))

func _draw_confirm() -> void:
	var sheet: Rect2 = _page("保存并退出？")
	text(Vector2(sheet.position.x + 60, sheet.position.y + 190), "将保存进度并回到最近的检查点。", 28)
