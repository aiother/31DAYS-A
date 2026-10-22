# verify-suite: {"name": "formal pause menu clock pages input save-and-quit and checkpoint save feedback", "path": "res://tests/test_pause_menu.gd", "marker": "PAUSE_MENU_TESTS checks=", "fixed_fps": 60, "timeout": 90}
extends SceneTree
## UI-003: the formal pause menu and save feedback, driven by real keys, D-pad
## and mouse events on the real session; assertions read what was drawn.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var quits: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
	if is_instance_valid(current_scene):
		session = current_scene as FinalBattleSession

func menu() -> PauseMenu:
	return session.ui.get("_pause") as PauseMenu

func toast() -> SaveToast:
	return session.ui.get("_save_toast") as SaveToast

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

func pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)

func click(target: Control) -> void:
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

func fixture(day: int, remaining: float) -> Dictionary:
	var result: Dictionary = session.store.fresh()
	result["events"][StartRoomSession.BIRTH] = true
	result["day"] = day
	result["day_remaining"] = remaining
	result["day3_remaining"] = remaining if day == 3 else 1800.0
	if day == 3:
		result["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
		for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
			result["events"][flag] = true
	return result

func quiet() -> void:
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)

func run() -> void:
	directory = "user://tests/pause_menu_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	check(session.store.save_slot(1, fixture(1, 1100.0)) and session.start_slot(1, false), "real first-day slot loads")
	await frames(12)
	quiet()
	session.ui.set("_quit_handler", func() -> void: quits += 1)
	await clock_cases()
	await navigation_cases()
	await direct_settings_cases()
	await quit_cases()
	await toast_cases()
	await layout_cases()
	await final_cases()
	paused = false
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	OS.delay_msec(500)
	for selected: int in [1, 2, 3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("PAUSE_MENU_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func clock_cases() -> void:
	await key(KEY_ESCAPE)
	await frames(2)
	check(paused and mode() == "pause" and menu().visible and focus_text() == "继续游戏", "real Esc opens the formal pause menu on continue")
	check(menu().button("返回标题") != null and menu().button("存档槽") == null and menu().button("保存并退出") != null and menu().buttons.size() == 4, "options are continue, settings, 返回标题 (UI-005, was the kept slot entry) and save and quit")
	var time: Dictionary = session.call("ui_time_state")
	var clock: Dictionary = menu().drawn.get("clock", {})
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	check(clock.get("time") == hud.clock_text(time) and clock.get("date") == "第 1 日 · 末日前 3 天", "clock shows the same time of day and date as the HUD")
	var days: Array = clock.get("days", [])
	check(days.size() == 3 and is_equal_approx(float(days[0]), float(time["day_progress"])) and days[1] == 0.0 and days[2] == 0.0, "three-day progress follows the real day progress")
	var left: int = ceili(float(time["day_remaining"]))
	check(clock.get("next") == "距下一日 %02d:%02d" % [int(left / 60.0), left % 60], "time to the next day matches the real clock")
	check(menu().drawn["font"] == UiTheme.FONT_PATH and menu().buttons[0].get_theme_font("font").resource_path == UiTheme.FONT_PATH, "menu draws and labels in the handwriting font")
	var before: float = DayClock.remaining(session.data)
	await frames(60)
	check(DayClock.remaining(session.data) == before and paused, "game clock does not run while the pause menu is open")

## Review R1: the public show_settings() must keep working when called from
## normal play or from a graybox panel, not only from inside the pause menu.
func direct_settings_cases() -> void:
	check(not paused and not menu().visible, "playing before the direct settings call")
	session.ui.call("show_settings")
	await frames(2)
	check(paused and menu().visible and mode() == "settings" and menu().page == "settings" and focus_text() == "返回", "direct show_settings from play opens a visible, paused settings page")
	# UI-006: the formal settings page replaced the three graybox controls.
	var page: SettingsPage = menu().settings_page
	check(page != null and page.is_visible_in_tree() and page.rows.size() == 6 and page.rows["master_volume"].is_visible_in_tree(), "the formal settings page is on screen")
	var volume: float = AudioServer.get_bus_volume_linear(0)
	(page.rows["master_volume"] as SettingRow).commit(40.0)
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.4), "the volume control still changes the master bus")
	(page.rows["master_volume"] as SettingRow).commit(volume * 100.0)
	await key(KEY_ESCAPE)
	await frames(2)
	check(paused and mode() == "pause" and menu().drawn.has("clock"), "Esc from a directly opened settings page returns to the pause clock")
	await key(KEY_ESCAPE)
	await frames(2)
	check(not paused and not menu().visible and mode() == "", "and Esc again resumes play")
	session.ui.call("show_slots")
	await frames(2)
	check((session.ui.get("_slots") as Control).visible and not menu().visible, "formal slot screen is open")
	session.ui.call("show_settings")
	await frames(2)
	check(menu().visible and menu().page == "settings" and not (session.ui.get("_slots") as Control).visible, "settings from the slot screen replaces it instead of stacking")
	session.ui.call("resume_game")
	await frames(2)

