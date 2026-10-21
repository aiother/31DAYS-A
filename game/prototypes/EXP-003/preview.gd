extends Control
## EXP-003 preview: main menu variants A/B/C and slot selection variants 1/2,
## wired into the full flow 主界面 → 存档选择 → 游戏 → 返回标题 with mock data.
## Nothing here touches real saves, scenes or project settings.
const Slots = preload("res://prototypes/EXP-003/mock_slots.gd")
const TITLES: Array[Script] = [preload("res://prototypes/EXP-003/title_dusk.gd"), preload("res://prototypes/EXP-003/title_page.gd"), preload("res://prototypes/EXP-003/title_blur.gd")]
const SLOT_VIEWS: Array[Script] = [preload("res://prototypes/EXP-003/slots_bookmark.gd"), preload("res://prototypes/EXP-003/slots_cards.gd")]
const GAME: Script = preload("res://prototypes/EXP-003/game_stub.gd")
const HELP: String = "EXP-003 原型（H 隐藏）\n1 / 2 / 3  主界面方案 A / B / C\n4 / 5  存档选择方案 1 / 2\nN  切换“没有任何存档”\nB  切换槽三为“无法读取”\nR  重置模拟存档\n方向键 / 手柄 / 鼠标 操作菜单\nEnter / A 确认 · Esc 返回"

var data: RefCounted = Slots.new()
var title_index: int = 0
var slot_index: int = 0
var screen: Control
var where: String = ""
var slots_mode: String = "continue"
var help: Label
## Set by tests so quitting does not end the run.
var quit_handler: Callable

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quit_handler = get_tree().quit
	help = Label.new()
	help.theme = UiTheme.get_theme()
	help.text = HELP
	help.position = Vector2(1520, 24)
	help.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	help.add_theme_color_override("font_color", Color(DuskStyle.PAPER_DAY, 0.85))
	help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	help.add_theme_constant_override("outline_size", 6)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)
	open_title()

func _swap(next: Control, name: String) -> void:
	if screen != null:
		screen.queue_free()
	screen = next
	where = name
	screen.set("preview", self)
	screen.set("data", data)
	add_child(screen)
	move_child(screen, 0)

func open_title() -> void:
	_swap(TITLES[title_index].new(), "title")

func open_slots(mode: String) -> void:
	slots_mode = mode
	var next: Control = SLOT_VIEWS[slot_index].new()
	next.set("mode", mode)
	_swap(next, "slots")

func start_game(index: int) -> void:
	var next: Control = GAME.new()
	next.set("slot", index)
	_swap(next, "game")

func quit_prototype() -> void:
	quit_handler.call()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_1, KEY_2, KEY_3:
			title_index = (event as InputEventKey).keycode - KEY_1
			if where == "title":
				open_title()
		KEY_4, KEY_5:
			slot_index = (event as InputEventKey).keycode - KEY_4
			if where == "slots":
				open_slots(slots_mode)
		KEY_N:
			if data.call("has_any"):
				data.call("clear_all")
			else:
				data.call("reset")
			if where == "title":
				open_title()
		KEY_B:
			data.call("toggle_unreadable")
		KEY_R:
			data.call("reset")
			if where != "game":
				open_title()
		KEY_H:
			help.visible = not help.visible
		_:
			return
	get_viewport().set_input_as_handled()
