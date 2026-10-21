extends "res://prototypes/EXP-003/screen_base.gd"
## Main menu shared logic (T7-A): title in the upper third; 新游戏、继续游戏
## (only when a save exists)、设置、退出游戏. New game is confirmed on the slot
## screen, where the slot it overwrites is known. Variants only lay out and draw.
const TITLE: String = "末日前31天"

## Subclasses return the container the menu buttons go into.
func menu_container() -> Container:
	return VBoxContainer.new()

func button_tone() -> String:
	return "ink"

func build() -> void:
	var menu: Container = menu_container()
	add_child(menu)
	make_button(menu, "新游戏", func() -> void: preview.call("open_slots", "new"), 32, button_tone())
	if data.call("has_any"):
		make_button(menu, "继续游戏", func() -> void: preview.call("open_slots", "continue"), 32, button_tone())
	make_button(menu, "设置", func() -> void: ask("设置界面在第五批正式实现\n（接 SYS-007 的设置数据）", "知道了", func() -> void: pass), 32, button_tone())
	make_button(menu, "退出游戏", func() -> void: ask("退出游戏？", "退出", func() -> void: preview.call("quit_prototype")), 32, button_tone())
	drawn["menu"] = buttons.map(func(item: Button) -> String: return item.text)
	# Continue is the likely choice whenever a save exists.
	(buttons[1] if buttons.size() == 4 else buttons[0]).grab_focus.call_deferred()

func title_rect() -> Rect2:
	return Rect2(0, 0, size.x, size.y / 3.0)
