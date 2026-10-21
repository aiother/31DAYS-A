extends "res://tests/acceptance/ui002_hud.gd"
## UI-003 adapter: the same isolated slot fixtures as UI-002, aimed at the
## pause menu on the first day, the third day and during the final battle.
const DAY_ONE: float = 1100.0

func configuration() -> Dictionary:
	return {"id":"UI-003", "marker":"UI003_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:fixture(1, DAY_ONE), 2:fixture(3, LONG_BUDGET), 3:fixture(3, SHORT_BUDGET)}, "enter":false,
		"instructions":"UI-003 独立临时存档（关闭窗口自动清理）\n槽1 第1日：Esc 打开暂停菜单，看右侧时钟、三天进度、距下一日\n槽2 第3日：同上；向右进入中心战场后再暂停，看最终战剩余\n槽3 第3日剩9:12：进入中心战场后暂停\n方向键 / 手柄十字键 / 鼠标都试一下；设置与保存并退出会盖住时钟"}

func self_test() -> void:
	check((panel == null) or ((panel.get_node("ReadOnlyStatus") as Label).position == PANEL_POSITION), "slot menu instructions sit clear of the HUD")
	await load_slot(1)
	session.ui.call("show_pause")
	await frames(3)
	var menu: PauseMenu = session.ui.get("_pause") as PauseMenu
	check(menu.visible and menu.drawn.has("clock") and menu.drawn["clock"]["date"] == "第 1 日 · 末日前 3 天", "slot 1 pause shows the clock on the first day")
	await capture("pause-day1")
	session.ui.call("show_settings")
	await frames(3)
	check(menu.page == "settings" and not menu.drawn.has("clock"), "settings page covers the clock")
	await capture("pause-settings")
	session.ui.call("resume_game")
	await load_slot(3)
	await enter_battlefield()
	session.ui.call("show_pause")
	await frames(3)
	menu = session.ui.get("_pause") as PauseMenu
	check(menu.drawn.has("clock") and str(menu.drawn["clock"]["next"]).begins_with("最终战剩余"), "slot 3 final battle pause shows the final remainder")
	await capture("pause-final")
	session.ui.call("resume_game")
