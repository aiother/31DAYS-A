# verify-suite: {"name": "formal settings page through the settings service from pause and title with real input", "path": "res://tests/test_settings_page.gd", "marker": "SETTINGS_PAGE_TESTS checks=", "fixed_fps": 60, "timeout": 120}
extends SceneTree
## UI-006: the formal settings page on the real session, opened from the pause
## menu and from the title, driven by real keys, D-pad and mouse events. The
## settings file is the isolated one SettingsService picks for test runs.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var settings: Node

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

func menu() -> PauseMenu:
	return session.ui.get("_pause") as PauseMenu

func page() -> SettingsPage:
	return menu().settings_page

func mode() -> String:
	return str(session.ui.get("_mode"))

func focused() -> Control:
	return root.gui_get_focus_owner()

func focus_label() -> String:
	var owner: Control = focused()
	if owner is SettingRow:
		return (owner as SettingRow).label
	if owner is Button:
		return (owner as Button).text
	if owner is SettingsPage.KeyList:
		return "按键列表"
	return ""

func values() -> Dictionary:
	return settings.call("get_values")

func saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(settings.get("file_path"))))
	return parsed if parsed is Dictionary else {}

## JSON keeps the window size as two floats.
func saved_size() -> Vector2i:
	var pair: Variant = saved().get("window_size")
	return Vector2i(int(pair[0]), int(pair[1])) if pair is Array and pair.size() == 2 else Vector2i.ZERO

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

func mouse_at(point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = button
		event.position = point
		event.global_position = point
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down and button == MOUSE_BUTTON_LEFT else 0
		root.push_input(event, true)
		await frames(1)
	await frames(1)

func click(target: Control) -> void:
	if check(is_instance_valid(target) and target.is_visible_in_tree(), "click target is on screen"):
		await mouse_at(target.get_global_rect().get_center())

func row(name: String) -> SettingRow:
	return page().rows[name] as SettingRow

func fixture() -> Dictionary:
	var result: Dictionary = session.store.fresh()
	result["events"][StartRoomSession.BIRTH] = true
	return result

func run() -> void:
	settings = root.get_node("GameSettings")
	directory = OS.get_cache_dir().path_join("31days_settings_page_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	check(str(settings.get("file_path")).begins_with(OS.get_cache_dir().path_join("31days_settings_")), "the settings file is the isolated test file")
	settings.call("restore_defaults")
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	check(session.store.save_slot(1, fixture()) and session.start_slot(1, false), "real slot loads")
	await frames(12)
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
	await open_from_pause()
	await row_cases()
	await key_list_cases()
	await restore_cases()
	await layout_cases()
	await pause_return_cases()
	await title_cases()
	settings.call("restore_defaults")
	paused = false
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("SETTINGS_PAGE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func open_from_pause() -> void:
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(mode() == "settings" and menu().page == "settings" and page().visible and not menu().standalone, "Enter on 设置 opens the formal settings page")
	check(focus_label() == "返回", "the page opens on 返回 like the other secondary pages")
	var labels: Array = []
	for name: String in page().drawn["rows"]:
		labels.append(page().drawn["rows"][name]["label"])
	check(labels == ["总音量", "效果音", "背景音", "窗口尺寸", "全屏", "帧率上限"] and page().drawn["restore"]["label"] == "恢复默认", "the page lists every A-017 setting and restore defaults")
	check(page().drawn["rows"]["master_volume"]["text"] == "100" and page().drawn["rows"]["max_fps"]["text"] == "60" and page().drawn["rows"]["window_size"]["text"] == "1280 × 720" and page().drawn["rows"]["fullscreen"]["text"] == "关", "rows show the service's current values")

func walk_up(count: int) -> void:
	for i: int in range(count):
		await key(KEY_UP)

func row_cases() -> void:
	await walk_up(8)
	check(focus_label() == "总音量", "up walks the column to the first row")
	await key(KEY_LEFT)
	await key(KEY_LEFT)
	check(values()["master_volume"] == 90.0 and saved().get("master_volume") == 90.0 and is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")), 0.9), "left lowers the master volume through the service, applied and saved")
	check(page().drawn["rows"]["master_volume"]["text"] == "90", "the slider draws its new value")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_DPAD_LEFT)
	check(focus_label() == "效果音" and values()["sfx_volume"] == 95.0 and saved().get("sfx_volume") == 95.0 and is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("效果音")), 0.95), "D-pad adjusts the effects volume")
	var music: SettingRow = row("music_volume")
	var bar: Rect2 = music.bar_rect()
	await mouse_at(music.get_global_rect().position + bar.position + Vector2(bar.size.x * 0.5, 4))
	check(focus_label() == "背景音" and values()["music_volume"] == 50.0 and saved().get("music_volume") == 50.0 and is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("背景音")), 0.5), "clicking the music bar sets it there")
	await key(KEY_DOWN)
	await key(KEY_RIGHT)
	check(values()["window_size"] == Vector2i(1920, 1080) and saved_size() == Vector2i(1920, 1080) and page().drawn["rows"]["window_size"]["text"] == "1920 × 1080", "right picks the larger window size")
	await key(KEY_LEFT)
	check(values()["window_size"] == Vector2i(1280, 720) and saved_size() == Vector2i(1280, 720), "left picks the smaller one back")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(values()["fullscreen"] == true and saved().get("fullscreen") == true and page().drawn["rows"]["fullscreen"]["text"] == "开", "Enter switches fullscreen on")
	await pad(JOY_BUTTON_A)
	check(values()["fullscreen"] == false and saved().get("fullscreen") == false, "A switches it off again")
	await key(KEY_DOWN)
	await key(KEY_RIGHT)
	check(values()["max_fps"] == 120 and saved().get("max_fps") == 120 and Engine.max_fps == 120 and Engine.physics_ticks_per_second == 60, "right raises the frame cap; physics stays at 60")
	await key(KEY_RIGHT)
	check(values()["max_fps"] == 0 and page().drawn["rows"]["max_fps"]["text"] == "不限制", "the cap also offers 不限制")
	var cap: SettingRow = row("max_fps")
	await mouse_at(cap.get_global_rect().position + Vector2(SettingRow.VALUE_X + 5, cap.size.y * 0.5))
	check(values()["max_fps"] == 120, "clicking the left arrow steps back")
	settings.call("set_value", "max_fps", 60)

