# verify-suite: {"name":"completed slots block entry without writes and unfinished endings resume","path":"res://tests/test_completed_slots.gd","marker":"COMPLETED_SLOTS_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
## Also provides an isolated real-menu G4 entry: -- --acceptance.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String = ""
var finishing: bool = false

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok

func frames(count: int = 3) -> void:
	for i: int in range(count):
		await process_frame
	if is_instance_valid(current_scene):
		session = current_scene as FinalBattleSession

func fixture(kind: String) -> Dictionary:
	var snapshot: Dictionary = SlotStore.new().fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	for flag: String in [StartRoomSession.BIRTH, RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
		snapshot["events"][flag] = true
	if kind != "normal":
		FinalClock.start(snapshot)
	if kind in ["won", "talk", "end"]:
		snapshot["events"][FinalClock.WON] = true
	if kind in ["talk", "end"]:
		snapshot["events"][FinalClock.TALK] = true
	if kind == "end":
		snapshot["events"][FinalClock.END] = true
	if kind == "timeout":
		snapshot["events"][FinalClock.TIMEOUT] = true
		snapshot["final_remaining"] = 0.0
	return snapshot

func physics_frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await frames(1)

func launch() -> void:
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await frames()

func stop() -> void:
	paused = false
	if is_instance_valid(session):
		session.queue_free()
	await process_frame
	await process_frame
	session = null
	current_scene = null

func write_pair(kind: String, selected: int = 1) -> void:
	var backup: Dictionary = fixture(kind)
	backup["balance"] = 2
	check(session.store.save_slot(selected, backup), kind + " backup fixture is valid and written")
	check(session.store.save_slot(selected, fixture(kind)), kind + " primary fixture is valid and written")

func disk_bytes(selected: int = 1) -> Dictionary:
	var result: Dictionary = {}
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = session.store.path_for(selected) + suffix
		result[suffix] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return result

func slot_button(selected: int, title: String) -> Button:
	var row_index: int = 0
	for child: Node in (session.ui.get("_menu") as VBoxContainer).get_children():
		if child is HBoxContainer:
			row_index += 1
			if row_index == selected:
				for item: Node in child.get_children():
					if item is Button and item.text == title:
						return item as Button
	return null

func menu_button(title: String) -> Button:
	for child: Node in (session.ui.get("_menu") as VBoxContainer).get_children():
		if child is Button and child.text == title:
			return child as Button
	return null

func click(button: Button) -> void:
	if not check(is_instance_valid(button), "real menu button exists"):
		return
	var point: Vector2 = button.get_global_rect().get_center()
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
		await frames(2)

func blocked_case(primary_mode: String, active: bool = false) -> void:
	await launch()
	write_pair("end")
	if primary_mode == "corrupt":
		var file: FileAccess = FileAccess.open(session.store.path_for(1), FileAccess.WRITE)
		file.store_string("{broken primary")
		file.close()
	elif primary_mode == "missing":
		check(DirAccess.remove_absolute(session.store.path_for(1)) == OK, "remove primary for backup-only END fixture")
	if active:
		write_pair("normal", 2)
		check(session.start_slot(2, false), "independent active session starts")
		await frames()
	session.ui.show_slots()
	await frames()
	var before: Dictionary = disk_bytes()
	var before_data: Dictionary = session.data.duplicate(true)
	var before_slot: int = session.slot
	var scene_id: int = session.get_instance_id()
	var room_id: int = session.room.get_instance_id()
	await click(slot_button(1, "继续"))
	check(session.get_instance_id() == scene_id and session.room.get_instance_id() == room_id, "END neither restores a room nor reloads the scene: " + primary_mode)
	check(session.slot == before_slot and session.data == before_data and not session._reloading and not has_meta("checkpoint_reload"), "END leaves the active or empty session unchanged")
	check(paused and session.ui.get("_mode") == "slots", "END stays at slot selection")
	var notice: Label = session.ui.get("_error_label") as Label
	check(notice.visible and notice.text == "游戏已通关", "END displays the exact completed-game prompt")
	check(disk_bytes() == before, "END primary backup and temporary bytes stay unchanged: " + primary_mode)
	await stop()

func new_game_case() -> void:
	await launch()
	write_pair("end")
	session.ui.show_slots()
	await frames()
	await click(slot_button(1, "新游戏"))
	check(session.ui.get("_mode") == "confirm_new", "completed slot still asks for new-game overwrite confirmation")
	await click(menu_button("确认开始"))
	check(session.has_session() and session.slot == 1 and not bool(session.data["events"].get(FinalClock.END, false)), "new game overwrites the completed slot and starts normally")
	check(not bool(session.store.load_slot(1)["events"].get(FinalClock.END, false)), "new-game primary is a fresh real save")
	await stop()

func unfinished_case(kind: String) -> void:
	await launch()
	write_pair(kind)
	session.ui.show_slots()
	await frames()
	await click(slot_button(1, "继续"))
	check(session.has_session() and session.slot == 1, kind + " remains enterable")
	check((session.ui.get("_error_label") as Label).text != "游戏已通关", kind + " is not mislabeled completed")
	if kind == "normal":
		check(not paused and session.room is TrenchPassageRoom, "ordinary ongoing save restores its real checkpoint")
	elif kind == "timeout":
		check(paused and session._timeout_active, "TIMEOUT restores explicit retry UI")
		check(session.retry_final_battle(), "TIMEOUT can still explicitly retry")
		await frames()
		check(not paused and not session._timeout_active and session.room is FinalBattlefieldRoom, "TIMEOUT retry actually starts the final encounter")
	elif kind == "won":
		check(not bool(session.data["events"].get(FinalClock.TALK, false)) and not session._ending_active, "WON without TALK does not skip the victory dialogue")
		session._change_room(BattlefieldSession.BATTLEFIELD_ID)
		session.player.position = (session.room as FinalBattlefieldRoom).ten.position
		session.player.reset_kinematics()
		await physics_frames()
		Input.action_press("interact")
		await physics_frames()
		Input.action_release("interact")
		check(session._final_talk and session.dialogue_ui.active, "WON can begin the real victory dialogue")
		for i: int in range(8):
			if session.dialogue_ui.active:
				session.dialogue_ui.advance()
		check(session._ending_active and bool(session.data["events"].get(FinalClock.TALK, false)), "WON can finish dialogue and continue the ending")
	elif kind == "talk":
		check(session._ending_active and not bool(session.data["events"].get(FinalClock.END, false)), "TALK without END resumes the ending presentation")
		await create_timer(3.2).timeout
		check(paused and session.final_ui.mode == "finished" and bool(session.store.load_slot(1)["events"].get(FinalClock.END, false)), "current resumed ending still saves END and displays finished screen")
	await stop()

func acceptance() -> void:
	await launch()
	write_pair("end")
	session.ui.show_slots()
	if root.close_requested.is_connected(session._on_close_requested):
		root.close_requested.disconnect(session._on_close_requested)
	root.close_requested.connect(finish)
	var banner: CanvasLayer = CanvasLayer.new()
	banner.layer = 90
	var note: Label = Label.new()
	note.position = Vector2(820, 900)
	note.text = "SYS-004 独立临时槽1（已通关）\n点继续：游戏已通关且停留选槽。\n点新游戏并确认：正常开始；关闭窗口清理临时存档。"
	note.add_theme_font_size_override("font_size", 22)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(note)
	root.add_child(banner)
	await frames()
	print("SYS004_ACCEPTANCE_READY directory=", directory)
	await capture("slots")
	if "--acceptance-smoke" in OS.get_cmdline_user_args():
		var before: Dictionary = disk_bytes()
		await click(slot_button(1, "继续"))
		check(session.ui.get("_mode") == "slots" and not session.has_session(), "acceptance continue stays in the real slot menu")
		check((session.ui.get("_error_label") as Label).text == "游戏已通关" and disk_bytes() == before, "acceptance prompt and byte preservation")
		await capture("blocked")
		await click(slot_button(1, "新游戏"))
		await click(menu_button("确认开始"))
		check(session.has_session() and not bool(session.data["events"].get(FinalClock.END, false)), "acceptance new game starts")
		await capture("new-game")
		await finish()

func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://../codexandclaude/runs/SYS-004-g4/" + label + ".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(root.get_texture().get_image().save_png(path) == OK, "acceptance screenshot saved: " + label)

func cleanup() -> void:
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory):
		return
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	check(DirAccess.remove_absolute(directory) == OK, "isolated temporary directory is cleaned")

func finish() -> void:
	if finishing:
		return
	finishing = true
	await stop()
	await create_timer(0.15).timeout
	cleanup()
	print("COMPLETED_SLOTS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_sys004_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if "--acceptance" in OS.get_cmdline_user_args() or "--acceptance-smoke" in OS.get_cmdline_user_args():
		await acceptance()
		return
	for mode: String in ["valid", "corrupt", "missing"]:
		await blocked_case(mode)
	await blocked_case("valid", true)
	await new_game_case()
	for kind: String in ["won", "talk", "timeout", "normal"]:
		await unfinished_case(kind)
	await finish()

func _finalize() -> void:
	cleanup()
