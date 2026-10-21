class_name TitleScreen
extends MenuScreen
## UI-004 main menu, EXP-003 variant A · 黄昏远景 (user, 2026-10-21): a dusk
## sky over two layers of ruined skyline, a low sun with its glow, drifting
## dust. The title takes the upper third; the menu sits centred below.
## Continue only shows when a save exists, and then has the focus.
const TITLE: String = "末日前31天"
## The title screen keeps one fixed dusk: day three, late afternoon.
const MOOD: Dictionary = {"day": 3, "day_progress": 0.55}

var menu: VBoxContainer

func _ready() -> void:
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	add_child(menu)

## actions: {"new", "continue", "settings", "quit"} -> Callable.
func open(has_save: bool, actions: Dictionary) -> void:
	close_dialog(false)
	clear_buttons()
	set_prompt("")
	light_button(menu, "新游戏", actions["new"])
	if has_save:
		light_button(menu, "继续游戏", actions["continue"])
	light_button(menu, "设置", actions["settings"])
	light_button(menu, "退出游戏", func() -> void: ask("退出游戏？", "退出", actions["quit"], buttons[-1]))
	drawn["menu"] = buttons.map(func(item: Button) -> String: return item.text)
	visible = true
	_place_menu()
	# Continue is the likely choice whenever a save exists.
	(buttons[1] if has_save else buttons[0]).grab_focus()

func button(title: String) -> Button:
	for item: Button in buttons:
		if item.text == title:
			return item
	return null

func sheet_time() -> Dictionary:
	return MOOD

func title_rect() -> Rect2:
	return Rect2(0, 0, size.x, size.y / 3.0)

func _place_menu() -> void:
	menu.reset_size()
	menu.position = Vector2((size.x - 320.0) * 0.5, size.y * 0.37)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and menu != null:
		_place_menu()

func _draw() -> void:
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), DuskStyle.DUSK_TOP.darkened(0.35), DuskStyle.DUSK_BOTTOM)
	var sun: Vector2 = Vector2(size.x * 0.5, size.y * 0.66)
	InkDraw.glow(self, sun, 220, DuskStyle.SUN, 1.3 + 0.1 * sin(clock * 0.8))
	draw_circle(sun, 90, Color(DuskStyle.SUN, 0.85))
	_skyline(size.y * 0.72, 0.45, 11, Color(0.30, 0.15, 0.20, 0.75))
	_skyline(size.y * 0.80, 0.75, 29, Color(0.13, 0.07, 0.10, 0.95))
	draw_rect(Rect2(0, size.y * 0.86, size.x, size.y * 0.14), Color(0.07, 0.04, 0.06, 1.0))
	# Low haze over the ruins.
	InkDraw.wash(self, Rect2(0, size.y * 0.55, size.x, size.y * 0.25), Color(DuskStyle.DUSK_BOTTOM, 0.0), Color(DuskStyle.PAPER_DUSK, 0.18))
	for i: int in range(48):
		var x: float = fposmod(InkDraw.noise(i, 5) * size.x + clock * (8.0 + InkDraw.noise(i, 6) * 18.0), size.x)
		var y: float = fposmod(InkDraw.noise(i, 7) * size.y - clock * (4.0 + InkDraw.noise(i, 8) * 6.0), size.y)
		draw_circle(Vector2(x, y), 1.2 + InkDraw.noise(i, 9) * 1.8, Color(DuskStyle.PAPER_DAY, 0.25))
	var title: Rect2 = title_rect()
	var baseline: float = title.end.y - 92
	draw_string(font, Vector2(4, baseline + 5), TITLE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 132, Color(0, 0, 0, 0.35))
	var shown: Dictionary = ink(self, Vector2(0, baseline), TITLE, 132, DuskStyle.PAPER_DAY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	var text_size: Vector2 = font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, 132)
	var text_rect: Rect2 = Rect2(Vector2((size.x - text_size.x) * 0.5, baseline - font.get_ascent(132)), text_size)
	InkDraw.rough_line(self, Vector2(size.x * 0.5 - 220, title.end.y - 64), Vector2(size.x * 0.5 + 220, title.end.y - 64), Color(DuskStyle.LIFE, 0.85), 3.0, 41, 1.2)
	draw_string(font, Vector2(0, title.end.y - 22), "V0.1", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7))
	drawn["title"] = {"text": shown["text"], "rect": text_rect, "band": title, "font": font.resource_path}
	drawn["menu_rect"] = menu.get_rect()
	draw_prompt(MOOD)

## Broken building silhouettes with ragged tops, deterministic per seed.
func _skyline(base: float, height: float, seed: int, color: Color) -> void:
	var x: float = -20.0
	var i: int = 0
	while x < size.x + 40.0:
		var w: float = 60.0 + InkDraw.noise(i, seed) * 90.0
		var h: float = (90.0 + InkDraw.noise(i, seed + 1) * 300.0) * height
		var top: float = base - h
		var broken: float = InkDraw.noise(i, seed + 2) * 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, base + 200), Vector2(x, top + broken), Vector2(x + w * 0.4, top), Vector2(x + w * 0.55, top + broken * 0.6), Vector2(x + w, top + broken * 1.4), Vector2(x + w, base + 200)]), color)
		x += w + InkDraw.noise(i, seed + 3) * 20.0
		i += 1
