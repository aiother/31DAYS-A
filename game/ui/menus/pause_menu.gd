class_name PauseMenu
extends Control
## Formal pause menu (UI-003): EXP-001 variant four layout in the EXP-002 sample
## two look. Options on a paper sheet at the left; the right shows the clock,
## the three days and the current task, and a secondary page (settings, save
## and quit) covers the clock while it is open. LifeUI owns every action; this
## node only lays out, draws and routes focus.
## A secondary page closed and the clock is showing again.
signal returned
const LEFT_WIDTH: float = 560.0
const CLOCK_CENTER_Y: float = 360.0
const CLOCK_RADIUS: float = 190.0
const PAGE: Rect2 = Rect2(LEFT_WIDTH + 120, 120, 1920 - LEFT_WIDTH - 240, 800)

var session: Node
var hud: FormalHud
var font: Font
## "" shows the clock; "settings" and "confirm" cover it.
var page: String = ""
var buttons: Array[InkButton] = []
var _actions: Dictionary = {}
var _page_nodes: Array[Control] = []
var _return_focus: int = 0
var _error_text: String = ""
## What the last _draw put on screen; read by tests.
var drawn: Dictionary = {}

## actions: {"continue", "settings", "slots" (optional), "quit"} -> Callable;
## "quit_label" names the last option (保存并退出 when the session can save).
func setup(owner_session: Node, formal_hud: FormalHud, actions: Dictionary) -> void:
	session = owner_session
	hud = formal_hud
	_actions = actions
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(84, 380)
	menu.add_theme_constant_override("separation", 14)
	add_child(menu)
	var entries: Array = [["继续游戏", "continue"], ["设置", "settings"]]
	if actions.has("slots"):
		entries.append(["存档槽", "slots"])
	entries.append([str(actions.get("quit_label", "保存并退出")), "quit"])
	for i: int in range(entries.size()):
		var button: InkButton = InkButton.new().setup(entries[i][0], 30, 300 + i)
		button.pressed.connect(_actions[entries[i][1]])
		buttons.append(button)
		menu.add_child(button)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = UiTheme.font()
	visible = false

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func button(title: String) -> InkButton:
	for item: InkButton in buttons:
		if item.text == title:
			return item
	return null

func time_state() -> Dictionary:
	if session != null and session.has_method("ui_time_state"):
		return session.call("ui_time_state")
	return {}

func open() -> void:
	visible = true
	_show_clock()
	buttons[0].grab_focus()

func close() -> void:
	visible = false
	_clear_page()
	page = ""

## Back from a secondary page to the clock, focusing the option that opened it.
func back() -> void:
	if page.is_empty():
		return
	_show_clock()
	buttons[_return_focus].grab_focus()
	returned.emit()

func show_settings() -> void:
	_open_page("settings", buttons.find(button("设置")))
	var volume: HSlider = HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.value = AudioServer.get_bus_volume_linear(0) * 100.0
	volume.value_changed.connect(func(value: float) -> void: AudioServer.set_bus_volume_linear(0, value / 100.0))
	_place(volume, Vector2(260, 150), Vector2(420, 36))
	var resolution: OptionButton = OptionButton.new()
	resolution.add_item("1280 × 720")
	resolution.add_item("1920 × 1080")
	resolution.select(1 if DisplayServer.window_get_size().x >= 1920 else 0)
	resolution.item_selected.connect(func(index: int) -> void: DisplayServer.window_set_size(Vector2i(1280, 720) if index == 0 else Vector2i(1920, 1080)))
	_place(resolution, Vector2(260, 220), Vector2(300, 50))
	var fullscreen: CheckButton = CheckButton.new()
	fullscreen.text = "全屏"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool) -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	_place(fullscreen, Vector2(260, 296), Vector2(300, 50))
	_page_button("返回", back, Vector2(60, 690)).grab_focus()

## error_text: the last save failure, shown on the page because the pause
## sheet covers LifeUI's own error prompt.
func show_confirm(confirm: Callable, error_text: String = "") -> void:
	_open_page("confirm", buttons.size() - 1)
	_error_text = error_text
	_page_button(str(_actions.get("quit_label", "保存并退出")), confirm, Vector2(60, 330))
	_page_button("返回", back, Vector2(60, 400)).grab_focus()

func set_error(error_text: String) -> void:
	_error_text = error_text

func _open_page(name: String, return_focus: int) -> void:
	_clear_page()
	page = name
	_return_focus = maxi(0, return_focus)

func _show_clock() -> void:
	_clear_page()
	page = ""
	_error_text = ""

func _clear_page() -> void:
	for node: Control in _page_nodes:
		node.queue_free()
	_page_nodes.clear()

