extends Control
## Prototype pause menu (user idea, 2026-10-20): options on the left; the right
## shows the clock and day progress; a secondary page (settings, confirm)
## covers the clock. Placeholder content only - formal menus are BL-046/BL-047.
const PauseClock = preload("res://prototypes/EXP-001/pause_clock.gd")
const LEFT_WIDTH: float = 560.0

var state: RefCounted
var mode: String = ""
var was_paused: bool = false
var buttons: Array[Button] = []
var clock: Control
var page: PanelContainer
var page_title: Label
var page_body: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(90, 330)
	menu.add_theme_constant_override("separation", 18)
	add_child(menu)
	menu.add_child(_label("暂停", 44))
	for entry: Array in [["继续游戏", close], ["设置", show_settings], ["保存并退出", show_confirm]]:
		var button: Button = _button(entry[0], entry[1])
		buttons.append(button)
		menu.add_child(button)
	clock = PauseClock.new()
	clock.state = state
	clock.position = Vector2(LEFT_WIDTH, 0)
	clock.size = Vector2(1920 - LEFT_WIDTH, 1080)
	add_child(clock)
	page = PanelContainer.new()
	page.position = Vector2(LEFT_WIDTH + 120, 140)
	page.size = Vector2(1920 - LEFT_WIDTH - 240, 800)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.96)
	style.border_color = Color(1, 1, 1, 0.2)
	style.set_border_width_all(2)
	style.set_content_margin_all(48)
	page.add_theme_stylebox_override("panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	page_title = _label("", 36)
	page_body = VBoxContainer.new()
	page_body.add_theme_constant_override("separation", 16)
	column.add_child(page_title)
	column.add_child(page_body)
	page.add_child(column)
	page.visible = false
	add_child(page)

func _label(value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button(value: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(360, 64)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(action)
	return button

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
		clock.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.02, 0.7))
	draw_rect(Rect2(0, 0, LEFT_WIDTH, size.y), Color(0.03, 0.04, 0.06, 0.9))
	draw_line(Vector2(LEFT_WIDTH, 0), Vector2(LEFT_WIDTH, size.y), Color(1, 1, 1, 0.15), 2.0)

func open() -> void:
	was_paused = state.paused
	state.paused = true
	visible = true
	_back_to_clock()
	buttons[0].grab_focus()

func close() -> void:
	visible = false
	mode = ""
	state.paused = was_paused

## Esc: leave a secondary page first, otherwise close the menu.
func back() -> void:
	if mode.is_empty():
		close()
		return
	var previous: String = mode
	_back_to_clock()
	buttons[1 if previous == "settings" else 2].grab_focus()

func _back_to_clock() -> void:
	mode = ""
	page.visible = false
	clock.visible = true

func _open_page(name: String, title: String) -> void:
	mode = name
	clock.visible = false
	page.visible = true
	page_title.text = title
	for child: Node in page_body.get_children():
		child.queue_free()

func show_settings() -> void:
	_open_page("settings", "设置")
	for row: String in ["总音量　　▮▮▮▮▮▮▮▯▯▯", "效果音量　▮▮▮▮▮▮▯▯▯▯", "背景音量　▮▮▮▮▮▯▯▯▯▯", "分辨率　　1920 × 1080", "显示模式　全屏 / 窗口", "帧率　　　60", "按键列表　（自定义按键在 V0.1 之后）"]:
		page_body.add_child(_label(row, 26))
	page_body.add_child(_label("原型占位：二级界面打开时覆盖右侧时钟；正式内容见 BL-047（A-017）", 18))
	var back_button: Button = _button("返回", back)
	page_body.add_child(back_button)
	back_button.grab_focus()

func show_confirm() -> void:
	_open_page("confirm", "保存并退出？")
	page_body.add_child(_label("将保存进度并回到最近的检查点。", 26))
	var confirm: Button = _button("确认（原型中只关闭菜单）", close)
	var cancel: Button = _button("取消", back)
	page_body.add_child(confirm)
	page_body.add_child(cancel)
	cancel.grab_focus()
