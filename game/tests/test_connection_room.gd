extends SceneTree
var checks: int = 0
var failures: int = 0
var session: ConnectionSession
var directory: String

func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func open_session() -> void:
	session = (load("res://world/connection_session.tscn") as PackedScene).instantiate() as ConnectionSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
func close_session() -> void:
	paused = false
	session.queue_free()
	await ticks(2)
func enemy() -> ColorlessEntity:
	return session.room.get_node("Enemies/Entity") as ColorlessEntity
func enter_connection() -> void:
	session._on_room_exit(TowerSession.TOWER_ID)
	await ticks(4)
	session._on_room_exit(ExplorationSession.EXPLORATION_ID)
	await ticks(4)
	session.player.position = Vector2(2416, 520)
	session.player.reset_kinematics()
	await ticks(4)
	enemy().set_physics_process(false)
func place(position: Vector2) -> void:
	session.player.position = position
	session.player.reset_kinematics()
	await ticks(4)
func run() -> void:
	directory = "user://tests/connection_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for key: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER]:
		snapshot["events"][key] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "previous slot remains compatible")
	await ticks(3)
	await enter_connection()
	check(session.room.config.room_id == ConnectionSession.CONNECTION_ID, "actual Room3 exit enters connection Room")
	check(session.room.config.scene_id == "Region_HD_Scene_10003" and session.room.config.next_room_id == "HD_10004_1", "frozen scene identity and target")
	check(session._all_checkpoints().is_empty() and session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "confirmed entry checkpoint retained")
	check(session.room.get_node("Enemies").get_child_count() == 1 and enemy().health == 13, "existing colorless enemy reused")
	var area: ConnectionRoom = session.room as ConnectionRoom
	await place(Vector2(48, 896))
	check(session.room == area and not paused, "living enemy locks actual return trigger")
	await place(Vector2(1488, 896))
	check(not paused and session.room == area, "living enemy locks actual forward trigger")
	await place(Vector2(1184, 896))
	check(not session.activate_switch(), "nearby switch rejects before clear")
	check(not session.data["events"].get(area.forward_key, false), "rejected switch writes no unlock")
	# Ordinary movement and jump through the local platform route, without dodge.
	await place(Vector2(416, 896))
	session.player.possibility.balance = 0
	Input.action_press("jump")
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	await ticks(24)
	Input.action_release("jump")
	check(session.player.is_on_floor() and absf(session.player.position.y - 752) < 2, "ordinary jump reaches narrow Room platform: %s" % session.player.position)
	check(session.player.possibility.balance == 0, "platform route spends no possibility")
	await place(Vector2(848, 896))
	session.player.facing = 1
	Input.action_press("attack")
	await ticks(30)
	Input.action_release("attack")
	check(enemy().health == 8, "actual attack damages connection enemy")
	await ticks(30)
	# Finish through the actual Hurtbox, exercising defeat signal and gate save.
	enemy().hurtbox.receive_attack(8, Vector2.ZERO, session.player, 999)
	await ticks(3)
	check(session._cleared() and session.data["events"].get(area.return_key, false), "last defeat automatically unlocks return")
	check(session.player.possibility.balance == 2, "first defeat still awards +2")
	check(session.store.load_slot(1)["events"].get(area.return_key, false), "return unlock immediately saved")
	check(not session.activate_switch(), "remote switch activation rejected after clear")
	await place(Vector2(1488, 896))
	check(not paused, "clear alone does not unlock forward passage")
	await place(Vector2(1184, 896))
	check(area.get_node("Switch/Prompt").visible, "nearby cleared switch displays prompt")
	session.ui.call("show_pause")
	check(not session.activate_switch(), "paused interaction rejected")
	session.ui.call("resume_game")
	session.player.combat.phase = PlayerCombat.Phase.WINDUP
	check(not session.activate_switch(), "switch cannot cancel attack")
	session.player.combat.interrupt()
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.activate_switch() and not session.data["events"].get(area.forward_key, false), "write failure rolls forward unlock back")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(area.forward_open and session.store.load_slot(1)["events"].get(area.forward_key, false), "E input permanently opens and saves forward passage")
	check(str(session.ui.get("_error_label").text).is_empty(), "retry clears stale save error")
	check(not session.activate_switch(), "open switch cannot activate twice")
	await place(Vector2(1488, 896))
	check(paused and session.ui.get("_mode") == "room_boundary", "opened forward passage stops at unimplemented Boss boundary")
	session.ui.call("resume_game")
	await place(Vector2(48, 896))
	check(session.room.config.room_id == ExplorationSession.EXPLORATION_ID and session.player.position.distance_to(Vector2(2208, 520)) < 2, "unlocked downward return reaches Room3 upper entrance")
	await place(Vector2(2416, 520))
	enemy().set_physics_process(false)
	area = session.room as ConnectionRoom
	check(enemy().health == 13 and area.return_open and area.forward_open, "revisit resets enemy while preserving both opened passages")
	enemy().hurtbox.receive_attack(13, Vector2.ZERO, session.player, 1000)
	await ticks(3)
	check(session.player.possibility.balance == 4, "reset enemy awards another +2")
	enemy()._on_hit(13, Vector2.ZERO, session.player, 1001)
	check(session.player.possibility.balance == 4, "dead instance cannot award twice")
	session.player.life.take_hit(5)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as ConnectionSession
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.possibility.balance == 2, "death returns to entry with floor half balance")
	check(session.data["events"].get("gate:HD_10003_1:forward", false), "death retains opened mechanism")
	await close_session()
	await open_session()
	session.start_slot(1, false)
	await ticks(3)
	await enter_connection()
	area = session.room as ConnectionRoom
	check(area.return_open and area.forward_open and enemy().health == 13, "normal load retains gates but resets enemy")
	check(session.player.life.protection_remaining == 0, "normal load grants no death protection")
	await place(Vector2(1488, 896))
	check(paused, "permanent forward passage remains usable before new enemy clear")
	session.ui.call("resume_game")
	await close_session()
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(store.path_for(1) + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("CONNECTION_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
