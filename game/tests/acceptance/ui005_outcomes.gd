extends "res://tests/acceptance/ui002_hud.gd"
## UI-005 adapter: death, ending and timeout sheets and the pause menu's
## 返回标题 on isolated slots. Opens on the title.
## Slot 1: day one (F5 in play: die). Slot 2: final battle timeout with its
## budget. Slot 3: third-day exploration timeout; on the title F3 makes it the
## zero-budget timeout, F4 the V0.1 ending, F2 the exploration timeout again.
var _title_shown: bool = false

func configuration() -> Dictionary:
	return {"id":"UI-005", "marker":"UI005_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:day_one(), 2:outcome("timeout"), 3:outcome("explore_timeout")}, "enter":false,
		"instructions":"UI-005 独立临时存档（关闭窗口自动清理）\n槽1 第1日：进入后 F5 倒下 → 死亡界面；Esc → 返回标题\n槽2 最终战超时（可重试）· 槽3 第三日探索超时\n主界面上：F3 槽3改为无预算超时 · F4 槽3改为V0.1结束 · F2 改回探索超时\n方向键 / 十字键 / 鼠标都试一下"}

func day_one() -> Dictionary:
	var snapshot: Dictionary = fixture(1, DAY_ONE_LEFT)
	snapshot["play_seconds"] = 3725.0
	return snapshot

func outcome(kind: String) -> Dictionary:
	var snapshot: Dictionary = fixture(3, LONG_BUDGET)
	snapshot["play_seconds"] = 3725.0
	match kind:
		"explore_timeout":
			snapshot["day3_remaining"] = 0.0
		"timeout", "timeout_zero":
			FinalClock.start(snapshot)
			snapshot["events"][FinalClock.TIMEOUT] = true
			snapshot["final_remaining"] = 0.0
			if kind == "timeout_zero":
				snapshot["final_budget"] = 0.0
				snapshot["day3_remaining"] = 0.0
		"talk":
			FinalClock.start(snapshot)
			for flag: String in [FinalClock.WON, FinalClock.TALK]:
				snapshot["events"][flag] = true
	return snapshot

## The shared harness opens the slot screen once fixtures are written; this
## adapter starts on the title instead.
func capture(label: String) -> void:
	if label == "slots" and not _title_shown:
		_title_shown = true
		session.ui.call("show_title")
		await frames(3)
		label = "title"
	await super.capture(label)

func _unhandled_key_input(event: InputEvent) -> void:
	if finishing or not is_instance_valid(session) or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: Key = (event as InputEventKey).keycode
	if code == KEY_F5 and session.has_session() and session.player.life.is_alive():
		session.player.life.take_hit(99)
	elif not session.has_session() and code in [KEY_F2, KEY_F3, KEY_F4]:
		var kind: String = {KEY_F2: "explore_timeout", KEY_F3: "timeout_zero", KEY_F4: "talk"}[code]
		session.store.save_slot(3, outcome(kind))
		session.ui.call("show_title")
	else:
		return
	get_viewport().set_input_as_handled()

func self_test() -> void:
	var title: TitleScreen = session.ui.get("_title") as TitleScreen
	check(title.visible, "acceptance opens on the title")
	await click(title.button("继续游戏"))
	await click((session.ui.get("_slots") as SlotSelect).cards[1])
	await frames(6)
	var sheet: OutcomeSheet = (session as FinalBattleSession).final_ui.sheet
	check(sheet.visible and sheet.drawn.get("title", {}).get("text") == "未来已失", "acceptance slot 2 shows the timeout sheet")
	await capture("timeout")
	await click(sheet.button("返回标题"))
	await frames(6)
	session = get_tree().current_scene as CheckpointLab
	title = session.ui.get("_title") as TitleScreen
	check(title.visible and not session.has_session(), "acceptance timeout returns to the title")
	await click(title.button("继续游戏"))
	await click((session.ui.get("_slots") as SlotSelect).cards[0])
	await frames(6)
	session.player.life.take_hit(99)
	var death: OutcomeSheet = session.ui.get("_death") as OutcomeSheet
	for i: int in range(600):
		if death.visible:
			break
		await frames(1)
	await frames(2)
	check(death.visible and death.drawn.get("buttons") == ["从检查点继续", "返回标题", "设置", "退出游戏"], "acceptance death shows the A-014 sheet")
	await capture("death")
	await click(death.button("返回标题"))
	await frames(6)
	session = get_tree().current_scene as CheckpointLab
	check((session.ui.get("_title") as TitleScreen).visible, "acceptance death returns to the title")
