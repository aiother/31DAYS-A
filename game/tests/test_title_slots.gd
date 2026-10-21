# verify-suite: {"name": "formal title and bookmark slot screens with sky strips, prompts and real input", "path": "res://tests/test_title_slots.gd", "marker": "TITLE_SLOTS_TESTS checks=", "fixed_fps": 60, "timeout": 120}
extends SceneTree
## UI-004: the formal main menu (EXP-003 A · 黄昏远景) and slot selection
## (1 · 书签 with sky strips) on the real session and real isolated save files,
## driven by real keys, D-pad and mouse events; assertions read what was drawn.
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

func title() -> TitleScreen:
	return session.ui.get("_title") as TitleScreen

func slots() -> SlotSelect:
	return session.ui.get("_slots") as SlotSelect

func mode() -> String:
	return str(session.ui.get("_mode"))

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)
	# One more frame so the screen has drawn the result.
	await frames(1)

func pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)
	# One more frame so the screen has drawn the result.
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

func launch() -> void:
	if is_instance_valid(session):
		paused = false
		session.queue_free()
		current_scene = null
		await frames(2)
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	session.ui.set("_quit_handler", func() -> void: quits += 1)
	await frames(4)

func store() -> SlotStore:
	var result: SlotStore = SlotStore.new()
	result.directory = directory
	# Same starting checkpoint as the real session, so fixtures can load.
	result.initial_checkpoint = session.store.initial_checkpoint
	return result

func progress_fixture() -> Dictionary:
	var snapshot: Dictionary = store().fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["day"] = 2
	snapshot["day_remaining"] = DayClock.CONFIG.day_seconds * 0.6
	snapshot["play_seconds"] = 5025.0
	snapshot["health"] = 4
	snapshot["balance"] = 6
	return snapshot

func completed_fixture() -> Dictionary:
	var snapshot: Dictionary = store().fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	for flag: String in [StartRoomSession.BIRTH, RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
		snapshot["events"][flag] = true
	FinalClock.start(snapshot)
	for flag: String in [FinalClock.WON, FinalClock.TALK, FinalClock.END]:
		snapshot["events"][flag] = true
	return snapshot

func write_broken(selected: int) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(directory.path_join("slot_%d.json" % selected), FileAccess.WRITE)
	file.store_string("{broken")
	file.close()

func clear_slots() -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))

