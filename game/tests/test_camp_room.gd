# verify-suite: {"name": "deserter camp exploration and persistent pearl", "path": "res://tests/test_camp_room.gd", "marker": "CAMP_ROOM_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: CampSession
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
	check(session.store.save_slot(selected,snapshot) and session.start_slot(selected,false), "existing snapshot loads in extended session")
	await ticks(4)
	session = current_scene as CampSession
func enter_camp() -> void:
	await place(Vector2(2368,848))
	await place(Vector2(1824,1152))
	await place(Vector2(1824,1280))
func enemies() -> Array[Node]:
	return session.room.get_node("Enemies").get_children()
func disable_enemies() -> void:
	for enemy: Node in enemies():
		enemy.set_physics_process(false)
func pearl() -> RoomPickup:
	return session.room.get_node("Pearl") as RoomPickup
func mono() -> MonochromeEntity:
	return session.room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(30)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = point.x-session.player.position.x
		if absf(dx)>10:
			Input.action_press("move_right" if dx>0 else "move_left")
		await ticks(1)
		if i>4 and session.player.is_on_floor():
			reached = absf(session.player.position.y-point.y)<2 and absf(session.player.position.x-point.x)<110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func run() -> void:
	directory = "user://tests/camp_%d" % Time.get_ticks_usec()
	session = (load("res://world/camp_session.tscn") as PackedScene).instantiate() as CampSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 14
	base["balance"] = 0
	for key: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,TownSession.GAZE,RavineRescueSession.HELPED,RavineDepthSession.DEPTH_HELPED,RavineDepthRoom.GATES,RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_snapshot(base)
	await enter_camp()
	check(session.room is CampRoom and session.room.config.room_id=="HD_20002_1" and session.room.config.scene_id=="Region_HD_Scene_20002", "actual cleared ravine exit enters first deserter camp Room")
	check(session.room.config.previous_room_id=="HD_20001_3" and session.room.config.next_room_id=="HD_20002_2", "camp uses frozen adjacent Room identifiers")
	check(enemies().size()==4 and enemies()[3] is MonochromeEntity and session._all_checkpoints().is_empty() and not session.room.has_node("Survivor"), "camp keeps three colorless and adds existing monochrome without NPC or checkpoint")
	check(mono().health==21 and mono().config.reward==7 and not mono().flying and mono().target==session.player and mono().coordinator==session.room.get_node("AttackCoordinator"), "ground monochrome reuses21HP/reward7 and shared attack budget")
	check(mono().position.is_equal_approx(Vector2(1760,1280)) and mono().is_on_floor(), "monochrome starts on real floor below upper route away from entry")
	check(session.data["checkpoint"]==RavineSession.RAVINE_CHECKPOINT and session.data["day"]==2 and session.player.possibility.balance==0 and session.player.possibility.maximum==14, "crossing into camp preserves resources date and checkpoint")
	var camera: Camera2D = session.player.get_node("Camera2D") as Camera2D
	check(camera.limit_right==3072 and camera.limit_bottom==1536, "camera limits follow larger camp Room")
	disable_enemies()
	await place(Vector2(48,1280))
	check(session.room is RavineDepthRoom and session.player.position.distance_to(Vector2(1664,1280))<2 and not session.dialogue_ui.confirming, "living camp enemies do not prevent actual safe return")
	await place(Vector2(1824,1280))
	disable_enemies()
	check(not session.collect_pickup(pearl()), "distant pearl cannot be collected")
	await place(Vector2(768,1280))
	check(await jump_to(Vector2(1024,1152)), "ordinary jump reaches central high ground at zero possibility")
	Input.action_press("move_right")
	await ticks(35)
	Input.action_release("move_right")
	await ticks(30)
	for point: Vector2 in [Vector2(1424,1136),Vector2(1648,992),Vector2(1872,848)]:
		check(await jump_to(point), "ordinary jump reaches camp platform %s; actual %s" % [point,session.player.position])
	check(session.player.possibility.balance==0 and pearl().can_collect(session.player), "zero-resource route reaches actual pearl interaction radius")
	var collected_health: int = session.player.life.health
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.collect_pickup(pearl()) and pearl().visible and not session.data["events"].get(pearl().config.persistence_key,false), "failed pearl write rolls back state and visibility")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(not pearl().visible and session.store.load_slot(1)["events"].get("keyitem:HD_20002_1:pearl_01",false), "real E collects and persists camp pearl")
	check(not session.collect_pickup(pearl()) and session.player.possibility.maximum==14 and session.player.possibility.balance==0 and session.player.life.health==collected_health, "duplicate pearl cannot change resources growth or pre-pickup health after environmental traversal")
	check(not session.data["events"].get("keyitem:HD_20001_3:pearl_01",false), "camp and ravine pearls have independent ownership")
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(200)
	Input.action_release("move_right")
	Input.action_release("run")
	check(paused and session.ui.get("_mode")=="room_boundary" and (enemies()[0] as ColorlessEntity).health==15 and mono().health==21, "main route reaches next camp boundary with second-day colorless and unchanged monochrome alive")
	check(session.player.possibility.balance==0 and session.data["day"]==2, "traversal and boundary charge no resources or date changes")
	session.ui.call("resume_game")
	# A real down attack is possible on open ground, independent of platform traversal.
	await place(Vector2(600,1126))
	Input.action_press("aim_down")
	Input.action_press("attack")
	var bounced: bool = false
	for i: int in range(30):
		await ticks(1)
		if (enemies()[0] as ColorlessEntity).health<15:
			bounced = session.player.velocity.y<0
			break
	Input.action_release("attack")
	Input.action_release("aim_down")
	check((enemies()[0] as ColorlessEntity).health==10 and bounced, "actual down attack deals five and bounces from second-day camp enemy")
	(enemies()[0] as ColorlessEntity).hurtbox.receive_attack(10,Vector2.ZERO,session.player,3000)
	await ticks(2)
	check(session.player.possibility.balance==2, "existing camp enemy gives established +2 defeat reward")
	var before_monochrome: Dictionary = session.data["events"].duplicate()
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,3100)
	check(session.player.possibility.balance==9 and session.store.load_slot(1)["balance"]==9, "monochrome kill immediately saves its independent+7 reward")
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,3101)
	check(session.player.possibility.balance==9 and session.data["events"]==before_monochrome, "corpse cannot reward twice or invent permanent progress")
	await place(Vector2(48,1280))
	await place(Vector2(1824,1280))
	disable_enemies()
	check((enemies()[0] as ColorlessEntity).health==15 and mono().health==21 and mono().dodge_cooldown_remaining==0 and not pearl().visible, "second-day revisit resets both enemy types while preserving pearl collection")
	(enemies()[0] as ColorlessEntity).hurtbox.receive_attack(15,Vector2.ZERO,session.player,3001)
	check(session.player.possibility.balance==11, "reset colorless enemy still gives+2 independently of monochrome reward")
	session._set_balance(-9)
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,3102)
	check(session.player.possibility.balance==-2 and session.store.load_slot(1)["balance"]==-2, "reset monochrome again pays full7 from negative balance")
	# Preserve the existing odd-balance death fixture after independently testing rewards.
	session._set_balance(7)
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as CampSession
	check(session.room is RavineRoom and session.player.life.health==5 and session.player.possibility.balance==3 and session.player.possibility.maximum==14 and session.player.life.protection_remaining>2.8, "death returns to existing ravine checkpoint with full health floor half resources and protection")
	check(session.data["day"]==2 and session.data["events"].get("keyitem:HD_20002_1:pearl_01",false) and session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "death retains date pearl and previous rescue")
	await load_snapshot(session.store.load_slot(1))
	check(session.player.possibility.balance==3 and session.player.life.protection_remaining==0, "normal load preserves current resources without revive protection")
	await enter_camp()
	disable_enemies()
	check(not pearl().visible and (enemies()[0] as ColorlessEntity).health==15 and mono().health==21 and mono().dodge_cooldown_remaining==0, "post-death second-day load restores pearl ownership and both enemy types")
	await place(Vector2(48,1280))
	var saved: Dictionary = session.store.load_slot(1)
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await place(Vector2(1824,1280))
	check(session.room is RavineDepthRoom and not session._transitioning, "failed transition save stays in previous Room")
	session.store.directory = real_directory
	session._on_room_exit(CampSession.CAMP_ID)
	await ticks(4)
	check(session.room is CampRoom and session.data["events"]==saved["events"], "retry enters camp without losing permanent state")
	await load_snapshot(base,2)
	await enter_camp()
	disable_enemies()
	check(pearl().visible and session.player.possibility.balance==0 and session.store.load_slot(1)["events"].get("keyitem:HD_20002_1:pearl_01",false), "different slot has its own pearl and resources")
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,3103)
	check(session.player.possibility.balance==7 and session.store.load_slot(1)["balance"]==3, "monochrome rewards stay isolated between slots")
	session.start_slot(2,true)
	await ticks(4)
	session = current_scene as CampSession
	check(session.room.config.room_id==TwoRoomSession.START_ID and session.player.possibility.maximum==10 and not session.data["events"].has("keyitem:HD_20002_1:pearl_01"), "new game clears camp progress without touching other slot")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1,2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected)+suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("CAMP_ROOM_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
