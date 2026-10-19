extends SceneTree
## Exercise real GUI focus and confirmation without changing runtime bindings.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await process_frame

func pad(button: JoyButton, device: int = 0) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func run() -> void:
	directory = "user://tests/menu_controller_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "isolated menu test slot starts")
	await frames(3)
	session = current_scene as FinalBattleSession
	session.data["events"][StartRoomSession.BIRTH] = true
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	paused = false
	session.player.set_physics_process(false)
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
	if session.room.environment_hazard != null:
		session.room.environment_hazard.set_physics_process(false)
	for device: int in [0, 1, 2]:
		session.ui.show_pause()
		await frames()
		check(paused and focus_text() == "继续游戏", "pause focuses continue for device %d" % device)
		await pad(JOY_BUTTON_DPAD_DOWN, device)
		check(focus_text() == "设置", "D-pad selects settings for device %d" % device)
		await pad(JOY_BUTTON_A, device)
		check(paused and session.ui.get("_mode") == "settings", "A activates settings for device %d" % device)
		check(focus_text() == "返回", "settings focuses return for device %d" % device)
		await pad(JOY_BUTTON_A, device)
		check(session.ui.get("_mode") == "pause" and focus_text() == "继续游戏", "A returns to pause for device %d" % device)
		await pad(JOY_BUTTON_A, device)
		check(not paused and session.ui.get("_mode") == "", "A confirms continue for device %d" % device)
		var action: InputEventJoypadButton = InputEventJoypadButton.new()
		action.device = device
		action.button_index = JOY_BUTTON_A
		action.pressed = true
		if device == 0:
			check(action.is_action_pressed("jump"), "A retains the existing primary-controller jump binding")
		check(action.is_action_pressed("ui_accept"), "A is configured confirmation for device %d" % device)
	for code: Key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		session.ui.show_pause()
		await frames()
		await key(code)
		check(not paused and session.ui.get("_mode") == "", "keyboard confirm remains working: %s" % OS.get_keycode_string(code))
	session.ui.show_pause()
	await frames()
	await pad(JOY_BUTTON_START)
	check(not paused, "Start still toggles the existing pause action")
	var dodge: InputEventJoypadButton = InputEventJoypadButton.new()
	dodge.button_index = JOY_BUTTON_B
	dodge.pressed = true
	check(dodge.is_action_pressed("dodge") and not dodge.is_action_pressed("ui_accept"), "B retains dodge without becoming confirmation")
	paused = false
	session.queue_free()
	await frames(3)
	current_scene = null
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path):
				check(DirAccess.remove_absolute(path) == OK, "temporary test save cleanup")
	check(DirAccess.remove_absolute(directory) == OK, "temporary test directory cleanup")
	print("MENU_CONTROLLER_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
