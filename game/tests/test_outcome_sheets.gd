# verify-suite: {"name": "formal death ending and timeout sheets and pause return to title with real input", "path": "res://tests/test_outcome_sheets.gd", "marker": "OUTCOME_SHEETS_TESTS checks=", "fixed_fps": 60, "timeout": 180}
extends SceneTree
## UI-005: the death sheet (A-014), the V0.1 ending (夕阳将至), the final
## battle timeout with and without a budget (A-011, 未来已失), the third-day
## exploration timeout (G-03) and the pause menu's 返回标题, on the real
## session and isolated real saves, driven by real keys, D-pad and mouse.
## Assertions read what the sheets really drew.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var quits: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
	return ok

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
	if is_instance_valid(current_scene):
		session = current_scene as FinalBattleSession

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)
	await frames(1)

func pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)
	await frames(1)

func click(target: Control) -> void:
	if not check(is_instance_valid(target) and target.is_visible_in_tree(), "click target is on screen"):
		return
	var point: Vector2 = target.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event, true)
		await frames(1)
	await frames(1)

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func death() -> OutcomeSheet:
	return session.ui.get("_death") as OutcomeSheet

func final_sheet() -> OutcomeSheet:
	return session.final_ui.sheet

func pause_menu() -> PauseMenu:
	return session.ui.get("_pause") as PauseMenu

func title() -> TitleScreen:
	return session.ui.get("_title") as TitleScreen

func mode() -> String:
	return str(session.ui.get("_mode"))

func error_label() -> Label:
	return session.ui.get("_error_label") as Label

func fixture(kind: String) -> Dictionary:
	var snapshot: Dictionary = session.store.fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["play_seconds"] = 3725.0
	if kind == "day1":
		return snapshot
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
		snapshot["events"][flag] = true
	match kind:
		"explore_timeout":
			snapshot["day3_remaining"] = 0.0
		"timeout":
			FinalClock.start(snapshot)
			snapshot["events"][FinalClock.TIMEOUT] = true
			snapshot["final_remaining"] = 0.0
		"timeout_zero":
			FinalClock.start(snapshot)
			snapshot["events"][FinalClock.TIMEOUT] = true
			snapshot["final_remaining"] = 0.0
			snapshot["final_budget"] = 0.0
			snapshot["day3_remaining"] = 0.0
		"talk":
			FinalClock.start(snapshot)
			for flag: String in [FinalClock.WON, FinalClock.TALK]:
				snapshot["events"][flag] = true
	return snapshot

## Loads a fixture into the slot through the real slot entry.
func load_kind(kind: String, selected: int = 1) -> void:
	check(session.store.save_slot(selected, fixture(kind)) and session.start_slot(selected, false), kind + " fixture loads")
	await frames(8)

## Breaks the save directory so the next save fails, then restores it.
func with_failing_save(action: Callable) -> void:
	var real: String = session.store.directory
	session.store.directory = real.path_join("slot_1.json")
	await action.call()
	session.store.directory = real

