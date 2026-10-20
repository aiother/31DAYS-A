# verify-suite: {"name": "town rescue and first permanent growth", "path": "res://tests/test_town_rescue.gd", "marker": "TOWN_RESCUE_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TownSession
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
	session = (load("res://world/town_session.tscn") as PackedScene).instantiate() as TownSession
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
func enter_town() -> void:
	await place(Vector2(1552, 848))
	await place(Vector2(2480, 896))
func finish_dialogue() -> void:
	for i: int in range(12):
		if not session.dialogue_ui.active:
			break
		session.dialogue_ui.advance()
		await ticks(1)
func run() -> void:
	directory = "user://tests/town_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	snapshot["balance"] = 0
	for key: String in [BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE]:
		snapshot["events"][key] = true
	check(session.store.save_slot(1, snapshot) and session.start_slot(1, false), "old maximum-10 field save remains compatible")
	await ticks(3)
	await enter_town()
	check(session.room.config.room_id == TownSession.TOWN_ID and session.room.config.region_id == "Region_TY" and session.room.config.next_room_id == "HD_20001_1", "actual wheat-field road enters configured town and next target")
	check(session.room.get_node("Enemies").get_child_count() == 0 and session._all_checkpoints().is_empty() and session.data["checkpoint"] == BossSession.BOSS_CHECKPOINT, "peaceful town adds no enemy or undefined checkpoint")
	check(not session.interact_survivor(), "remote rescue cannot start")
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(240)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode") == "room_boundary", "ordinary run traverses under optional porch to future HD boundary")
	check(not session.data["events"].get(FieldSession.RESCUE_FAILED, false) and session.player.possibility.balance == 0, "unimplemented boundary is not an actual region departure or resource cost")
	session.ui.call("resume_game")
	await place(Vector2(928, 896))
	await ticks(12)
	check(session.room.get_node("Survivor/Prompt").visible, "nearby survivor displays rescue interaction")
	session.player.combat.phase = PlayerCombat.Phase.WINDUP
	check(not session.interact_survivor(), "rescue cannot cancel current attack")
	session.player.combat.interrupt()
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.dialogue_ui.active and session.player.life.can_control() and session.player.possibility.balance == 0, "real E begins free-control rescue dialogue at zero possibility")
	session.ui.call("show_pause")
	var chars: int = session.dialogue_ui.text.visible_characters
	await ticks(5)
	check(session.dialogue_ui.text.visible_characters == chars, "pause freezes rescue conversation")
	session.ui.call("resume_game")
	# Finish the two temporary lines but fail the reward write once.
	for i: int in range(4):
		if session.dialogue_ui.line_index == 1 and session.dialogue_ui.text.visible_characters == session.dialogue_ui.text.get_total_character_count():
			break
		session.dialogue_ui.advance()
		await ticks(1)
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	session.dialogue_ui.advance()
	check(session.dialogue_ui.active and session.player.possibility.balance == 0 and not session.data["events"].get(FieldSession.RESCUE_DONE, false), "failed rescue write rolls back reward and completion")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(not session.dialogue_ui.active and session.player.possibility.balance == 4 and session.player.life.health == 3, "successful rescue gives +4 once without healing player or charging a fee")
	check(session.store.load_slot(1)["events"].get(FieldSession.RESCUE_DONE, false) and session.store.load_slot(1)["balance"] == 4, "rescue and resource reward persist atomically")
	check(session.room.get_node("Survivor/Name").text.contains("已救助") and session.quest_status_text().contains("返回黄金麦湖") and session.room.get_node("Survivor/VisualRoot/Body").polygon.size() == 4 and session.room.get_node("Survivor/VisualRoot/Body").polygon[1] == Vector2(-24,-80), "survivor appearance and return-to-Seven objective update")
	check(session.interact_survivor(), "rescued NPC remains available for dialogue")
	await finish_dialogue()
	check(session.player.possibility.balance == 4 and session.player.possibility.maximum == 10, "repeat survivor dialogue awards neither resources nor premature growth")
	await place(Vector2(48, 896))
	check(session.room.config.room_id == FieldSession.FIELD_ID and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "return within TY preserves completed rescue")
	await place(Vector2(1680, 896))
	await ticks(12)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session._gaze_active and session.intro_active and not session.player.life.can_control() and not session.ui.get("_health").visible, "Seven settlement starts forced golden-particle dialogue with hidden HUD")
	check(session.player.possibility.maximum == 10 and session.player.possibility.balance == 4, "growth waits for settlement completion")
	session.ui.call("show_pause")
	var gaze_time: float = session._gaze_remaining
	await ticks(5)
	check(session._gaze_remaining == gaze_time, "pause freezes settlement particles and timing")
	session.ui.call("resume_game")
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await finish_dialogue()
	await ticks(100)
	check(session._gaze_active and session.player.possibility.maximum == 10 and session.player.possibility.balance == 4 and not session.data["events"].get(TownSession.GAZE, false), "failed growth save restores old cap and keeps settlement retryable")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(not session.intro_active and session.player.life.can_control() and session.ui.get("_health").visible, "successful growth retry restores control and HUD")
	check(session.player.possibility.maximum == 12 and session.player.possibility.balance == 4 and session.player.possibility.config.maximum == 10, "gaze raises runtime cap 10 to 12 without refill or shared-config mutation")
	check(session.store.load_slot(1)["maximum"] == 12 and session.store.load_slot(1)["events"].get(TownSession.GAZE, false), "raised cap is saved together with permanent gaze source")
	check(session.ui.get("_health").text.contains("4 / 12") and session.quest_status_text().contains("已获得7的注视"), "HUD and quest reflect grown cap")
	check(session.interact_seven(), "Seven remains interactable after settlement")
	await finish_dialogue()
	check(session.player.possibility.maximum == 12 and session.player.possibility.balance == 4, "repeat Seven dialogue cannot repeat growth or resources")
	session.player.possibility.gain(100)
	check(session.player.possibility.balance == 12, "normal resource gain now caps at grown maximum")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TownSession
	check(session.room.config.room_id == BossSession.BOSS_ID and session.player.possibility.maximum == 12 and session.player.possibility.balance == 6, "death preserves grown cap and halves actual balance")
	check(session.data["events"].get(FieldSession.RESCUE_DONE, false) and session.data["events"].get(TownSession.GAZE, false), "death preserves rescue and gaze records")
	await enter_town()
	await place(Vector2(928, 896))
	session.interact_survivor()
	await finish_dialogue()
	check(session.player.possibility.balance == 6 and session.room.get_node("Survivor/Name").text.contains("已救助"), "death and Room revisit cannot farm rescued NPC")
	await close_session()
	await open_session()
	check(session.start_slot(1, false), "maximum-12 slot loads normally")
	await ticks(3)
	check(session.player.possibility.maximum == 12 and session.player.possibility.balance == 6 and session.player.life.protection_remaining == 0, "normal load preserves growth and resources without respawn protection")
	# Reject unsupported or unearned cap changes, independently of actual game reward path.
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid["maximum"] = 12
	check(not session.store.valid(invalid), "raised cap without permanent gaze rejected")
	invalid = session.store.load_slot(1)
	invalid["maximum"] = 10
	check(not session.store.valid(invalid), "gaze record with missing growth rejected")
	invalid = session.store.load_slot(1)
	invalid["balance"] = 13
	check(not session.store.valid(invalid), "balance above grown cap rejected")
	invalid = session.store.load_slot(1)
	invalid["events"][FieldSession.RESCUE_FAILED] = true
	check(not session.store.valid(invalid), "contradictory rescued and abandoned state rejected")
	invalid = snapshot.duplicate(true)
	invalid["maximum"] = 11
	check(not session.store.valid(invalid), "undefined intermediate cap rejected")
	# Switching away from a grown save must restore the independent base cap.
	var negative: Dictionary = snapshot.duplicate(true)
	negative["balance"] = -9
	session.store.save_slot(2, negative)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as TownSession
	check(session.player.possibility.maximum == 10 and session.player.possibility.balance == -9, "slot switch restores independent cap without shared resource leakage")
	await enter_town()
	await place(Vector2(928, 896))
	session.interact_survivor()
	await finish_dialogue()
	check(session.player.possibility.balance == -5 and session.data["events"].get(FieldSession.RESCUE_DONE, false), "negative-balance player can rescue and gain exactly four")
	await place(Vector2(48, 896))
	await place(Vector2(1680, 896))
	session.interact_seven()
	session.player.life.take_hit(3)
	check(not session._gaze_active and session.player.possibility.maximum == 10 and not session.data["events"].get(TownSession.GAZE, false) and session.data["events"].get(FieldSession.RESCUE_DONE, false), "death during settlement cancels unearned growth while retaining rescue")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TownSession
	check(session.player.possibility.maximum == 10 and session.player.possibility.balance == 0 and session.quest_status_text().contains("返回黄金麦湖"), "interrupted settlement retries from checkpoint without negative debt or lost objective")
	var abandoned: Dictionary = snapshot.duplicate(true)
	abandoned["events"][FieldSession.RESCUE_FAILED] = true
	session.store.save_slot(3, abandoned)
	session.start_slot(3, false)
	await ticks(4)
	session = current_scene as TownSession
	await enter_town()
	await place(Vector2(928, 896))
	check(session.interact_survivor(), "failed-state survivor still permits ordinary temporary dialogue")
	await finish_dialogue()
	check(not session.data["events"].get(FieldSession.RESCUE_DONE, false) and session.player.possibility.balance == 0 and session.player.possibility.maximum == 10, "permanent abandonment cannot be rescued or rewarded retroactively")
	# Overflow is discarded; rescue remains once per NPC.
	var overflowing: Dictionary = snapshot.duplicate(true)
	overflowing["balance"] = 9
	session.store.save_slot(2, overflowing)
	session.start_slot(2, false)
	await ticks(4)
	session = current_scene as TownSession
	await enter_town()
	await place(Vector2(928, 896))
	session.interact_survivor()
	await finish_dialogue()
	check(session.player.possibility.balance == 10 and session.data["events"].get(FieldSession.RESCUE_DONE, false), "rescue overflow is capped without extra growth")
	session.start_slot(2, true)
	await ticks(4)
	session = current_scene as TownSession
	check(session.player.possibility.maximum == 10 and session.player.possibility.balance == 3 and not session.data["events"].get(TownSession.GAZE, false), "new game resets growth and gaze while preserving other slots")
	check(session.store.load_slot(1)["maximum"] == 12, "new game in another slot does not alter grown save")
	await close_session()
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1, 2, 3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("TOWN_RESCUE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
