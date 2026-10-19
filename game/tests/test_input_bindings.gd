extends SceneTree
## Validate the loaded InputMap against T1 with engine enums, then inject keys.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames() -> void:
	for i: int in range(2):
		await process_frame

func key(code: Key, logical: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	if logical:
		event.keycode = code
		event.device = 16
	else:
		event.physical_keycode = code
	return event

func pad(button: JoyButton, device: int = 0) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.device = device
	return event

func axis(index: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = index
	event.axis_value = direction
	return event

func signature(event: InputEvent) -> Array:
	if event is InputEventKey:
		return ["key", event.physical_keycode, event.keycode, event.device,
			event.shift_pressed, event.ctrl_pressed, event.alt_pressed, event.meta_pressed]
	if event is InputEventJoypadButton:
		return ["pad", event.button_index, event.device]
	if event is InputEventJoypadMotion:
		return ["axis", event.axis, event.axis_value, event.device]
	if event is InputEventMouseButton:
		return ["mouse", event.button_index, event.device]
	return [event.get_class()]

func movement_input(code: Key, left: bool, right: bool) -> void:
	var event: InputEventKey = key(code)
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	check(Input.is_action_pressed("move_left") == left, "%s left action" % OS.get_keycode_string(code))
	check(Input.is_action_pressed("move_right") == right, "%s right action" % OS.get_keycode_string(code))
	check(is_equal_approx(Input.get_axis("move_left", "move_right"), float(int(right) - int(left))),
		"%s movement axis" % OS.get_keycode_string(code))
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await frames()
	check(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
		"%s release clears movement" % OS.get_keycode_string(code))

func run() -> void:
	# Let startup input initialization finish before injecting the first key.
	await frames()
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	var expected: Dictionary = {
		"move_left": [key(KEY_A), key(KEY_LEFT), axis(JOY_AXIS_LEFT_X, -1.0), pad(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [key(KEY_D), key(KEY_RIGHT), axis(JOY_AXIS_LEFT_X, 1.0), pad(JOY_BUTTON_DPAD_RIGHT)],
		"aim_up": [key(KEY_W), key(KEY_UP), axis(JOY_AXIS_LEFT_Y, -1.0), pad(JOY_BUTTON_DPAD_UP)],
		"aim_down": [key(KEY_S), key(KEY_DOWN), axis(JOY_AXIS_LEFT_Y, 1.0), pad(JOY_BUTTON_DPAD_DOWN)],
		"jump": [key(KEY_SPACE), pad(JOY_BUTTON_A)],
		"attack": [key(KEY_J), pad(JOY_BUTTON_X), mouse],
		"dodge": [key(KEY_K), pad(JOY_BUTTON_B)],
		"recover": [key(KEY_L), pad(JOY_BUTTON_Y)],
		"run": [key(KEY_SHIFT), pad(JOY_BUTTON_LEFT_SHOULDER)],
		"interact": [key(KEY_E), pad(JOY_BUTTON_RIGHT_SHOULDER)],
		"use_item": [key(KEY_Q), pad(JOY_BUTTON_BACK)],
		"pause": [key(KEY_ESCAPE), pad(JOY_BUTTON_START)],
		"ui_accept": [key(KEY_ENTER, true), key(KEY_KP_ENTER, true), key(KEY_SPACE, true), pad(JOY_BUTTON_A, -1)],
		"toggle_fullscreen": [key(KEY_F11)], "debug_reset": [key(KEY_R)],
	}
	for action: String in expected:
		check(InputMap.has_action(action), "%s exists" % action)
		var actual: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			actual.append(signature(event))
		check(actual.size() == expected[action].size(), "%s exact event count" % action)
		for event: InputEvent in expected[action]:
			check(actual.has(signature(event)), "%s includes %s" % [action, signature(event)])
	await movement_input(KEY_LEFT, true, false)
	await movement_input(KEY_RIGHT, false, true)
	await movement_input(KEY_PAGEUP, false, false)
	await movement_input(KEY_A, true, false)
	await movement_input(KEY_D, false, true)
	print("INPUT_BINDINGS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