func at_title() -> bool:
	return title().visible and not session.has_session() and mode() == "title"

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_outcome_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	await frames(4)
	await death_cases()
	await pause_cases()
	await timeout_cases()
	await zero_budget_cases()
	await exploration_cases()
	await ending_cases()
	paused = false
	if is_instance_valid(session):
		session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("OUTCOME_SHEETS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func die() -> void:
	session.player.life.take_hit(99)
	for i: int in range(600):
		if session.player.life.state == PlayerLife.State.DEATH_MENU and death().visible:
			break
		await frames(1)
	await frames(2)

func death_cases() -> void:
	await load_kind("day1")
	session.ui.set("_quit_handler", func() -> void: quits += 1)
	await die()
	var drawn: Dictionary = death().drawn
	check(death().visible and paused and mode() == "death", "death opens the formal death sheet")
	check(drawn.get("title", {}).get("text") == "你倒下了" and drawn.get("title", {}).get("color") == DuskStyle.LIFE, "titled 你倒下了 in vermilion")
	check(drawn.get("buttons") == ["从检查点继续", "返回标题", "设置", "退出游戏"], "the A-014 options in order")
	check(drawn.get("body", {}).get("text") == "满生命复活 · 可能性减半向下取整 · 负数清零", "the existing rule line stays")
	check(focus_text() == "从检查点继续", "focus starts on 从检查点继续")
	await key(KEY_UP)
	check(focus_text() == "从检查点继续", "up at the top stays on the sheet")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_DPAD_DOWN)
	check(focus_text() == "设置", "the D-pad walks down the options")
	await key(KEY_ENTER)
	var menu: PauseMenu = pause_menu()
	check(menu.visible and menu.standalone and menu.page == "settings" and death().visible and mode() == "settings", "设置 opens the settings page over the death sheet")
	await key(KEY_ESCAPE)
	check(not menu.visible and death().visible and mode() == "death" and focus_text() == "设置", "Esc returns to the death sheet on 设置")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(death().asking() and death().drawn.get("question", {}).get("text") == "保存并退出游戏？\n下次从最近的检查点继续" and focus_text() == "返回", "退出游戏 asks first, starting on 返回")
	await key(KEY_UP)
	check(focus_text() == "返回" or focus_text() == "保存并退出", "the question keeps the focus")
	await key(KEY_ESCAPE)
	check(not death().asking() and focus_text() == "退出游戏" and quits == 0 and mode() == "death", "Esc closes the question back onto 退出游戏")
	await key(KEY_ENTER)
	await click(death().answer_button("accept"))
	check(quits == 1, "confirming saves and quits")
	await death_title_cases()
	await death_continue_cases()

func death_title_cases() -> void:
	death().buttons[1].grab_focus()
	await with_failing_save(func() -> void: await key(KEY_ENTER))
	await frames(2)
	var drawn: Dictionary = death().drawn
	check(session.has_session() and death().visible and mode() == "death" and not str(drawn.get("error", {}).get("text", "")).is_empty() and drawn["error"]["text"] == error_label().text, "a failed save keeps the death sheet with the error on it")
	check(not error_label().visible and Rect2(drawn["rect"]).encloses(Rect2(drawn["rect"].position.x + 30, drawn["rect"].end.y - 60, 700, 40)), "the error sits inside the sheet; the graybox label is hidden")
	await key(KEY_ENTER)
	await frames(6)
	check(at_title(), "返回标题 from death reaches the title")

func death_continue_cases() -> void:
	await load_kind("day1")
	await die()
	await click(death().button("从检查点继续"))
	await frames(6)
	check(session.has_session() and not death().visible and not paused and session.player.life.is_alive(), "从检查点继续 still revives at the checkpoint")

func pause_cases() -> void:
	await key(KEY_ESCAPE)
	var menu: PauseMenu = pause_menu()
	check(menu.visible and menu.button("返回标题") != null and menu.button("存档槽") == null, "the pause menu offers 返回标题 instead of 存档槽")
	await click(menu.button("返回标题"))
	check(mode() == "confirm_title" and menu.page == "confirm" and menu.drawn.get("confirm", {}).get("heading") == "保存并返回标题？" and menu.drawn["confirm"]["text"] == "下次从最近的检查点继续。", "返回标题 asks first")
	check(focus_text() == "返回", "starting on 返回")
	await key(KEY_ESCAPE)
	check(mode() == "pause" and menu.page == "" and focus_text() == "返回标题" and session.has_session(), "Esc goes back to the pause menu")
	await key(KEY_ENTER)
	await key(KEY_UP)
	check(focus_text() == "返回标题", "up reaches the confirm button")
	await with_failing_save(func() -> void: await key(KEY_ENTER))
	await frames(2)
	check(session.has_session() and menu.visible and menu.page == "confirm" and not str(menu.drawn.get("error", "")).is_empty(), "a failed save stays on the question with the error")
	await key(KEY_ENTER)
	await frames(6)
	check(at_title(), "confirming returns to the title")