func write_fixtures() -> void:
	clear_slots()
	var writer: SlotStore = store()
	check(writer.save_slot(1, progress_fixture()) and writer.save_slot(2, completed_fixture()), "real isolated fixtures written")
	write_broken(3)

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_title_slots_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	root.size = Vector2i(1920, 1080)
	await empty_title_cases()
	write_fixtures()
	await launch()
	await title_cases()
	await settings_cases()
	await quit_cases()
	await continue_cases()
	await colour_cases()
	await new_game_cases()
	await layout_cases()
	await enter_cases()
	paused = false
	if is_instance_valid(session):
		session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	clear_slots()
	DirAccess.remove_absolute(directory)
	print("TITLE_SLOTS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func empty_title_cases() -> void:
	clear_slots()
	await launch()
	check(not session.has_session() and paused and mode() == "title" and title().visible, "a fresh start without a session shows the formal title")
	check(title().drawn.get("menu") == ["新游戏", "设置", "退出游戏"], "without saves the menu hides 继续游戏")
	check(focus_text() == "新游戏", "without saves focus starts on 新游戏")

func title_cases() -> void:
	check(title().visible and title().drawn.get("menu") == ["新游戏", "继续游戏", "设置", "退出游戏"], "with saves the menu is 新游戏、继续游戏、设置、退出游戏")
	check(focus_text() == "继续游戏", "with saves focus starts on 继续游戏")
	var drawn: Dictionary = title().drawn.get("title", {})
	var rect: Rect2 = drawn.get("rect", Rect2())
	check(drawn.get("text") == "末日前31天" and rect.position.y >= 0.0 and rect.end.y <= title().size.y / 3.0 and rect.size.y > 0.0, "the title is drawn inside the upper third")
	check(absf(rect.get_center().x - title().size.x * 0.5) < 2.0, "the title is centred")
	check(drawn.get("font") == UiTheme.FONT_PATH and title().buttons[0].get_theme_font("font").resource_path == UiTheme.FONT_PATH, "title and menu use the handwriting font")
	var menu_rect: Rect2 = title().drawn.get("menu_rect", Rect2())
	check(menu_rect.position.y >= title().size.y / 3.0, "the menu sits below the title band")
	await key(KEY_DOWN)
	check(focus_text() == "设置", "arrow down moves through the title menu")
	await pad(JOY_BUTTON_DPAD_UP)
	check(focus_text() == "继续游戏", "D-pad up moves back")

func settings_cases() -> void:
	await click(title().button("设置"))
	var menu: PauseMenu = session.ui.get("_pause") as PauseMenu
	check(menu.visible and menu.page == "settings" and not title().visible and mode() == "settings", "设置 opens the existing settings page")
	await key(KEY_ESCAPE)
	await frames(2)
	check(title().visible and not menu.visible and mode() == "title" and paused, "Esc from settings returns to the title")
	await click(title().button("设置"))
	await click(menu.button("继续游戏"))
	check(title().visible and not menu.visible and not session.has_session() and paused, "the pause sheet's 继续游戏 without a session goes back to the title")

func quit_cases() -> void:
	await click(title().button("退出游戏"))
	check(title().dialog != null and title().drawn.get("dialog", {}).get("text") == "退出游戏？", "退出游戏 asks first")
	check(focus_text() == "返回" and quits == 0, "the quit sheet starts on 返回")
	await key(KEY_ENTER)
	check(title().dialog == null and quits == 0 and focus_text() == "退出游戏", "Enter on 返回 keeps the game and returns focus")
	await key(KEY_ENTER)
	await key(KEY_ESCAPE)
	check(title().dialog == null and quits == 0 and title().visible, "Esc closes the quit sheet")
	await key(KEY_ENTER)
	await click(title().dialog_button("accept"))
	check(quits == 1, "confirming quits")

func continue_cases() -> void:
	await click(title().button("继续游戏"))
	check(slots().visible and not title().visible and slots().mode == "continue" and mode() == "slots", "继续游戏 opens the slot screen")
	check(slots().drawn.get("heading") == "继续游戏 · 选择存档" and slots().focused() == 0, "continue starts on the slot in progress")
	var cards: Dictionary = slots().drawn.get("cards", {})
	check(cards.get(0, {}).get("state") == "progress" and cards.get(1, {}).get("state") == "completed" and cards.get(2, {}).get("state") == "unreadable", "the three bookmarks draw their real states")
	var lines: Array = cards.get(0, {}).get("lines", [])
	check(lines.size() == 6 and lines[0] == "第 2 日 · 末日前 2 天" and lines[1] == "游戏时长 1:23:45" and lines[3] == "可能性 6 / 10" and lines[4] == "珍珠 0", "a slot in progress shows day, countdown, play time, possibility and pearls")
	# Review N1: the exact display name of the fixtures' checkpoints.
	check(lines[5] == "最后检查点\n深谷检查点" and cards.get(1, {}).get("lines", [])[5] == "最后检查点\n堑壕第二间 · 入口", "and its last checkpoint by name")
	var shards: Dictionary = cards.get(0, {}).get("shards", {})
	check(shards.get("filled") == 4 and shards.get("slots") == session.player.life.config.max_health, "life shards show health against the maximum")
	check(cards.get(1, {}).get("seal") == "已通关" and not cards.get(0, {}).has("seal"), "only the completed bookmark wears the 已通关 seal")
	check(cards.get(2, {}).get("label") == "无法读取" and not cards.get(2, {}).has("sky"), "the unreadable bookmark has its own style")
	check(is_equal_approx(float(cards.get(0, {}).get("sky", {}).get("sun_x", 0.0)), 0.4), "the sky strip's sun stands where the saved day stood")
	check(float(cards.get(0, {}).get("lift", 0.0)) < 0.0 and float(cards.get(1, {}).get("lift", 0.0)) == 0.0, "the selected bookmark rises")
	await key(KEY_RIGHT)
	check(slots().focused() == 1 and float(slots().drawn["cards"][1]["lift"]) < 0.0, "right moves to the next bookmark")
	await key(KEY_ENTER)
	check(slots().visible and mode() == "slots" and not session.has_session() and slots().drawn.get("prompt", {}).get("text") == "游戏已通关", "a completed slot answers 游戏已通关 and stays")
	check(slots().drawn.get("prompt", {}).get("color") == DuskStyle.LIFE, "the prompt is drawn in the fixed vermilion")
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check(slots().focused() == 2, "D-pad right reaches the third bookmark")
	await pad(JOY_BUTTON_A)
	check(slots().drawn.get("prompt", {}).get("text") == "槽三无法读取，可在新游戏中覆盖" and not session.has_session(), "an unreadable slot explains why it cannot continue")
	await pad(JOY_BUTTON_DPAD_LEFT)
	await pad(JOY_BUTTON_DPAD_LEFT)
	check(slots().focused() == 0, "D-pad left walks back")
	await key(KEY_ESCAPE)
	check(title().visible and not slots().visible and mode() == "title", "Esc returns to the title")
	await click(title().button("继续游戏"))
	await pad(JOY_BUTTON_BACK)
	check(title().visible and not slots().visible, "Back returns to the title")
	# An empty third slot, then the mouse.
	DirAccess.remove_absolute(directory.path_join("slot_3.json"))
	await click(title().button("继续游戏"))
	check(slots().drawn["cards"][2]["state"] == "empty" and slots().drawn["cards"][2]["label"] == "没有存档", "an empty bookmark has its own style")
	await click(slots().cards[2])
	check(slots().drawn.get("prompt", {}).get("text") == "槽三是空的，请从主界面选择新游戏" and not session.has_session(), "an empty slot explains why it cannot continue")
	await click(slots().back_button)
	check(title().visible, "the mouse returns to the title")
	write_broken(3)

func colour_cases() -> void:
	await click(title().button("继续游戏"))
	var cards: Dictionary = slots().drawn["cards"]
	var day2: Dictionary = cards[0]
	var done: Dictionary = cards[1]
	check(float(day2["sky"]["dusk"]) < float(done["sky"]["dusk"]) and day2["sky"]["top"] != done["sky"]["top"] and day2["paper"] != done["paper"], "sky strip and paper follow each slot's own day")
	var same: bool = true
	for name: String in ["date", "shard", "possibility"]:
		same = same and day2["keys"].has(name) and day2["keys"][name] == done["keys"][name]
	check(same and day2["keys"]["date"] == DuskStyle.LIFE and done["keys"]["seal"] == DuskStyle.LIFE, "key colours stay the same whatever the slot's day")
	await key(KEY_ESCAPE)

func new_game_cases() -> void:
	await click(title().button("新游戏"))
	check(slots().visible and slots().mode == "new" and slots().drawn.get("heading") == "新游戏 · 选择存档位置", "新游戏 opens the slot screen for a new game")
	await key(KEY_ENTER)
	var sheet: Dictionary = slots().drawn.get("dialog", {})
	check(mode() == "confirm_new" and str(sheet.get("text", "")).contains("将覆盖此槽现有进度"), "a slot with progress warns before overwriting")
	check(focus_text() == "返回" and slots().dialog_button("accept").text == "覆盖并开始", "the overwrite sheet starts on 返回")
	await key(KEY_ENTER)
	check(slots().dialog == null and mode() == "slots" and slots().focused() == 0 and not session.has_session(), "返回 keeps the slot")
	await key(KEY_RIGHT)
	await key(KEY_RIGHT)
	await key(KEY_ENTER)
	check(str(slots().drawn.get("dialog", {}).get("text", "")).contains("将覆盖此槽现有进度"), "an unreadable slot also warns before overwriting")
	await key(KEY_ESCAPE)
	check(slots().dialog == null and slots().visible, "Esc closes the sheet but stays on the slots")
	DirAccess.remove_absolute(directory.path_join("slot_3.json"))
	await key(KEY_ESCAPE)
	await click(title().button("新游戏"))
	check(slots().focused() == 2, "a new game starts on the first empty slot")
	await key(KEY_ENTER)
	check(slots().drawn.get("dialog", {}).get("text") == "在槽三开始新游戏？" and slots().dialog_button("accept").text == "开始", "an empty slot asks without an overwrite warning")
	await key(KEY_ESCAPE)

## Save errors land on the prompt line: inside the window and clear of the
## bookmarks, the header and the back button, at both window sizes.
func layout_cases() -> void:
	var real: String = session.store.directory
	session.store.directory = real.path_join("slot_1.json")
	await key(KEY_ENTER)
	await click(slots().dialog_button("accept"))
	session.store.directory = real
	var prompt: Dictionary = slots().drawn.get("prompt", {})
	check(not session.has_session() and slots().visible and not str(prompt.get("text", "")).is_empty() and prompt.get("text") == (session.ui.get("_error_label") as Label).text, "a failed save shows the existing error on the slot screen")
	check(not (session.ui.get("_error_label") as Label).visible, "the graybox error label does not show behind the bookmarks")
	# Review R1: after the failed start the keys and pad still work, with no
	# focus repaired by the test.
	check(root.gui_get_focus_owner() == slots().cards[2] and slots().dialog == null, "after a failed start the focus is back on the bookmark that asked")
	await key(KEY_LEFT)
	check(slots().focused() == 1, "and left still moves between bookmarks")
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await key(KEY_ENTER)
	check(slots().dialog != null and focus_text() == "返回", "and Enter asks again for the same slot")
	await pad(JOY_BUTTON_BACK)
	check(slots().dialog == null and slots().focused() == 2 and slots().visible, "and Back closes the question back onto it")
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		for focus: int in [0, 1, 2]:
			slots().cards[focus].grab_focus()
			await frames(2)
			var area: Rect2 = Rect2(Vector2.ZERO, slots().size)
			var visible: Rect2 = root.get_visible_rect()
			var rects: Array[Rect2] = [slots().drawn["prompt"]["rect"], slots().drawn["header_rect"], slots().drawn["back_rect"]]
			for i: int in range(3):
				rects.append(slots().drawn["cards"][i]["rect"])
			var inside: bool = area.size == visible.size
			var apart: bool = true
			for a: int in range(rects.size()):
				inside = inside and area.encloses(rects[a])
				for b: int in range(a + 1, rects.size()):
					apart = apart and not rects[a].intersects(rects[b])
			check(inside and apart, "%dx%d focus %d: bookmarks, prompt, header and back stay apart and on screen" % [window.x, window.y, focus])
	root.size = Vector2i(1920, 1080)

func enter_cases() -> void:
	slots().cards[2].grab_focus()
	await key(KEY_ENTER)
	await key(KEY_LEFT)
	check(focus_text() == "开始", "left moves from 返回 to the confirm button")
	await key(KEY_ENTER)
	await frames(4)
	check(session.has_session() and session.slot == 3 and not paused and not slots().visible and not title().visible and mode() == "", "confirming starts the game in that slot")
	check(store().load_slot(1)["play_seconds"] == 5025.0 and SlotStore.is_completed(store().load_slot(2)), "other slots keep their progress")
	await launch()
	await click(title().button("继续游戏"))
	await key(KEY_ENTER)
	await frames(4)
	check(session.has_session() and session.slot == 1 and session.player.life.health == 4 and not slots().visible, "continuing a slot in progress enters the game")
