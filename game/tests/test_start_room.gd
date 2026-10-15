extends SceneTree
var checks: int = 0
var failures: int = 0
var session: StartRoomSession
var directory: String
var landing_events: int = 0

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

func open_room() -> void:
	session = (load("res://world/start_room_session.tscn") as PackedScene).instantiate() as StartRoomSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	session.player.landed.connect(func(_speed: float, _hard: bool) -> void: landing_events += 1)
	await ticks(2)

func close_room() -> void:
	paused = false
	session.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	directory = "user://tests/room_%d" % Time.get_ticks_usec()
	await open_room()
	check(paused and not session.has_session(), "Room waits for slot selection")
	check(session.room.config.room_id == "HD_10001_1" and session.room.config.scene_id == "Region_HD_Scene_10001" and session.room.config.region_id == "Region_HD", "Room identity matches T5 hierarchy")
	check(session.get_node("Enemies").get_child_count() == 0, "starting Room has no enemies")
	check(session.ground.get_used_cells().size() == 90 and not session.room.has_node("Platforms"), "Room is a single flat floor without added jumping challenge")
	check(session.room.config.next_room_id == "HD_10002_1", "crack targets frozen next Room")
	check(session.start_slot(1, true), "new game starts Room session")
	check(session.intro_active and not session.player.life.can_control() and session.player.position == session.room.config.fall_start, "birth starts high with controls locked")
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("attack")
	Input.action_press("dodge")
	Input.action_press("recover")
	await ticks(8)
	check(absf(session.player.position.x - 224) < 0.01 and session.player.position.y > 160 and not session.player.combat.is_attacking() and not session.player.possibility.busy(), "birth ignores movement jump attack dodge healing while gravity moves body")
	check(session.player.life.health == 3 and session.player.possibility.balance == 3, "opening fall does not add unconfigured damage or resource costs")
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	session.ui.call("show_pause")
	var position_before: Vector2 = session.player.position
	await ticks(3)
	check(session.player.position == position_before, "pause freezes opening fall")
	session.ui.call("resume_game")
	var waited: int = 0
	while session.intro_active and waited < 240:
		await ticks(1)
		waited += 1
	check(not session.intro_active and session.player.life.can_control() and session.player.is_on_floor(), "fall and get-up finish with control returned")
	check(landing_events == 1, "opening landing emits exactly one feedback event")
	check(session.player.life.health == 3 and session.player.possibility.balance == 3, "get-up preserves frozen 3/3 starting resources")
	var saved: Dictionary = session.store.load_slot(1)
	check(saved["checkpoint"] == StartRoomSession.CHECKPOINT, "formal checkpoint uses exact T5 Node ID")
	check(saved["events"].get(StartRoomSession.BIRTH, false) and saved["events"].get(StartRoomSession.GUIDE, false) and saved["events"].get(StartRoomSession.CHECKPOINT, false), "all three starting Nodes persist")
	check(session._guide_remaining > 0, "movement guidance appears when control is free")
	Input.action_press("move_right")
	await ticks(8)
	Input.action_release("move_right")
	check(session.player.position.x > 224 and session.player.life.can_control(), "guidance permits movement")
	Input.action_press("jump")
	await ticks(2)
	Input.action_release("jump")
	check(session.player.velocity.y < 0, "ordinary jump remains available after opening")
	await ticks(65)
	check(session._guide_remaining > 0, "guide duration uses Resource timing")
	# Completed birth/guide never replay on normal load or death respawn.
	session.save_current()
	await close_room()
	await open_room()
	check(session.start_slot(1, false), "Room save loads normally")
	await ticks(3)
	check(not session.intro_active and session._guide_remaining == 0 and session.player.life.can_control(), "normal load skips completed birth and tutorial")
	check(session.player.position.distance_to(Vector2(224, 896)) < 2 and session.player.life.protection_remaining == 0, "normal load uses formal checkpoint without protection")
	session.player.possibility.gain(2)
	session.player.life.take_hit(3)
	await ticks(90)
	check(paused and session.player.life.state == PlayerLife.State.DEATH_MENU, "Room uses existing death timeline")
	session.ui.call("restart_challenge")
	await ticks(3)
	session = current_scene as StartRoomSession
	check(not session.intro_active and session.player.life.health == 5 and session.player.possibility.balance == 2 and session.player.life.protection_remaining > 2.9, "Room death keeps 50 percent floor rule and respawn protection without replay")
	check(session.data["events"].get(StartRoomSession.BIRTH, false), "death retains birth flag")
	# Walk across flat floor to real exit trigger, without jumping/dodging.
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(200)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode") == "room_boundary", "flat route reaches actual crack trigger")
	check(session.room.config.room_id == "HD_10001_1" and session.get_node("Enemies").get_child_count() == 0, "exit does not invent or load an undelivered Room")
	check(session.store.load_slot(1)["checkpoint"] == StartRoomSession.CHECKPOINT, "exit saves current progress")
	session.ui.call("resume_game")
	Input.action_press("move_right")
	await ticks(25)
	Input.action_release("move_right")
	check(session.player.position.x < 1920, "right boundary prevents falling out of unloaded world")
	Input.action_press("move_left")
	Input.action_press("run")
	await ticks(40)
	Input.action_release("move_left")
	Input.action_press("move_right")
	await ticks(60)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode") == "room_boundary", "ordinary crack connection remains available on revisit")
	session.ui.call("resume_game")
	# Defensive rejection: debug saves are not silently interpreted as formal Room saves.
	var debug_snapshot: Dictionary = session.store.fresh()
	debug_snapshot["checkpoint"] = "graybox_forward"
	session.store.save_slot(2, debug_snapshot)
	check(not session.start_slot(2, false) and session.slot == 1, "foreign checkpoint cannot replace active Room session")
	await close_room()
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("START_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
