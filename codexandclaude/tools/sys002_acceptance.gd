extends SceneTree
## Process-local G4 harness; never advances the remnant clock or changes InputMap.
const OPTIONS: Dictionary = {
	"camp": [CampWavesSession.WAVES_ID, CampWavesSession.WAVES_CHECKPOINT, "营帐围攻"],
	"overlook": [BossSession.BOSS_ID, BossSession.BOSS_CHECKPOINT, "渴望俯视"],
	"parasite": [ParasiteSession.PARASITE_ID, ParasiteSession.PARASITE_CHECKPOINT, "寄生同伴者"],
	"rescue": [BattlefieldSession.BATTLEFIELD_ID, TrenchPassageSession.PASSAGE_CHECKPOINT, "中心战场救场"],
	"final": [BattlefieldSession.BATTLEFIELD_ID, TrenchPassageSession.PASSAGE_CHECKPOINT, "最终战"],
	"trench": [TrenchSession.TRENCH_ID, TrenchSession.TRENCH_CHECKPOINT, "堑壕（排除项）"],
}
var selected: String = "camp"
var initial_balance: int = 3
var maximum: int = 10
var smoke: bool = false
var session: FinalBattleSession
var directory: String = ""
var readout: Label
var checks: int = 0
var failures: int = 0
var ready: bool = false
var finishing: bool = false

class DebugKeys extends Node:
	var dispatch: Callable
	func _input(event: InputEvent) -> void:
		dispatch.call(event)

func _initialize() -> void:
	start.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok

func parse_arguments() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--smoke-test":
			smoke = true
		elif argument.begins_with("--encounter="):
			selected = argument.substr(argument.find("=") + 1)
		elif argument.begins_with("--balance=") or argument.begins_with("--maximum="):
			var value: String = argument.substr(argument.find("=") + 1)
			if not check(value.is_valid_int(), "argument must be an integer: " + argument):
				return false
			if argument.begins_with("--balance="):
				initial_balance = int(value)
			else:
				maximum = int(value)
		else:
			return check(false, "unknown argument: " + argument)
	return check(OPTIONS.has(selected), "encounter must be camp/overlook/parasite/rescue/final/trench") and check(maximum in [10, 12, 13, 14, 15], "maximum must be a real game cap: 10,12,13,14,15") and check(initial_balance >= -9 and initial_balance <= maximum, "balance must be between -9 and maximum")

