extends Node
## Acceptance-only infrastructure. Adapters supply fixtures, entry and display.
signal finished(code: int)
var session: CheckpointLab
var directory: String = ""
var options: Dictionary = {}
var checks: int = 0
var failures: int = 0
var finishing: bool = false
var panel: CanvasLayer
var _config: Dictionary = {}

func configuration() -> Dictionary:
	return {}

func parse_options(arguments: PackedStringArray) -> Dictionary:
	var result: Dictionary = {"self_test":false,"capture":false,"panel":true,"slot":1,"checkpoint":"","capture_dir":"","error":""}
	for argument: String in arguments:
		if argument in ["--acceptance", "--acceptance-smoke", "--self-test", "--capture", "--no-panel"]:
			match argument:
				"--acceptance-smoke", "--self-test": result["self_test"] = true
				"--capture": result["capture"] = true
				"--no-panel": result["panel"] = false
		elif argument.begins_with("--slot="):
			var value: String = argument.trim_prefix("--slot=")
			if not value.is_valid_int() or int(value) < 1 or int(value) > SlotStore.SLOT_COUNT:
				result["error"] = "slot must be 1..%d" % SlotStore.SLOT_COUNT
			else: result["slot"] = int(value)
		elif argument.begins_with("--checkpoint="):
			result["checkpoint"] = argument.trim_prefix("--checkpoint=")
		elif argument.begins_with("--capture-dir="):
			result["capture_dir"] = argument.trim_prefix("--capture-dir=")
		elif not argument.begins_with("--adapter="):
			result["error"] = "unknown acceptance argument: " + argument
	return result

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok

func run(arguments: PackedStringArray) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	options = parse_options(arguments)
	if not check(str(options["error"]).is_empty(), str(options["error"])):
		await finish()
		return
	_config = configuration()
	var config: Dictionary = _config
	directory = OS.get_cache_dir().path_join("31days_acceptance_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()])
	if not check(DirAccess.make_dir_recursive_absolute(directory) == OK, "temporary directory created"):
		await finish()
		return
	var candidate: Node = (config["scene"] as PackedScene).instantiate()
	if not check(candidate is CheckpointLab, "adapter scene supports checkpoint saves"):
		candidate.free()
		await finish()
		return
	session = candidate as CheckpointLab
	session.save_directory = directory
	# Guard BEFORE ready or fixtures can write anything, including in mutation tests.
	if not check(session.save_directory == directory, "save directory redirected before ready"):
		await finish()
		return
	get_tree().root.add_child(session)
	get_tree().current_scene = session
	if not check(session.store.directory == directory, "store uses isolated temporary directory"):
		await finish()
		return
	for selected: int in (config["snapshots"] as Dictionary):
		var value: Variant = config["snapshots"][selected]
		var versions: Array = value if value is Array else [value]
		for version: Dictionary in versions:
			var snapshot: Dictionary = version.duplicate(true)
			if not str(options["checkpoint"]).is_empty(): snapshot["checkpoint"] = options["checkpoint"]
			check(session.store.save_slot(selected,snapshot), "acceptance fixture written")
	if bool(config.get("enter",false)):
		check(session.start_slot(int(options["slot"]),false), "acceptance checkpoint entered")
	else:
		session.ui.call("show_slots")
	if bool(options["panel"]):
		panel = CanvasLayer.new()
		panel.layer = 90
		var note: Label = Label.new()
		note.name = "ReadOnlyStatus"
		note.position = Vector2(820,850)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.add_theme_font_size_override("font_size",20)
		panel.add_child(note)
		add_child(panel)
	check(is_instance_valid(panel) == bool(options["panel"]), "optional panel selection respected")
	await frames()
	print("G4_ACCEPTANCE_READY directory=",directory)
	await capture("slots")
	if bool(options["self_test"]):
		await self_test()
		await finish()

func _process(_delta: float) -> void:
	if finishing or not is_instance_valid(session): return
	var active: CheckpointLab = get_tree().current_scene as CheckpointLab
	if active != null: session = active
	var close: Callable = session._on_close_requested
	if get_tree().root.close_requested.is_connected(close): get_tree().root.close_requested.disconnect(close)
	if not get_tree().root.close_requested.is_connected(finish): get_tree().root.close_requested.connect(finish)
	if is_instance_valid(panel):
		var text: String = str(_config.get("instructions",""))
		var fields: Dictionary = status_fields()
		for key: String in fields: text += "\n%s: %s" % [key,str(fields[key])]
		(panel.get_node("ReadOnlyStatus") as Label).text = text

func status_fields() -> Dictionary:
	return {"day":session.data.get("day",0),"balance":session.player.possibility.balance,"health":session.player.life.health}

func self_test() -> void:
	pass

func frames(count: int = 3) -> void:
	for i: int in range(count): await get_tree().process_frame

func click(button: Button) -> void:
	if not check(is_instance_valid(button), "real menu button exists"): return
	var point: Vector2 = button.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	get_tree().root.push_input(motion,true)
	for down: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		get_tree().root.push_input(event,true)
		await frames(2)

func capture(label: String) -> void:
	if not bool(options.get("capture",false)): return
	if not check(DisplayServer.get_name() != "headless", "screenshots require a rendering display"): return
	await RenderingServer.frame_post_draw
	var output: String = str(options["capture_dir"])
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../codexandclaude/runs/%s-g4" % str(_config.get("id","acceptance")))
	check(DirAccess.make_dir_recursive_absolute(output) == OK and get_viewport().get_texture().get_image().save_png(output.path_join(label+".png")) == OK, "acceptance screenshot saved: "+label)

func cleanup() -> void:
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory): return
	if not directory.begins_with(OS.get_cache_dir().path_join("31days_acceptance_")): return
	for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)

func finish() -> void:
	if finishing: return
	finishing = true
	get_tree().paused = false
	if is_instance_valid(session):
		if session.is_inside_tree(): session.queue_free()
		else: session.free()
	get_tree().current_scene = null
	await frames(2)
	OS.delay_msec(250)
	cleanup()
	check(directory.is_empty() or not DirAccess.dir_exists_absolute(directory), "temporary directory cleaned")
	print("%s checks=%d failures=%d" % [str(_config.get("marker","G4_ACCEPTANCE_TESTS")),checks,failures])
	finished.emit(1 if failures else 0)

func _exit_tree() -> void:
	cleanup()
