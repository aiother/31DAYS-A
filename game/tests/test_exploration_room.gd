# verify-suite: {"name": "exploration Room and persistent pearl placeholder", "path": "res://tests/test_exploration_room.gd", "marker": "EXPLORATION_ROOM_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: ExplorationSession
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
	session = (load("res://world/exploration_session.tscn") as PackedScene).instantiate() as ExplorationSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
func disable_enemies() -> void:
	for actor: Node in session.room.get_node("Enemies").get_children():
		actor.set_physics_process(false)
func pearl() -> RoomPickup:
	return session.room.get_node("Pearl") as RoomPickup
func jump_to(target: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(2)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = target.x - session.player.position.x
		if absf(dx) > 10:
			Input.action_press("move_right" if dx > 0 else "move_left")
		await ticks(1)
		if i > 4 and session.player.is_on_floor():
			reached = absf(session.player.position.y - target.y) < 2 and absf(session.player.position.x - target.x) < 110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func enter_room3() -> void:
	session._on_room_exit(TowerSession.TOWER_ID)
	await ticks(4)
	session.player.position = Vector2(1760, 640)
	session.player.reset_kinematics()
	await ticks(4)
func close_session() -> void:
	paused = false
	session.queue_free()
	await process_frame
	await process_frame
func run() -> void:
	directory = "user://tests/exploration_%d" % Time.get_ticks_usec()
	await open_session()
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for key: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER]:
		snapshot["events"][key] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "previous checkpoint save remains compatible")
	await ticks(3)
	session._on_room_exit(ExplorationSession.EXPLORATION_ID)
	await ticks(2)
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID, "room registry cannot bypass non-adjacent connections")
	await enter_room3()
	check(session.room.config.room_id == ExplorationSession.EXPLORATION_ID and not paused, "real upward Room2 passage enters Room3")
	check(session.room.config.scene_id == "Region_HD_Scene_10002" and session.room.config.next_room_id == "HD_10003_1", "Room3 identity and upward target match T5")
	check(session._all_checkpoints().is_empty() and session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "confirmed scope keeps entry checkpoint and adds no undefined Node")
	check(session.room.get_node("Enemies").get_child_count() == 2 and session.room.has_node("BrokenPillar"), "Room3 reuses colorless enemies and pillar geometry")
	check((session.player.get_node("Camera2D") as Camera2D).limit_right == 2560, "camera adopts larger exploration Room")
	check(not session.collect_pickup(pearl()), "distant pearl cannot be collected remotely")
	disable_enemies()
	session.player.possibility.balance = 0
	session.player.possibility.balance_changed.emit(0, 10)
	session.player.position = Vector2(192, 1536)
	session.player.reset_kinematics()
	await ticks(4)
	for target: Vector2 in [Vector2(400, 1376), Vector2(624, 1216), Vector2(848, 1056), Vector2(1072, 896), Vector2(1390, 896)]:
		var reached: bool = await jump_to(target)
		check(reached, "ordinary jump reaches exploration landing %s; actual %s" % [target, session.player.position])
		if not reached:
			break
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	await ticks(5)
	for target: Vector2 in [Vector2(1776, 752), Vector2(2000, 600), Vector2(2250, 520)]:
		var reached: bool = await jump_to(target)
		check(reached, "upper arm reaches landing %s; actual %s" % [target, session.player.position])
		if not reached:
			break
	Input.action_press("move_right")
	await ticks(60)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode") == "room_boundary", "main route reaches next-scene boundary without pearl")
	check(session.player.possibility.balance == 0 and not session.data["events"].get(pearl().config.persistence_key, false), "zero-resource traversal needs neither pearl nor dodge")
	session.ui.call("resume_game")
	# Real downward attack uses existing damage and bounce against alcove enemy.
	session.player.position = Vector2(1008, 1510)
	session.player.reset_kinematics()
	await ticks(1)
	var enemy: ColorlessEntity = session.room.get_node("Enemies/DownAttackEntity") as ColorlessEntity
	Input.action_press("aim_down")
	Input.action_press("attack")
	var bounced: bool = false
	for i: int in range(30):
		await ticks(1)
		if enemy.health < 13:
			bounced = session.player.velocity.y < 0
			break
	Input.action_release("attack")
	Input.action_release("aim_down")
	check(enemy.health == 8 and bounced, "optional lower route permits real down-attack damage and bounce")
	session.player.position = Vector2(1120, 1664)
	session.player.reset_kinematics()
	await ticks(4)
	var item: RoomPickup = pearl()
	check(item.visible and not item.prompt.visible and session.interaction_targets().any(func(value: Dictionary) -> bool: return value["id"] == item.config.persistence_key and value["available"]), "nearby pearl stays interactable via formal query without duplicate gray text")
	session.ui.call("show_pause")
	check(not session.collect_pickup(item), "paused game refuses pickup even when nearby")
	session.ui.call("resume_game")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.collect_pickup(item) and not session.data["events"].get(item.config.persistence_key, false) and item.visible, "write failure rolls pickup back instead of claiming success")
	session.store.directory = real_directory
	session.player.combat.phase = PlayerCombat.Phase.WINDUP
	check(not session.collect_pickup(item), "interaction cannot cancel ongoing attack")
	session.player.combat.interrupt()
	var health: int = session.player.life.health
	var damage: int = session.player.combat.config.damage
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	check(not item.visible and session.store.load_slot(1)["events"].get(item.config.persistence_key, false), "E input collects pearl and immediately persists state")
	check(str(session.ui.get("_error_label").text).is_empty(), "successful retry clears stale write failure feedback")
	check(session.player.life.health == health and session.player.possibility.balance == 0 and session.player.combat.config.damage == damage and session.player.combat.pearl_count == 1 and is_equal_approx(session.player.combat.range_multiplier(),1.05), "pearl grants5% reach without health resource or damage changes")
	check(not session.collect_pickup(item), "collected pearl cannot be collected twice")
	# Escape the optional recess using only ordinary jump.
	Input.action_press("move_left")
	await ticks(25)
	Input.action_release("move_left")
	await ticks(5)
	check(await jump_to(Vector2(832, 1536)), "walk toward recess edge and jump out without spending possibility: %s" % session.player.position)
	session.player.position = Vector2(48, 1536)
	session.player.reset_kinematics()
	await ticks(4)
	check(session.room.config.room_id == TowerSession.TOWER_ID and session.player.position.distance_to(Vector2(1568, 640)) < 2, "downward return restores Room2 upper entrance")
	session.player.position = Vector2(1760, 640)
	session.player.reset_kinematics()
	await ticks(4)
	disable_enemies()
	check(not pearl().visible, "pearl remains absent after Room unload and revisit")
	session.player.possibility.gain(5)
	session.player.life.take_hit(5)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as ExplorationSession
	check(session.room.config.room_id == TwoRoomSession.ENTRY_ID and session.player.life.health == 5 and session.player.possibility.balance == 2, "Room3 death returns to entry checkpoint with existing settlement")
	check(session.data["events"].get("item:HD_10002_3:pearl_01", false), "death retains collected pearl")
	await close_session()
	await open_session()
	session.start_slot(1, false)
	await ticks(3)
	await enter_room3()
	check(not pearl().visible and session.player.life.protection_remaining == 0, "normal load retains pickup without granting respawn protection")
	await close_session()
	var cleanup: SlotStore = SlotStore.new()
	# AudioServer releases stopped playback asynchronously after Room teardown.
	await create_timer(0.2).timeout
	cleanup.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(cleanup.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("EXPLORATION_ROOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
