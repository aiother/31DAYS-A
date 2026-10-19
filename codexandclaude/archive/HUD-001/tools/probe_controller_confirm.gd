extends SceneTree
## Diagnose built-in confirmation and preview a binding in this process only.
var activations: int = 0
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func press_a(device: int) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	var original: Array[InputEvent] = InputMap.action_get_events("ui_accept")
	for event: InputEvent in original:
		print("ORIGINAL ui_accept: ", event.as_text(), " device=", event.device)
	var button: Button = Button.new()
	button.text = "isolated confirmation probe"
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.pressed.connect(func() -> void: activations += 1)
	root.add_child(button)
	button.grab_focus()
	paused = true
	await process_frame
	await press_a(0)
	print("ORIGINAL_XBOX_A_ACTIVATIONS=", activations)
	var binding: InputEventJoypadButton = InputEventJoypadButton.new()
	binding.device = -1
	binding.button_index = JOY_BUTTON_A
	var added: bool = not InputMap.action_has_event("ui_accept", binding)
	if added:
		InputMap.action_add_event("ui_accept", binding)
	for device: int in [0, 1, 2]:
		var before: int = activations
		await press_a(device)
		check(activations == before + 1, "temporary A binding confirms on device %d" % device)
	for event: InputEvent in original:
		check(InputMap.action_has_event("ui_accept", event), "existing keyboard bindings retained")
	if added:
		InputMap.action_erase_event("ui_accept", binding)
	check(InputMap.action_get_events("ui_accept").size() == original.size(), "temporary mapping restored before exit")
	paused = false
	button.queue_free()
	await process_frame
	print("CONTROLLER_CONFIRM_PROBE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