func _place(control: Control, offset: Vector2, size_px: Vector2) -> void:
	control.theme = UiTheme.get_theme()
	control.position = PAGE.position + offset
	control.custom_minimum_size = size_px
	control.size = size_px
	add_child(control)
	_page_nodes.append(control)

func _page_button(value: String, action: Callable, offset: Vector2) -> InkButton:
	var item: InkButton = InkButton.new().setup(value, 26, 410 + _page_nodes.size())
	item.pressed.connect(action)
	_place(item, offset, Vector2(360, 56))
	return item

func ink_text(at: Vector2, value: String, size_px: int, color: Color = DuskStyle.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, at, value, align, width, size_px, color)

func _draw() -> void:
	var time: Dictionary = time_state()
	drawn = {"page": page, "font": font.resource_path}
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.62))
	var dusk: float = DuskStyle.dusk(time)
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), Color(DuskStyle.DUSK_TOP, 0.25 * dusk), Color(DuskStyle.DUSK_BOTTOM, 0.2 * dusk))
	var sheet: Rect2 = Rect2(36, 40, LEFT_WIDTH - 70, size.y - 80)
	_solid_panel(sheet, time, 201)
	ink_text(Vector2(84, 340), "暂停", UiTheme.SIZE_TITLE)
	InkDraw.rough_line(self, Vector2(84, 356), Vector2(250, 356), Color(DuskStyle.LIFE, 0.8), 2.4, 202, DuskStyle.WOBBLE)
	drawn["sheet"] = sheet
	if page.is_empty():
		var quest: String = str(session.call("quest_status_text")) if session != null and session.has_method("quest_status_text") else ""
		drawn["quest"] = quest
		var center: Vector2 = Vector2(LEFT_WIDTH + (size.x - LEFT_WIDTH) * 0.5, CLOCK_CENTER_Y)
		if bool(time.get("has_session", false)):
			_draw_clock(time, center, quest)
		elif not quest.is_empty():
			# Sessions without the day clock still show the current task.
			var tag: Rect2 = Rect2(center + Vector2(-330, -40), Vector2(660, 80))
			_solid_panel(tag, time, 545)
			ink_text(tag.position + Vector2(0, 50), "当前任务：" + quest, UiTheme.SIZE_SMALL, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
	elif page == "settings":
		_draw_settings(time)
	else:
		_draw_confirm(time)

func _draw_clock(time: Dictionary, center: Vector2, quest: String) -> void:
	var radius: float = CLOCK_RADIUS
	InkDraw.glow(self, center, radius * 0.9, DuskStyle.DUSK_BOTTOM, DuskStyle.glow_strength(time) * DuskStyle.breath(time, Time.get_ticks_msec() / 1000.0))
	InkDraw.paper_disc(self, center, radius + 16, Color(DuskStyle.paper_color(time), DuskStyle.PANEL_ALPHA), 501, DuskStyle.WOBBLE)
	InkDraw.paper_disc(self, center, radius + 14, Color(DuskStyle.DUSK_TOP.lerp(DuskStyle.DUSK_BOTTOM, 0.55), 0.3 * DuskStyle.glass(time)), 502, 0.0)
	InkDraw.rough_circle(self, center, radius + 16, Color(DuskStyle.INK, 0.9), DuskStyle.INK_WIDTH + 0.6, 503, DuskStyle.WOBBLE)
	InkDraw.rough_circle(self, center, radius - 4, Color(DuskStyle.INK, 0.4), 1.4, 504, DuskStyle.WOBBLE)
	for i: int in range(12):
		var angle: float = -PI / 2.0 + TAU * i / 12.0
		InkDraw.rough_line(self, center + Vector2.from_angle(angle) * (radius - 30), center + Vector2.from_angle(angle) * (radius - 8), Color(DuskStyle.INK, 0.8), 2.4, 510 + i, 0.8)
	# Same in-game clock as the HUD's horizon tag.
	var clock: String = hud.clock_text(time)
	var minutes: int = int(clock.substr(0, 2)) * 60 + int(clock.substr(3, 2))
	var hour_angle: float = -PI / 2.0 + TAU * fmod(minutes / 60.0, 12.0) / 12.0
	var minute_angle: float = -PI / 2.0 + TAU * (minutes % 60) / 60.0
	InkDraw.rough_line(self, center, center + Vector2.from_angle(hour_angle) * radius * 0.5, DuskStyle.INK, 7.0, 530, 0.8)
	InkDraw.rough_line(self, center, center + Vector2.from_angle(minute_angle) * radius * 0.78, DuskStyle.INK, 3.5, 531, 0.8)
	draw_circle(center, 9, DuskStyle.SUN)
	var day: int = int(time["day"])
	var label: Rect2 = Rect2(center + Vector2(-330, radius + 40), Vector2(660, 250))
	_solid_panel(label, time, 540)
	var date: String = "第 %d 日 · 末日前 %d 天" % [day, hud.days_left(day)]
	ink_text(label.position + Vector2(0, 64), clock, 54, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, label.size.x)
	ink_text(label.position + Vector2(0, 104), date, 26, DuskStyle.LIFE, HORIZONTAL_ALIGNMENT_CENTER, label.size.x)
	var record: Dictionary = {"time": clock, "date": date, "rect": Rect2(center - Vector2.ONE * (radius + 16), Vector2.ONE * (radius + 16) * 2.0).merge(label)}
	record.merge(_draw_days(time, label.position + Vector2(40, 132), label.size.x - 80))
	if not quest.is_empty():
		ink_text(label.position + Vector2(0, 236), "当前任务：" + quest, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.7), HORIZONTAL_ALIGNMENT_CENTER, label.size.x)
	record["quest"] = quest
	drawn["clock"] = record

