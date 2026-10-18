extends SceneTree
var checks: int = 0
var failures: int = 0
var session: RavineDepthSession
var directory: String
var attack_id: int = 1000
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
	check(session.store.save_slot(selected,snapshot) and session.start_slot(selected,false), "valid snapshot loads independently")
	await ticks(4)
	session = current_scene as RavineDepthSession
func enter_depth() -> void:
	await place(Vector2(2368,848))
	await place(Vector2(1824,1152))
func enemies() -> Array[Node]:
	return session.room.get_node("Enemies").get_children()
func disable_enemies() -> void:
	for enemy: Node in enemies():
		enemy.set_physics_process(false)
func kill(enemy: ColorlessEntity) -> void:
	attack_id += 1
	check(enemy.hurtbox.receive_attack(enemy.config.max_health,Vector2.ZERO,session.player,attack_id), "existing hurtbox accepts lethal attack")
func clear() -> void:
	for enemy: Node in enemies():
		kill(enemy as ColorlessEntity)
	await ticks(2)
func pearl() -> RoomPickup:
	return session.room.get_node("Pearl") as RoomPickup
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
	directory = "user://tests/ravine_depth_%d" % Time.get_ticks_usec()
	session = (load("res://world/ravine_depth_session.tscn") as PackedScene).instantiate() as RavineDepthSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 13
	base["balance"] = 0
	for key: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,TownSession.GAZE,RavineRescueSession.HELPED,RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_snapshot(base)
	await enter_depth()
	check(session.room is RavineDepthRoom and session.room.config.room_id == "HD_20001_3" and session.room.config.next_room_id == "HD_20002_1", "actual Room2 road enters configured third ravine Room")
	check(enemies().size()==3 and (enemies()[0] as ColorlessEntity).health==15 and enemies()[2] is MonochromeEntity and session._all_checkpoints().is_empty(), "second-day composition has two strengthened colorless and one monochrome without new checkpoint")
	var monochrome: MonochromeEntity = enemies()[2] as MonochromeEntity
	check(monochrome.health==21 and monochrome.config.reward==7 and not monochrome.flying and monochrome.target==session.player and monochrome.coordinator==session.room.get_node("AttackCoordinator"), "existing ground21HP/reward7 binds to player and shared attack budget")
	disable_enemies()
	await place(Vector2(1824,1280))
	check(not paused and session.room is RavineDepthRoom and not session.data["events"].get(RavineDepthRoom.GATES,false), "forward passage rejects uncleared battle")
	check(not session.settle_depth() and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "interaction cannot rescue before clearing enemies")
	await place(Vector2(350,1280))
	for point: Vector2 in [Vector2(576,1136),Vector2(800,992),Vector2(1120,880)]:
		check(await jump_to(point), "zero-resource jump reaches pearl platform %s; actual %s" % [point,session.player.position])
	check(session.player.possibility.balance==0 and session.data["events"].get(RavineDepthSession.DEPTH_SEEN,false), "route and NPC sighting require no resource")
	Input.action_press("move_right")
	await ticks(20)
	Input.action_release("move_right")
	await ticks(4)
	check(not session.collect_pickup(null), "invalid pickup reference rejected")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.collect_pickup(pearl()) and pearl().visible and not session.data["events"].get(pearl().config.persistence_key,false), "failed pearl save rolls back pickup")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(not pearl().visible and session.store.load_slot(1)["events"].get(pearl().config.persistence_key,false), "real E collects and saves permanent pearl")
	check(session.player.possibility.maximum==13 and session.player.possibility.balance==0 and session.player.life.health==3 and session.player.combat.pearl_count==1 and session.player.combat.range_upgraded and is_equal_approx(session.player.combat.range_multiplier(),1.25), "pearl adds5% to earned Boss20% without health or possibility changes")
	# Use an actual attack for the first hit, then the established hurtbox API for settlement order.
	await place(Vector2(1190,1280))
	Input.action_press("attack")
	await ticks(12)
	Input.action_release("attack")
	check((enemies()[0] as ColorlessEntity).health==10, "real five-damage attack hits second-day lower colorless entity")
	kill(enemies()[0] as ColorlessEntity)
	check(session.player.possibility.balance==2 and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "first enemy pays +2 but cannot finish rescue")
	kill(enemies()[1] as ColorlessEntity)
	await ticks(2)
	check(session.player.possibility.balance==4 and monochrome.health==21 and not session.settle_depth() and not session.data["events"].get(RavineDepthRoom.GATES,false) and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "living monochrome prevents premature rescue and opening after both colorless die")
	session.store.directory = real_directory.path_join("slot_1.json")
	kill(monochrome)
	await ticks(2)
	check(session.player.possibility.balance==11 and session.player.possibility.maximum==13 and not session.data["events"].get(RavineDepthRoom.GATES,false) and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "failed clear settlement rolls back gates rescue and growth while retaining2+2+7 rewards")
	monochrome.hurtbox.receive_attack(21,Vector2.ZERO,session.player,9999)
	check(session.player.possibility.balance==11 and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "dead monochrome cannot pay twice or bypass pending settlement")
	check(session.room.get_node("Gates").visible, "failed clear save keeps gate indicators closed")
	session.store.directory = real_directory
	await ticks(20)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.player.possibility.balance==14 and session.player.possibility.maximum==14 and session.data["events"].get(RavineDepthRoom.GATES,false) and session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "E retries atomic opening and rescue with+1 growth before clipping reward to14")
	var completed: Dictionary = session.store.load_slot(1)
	check(completed["maximum"]==14 and completed["balance"]==14 and completed["events"].get(RavineDepthRoom.GATES,false) and completed["events"].get(RavineDepthSession.DEPTH_HELPED,false), "both gate directions and rescue rewards share saved snapshot")
	check(not session.room.get_node("Gates").visible and session.room.get_node("Survivor/Body").polygon[1]==Vector2(-24,-80) and not session.get_node("Instructions/Help").text.contains("放弃"), "cleared scene shows standing survivor open gates and completed-route guidance")
	check(not session.settle_depth() and session.player.possibility.balance==14, "repeated settlement cannot duplicate rescue reward")
	await place(Vector2(1824,1280))
	check(paused and session.ui.get("_mode")=="room_boundary", "cleared forward exit reaches camp stage boundary")
	session.ui.call("resume_game")
	await place(Vector2(48,1280))
	check(session.room is RavineRescueRoom and session.player.position.distance_to(Vector2(1664,1152))<2, "cleared return enters safe Room2 landing")
	await place(Vector2(1824,1152))
	disable_enemies()
	check((enemies()[0] as ColorlessEntity).health==15 and (enemies()[2] as MonochromeEntity).health==21 and (enemies()[2] as MonochromeEntity).dodge_cooldown_remaining==0 and not pearl().visible and session.data["events"].get(RavineDepthRoom.GATES,false), "second-day revisit resets both enemy types but preserves pearl rescue and open gates")
	session._set_balance(-9)
	await clear()
	check(session.player.possibility.balance==2 and session.player.possibility.maximum==14, "reset enemies again pay2+2+7 from negative balance without repeating rescue")
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RavineDepthSession
	check(session.room is RavineRoom and session.player.possibility.balance==1 and session.player.possibility.maximum==14 and session.player.life.health==5 and session.player.life.protection_remaining>2.8, "death uses entry checkpoint and preserves cap14 with half resources and protection")
	check(session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false) and session.data["day"]==2, "death preserves clear rescue and date")
	await load_snapshot(session.store.load_slot(1))
	check(session.player.possibility.maximum==14 and session.player.life.protection_remaining==0, "normal load preserves growth without death protection")
	await enter_depth()
	disable_enemies()
	check((enemies()[2] as MonochromeEntity).health==21 and session.data["events"].get(RavineDepthRoom.GATES,false) and session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false) and session.player.possibility.balance==1, "post-death normal load respawns monochrome without reclosing saved route or repeating rescue")
	# Early retreat is explicit, transactional and local to this NPC.
	await load_snapshot(base,2)
	await enter_depth()
	disable_enemies()
	await place(Vector2(500,1280))
	await place(Vector2(48,1280))
	check(session.dialogue_ui.confirming and not session.player.life.can_control(), "uncleared return offers explicit permanent-loss retreat")
	session.cancel_departure()
	check(not session.dialogue_ui.active and not session.data["events"].get(RavineDepthSession.DEPTH_FAILED,false), "cancel keeps third NPC available")
	session._on_room_exit(RavineRescueSession.RESCUE_ID)
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	check(not session.confirm_departure() and not session.data["events"].get(RavineDepthSession.DEPTH_FAILED,false), "failed retreat save rolls back abandonment")
	session.store.directory = real_directory
	check(session.confirm_departure(), "confirmed retreat saves permanent abandonment")
	await ticks(4)
	check(session.room is RavineRescueRoom and session.data["events"].get(RavineDepthSession.DEPTH_FAILED,false) and session.data["events"].get(RavineRescueSession.HELPED,false) and not session.data["events"].get(RavineDepthRoom.GATES,false), "retreat preserves second NPC and does not unlock uncleared gates")
	await place(Vector2(1824,1152))
	disable_enemies()
	await place(Vector2(1000,1280))
	await clear()
	check(session.player.possibility.maximum==13 and session.player.possibility.balance==11 and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false) and session.data["events"].get(RavineDepthRoom.GATES,false), "later clear pays2+2+7 and opens gates without repairing abandoned rescue or issuing+4")
	await load_snapshot(base,2)
	await enter_depth()
	disable_enemies()
	await place(Vector2(500,1280))
	session.player.life.take_hit(3)
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RavineDepthSession
	check(session.room is RavineRoom and not session.data["events"].get(RavineDepthSession.DEPTH_FAILED,false), "death before clearing never abandons the rescue")
	await load_snapshot(session.store.load_slot(2),2)
	check(not session.data["events"].get(RavineDepthSession.DEPTH_FAILED,false), "normal load of unfinished battle does not abandon rescue")
	# Early help before gaze is stored, then both independent NPC increments settle together.
	var pending: Dictionary = base.duplicate(true)
	pending["events"].erase(TownSession.GAZE)
	pending["maximum"] = 10
	pending["balance"] = -2
	await load_snapshot(pending,3)
	await enter_depth()
	disable_enemies()
	await place(Vector2(1000,1280))
	await clear()
	check(session.player.possibility.maximum==10 and session.player.possibility.balance==10 and session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false), "negative balance clear rescue clips rewards to base10 and stores pending growth")
	await load_snapshot(session.store.load_slot(3),3)
	await place(Vector2(48,1280))
	await place(Vector2(48,896))
	await place(Vector2(1680,896))
	await ticks(12)
	check(session.interact_seven(), "first gaze can settle both pending ravine rescues")
	await finish_dialogue()
	await ticks(100)
	check(session.player.possibility.maximum==14 and session.player.possibility.balance==10 and session.store.load_slot(3)["maximum"]==14, "first gaze yields10 plus2 plus1 plus1 without refilling balance")
	# Either NPC can independently supply the first post-gaze +1.
	var independent: Dictionary = base.duplicate(true)
	independent["events"].erase(RavineRescueSession.HELPED)
	independent["events"][RavineRescueSession.FAILED] = true
	independent["maximum"] = 12
	await load_snapshot(independent,2)
	await enter_depth()
	disable_enemies()
	await place(Vector2(1000,1280))
	await clear()
	check(session.player.possibility.maximum==13 and session.data["events"].get(RavineDepthSession.DEPTH_HELPED,false) and session.data["events"].get(RavineRescueSession.FAILED,false), "third NPC independently raises12 to13 without undoing second NPC failure")
	var invalid: Dictionary = completed.duplicate(true)
	invalid["events"][RavineDepthSession.DEPTH_FAILED] = true
	check(not session.store.valid(invalid), "contradictory third rescue completion and failure rejected")
	invalid = base.duplicate(true)
	invalid["maximum"] = 14
	check(not session.store.valid(invalid), "cap14 requires both actual growth sources")
	invalid = completed.duplicate(true)
	invalid["maximum"] = 15
	check(not session.store.valid(invalid), "undelivered cap15 rejected")
	check(session.store.load_slot(1)["maximum"]==14 and session.store.load_slot(2)["maximum"]==13, "growth and quest state stay isolated by slot")
	session.start_slot(2,true)
	await ticks(4)
	session = current_scene as RavineDepthSession
	check(session.player.possibility.maximum==10 and not session.data["events"].has(RavineDepthSession.DEPTH_HELPED), "new game resets independent rescue and growth")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected)+suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("RAVINE_DEPTH_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
