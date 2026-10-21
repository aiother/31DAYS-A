extends "res://prototypes/EXP-003/screen_base.gd"
## Stand-in for “in game”, only to walk every 返回标题 path the formal flow
## needs: pause (UI-003 adds the option once the main menu exists), death
## (A-014), the V0.1 ending (T7 夕阳将至) and the final battle timeout (A-011).
## K: simulate death · F: simulate the ending · T: simulate a timeout · Esc: pause.
var slot: int = 0
var page: String = ""
var menu: VBoxContainer
var played: float = 0.0

func build() -> void:
	menu = VBoxContainer.new()
	menu.position = Vector2(760, 560)
	menu.add_theme_constant_override("separation", 10)
	add_child(menu)
	played = float((data.slots[slot] as Dictionary).get("play_seconds", 0.0))

func _process(delta: float) -> void:
	super._process(delta)
	if page.is_empty():
		played += delta

func open_page(name: String) -> void:
	for button: Button in buttons:
		button.queue_free()
	buttons.clear()
	page = name
	match name:
		"pause":
			make_button(menu, "继续游戏", func() -> void: open_page(""))
			make_button(menu, "返回标题", func() -> void: ask("保存并返回标题？\n下次从最近的检查点继续", "返回标题", _to_title))
		"death":
			make_button(menu, "从检查点继续", func() -> void: open_page(""))
			make_button(menu, "返回标题", _to_title)
			make_button(menu, "设置", func() -> void: ask("设置界面在第五批正式实现", "知道了", func() -> void: pass))
			make_button(menu, "退出游戏", func() -> void: ask("退出游戏？", "退出", func() -> void: preview.call("quit_prototype")))
		"end":
			data.call("complete", slot)
			make_button(menu, "返回标题", _to_title)
		"timeout":
			make_button(menu, "重试最终战", func() -> void: open_page(""))
			make_button(menu, "返回标题", _to_title)
	focus_first()

func _to_title() -> void:
	(data.slots[slot] as Dictionary)["play_seconds"] = played
	preview.call("open_title")

func back() -> void:
	if page.is_empty():
		open_page("pause")
	elif page == "pause":
		open_page("")

func _unhandled_key_input(event: InputEvent) -> void:
	if not page.is_empty() or dialog != null or not (event is InputEventKey) or not event.pressed:
		return
	match (event as InputEventKey).keycode:
		KEY_K: open_page("death")
		KEY_F: open_page("end")
		KEY_T: open_page("timeout")

func _draw() -> void:
	var slot_data: Dictionary = data.slots[slot]
	var time: Dictionary = {"day": int(slot_data.get("day", 1)), "day_progress": float(slot_data.get("day_progress", 0.0))}
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.10, 0.13))
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), Color(DuskStyle.DUSK_TOP, 0.4 * DuskStyle.dusk(time)), Color(DuskStyle.DUSK_BOTTOM, 0.3 * DuskStyle.dusk(time)))
	draw_rect(Rect2(0, size.y * 0.8, size.x, size.y * 0.2), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(420, size.y * 0.8 - 90, 50, 90), Color(0.5, 0.85, 0.85))
	ink_text(Vector2(0, 160), "（原型）游戏中 · 槽 %d · 第 %d 日" % [slot + 1, int(time["day"])], UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	ink_text(Vector2(0, 210), "Esc 暂停 · K 模拟死亡 · F 模拟通关 · T 模拟最终战超时", UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	drawn.erase("page_title")
	if page.is_empty():
		return
	var titles: Dictionary = {"pause": "已暂停", "death": "你倒下了", "end": "夕阳将至", "timeout": "未来已失"}
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.03, 0.7 if page != "end" else 0.85))
	var sheet: Rect2 = Rect2(660, 300, 600, 520)
	InkDraw.paper(self, sheet, Color(DuskStyle.paper_color(MOOD), 0.95), 140, DuskStyle.WOBBLE, 6)
	DuskStyle.panel(self, sheet, MOOD, 141)
	draw_recorded(self, "page_title", sheet.position + Vector2(0, 110), str(titles[page]), UiTheme.SIZE_TITLE, DuskStyle.LIFE if page in ["death", "timeout"] else DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x)
	if page in ["end", "timeout"]:
		ink_text(sheet.position + Vector2(0, 170), "游玩时长 " + Slots.play_time(played), UiTheme.SIZE_BODY, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x)
	if page == "pause":
		ink_text(sheet.position + Vector2(0, 170), "正式暂停菜单见 UI-003；主界面完成后加入“返回标题”", UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.6), HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x)