func _draw_days(time: Dictionary, origin: Vector2, width: float) -> Dictionary:
	var day: int = int(time["day"])
	var gap: float = 16.0
	var segment: float = (width - gap * 2.0) / 3.0
	var fills: Array[float] = []
	for i: int in range(3):
		var a: Vector2 = origin + Vector2(i * (segment + gap), 0)
		InkDraw.rough_line(self, a, a + Vector2(segment, 0), Color(DuskStyle.INK, 0.25), 8.0, 550 + i, 1.0)
		var fill: float = 1.0 if i + 1 < day else (float(time.get("day_progress", 0.0)) if i + 1 == day else 0.0)
		if fill > 0.0:
			InkDraw.rough_line(self, a, a + Vector2(segment * fill, 0), DuskStyle.SUN if i + 1 == day else Color(DuskStyle.DUSK_BOTTOM, 0.7), 8.0, 560 + i, 1.0)
		fills.append(fill)
		ink_text(a + Vector2(0, 38), "第 %d 日" % (i + 1), 20, DuskStyle.INK if i + 1 == day else Color(DuskStyle.INK, 0.5), HORIZONTAL_ALIGNMENT_CENTER, segment)
	var next: String
	var color: Color = Color(DuskStyle.INK, 0.75)
	if bool(time.get("final_active", false)):
		var left: int = ceili(float(time.get("final_remaining", 0.0)))
		next = "最终战剩余 %02d:%02d" % [int(left / 60.0), left % 60]
		color = DuskStyle.LIFE
	elif day < 3:
		var left: int = ceili(float(time.get("day_remaining", 0.0)))
		next = "距下一日 %02d:%02d" % [int(left / 60.0), left % 60]
	else:
		next = "最后一日"
		color = DuskStyle.LIFE
	ink_text(origin + Vector2(0, 72), next, 19, color, HORIZONTAL_ALIGNMENT_CENTER, width)
	return {"days": fills, "next": next}

## Menu sheets carry reading text, so the HUD and room labels must not show
## through: an opaque paper backing goes under the usual translucent panel.
func _solid_panel(rect: Rect2, time: Dictionary, seed: int) -> void:
	InkDraw.paper(self, rect, Color(DuskStyle.paper_color(time), 0.92), seed + 1000, DuskStyle.WOBBLE, 0)
	DuskStyle.panel(self, rect, time, seed)

func _page_sheet(time: Dictionary, title: String) -> void:
	_solid_panel(PAGE, time, 600)
	ink_text(PAGE.position + Vector2(50, 78), title, 38)
	InkDraw.rough_line(self, PAGE.position + Vector2(50, 94), PAGE.position + Vector2(220, 94), Color(DuskStyle.LIFE, 0.8), 2.4, 601, DuskStyle.WOBBLE)
	drawn["page_rect"] = PAGE

func _draw_settings(time: Dictionary) -> void:
	_page_sheet(time, "设置")
	for row: Array in [["音量", 176], ["窗口尺寸", 254], ["显示", 330]]:
		ink_text(PAGE.position + Vector2(60, row[1]), row[0], UiTheme.SIZE_BODY)
	ink_text(PAGE.position + Vector2(60, 440), "分开音量、帧率与按键列表将在后续版本加入。", UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.6))

func _draw_confirm(time: Dictionary) -> void:
	_page_sheet(time, "%s？" % str(_actions.get("quit_label", "保存并退出")))
	ink_text(PAGE.position + Vector2(60, 190), "保存当前进度并退出游戏；下次从最近的检查点继续。", 26)
	if not _error_text.is_empty():
		ink_text(PAGE.position + Vector2(60, 250), _error_text, UiTheme.SIZE_SMALL, DuskStyle.LIFE, HORIZONTAL_ALIGNMENT_LEFT, PAGE.size.x - 120)
	drawn["error"] = _error_text
