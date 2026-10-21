# verify-suite: {"name": "golden wheat field dialogue and rescue departure", "path": "res://tests/test_field_room.gd", "marker": "FIELD_ROOM_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FieldSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func open_session() -> void:
	session = (load("res://world/field_session.tscn") as PackedScene).instantiate() as FieldSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
func close_session() -> void:
	paused = false
	session.queue_free()
	await ticks(2)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func enter_field() -> void:
	await place(Vector2(1552, 848))
func finish_dialogue() -> void:
	for i: int in range(12):
		if not session.dialogue_ui.active:
			break
		session.dialogue_ui.advance()
		await ticks(1)
func run() -> void:
	directory = "user://tests/field_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	snapshot["balance"] = -4
	for key: String in [BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE]:
		snapshot["events"][key] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "previous Boss checkpoint slot is compatible")
	await ticks(3)
	await enter_field()
	check(session.room.config.room_id == FieldSession.FIELD_ID and session.room.config.region_id == "Region_TY", "actual Boss skylight enters golden wheat field Region")
	check(session.room.config.scene_id == "Region_TY_Scene_10001" and session.room.config.next_room_id == "TY_10002_1", "field identity and next town match frozen configuration")
	check(session._all_checkpoints().is_empty() and session.data["checkpoint"] == BossSession.BOSS_CHECKPOINT, "confirmed scope reuses Boss checkpoint without invented Node")
	check(session.room.get_node("Enemies").get_child_count() == 0 and session.room.has_node("Seven/VisualRoot"), "noncombat Room contains Seven visual and no enemy")
	check(session.intro_active and not session.player.life.can_control() and not session.get_node("Instructions").visible and not session.ui.get("_health").visible, "first cinematic locks actions and hides HUD")
	check(session.player.possibility.balance == -4, "entering alone does not grant reward early")
	var opening: float = session._field_opening
	var wave: float = (session.room as FieldRoom).wave_time
	session.ui.call("show_pause")
	await ticks(5)
	check(session._field_opening == opening and (session.room as FieldRoom).wave_time == wave, "pause freezes cinematic and wheat animation")
	session.ui.call("resume_game")
	Input.action_press("move_right")
	Input.action_press("attack")
	await ticks(10)
	Input.action_release("move_right")
	Input.action_release("attack")
	check(absf(session.player.position.x - 160) < 2 and not session.player.combat.is_attacking(), "forced opening ignores movement and attacks")
	await ticks(120)
	check(session.dialogue_ui.active and session.dialogue_ui.speaker.text.contains("临时台词"), "automatic first dialogue explicitly marks temporary script")
	var view_center: Vector2 = (session.player.get_node("Camera2D") as Camera2D).get_screen_center_position()
	check(view_center.x - 960 >= -1 and view_center.x + 960 <= session.room.config.bounds.end.x + 1, "first cinematic camera stays inside Room bounds")
	var visible_before: int = session.dialogue_ui.text.visible_characters
	await ticks(3)
	check(session.dialogue_ui.text.visible_characters > visible_before, "dialogue reveals text over time")
	session.ui.call("show_pause")
	visible_before = session.dialogue_ui.text.visible_characters
	await ticks(5)
	check(session.dialogue_ui.text.visible_characters == visible_before, "pause retains current dialogue line and character progress")
	session.ui.call("resume_game")
	await ticks(20)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(1)
	check(session.dialogue_ui.line_index == 1, "real E input advances completed sentence")
	Input.action_press("interact")
	await ticks(7)
	Input.action_release("interact")
	check(session.dialogue_ui.text.visible_characters >= 8, "holding interact accelerates text without skipping dialogue")
	# Reach last fully displayed line, then inject one save failure.
	for i: int in range(6):
		if session.dialogue_ui.line_index == 2 and session.dialogue_ui.text.visible_characters == session.dialogue_ui.text.get_total_character_count():
			break
		session.dialogue_ui.advance()
		await ticks(1)
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	session.dialogue_ui.advance()
	check(session.dialogue_ui.active and session.intro_active and session.player.possibility.balance == -4 and not session.data["events"].get(FieldSession.FIELD_STORY, false), "failed story reward write rolls back balance and completion while keeping retry dialogue")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(not session.dialogue_ui.active and not session.intro_active and session.player.life.can_control(), "successful retry closes dialogue and restores control")
	check(session.player.possibility.balance == 10 and session.player.life.health == 3, "story fills possibility once without healing health or growth")
	check(session.store.load_slot(1)["events"].get(FieldSession.FIELD_STORY, false) and session.store.load_slot(1)["events"].get(FieldSession.HEAL_GUIDE, false), "story reward and recovery tutorial flags saved together")
	check(session.ui.get("_health").visible and session.get_node("Instructions").visible and (session.player.get_node("Camera2D") as Camera2D).offset == Vector2.ZERO, "story restores HUD and camera")
	check(session.get_node("Instructions/Help").text.contains("长按 L / Y") and session.quest_status_text().contains("麦秆镇"), "free-control recovery tutorial and quest objective appear")
	check(not session.interact_seven(), "distant Seven cannot be interacted with")
	session.player.possibility.balance = 2
	session.player.possibility.balance_changed.emit(2, 10)
	await place(Vector2(1680, 896))
	check(session.room.get_node("Seven/Prompt").visible, "nearby NPC shows interaction prompt")
	await ticks(12) # The fixture teleports immediately after closing the story dialogue.
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.dialogue_ui.active and session.player.life.can_control(), "manual NPC dialogue leaves player free to move")
	session.ui.call("show_pause")
	await ticks(1)
	# UI-003: the formal pause menu draws the task line; read its drawn record.
	var task_in_pause: bool = str((session.ui.get("_pause") as PauseMenu).drawn.get("quest", "")).contains("麦秆镇")
	check(task_in_pause, "pause menu includes current rescue objective")
	session.ui.call("resume_game")
	await finish_dialogue()
	check(session.data["events"].get(FieldSession.SEVEN, false) and session.player.possibility.balance == 2, "repeatable NPC dialogue saves interaction without repeating full refill")
	session.interact_seven()
	Input.action_press("move_left")
	await ticks(32)
	Input.action_release("move_left")
	check(not session.dialogue_ui.active and session.player.life.can_control(), "walking away closes ordinary conversation without locking movement")
	session.player.possibility.gain(3)
	Input.action_press("recover")
	await ticks(172)
	Input.action_release("recover")
	check(session.player.life.health == 5 and session.player.possibility.balance == 2, "tutorial uses existing real hold-to-heal cost and health gain")
	# Flat through-route needs no combat, pearl, dodge, or possibility.
	session.player.possibility.balance = 0
	session.player.possibility.balance_changed.emit(0, 10)
	await place(Vector2(160, 896))
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(300)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode") == "room_boundary" and session.room.config.room_id == FieldSession.FIELD_ID, "actual flat route reaches undeveloped town boundary")
	check(not session.data["events"].get(FieldSession.RESCUE_FAILED, false) and session.player.possibility.balance == 0, "eastward field boundary does not abandon rescue or consume resources")
	session.ui.call("resume_game")
	session.player.possibility.gain(5)
	session.player.life.take_hit(5)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as FieldSession
	check(session.room.config.room_id == BossSession.BOSS_ID and session.player.life.health == 5 and session.player.possibility.balance == 2, "field death restores Boss checkpoint with existing floor-half settlement")
	check(not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "death return to HD does not count as voluntary abandonment")
	await enter_field()
	check(not session.intro_active and not session.dialogue_ui.active and session.player.possibility.balance == 2, "revisit preserves completed story without replay or repeated refill")
	await close_session()
	await open_session()
	session.start_slot(1, false)
	await ticks(4)
	check(session.room.config.room_id == BossSession.BOSS_ID and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "normal load returns to checkpoint without abandoning rescue")
	await enter_field()
	check(session.player.possibility.balance == 2 and not session.intro_active, "normal load retains one-time story reward state")
	session._on_room_exit(TowerSession.TOWER_ID)
	check(not session.dialogue_ui.active and session.room.config.room_id == FieldSession.FIELD_ID, "nonadjacent exit cannot trigger abandonment")
	await place(Vector2(48, 896))
	check(session.dialogue_ui.confirming and not session.player.life.can_control() and session.room.config.room_id == FieldSession.FIELD_ID, "actual return passage asks explicit permanent-abandonment confirmation")
	check(not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "showing warning does not fail quest")
	session.cancel_departure()
	check(not session.dialogue_ui.active and session.player.life.can_control() and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "cancel keeps field and rescue opportunity")
	session._on_room_exit(BossSession.BOSS_ID)
	session.ui.call("show_pause")
	check(not session.confirm_departure(), "pause blocks confirmation mutation")
	session.ui.call("resume_game")
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.confirm_departure() and session.dialogue_ui.confirming and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "failed abandonment write keeps confirmation and opportunity for retry")
	session.store.directory = real_directory
	check(session.confirm_departure(), "explicit confirmed departure commits abandonment")
	await ticks(4)
	check(session.room.config.room_id == BossSession.BOSS_ID and session.player.position.distance_to(Vector2(1344, 848)) < 2 and session.store.load_slot(1)["events"].get(FieldSession.RESCUE_FAILED, false), "confirmed departure reaches safe HD landing with permanent failure saved")
	check(session.dialogue_ui.notice.text.contains("已放弃救助"), "departure gives central failure feedback")
	await enter_field()
	await place(Vector2(1680, 896))
	check(session.interact_seven(), "Seven remains interactable after abandonment")
	check(session.dialogue_ui.text.text == (session.room as FieldRoom).dialogue.failed_lines[0], "failed-state repeat dialogue uses its configured temporary branch")
	await finish_dialogue()
	check(session.player.possibility.balance == 2 and session.player.possibility.config.maximum == 10 and not session.data["events"].get(FieldSession.RESCUE_DONE, false), "deferred rescue and growth are not silently completed")
	await close_session()
	await open_session()
	session.start_slot(1, false)
	await ticks(3)
	check(session.data["events"].get(FieldSession.RESCUE_FAILED, false), "permanent abandonment survives reload")
	session.start_slot(1, true)
	await ticks(4)
	session = current_scene as FieldSession
	check(session.room.config.room_id == TwoRoomSession.START_ID and not session.data["events"].get(FieldSession.RESCUE_FAILED, false) and not session.data["events"].get(FieldSession.FIELD_STORY, false), "explicit new game clears abandoned quest and one-time story state")
	check(session.quest_status_text().is_empty() and session.player.possibility.balance == 3, "new game starts without stale quest HUD or story reward")
	await close_session()
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(store.path_for(1) + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("FIELD_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