func navigation_cases() -> void:
	await key(KEY_DOWN)
	check(focus_text() == "设置", "arrow key moves focus to settings")
	await pad(JOY_BUTTON_DPAD_DOWN)
	check(focus_text() == "返回标题", "D-pad moves focus to 返回标题")
	await key(KEY_DOWN)
	check(focus_text() == "保存并退出", "focus reaches save and quit")
	check(menu().button("保存并退出").ink_state() == "focus", "focused option draws its ink marker")
	await click(menu().button("设置"))
	await frames(2)
	check(mode() == "settings" and menu().page == "settings" and focus_text() == "返回", "mouse click opens settings with focus on return")
	check(not menu().drawn.has("clock") and menu().drawn.has("page_rect"), "settings page covers the clock")
	await key(KEY_ESCAPE)
	await frames(2)
	check(paused and mode() == "pause" and menu().page.is_empty() and focus_text() == "设置" and menu().drawn.has("clock"), "Esc on a page returns to the clock and the option that opened it")
	await key(KEY_ENTER)
	await frames(1)
	check(mode() == "settings", "Enter activates the focused option")
	await key(KEY_ENTER)
	await frames(2)
	check(mode() == "pause" and menu().drawn.has("clock"), "Enter on return goes back to the clock")
	await key(KEY_ESCAPE)
	await frames(2)
	check(not paused and mode() == "" and not menu().visible, "Esc on the clock resumes the game")

func quit_cases() -> void:
	session.ui.call("show_pause")
	await frames(2)
	await click(menu().button("保存并退出"))
	await frames(2)
	check(mode() == "confirm_quit" and menu().page == "confirm" and focus_text() == "返回" and not menu().drawn.has("clock"), "save and quit asks first, defaulting to return, covering the clock")
	await key(KEY_ESCAPE)
	await frames(2)
	check(mode() == "pause" and focus_text() == "保存并退出" and quits == 0, "Esc cancels the confirmation without quitting")
	# Failed write: the game does not quit and the page shows the error.
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await key(KEY_ENTER)
	await frames(1)
	var confirm: Button = null
	for node: Node in menu().get_children():
		if node is InkButton and (node as InkButton).text == "保存并退出" and not menu().buttons.has(node):
			confirm = node as Button
	await click(confirm)
	await frames(2)
	check(quits == 0 and paused and menu().page == "confirm", "failed save does not quit")
	check(not str(menu().drawn.get("error", "")).is_empty(), "failed save shows the error on the confirmation page")
	session.store.directory = real_directory
	session.player.life.health = 4
	await click(confirm)
	await frames(2)
	check(quits == 1 and int(session.store.load_slot(1)["health"]) == 4, "confirmed save and quit writes the slot then quits once")
	session.ui.call("resume_game")
	await frames(2)

func toast_cases() -> void:
	check(not toast().visible, "no save feedback before a checkpoint")
	session.save_current()
	await frames(2)
	check(not toast().visible, "periodic and resource autosaves show no feedback")
	# Entering the ravine records its entry checkpoint; first with a broken write.
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	session.set_physics_process(false)
	session._change_room(RavineSession.RAVINE_ID)
	await frames(4)
	quiet()
	check(str(session.data["checkpoint"]) != RavineSession.RAVINE_CHECKPOINT, "failed write leaves the ravine checkpoint unrecorded")
	check(not toast().visible, "failed checkpoint save shows no feedback")
	session.store.directory = real_directory
	check(session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT), "retrying the real ravine checkpoint saves it")
	await frames(2)
	check(toast().visible and toast().drawn.get("text") == "检查点已保存", "new checkpoint on disk shows the save feedback")
	session.save_current()
	await frames(200)
	check(not toast().visible, "feedback fades and later autosaves of the same checkpoint stay quiet")

