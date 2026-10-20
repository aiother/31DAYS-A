# verify-suite: {"name": "ravine survivor rescue and deferred growth", "path": "res://tests/test_ravine_rescue.gd", "marker": "RAVINE_RESCUE_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: RavineRescueSession
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
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func load_snapshot(snapshot: Dictionary, selected: int = 1) -> void:
	check(session.store.save_slot(selected, snapshot) and session.start_slot(selected, false), "validated fixture loads in its own slot")
	await ticks(4)
	session = current_scene as RavineRescueSession
func enter_rescue() -> void:
	await place(Vector2(2368, 848))
func finish_dialogue() -> void:
	for i: int in range(12):
		if not session.dialogue_ui.active:
			break
		session.dialogue_ui.advance()
		await ticks(1)
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(30)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = point.x - session.player.position.x
		if absf(dx) > 10:
			Input.action_press("move_right" if dx > 0 else "move_left")
		await ticks(1)
		if i > 4 and session.player.is_on_floor():
			reached = absf(session.player.position.y - point.y) < 2 and absf(session.player.position.x - point.x) < 110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func run() -> void:
	directory = "user://tests/ravine_rescue_%d" % Time.get_ticks_usec()
	session = (load("res://world/ravine_rescue_session.tscn") as PackedScene).instantiate() as RavineRescueSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 12
	base["balance"] = 0
	for key: String in [BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE, TownSession.GAZE, RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_snapshot(base)
	await enter_rescue()
	check(session.room is RavineRescueRoom and session.room.config.room_id == "HD_20001_2" and session.room.config.next_room_id == "HD_20001_3", "actual upper door enters next configured ravine Room")
	check(session.room.get_node("Enemies").get_child_count() == 0 and session._all_checkpoints().is_empty() and session.data["checkpoint"] == RavineSession.RAVINE_CHECKPOINT, "Room has no ordinary enemy and reuses entry checkpoint")
	check(not session.interact_ravine_survivor(), "distant rescue is unavailable")
	check(not session.data["events"].get(RavineRescueSession.SEEN, false), "entry outside encounter area does not mark NPC as seen")
	await place(Vector2(48,1152))
	check(session.room is RavineRoom and not session.data["events"].get(RavineRescueSession.FAILED, false), "return before seeing NPC requires no abandonment")
	await enter_rescue()
	await place(Vector2(350, 1152))
	for point: Vector2 in [Vector2(576,992), Vector2(800,848), Vector2(1088,720)]:
		check(await jump_to(point), "zero-resource ordinary jump reaches %s; actual %s" % [point, session.player.position])
	check(session.player.possibility.balance == 0 and session.data["events"].get(RavineRescueSession.SEEN, false), "visible NPC encounter persists without a resource cost")
	var body: Polygon2D = session.room.get_node("Survivor/VisualRoot/Body") as Polygon2D
	check(body.polygon.size() == 4 and body.polygon[1] == Vector2(-36,-40), "injured survivor has visible nondegenerate geometry")
	session.player.combat.phase = PlayerCombat.Phase.WINDUP
	check(not session.interact_ravine_survivor(), "interaction does not cancel an attack")
	session.player.combat.interrupt()
	await ticks(12)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.dialogue_ui.active and session.player.life.can_control(), "real E opens free-control rescue dialogue")
	session.ui.call("show_pause")
	var chars: int = session.dialogue_ui.text.visible_characters
	await ticks(5)
	check(session.dialogue_ui.text.visible_characters == chars, "pause freezes rescue text")
	session.ui.call("resume_game")
	await place(Vector2(1450,1152))
	check(not session.dialogue_ui.active and not session.data["events"].get(RavineRescueSession.HELPED, false), "walking away cancels dialogue without awarding rescue")
	await place(Vector2(1088,720))
	await ticks(12)
	check(session.interact_ravine_survivor(), "rescue can restart nearby")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await finish_dialogue()
	check(session.dialogue_ui.active and session.player.possibility.maximum == 12 and session.player.possibility.balance == 0 and not session.data["events"].get(RavineRescueSession.HELPED, false), "failed write rolls back rescue resource and growth together")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(not session.dialogue_ui.active and session.player.possibility.maximum == 13 and session.player.possibility.balance == 4 and session.player.life.health == 3, "free rescue gives +4 and one +1 cap without filling resources or healing player")
	var completed: Dictionary = session.store.load_slot(1)
	check(completed["events"].get(RavineRescueSession.HELPED, false) and completed["maximum"] == 13 and completed["balance"] == 4, "rescue completion and both rewards persist atomically")
	check(session.room.get_node("Survivor/Name").text.contains("已救助") and session.quest_status_text().contains("13"), "NPC and objective show completed rescue and raised cap")
	check(body.polygon.size() == 4 and body.polygon[1] == Vector2(-24,-80), "rescued survivor stands with valid polygon geometry")
	check(session.interact_ravine_survivor(), "rescued NPC can still talk")
	await finish_dialogue()
	check(session.player.possibility.balance == 4 and session.player.possibility.maximum == 13, "repeat dialogue cannot repeat either reward")
	session.player.possibility.gain(99)
	check(session.player.possibility.balance == 13, "subsequent gains use new runtime cap")
	await place(Vector2(48,1152))
	check(session.room is RavineRoom and session.player.position.distance_to(Vector2(2112,848)) < 2, "return reaches safe upper landing in ravine entry")
	await enter_rescue()
	check(session.data["events"].get(RavineRescueSession.HELPED, false) and session.player.possibility.maximum == 13, "revisit retains rescue and growth")
	await place(Vector2(1824,1152))
	check(paused and session.ui.get("_mode") == "room_boundary", "next Room remains an explicit stage boundary")
	session.ui.call("resume_game")
	session.player.possibility.balance = 7
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RavineRescueSession
	check(session.room is RavineRoom and session.player.life.health == 5 and session.player.possibility.balance == 3 and session.player.possibility.maximum == 13 and session.player.life.protection_remaining > 2.8, "death returns to entry with existing full health half balance and protection rules")
	check(session.data["day"] == 2 and session.data["events"].get(RavineRescueSession.HELPED, false), "death retains rescue and date")
	var dead: Dictionary = session.store.load_slot(1)
	await load_snapshot(dead)
	check(session.player.possibility.maximum == 13 and session.player.possibility.balance == 3 and session.player.life.protection_remaining == 0, "normal load retains cap and balance without revive protection")
	# Rescue before first gaze remains pending and survives a normal load.
	var pending: Dictionary = base.duplicate(true)
	pending["events"].erase(TownSession.GAZE)
	pending["maximum"] = 10
	pending["balance"] = -2
	await load_snapshot(pending,2)
	await enter_rescue()
	await place(Vector2(1088,720))
	await ticks(12)
	session.interact_ravine_survivor()
	await finish_dialogue()
	check(session.player.possibility.balance == 2 and session.player.possibility.maximum == 10 and session.data["events"].get(RavineRescueSession.HELPED, false), "negative-balance rescue is free and defers growth before gaze")
	var early: Dictionary = session.store.load_slot(2)
	await load_snapshot(early,2)
	check(session.player.possibility.maximum == 10 and session.data["events"].get(RavineRescueSession.HELPED, false), "pending growth survives normal load")
	await place(Vector2(48,1280))
	await place(Vector2(48,896))
	await place(Vector2(1680,896))
	await ticks(12)
	check(session.interact_seven(), "previously rescued player can return to Seven for first gaze")
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	await finish_dialogue()
	await ticks(100)
	check(session.player.possibility.maximum == 10 and not session.data["events"].get(TownSession.GAZE, false) and session.data["events"].get(RavineRescueSession.HELPED, false), "failed first gaze rolls back both cap increments while keeping prior rescue")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(session.player.possibility.maximum == 13 and session.player.possibility.balance == 2 and session.store.load_slot(2)["maximum"] == 13, "first gaze atomically settles 10 to 12 plus deferred +1 without refill")
	# An actual departure after sighting requires confirmation; death does not abandon.
	await load_snapshot(base,3)
	await enter_rescue()
	await place(Vector2(640,1152))
	check(session.data["events"].get(RavineRescueSession.SEEN, false), "encounter records rescue opportunity before departure")
	await place(Vector2(1824,1152))
	check(paused and not session.data["events"].get(RavineRescueSession.FAILED, false), "unimplemented next boundary does not abandon rescue")
	session.ui.call("resume_game")
	await place(Vector2(48,1152))
	await ticks(5)
	check(session.dialogue_ui.confirming and session.room is RavineRescueRoom and not session.player.life.can_control(), "actual return retains permanent-loss confirmation and locks movement")
	session.cancel_departure()
	check(not session.dialogue_ui.active and not session.data["events"].get(RavineRescueSession.FAILED, false) and session.player.life.can_control(), "cancel leaves quest available and unlocks movement")
	session._on_room_exit(RavineSession.RAVINE_ID)
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	check(not session.confirm_departure() and session.dialogue_ui.confirming and not session.data["events"].get(RavineRescueSession.FAILED, false), "failed departure write keeps confirmation and rolls back permanent failure")
	session.store.directory = real_directory
	check(session.confirm_departure(), "explicit confirmed departure succeeds after storage recovery")
	await ticks(4)
	check(session.room is RavineRoom and session.store.load_slot(3)["events"].get(RavineRescueSession.FAILED, false) and not session.data["events"].get(FieldSession.RESCUE_FAILED, false), "only ravine quest fails; completed town rescue is independent")
	await enter_rescue()
	await place(Vector2(1088,720))
	await ticks(12)
	session.interact_ravine_survivor()
	await finish_dialogue()
	check(session.player.possibility.maximum == 12 and session.player.possibility.balance == 0 and not session.data["events"].get(RavineRescueSession.HELPED, false), "failed rescue cannot be repaired or rewarded on return")
	var observed: Dictionary = base.duplicate(true)
	observed["events"][RavineRescueSession.SEEN] = true
	await load_snapshot(observed,3)
	await enter_rescue()
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RavineRescueSession
	check(not session.data["events"].get(RavineRescueSession.FAILED, false) and session.room is RavineRoom, "death with unfinished rescue does not abandon it")
	# Schema enforces exactly the delivered growth source and slot isolation.
	var invalid_sources: Array[Dictionary] = [base.duplicate(true), completed.duplicate(true), completed.duplicate(true)]
	invalid_sources[0]["maximum"] = 13
	invalid_sources[1]["events"][RavineRescueSession.FAILED] = true
	invalid_sources[2]["maximum"] = 14
	for invalid: Dictionary in invalid_sources:
		check(not session.store.valid(invalid), "unsupported or contradictory growth source rejected")
	var invalid_pending: Dictionary = early.duplicate(true)
	invalid_pending["maximum"] = 13
	check(not session.store.valid(invalid_pending), "pending help without gaze cannot claim cap13")
	var missing_growth: Dictionary = completed.duplicate(true)
	missing_growth["maximum"] = 12
	check(not session.store.valid(missing_growth), "completed gaze and help must include their cap increment")
	check(session.store.load_slot(1)["maximum"] == 13 and session.store.load_slot(3)["maximum"] == 12, "different slot caps remain isolated")
	var overflowing: Dictionary = base.duplicate(true)
	overflowing["balance"] = 12
	await load_snapshot(overflowing,3)
	await enter_rescue()
	await place(Vector2(1088,720))
	await ticks(12)
	session.interact_ravine_survivor()
	await finish_dialogue()
	check(session.player.possibility.maximum == 13 and session.player.possibility.balance == 13, "rescue raises cap first then truncates +4 overflow to new maximum")
	session.start_slot(3,true)
	await ticks(4)
	session = current_scene as RavineRescueSession
	check(session.player.possibility.maximum == 10 and session.data["day"] == 1 and not session.data["events"].has(RavineRescueSession.HELPED), "new game clears growth quest and date")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("RAVINE_RESCUE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