func fixture() -> Dictionary:
	var data: Dictionary = session.store.fresh()
	data["health"] = 5
	data["balance"] = initial_balance
	data["maximum"] = maximum
	data["events"][StartRoomSession.BIRTH] = true
	data["events"][BossSession.BOSS_INTRO] = true
	data["events"][ParasiteSession.PARASITE_INTRO] = true
	# Give the temporary slot the existing source flags required by its real cap.
	if maximum >= 12:
		for key: String in [FieldSession.FIELD_STORY, TownSession.RESCUE_DONE, TownSession.GAZE]:
			data["events"][key] = true
	if maximum >= 13:
		data["events"]["rescue:HD_20001_2:completed"] = true
	if maximum >= 14:
		data["events"]["rescue:HD_20001_3:completed"] = true
	if maximum == 15:
		for key: String in [ParasiteSession.PARASITE_DEFEATED, ParasiteSession.DODGE_GROWTH, "gate:NSZC_10001_1:spikes_cleared", "rescue:NSZC_10001_1:completed"]:
			data["events"][key] = true
	if selected in ["rescue", "final", "trench"]:
		data["day"] = 3
	if selected == "final":
		data["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	return data

func start() -> void:
	if not parse_arguments():
		quit(2)
		return
	directory = "user://tests/sys002_acceptance_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var data: Dictionary = fixture()
	if not check(session.store.save_slot(1, data) and session.start_slot(1, false), "isolated acceptance slot starts"):
		await finish()
		return
	session._mount_room(OPTIONS[selected][0])
	session.data["checkpoint"] = OPTIONS[selected][1]
	session.player.position = Vector2(520 if selected in ["rescue", "final"] else 432, session.room.config.floor_row * 64)
	session.player.reset_kinematics()
	(session.player.get_node("Camera2D") as Camera2D).reset_smoothing()
	if selected == "camp":
		check((session.room as CampWavesRoom).start_waves(), "camp starts via its real encounter method")
	elif selected == "overlook":
		(session.room.get_node("Boss") as OverlookBoss).start_combat()
		(session.room as BossRoom).start_ordinary(session.player)
	elif selected == "parasite":
		(session.room.get_node("Boss") as ParasiteBoss).start_combat()
		(session.room as ParasiteRoom).start_ordinary(session.player)
	elif selected == "final":
		(session.room as FinalBattlefieldRoom).start_coop()
	# Rescue starts normally when the real player crosses its x=400 boundary.
	check(session.save_current("独立 SYS-002 验收"), "acceptance snapshot remains a valid real save")
	var keys: DebugKeys = DebugKeys.new()
	keys.process_mode = Node.PROCESS_MODE_ALWAYS
	keys.dispatch = debug_input
	root.add_child(keys)
	make_readout()
	root.title = "SYS-002 G4 · %s · 独立临时存档" % OPTIONS[selected][2]
	root.size = Vector2i(1280, 720)
	if root.close_requested.is_connected(session._on_close_requested):
		root.close_requested.disconnect(session._on_close_requested)
	root.close_requested.connect(func() -> void: finish.call_deferred())
	process_frame.connect(update_readout)
	# Wait for ordinary physics frames and the camp's real warning timer.
	var deadline: int = Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		await process_frame
		if selected == "trench" or (component() != null and component().encounter_active() and (selected != "camp" or (session.room as CampWavesRoom).phase == CampWavesRoom.Phase.ACTIVE)):
			break
	check(selected == "trench" or (component() != null and component().encounter_active()), "selected encounter is actually active")
	check(selected != "trench" or component() == null, "trench has no remnant generator")
	ready = true
	update_readout()
	print("SYS002_ACCEPTANCE_READY encounter=%s balance=%d maximum=%d directory=%s" % [selected, session.player.possibility.balance, session.player.possibility.maximum, ProjectSettings.globalize_path(directory)])
	if smoke:
		await smoke_test()

func component() -> RemnantPossibilitySpawner:
	return session.room.get_node_or_null("RemnantPossibility") as RemnantPossibilitySpawner

func update_readout() -> void:
	# A normal death/reload can replace the complete scene; retain the temporary slot.
	if current_scene is FinalBattleSession:
		session = current_scene as FinalBattleSession
	if not is_instance_valid(session) or readout == null:
		return
	var resource: PlayerPossibility = session.player.possibility
	var source: RemnantPossibilitySpawner = component()
	var timer: String = "不适用（无生成器）"
	var count: int = 0
	if source != null:
		count = source.living().size()
		timer = "%.1f 秒" % source.remaining if source.remaining >= 0 else "未计时"
		if source.frozen():
			timer += "（冻结）"
	readout.text = "SYS-002 独立验收 · %s\n余额 / 上限：%d / %d\n低于一半：%s\n距下次生成：%s\n在场保底：%d\nF6 +5 · F7 -5 · Esc 暂停\n正常战斗/伤害/计时；关闭窗口清理退出" % [OPTIONS[selected][2], resource.balance, resource.maximum, "是" if resource.balance * 2 < resource.maximum else "否", timer, count]

func make_readout() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 120
	root.add_child(layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -440
	panel.offset_right = -16
	panel.offset_top = 16
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size", 20)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(readout)

func debug_input(event: InputEvent) -> void:
	if not ready or not event is InputEventKey or not event.pressed or event.echo or not session.player.life.is_alive():
		return
	var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
	if code == KEY_F6:
		session.player.possibility.gain(5)
	elif code == KEY_F7:
		session._set_balance(maxi(session.player.possibility.config.floor_balance, session.player.possibility.balance - 5))
		session.save_current("验收调试：可能性 -5")
	else:
		return
	root.set_input_as_handled()

func send_key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

func smoke_test() -> void:
	var before: int = session.player.possibility.balance
	await send_key(KEY_F6)
	check(session.player.possibility.balance == mini(maximum, before + 5), "process-local F6 adds five with the real cap")
	before = session.player.possibility.balance
	await send_key(KEY_F7)
	check(session.player.possibility.balance == maxi(-9, before - 5), "process-local F7 subtracts five with the real debt floor")
	check(readout.text.contains("余额 / 上限") and readout.text.contains("距下次生成"), "read-only corner display updates")
	check(root.get_visible_rect().encloses(readout.get_global_rect()), "corner display stays inside the viewport")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var destination: String = ProjectSettings.globalize_path("res://../codexandclaude/runs/SYS-002-g4/preview-" + selected + ".png")
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		check(root.get_texture().get_image().save_png(destination) == OK, "windowed smoke preview saved")
	check(session.player.is_physics_processing() and (not session.room.has_method("_physics_process") or session.room.is_physics_processing()), "normal player and room physics stay enabled")
	check(session.store.valid(session.data), "debug resources still use valid isolated saves")
	var source: RemnantPossibilitySpawner = component()
	var old_remaining: float = source.remaining if source != null else -1
	await create_timer(0.3).timeout
	if source != null and old_remaining > 0 and session.player.possibility.balance * 2 < maximum:
		check(source.remaining < old_remaining, "real elapsed frames advance the existing countdown")
	await send_key(KEY_ESCAPE)
	check(paused, "normal Escape input opens real pause menu")
	var frozen_time: float = source.remaining if source != null else -1
	await create_timer(0.2).timeout
	check(source == null or source.remaining == frozen_time, "pause freezes the real generator timer")
	await send_key(KEY_ESCAPE)
	check(not paused, "normal Escape input resumes real gameplay")
	await finish()

func cleanup() -> void:
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory):
		return
	for selected_slot: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = directory.path_join("slot_%d.json" % selected_slot) + suffix
			if FileAccess.file_exists(path):
				check(DirAccess.remove_absolute(path) == OK, "temporary acceptance save removed")
	check(DirAccess.remove_absolute(directory) == OK, "temporary acceptance directory removed")

func finish() -> void:
	if finishing:
		return
	finishing = true
	ready = false
	paused = false
	if is_instance_valid(session):
		session.queue_free()
	await process_frame
	await process_frame
	current_scene = null
	# Let the audio mixer release any warning playback stopped by scene teardown.
	await create_timer(0.15).timeout
	cleanup()
	print("SYS002_ACCEPTANCE_TESTS encounter=%s checks=%d failures=%d" % [selected, checks, failures])
	quit(0 if failures == 0 else 1)

func _finalize() -> void:
	cleanup()