func key_list_cases() -> void:
	var expected: Array = settings.call("bindings")
	await key(KEY_DOWN)
	check(focus_label() == "按键列表" and page().keys.offset == 0, "down reaches the key list")
	var seen: Array = []
	var inside: bool = true
	var keys_rect: Rect2 = Rect2(Vector2.ZERO, page().keys.size)
	for step: int in range(20):
		for shown: Dictionary in page().keys.drawn["rows"]:
			inside = inside and keys_rect.encloses(shown["rect"])
			if not seen.has(shown["action"]):
				seen.append(shown["action"])
		if focus_label() != "按键列表":
			break
		await key(KEY_DOWN)
	var actions: Array = expected.map(func(item: Dictionary) -> String: return item["action"])
	check(expected.size() == 15 and seen == actions, "scrolling shows every frozen binding in table order")
	check(inside, "key rows stay inside the list while scrolling")
	check(page().keys.max_offset() > 0 and focus_label() == "恢复默认", "the long list scrolls, then down moves on to restore defaults")
	var texts: bool = true
	for shown: Dictionary in page().keys.drawn["rows"]:
		var source: Dictionary = expected[actions.find(shown["action"])]
		texts = texts and shown["name"] == source["name"] and shown["keyboard"] == source["keyboard"] and shown["controller"] == source["controller"]
	check(texts, "each row draws the binding's name, keyboard and controller text")
	check(page().drawn["note"] == "自定义按键将在后续版本提供", "the list says custom keys come later")
	await key(KEY_UP)
	await mouse_at(page().keys.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_UP)
	check(page().keys.offset == page().keys.max_offset() - 1, "the mouse wheel scrolls the list")
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	check(focus_label() == "恢复默认", "down scrolls to the end, then leaves the list")

