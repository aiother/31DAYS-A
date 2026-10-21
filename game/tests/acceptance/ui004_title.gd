extends "res://tests/acceptance/ui002_hud.gd"
## UI-004 adapter: the formal title and bookmark slot screens on isolated
## slots. Slot 1 is in progress on the second day, slot 2 completed, slot 3
## unreadable; F2 switches slot 3 between unreadable and empty, F3 clears every
## temporary slot (title without 继续游戏).
var _title_shown: bool = false

func configuration() -> Dictionary:
	var progress: Dictionary = fixture(2, DayClock.CONFIG.day_seconds * 0.6)
	progress["play_seconds"] = 5025.0
	progress["health"] = 4
	return {"id":"UI-004", "marker":"UI004_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:progress, 2:completed()}, "enter":false,
		"instructions":"UI-004 独立临时存档（关闭窗口自动清理）\n槽1 第2日进行中 · 槽2 已通关 · 槽3 无法读取\nF2 切换槽3：无法读取 / 空 · F3 清空全部临时存档\n继续游戏：槽1进入，槽2提示已通关，槽3说明原因\n新游戏：有进度或无法读取的槽提示覆盖，默认焦点在返回\n方向键 / 十字键 / 鼠标都试一下；Esc / Back 返回"}

func completed() -> Dictionary:
	var snapshot: Dictionary = fixture(3, LONG_BUDGET)
	FinalClock.start(snapshot)
	for flag: String in [FinalClock.WON, FinalClock.TALK, FinalClock.END]:
		snapshot["events"][flag] = true
	return snapshot

func write_broken() -> void:
	var file: FileAccess = FileAccess.open(session.store.path_for(3), FileAccess.WRITE)
	file.store_string("{broken")
	file.close()

## The shared harness opens the slot screen once fixtures are written; this
## adapter starts on the title instead, with slot 3 made unreadable first.
func capture(label: String) -> void:
	if label == "slots" and not _title_shown:
		_title_shown = true
		write_broken()
		session.ui.call("show_title")
		await frames(3)
		label = "title"
	await super.capture(label)

func _unhandled_key_input(event: InputEvent) -> void:
	if finishing or not is_instance_valid(session) or session.has_session() or not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_F2:
			if FileAccess.file_exists(session.store.path_for(3)):
				DirAccess.remove_absolute(session.store.path_for(3))
			else:
				write_broken()
		KEY_F3:
			for file: String in DirAccess.get_files_at(directory):
				DirAccess.remove_absolute(directory.path_join(file))
		_:
			return
	session.ui.call("show_title")
	get_viewport().set_input_as_handled()

func self_test() -> void:
	var title: TitleScreen = session.ui.get("_title") as TitleScreen
	check(title.visible and title.drawn.get("menu") == ["新游戏", "继续游戏", "设置", "退出游戏"], "acceptance opens on the title with 继续游戏")
	await click(title.button("继续游戏"))
	var slots: SlotSelect = session.ui.get("_slots") as SlotSelect
	var cards: Dictionary = slots.drawn.get("cards", {})
	check(slots.visible and cards.get(0, {}).get("state") == "progress" and cards.get(1, {}).get("state") == "completed" and cards.get(2, {}).get("state") == "unreadable", "acceptance slots show progress, completed and unreadable")
	await capture("slots-continue")
	await click(slots.cards[1])
	await frames(2)
	check(slots.drawn.get("prompt", {}).get("text") == "游戏已通关" and not session.has_session(), "acceptance completed slot stays with its prompt")
	await capture("slots-completed")
	await click(slots.back_button)
	await click(title.button("新游戏"))
	await click(slots.cards[0])
	check(slots.dialog != null and slots.dialog_button("cancel").has_focus(), "acceptance overwrite sheet starts on 返回")
	await capture("slots-overwrite")
	await click(slots.dialog_button("cancel"))
	await click(slots.cards[0])
	await click(slots.dialog_button("accept"))
	await frames(3)
	check(session.has_session() and session.slot == 1, "acceptance new game enters the game")
