# verify-suite: {"name": "adjacent Rooms and first encounter", "path": "res://tests/test_two_rooms.gd", "marker": "TWO_ROOM_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TwoRoomSession
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

func enter(target: String) -> void:
	session._on_room_exit(target)
	await ticks(3)

func enemy() -> ColorlessEntity:
	return session.room.get_node("Enemies/GroundEntity") as ColorlessEntity

func kill_enemy() -> void:
	var receiver: CombatHurtbox = enemy().get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.receive_attack(20, Vector2.ZERO, session.player, 700)

func open_session() -> void:
	session = (load("res://world/two_room_session.tscn") as PackedScene).instantiate() as TwoRoomSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)

func close_session() -> void:
	paused = false
	session.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	directory = "user://tests/two_rooms_%d" % Time.get_ticks_usec()
	await open_session()
	check(paused and session.room.config.room_id == TwoRoomSession.START_ID, "new session begins at starting Room slot menu")
	# Existing previous-stage Room save remains directly loadable.
	var snapshot: Dictionary = session.store.fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["events"][StartRoomSession.GUIDE] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "previous first-Room save remains compatible")
	await ticks(5)
	check(not session.intro_active and session.player.life.health == 3, "completed birth does not replay")
	check((TwoRoomSession.ROOMS[TwoRoomSession.START_ID] as PackedScene) != null and (TwoRoomSession.ROOMS[TwoRoomSession.ENTRY_ID] as PackedScene) != null, "both adjacent Room resources preload")
	var previous_room: WeakRef = weakref(session.room)
	session.player.position = Vector2(1810, 896)
	await ticks(4)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and previous_room.get_ref() == null, "real crack trigger replaces and unloads old Room")
	check(session.get_node("Room") == session.room and session.ground == session.room.get_node("Ground"), "one active Room owns geometry and checkpoint lookup")
	check(session.player.position.x >= 120 and session.player.position.x < 200 and session.player.life.health == 3 and session.player.possibility.balance == 3, "transition preserves resources and enters clear of return trigger")
	await ticks(5)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID, "transition cannot immediately ping-pong")
	session.room._on_exit_entered(session.player)
	check(not paused, "stale pre-teleport exit cannot open next boundary")
	check(session.room.config.scene_id == "Region_HD_Scene_10002" and session.room.config.next_room_id == "HD_10002_2", "entry identity and future road match T5")
	check(session.ground.get_cell_source_id(Vector2i(13, 16)) == 0, "raised terrain retains continuous ground foundation")
	check(enemy().health == 13 and not enemy().is_physics_processing(), "first encounter waits for actual introduction trigger")
	session.player.position = Vector2(288, 896)
	session.player.velocity = Vector2.ZERO
	await ticks(4)
	check(session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT and session.store.load_slot(1)["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "Room 2 checkpoint automatically persists: %s / %s" % [session.player.position, session.data["checkpoint"]])
	session.player.position = Vector2(608, 896)
	await ticks(4)
	check(session.data["events"].get(TwoRoomSession.ENCOUNTER, false) and enemy().is_physics_processing(), "actual introduction trigger enables normal enemy AI: %s" % session.player.position)
	var intro: PanelContainer = session.ui.get("_enemy_intro") as PanelContainer
	check(intro.visible and session.player.life.can_control() and not paused, "right-top intro card leaves player in control")
	check(session.store.load_slot(1)["events"].get(TwoRoomSession.ENCOUNTER, false), "first introduction flag saves immediately")
	session.ui.call("show_pause")
	var remaining: float = session.ui.get("_enemy_intro_remaining")
	var card_position: Vector2 = intro.position
	await ticks(4)
	check(session.ui.get("_enemy_intro_remaining") == remaining and intro.position == card_position, "pause freezes intro timer and slide animation")
	session.ui.call("resume_game")
	session.player.position = Vector2(1080, 896)
	session.player.reset_kinematics()
	await ticks(38)
	check(session.player.life.health < 3, "Room enemy performs real melee damage after introduction")
	# Isolate traversal checks from the accepted hit's temporary stun.
	session.player.life.start_new_run()
	# Terrain requires ordinary jump, without relying on resource-consuming dodge.
	session.player.position = Vector2(700, 896)
	session.player.reset_kinematics()
	Input.action_press("move_right")
	await ticks(20)
	check(session.player.position.x < 768, "raised terrain blocks simply walking through high ledge")
	Input.action_press("jump")
	await ticks(25)
	Input.action_release("jump")
	Input.action_release("move_right")
	check(session.player.position.x > 768 and session.player.position.y < 800, "ordinary jump reaches raised route without dodge")
	session.player.possibility.balance = 0
	session.player.possibility.balance_changed.emit(0, 10)
	kill_enemy()
	check(session.player.possibility.balance == 2, "first real defeat awards 2 possibility")
	kill_enemy()
	check(session.player.possibility.balance == 2, "dead instance cannot award twice")
	session.player.position = Vector2(48, 896)
	session.player.velocity = Vector2.ZERO
	await ticks(4)
	check(session.room.config.room_id == TwoRoomSession.START_ID and session.player.position.x > 1600 and not session.intro_active, "reverse transition returns through crack without replaying birth")
	check(session.player.possibility.balance == 2, "returning does not refill or spend possibility")
	await enter(TwoRoomSession.ENTRY_ID)
	check(enemy().health == 13 and enemy().is_physics_processing() and not intro.visible, "revisit resets enemy and retains introduction state")
	kill_enemy()
	check(session.player.possibility.balance == 4, "producer rule: reset enemy awards 2 again")
	check(session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "transition alone does not replace latest checkpoint")
	# Death in a Room reloads its saved checkpoint and refreshes the enemy.
	session.player.life.protection_remaining = 0
	session.player.life.hurt_remaining = 0
	session.player.life.take_hit(5)
	await ticks(90)
	check(paused, "death menu pauses two-Room session")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as TwoRoomSession
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.position.distance_to(Vector2(288, 896)) < 2, "death mounts Room containing last checkpoint before restoring player")
	if session.room.config.room_id != TwoRoomSession.ENTRY_ID:
		await close_session()
		quit(1)
		return
	check(session.player.life.health == 5 and session.player.possibility.balance == 2 and session.player.life.protection_remaining > 2.8, "cross-Room death preserves frozen settlement and protection")
	check(enemy().health == 13 and not (session.ui.get("_enemy_intro") as PanelContainer).visible, "death resets enemy without replaying introduction")
	kill_enemy()
	check(session.player.possibility.balance == 4, "death-reset enemy still awards possibility")
	session.save_current()
	await close_session()
	await open_session()
	check(session.start_slot(1, false), "saved Room 2 checkpoint loads from initial Room selection")
	await ticks(3)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.possibility.balance == 4 and session.player.life.protection_remaining == 0, "normal load mounts Room 2 preserving resources without protection")
	check(enemy().health == 13 and enemy().is_physics_processing(), "load resets ordinary enemy but retains intro flag")
	kill_enemy()
	check(session.player.possibility.balance == 6, "normal-load reset enemy still awards possibility")
	# An old Room's temporary projectile dies with its owning Room.
	var projectile: Node2D = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate() as Node2D
	session.room.get_node("Enemies").add_child(projectile)
	var shot: WeakRef = weakref(projectile)
	await enter(TwoRoomSession.START_ID)
	check(shot.get_ref() == null, "Room unloading removes transient projectiles")
	await enter(TwoRoomSession.ENTRY_ID)
	session.player.position = Vector2(1810, 896)
	await ticks(4)
	check(paused and session.ui.get("_mode") == "room_boundary" and session.room.config.room_id == TwoRoomSession.ENTRY_ID, "future road ends at delivered boundary without inventing third Room")
	await close_session()
	var cleanup: SlotStore = SlotStore.new()
	cleanup.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(cleanup.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("TWO_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