func restore_cases() -> void:
	settings.call("set_value", "master_volume", 35.0)
	await key(KEY_ENTER)
	check(page().confirm != null and page().drawn.get("confirm", {}).get("text") == "恢复全部默认设置？" and focus_label() == "返回", "restore defaults asks first, starting on 返回")
	check(values()["master_volume"] == 35.0, "asking changes nothing")
	await key(KEY_ENTER)
	check(page().confirm == null and values()["master_volume"] == 35.0 and focus_label() == "恢复默认", "返回 keeps the settings")
	await key(KEY_ENTER)
	await key(KEY_ESCAPE)
	check(page().confirm == null and page().visible and values()["master_volume"] == 35.0, "Esc closes the question but stays on the page")
	await key(KEY_ENTER)
	await key(KEY_LEFT)
	await key(KEY_ENTER)
	var defaults: Dictionary = SettingsService.DEFAULTS
	check(page().confirm == null and values() == defaults and saved().get("master_volume") == 100.0 and saved_size() == Vector2i(1280, 720), "confirming restores and saves every default")
	check(page().drawn["rows"]["master_volume"]["text"] == "100", "the rows show the restored values")

## Every row, the list and the buttons stay on the paper and apart, in both
## window sizes.
func layout_cases() -> void:
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		settings.call("set_value", "window_size", window)
		root.size = window
		await frames(3)
		var paper: Rect2 = Rect2(Vector2.ZERO, page().size)
		var rects: Array[Rect2] = []
		for name: String in page().drawn["rows"]:
			rects.append(page().drawn["rows"][name]["rect"])
		rects.append(page().drawn["restore"]["rect"])
		rects.append(page().drawn["keys_rect"])
		rects.append(page().drawn["back_rect"])
		var ok: bool = page().get_global_rect().size == Vector2(PauseMenu.PAGE.size) and menu().drawn.get("page_rect") == Rect2(page().position, page().size)
		for a: int in range(rects.size()):
			ok = ok and paper.encloses(rects[a])
			for b: int in range(a + 1, rects.size()):
				ok = ok and not rects[a].intersects(rects[b])
		check(ok and Rect2(Vector2.ZERO, menu().size).encloses(menu().drawn["page_rect"]), "%dx%d: settings rows, list and buttons stay on the paper and apart" % [window.x, window.y])
	settings.call("restore_defaults")

func pause_return_cases() -> void:
	await key(KEY_ESCAPE)
	check(mode() == "pause" and not page().visible and menu().drawn.has("clock") and focus_label() == "设置", "Esc returns to the pause menu on 设置")
	await key(KEY_ENTER)
	await pad(JOY_BUTTON_BACK)
	check(mode() == "pause" and not page().visible and focus_label() == "设置", "Back returns there too")
	await key(KEY_ENTER)
	await click(page().back_button)
	check(mode() == "pause" and focus_label() == "设置", "the mouse on 返回 returns there too")
	await key(KEY_ESCAPE)
	check(not paused and mode() == "", "and play resumes")

func title_cases() -> void:
	check(session.call("return_to_title"), "return to the title")
	await frames(6)
	var title: TitleScreen = session.ui.get("_title") as TitleScreen
	check(title.visible and mode() == "title", "the title is up")
	await click(title.button("设置"))
	check(page() != null and page().visible and menu().standalone and title.visible and mode() == "settings", "设置 on the title opens the settings page over the title")
	check(not menu().button("继续游戏").is_visible_in_tree() and not menu().drawn.has("clock") and menu().drawn.get("standalone") == true, "without the pause options or clock")
	var page_rect: Rect2 = menu().drawn.get("page_rect", Rect2())
	check(absf(page_rect.get_center().x - menu().size.x * 0.5) < 1.0 and absf(page_rect.get_center().y - menu().size.y * 0.5) < 1.0, "centred over the title")
	var labels: Array = []
	for name: String in page().drawn["rows"]:
		labels.append(page().drawn["rows"][name]["label"])
	check(labels == ["总音量", "效果音", "背景音", "窗口尺寸", "全屏", "帧率上限"] and page().keys.bindings.size() == 15, "it is the same settings page")
	await walk_up(7)
	await key(KEY_LEFT)
	check(focus_label() == "效果音" and values()["sfx_volume"] == 95.0 and saved().get("sfx_volume") == 95.0, "changes from the title also go through the service")
	await key(KEY_ESCAPE)
	check(title.visible and not menu().visible and mode() == "title" and focus_label() == "设置" and not session.has_session(), "Esc returns to the title on 设置")
	await key(KEY_ENTER)
	await pad(JOY_BUTTON_BACK)
	check(title.visible and not menu().visible and focus_label() == "设置", "Back returns to the title too")
	await key(KEY_ENTER)
	await click(page().back_button)
	check(title.visible and not menu().visible and mode() == "title", "and so does 返回")
	check(menu().get_index() < title.get_index(), "the pause menu goes back under the title")