func timeout_cases() -> void:
	await load_kind("timeout")
	var drawn: Dictionary = final_sheet().drawn
	check(paused and session.final_ui.mode == "timeout" and final_sheet().visible, "a final battle timeout opens its sheet")
	check(drawn.get("title", {}).get("text") == "未来已失" and drawn.get("buttons") == ["确认重试最终战（重新计时）", "返回标题"], "未来已失 with retry and 返回标题")
	check(str(drawn.get("body", {}).get("text", "")).begins_with("游玩时长 1:02:05\n最终战超时 · 本次可恢复 15:00"), "with the play time and the recoverable budget")
	check(focus_text() == "确认重试最终战（重新计时）", "focus starts on retry")
	await key(KEY_ESCAPE)
	check(session.final_ui.mode == "timeout" and final_sheet().visible, "Esc cannot slip past the timeout")
	await key(KEY_ENTER)
	await frames(4)
	check(session.has_session() and not paused and not session._timeout_active and session.final_ui.mode == "" and not final_sheet().visible, "retry restarts the final battle")
	await load_kind("timeout", 2)
	await key(KEY_DOWN)
	check(focus_text() == "返回标题", "down reaches 返回标题")
	await key(KEY_ENTER)
	await frames(6)
	check(at_title(), "返回标题 from the timeout reaches the title")

func zero_budget_cases() -> void:
	await load_kind("timeout_zero")
	var drawn: Dictionary = final_sheet().drawn
	check(session.final_ui.mode == "timeout" and drawn.get("buttons") == ["返回标题"] and str(drawn.get("body", {}).get("text", "")).ends_with("第三日已结束，开战时已无可用计时预算。"), "with no budget only 返回标题 remains")
	await layout_cases()
	await pad(JOY_BUTTON_A)
	await frames(6)
	check(at_title(), "A on 返回标题 reaches the title")

func exploration_cases() -> void:
	await load_kind("explore_timeout")
	var drawn: Dictionary = final_sheet().drawn
	check(session._exploration_timeout and session.final_ui.mode == "day_timeout" and drawn.get("title", {}).get("text") == "第三日时间已耗尽", "the third-day exploration timeout keeps its own sheet")
	check(drawn.get("buttons") == ["确认重试第三日（返回检查点）", "返回标题"], "with retry and 返回标题")
	await click(final_sheet().button("确认重试第三日（返回检查点）"))
	await frames(8)
	check(session.has_session() and not session._timeout_active and DayClock.remaining(session.data) >= DayClock.CONFIG.day_seconds - 1.0, "retry restores the day at the checkpoint")
	await load_kind("explore_timeout", 2)
	await click(final_sheet().button("返回标题"))
	await frames(6)
	check(at_title(), "返回标题 from the exploration timeout reaches the title")

func ending_cases() -> void:
	await load_kind("talk")
	for i: int in range(400):
		if session.final_ui.mode == "finished":
			break
		await frames(1)
	await frames(2)
	var drawn: Dictionary = final_sheet().drawn
	check(session.final_ui.mode == "finished" and drawn.get("title", {}).get("text") == "夕阳将至", "the V0.1 ending sheet is titled 夕阳将至")
	check(str(drawn.get("body", {}).get("text", "")).ends_with("游玩时长 " + SlotSelect.play_time(float(session.data["play_seconds"]))) and drawn.get("buttons") == ["返回标题"], "with the play time and only 返回标题")
	await key(KEY_ENTER)
	await frames(6)
	check(at_title(), "返回标题 from the ending reaches the title")
	check(SlotStore.is_completed(session.store.load_slot(1)), "the slot is completed for the title to show")

## Both window sizes: the sheet, its buttons and its error line on screen.
func layout_cases() -> void:
	final_sheet().set_error("无法写入存档，请检查磁盘空间和权限")
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		await frames(2)
		var drawn: Dictionary = final_sheet().drawn
		var area: Rect2 = Rect2(Vector2.ZERO, final_sheet().size)
		var sheet: Rect2 = drawn["rect"]
		var ok: bool = area.encloses(sheet) and final_sheet().size == Vector2(root.get_visible_rect().size)
		for rect: Rect2 in drawn["button_rects"]:
			ok = ok and sheet.encloses(rect)
		var error_box: Rect2 = Rect2(sheet.position.x + 30, sheet.end.y - 56, sheet.size.x - 60, 30)
		for rect: Rect2 in drawn["button_rects"]:
			ok = ok and not rect.intersects(error_box)
		check(ok and drawn.get("error", {}).get("text") == "无法写入存档，请检查磁盘空间和权限" and not error_label().visible, "%dx%d: sheet, buttons and error line on screen and apart" % [window.x, window.y])
	root.size = Vector2i(1920, 1080)
	final_sheet().set_error("")