func layout_cases() -> void:
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		session.ui.call("show_enemy_intro", 6.0)
		await frames(30)
		toast().show_saved()
		session.ui.call("save_failed", "存档写入失败，请稍后重试")
		await frames(3)
		var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(window))
		var to_screen: Transform2D = root.get_final_transform()
		var toast_box: Rect2 = to_screen * toast().get_global_rect()
		var error_box: Rect2 = to_screen * (session.ui.get("_error_label") as Label).get_global_rect()
		var clear: bool = not toast_box.intersects(error_box)
		for key_name: String in ["emblem", "hint", "horizon", "warning", "banner", "final"]:
			if hud.drawn.has(key_name) and (to_screen * (hud.drawn[key_name]["rect"] as Rect2)).intersects(toast_box):
				clear = false
		check(clear and screen.encloses(toast_box), "save feedback keeps clear of the HUD and the error prompt at %dx%d" % [window.x, window.y])
		# User 2026-10-21: top-right corner, inset from both edges.
		var inset: float = SaveToast.MARGIN * to_screen.get_scale().x
		check(toast_box.position.x > screen.size.x * 0.75 and is_equal_approx(screen.end.x - toast_box.end.x, inset) and is_equal_approx(toast_box.position.y, inset), "save feedback sits in the top-right corner, inset from the edges at %dx%d" % [window.x, window.y])
		var intro: Rect2 = to_screen * (session.ui.get("_enemy_intro") as Control).get_global_rect()
		var beside: bool = (session.ui.get("_enemy_intro") as Control).is_visible_in_tree() and not toast_box.intersects(intro)
		for label: Node in session.get_node("Instructions").get_children():
			if label is Label and (label as Label).is_visible_in_tree() and not (label as Label).text.strip_edges().is_empty():
				if toast_box.intersects(to_screen * (label as Label).get_global_rect()):
					beside = false
		check(beside, "save feedback clears the enemy intro card and the graybox room text at %dx%d" % [window.x, window.y])
		session.ui.call("save_failed", "")
		session.ui.call("show_pause")
		await frames(3)
		var sheet: Rect2 = to_screen * (menu().drawn["sheet"] as Rect2)
		var clock: Rect2 = to_screen * (menu().drawn["clock"]["rect"] as Rect2)
		check(screen.encloses(sheet) and screen.encloses(clock) and not sheet.intersects(clock), "pause sheet and clock fit apart at %dx%d" % [window.x, window.y])
		session.ui.call("show_settings")
		await frames(3)
		var page: Rect2 = to_screen * (menu().drawn["page_rect"] as Rect2)
		check(screen.encloses(page) and not page.intersects(sheet), "secondary page fits beside the options at %dx%d" % [window.x, window.y])
		session.ui.call("resume_game")
		await frames(2)
	root.size = Vector2i(1920, 1080)
	check(toast().mouse_filter == Control.MOUSE_FILTER_IGNORE, "save feedback never intercepts the mouse")

func final_cases() -> void:
	check(session.store.save_slot(2, fixture(3, 552.0)) and session.start_slot(2, false), "short-budget third-day slot loads")
	await frames(5)
	session.set_physics_process(false)
	session.data["day3_remaining"] = 552.0
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	await frames(2)
	quiet()
	session.ui.set("_quit_handler", func() -> void: quits += 1)
	session.ui.call("show_pause")
	await frames(2)
	var time: Dictionary = session.call("ui_time_state")
	var clock: Dictionary = menu().drawn.get("clock", {})
	var left: int = ceili(float(time["final_remaining"]))
	check(time["final_active"] and clock.get("next") == "最终战剩余 %02d:%02d" % [int(left / 60.0), left % 60] and clock.get("date") == "第 3 日 · 末日前 1 天", "final battle pause shows the real final remainder")
	var days: Array = clock.get("days", [])
	check(days == [1.0, 1.0, float(time["day_progress"])], "first two days show as complete on the third day")
	check(str(clock.get("quest", "")) == str(session.call("quest_status_text")), "current task line follows the session quest text")
	session.ui.call("resume_game")
	await frames(2)
