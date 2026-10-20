# verify-suite: {"name": "final waves support permanent victory and ending", "path": "res://tests/test_final_battle.gd", "marker": "FINAL_BATTLE_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func arena() -> FinalBattlefieldRoom:
	return session.room as FinalBattlefieldRoom
func quiet() -> void:
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
	if arena()!=null:
		for child: Node in arena().get_node("Allies").get_children():
			child.set_physics_process(false)
func kill_wave() -> void:
	for child: Node in arena().get_node("Enemies").get_children():
		if child is ColorlessEntity:
			var enemy: ColorlessEntity = child as ColorlessEntity
			enemy.hurtbox.receive_attack(enemy.health,Vector2.ZERO,session.player,8000)
	await ticks(66)
	quiet()
func run() -> void:
	directory = "user://tests/final_battle_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	snapshot["balance"] = -9
	snapshot["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	for key: String in [TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]:
		snapshot["events"][key] = true
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false),"old rescued save loads in final battle entry")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450,896)
	session.player.reset_kinematics()
	await ticks(4)
	quiet()
	check(arena().phase==RescueBattlefieldRoom.Phase.COOP and arena().wave_index==0 and arena().get_node("Enemies").get_child_count()==3,"rescued save begins first final wave without replaying rescue")
	check(session.data["events"].get(FinalClock.STARTED,false) and session.data["final_budget"]==900 and session.data["final_remaining"]<900,"formal start persists bounded final clock")
	var remaining: float = session.data["final_remaining"]
	paused = true
	await ticks(8)
	check(session.data["final_remaining"]==remaining,"pause freezes final budget")
	paused = false
	await kill_wave()
	check(arena().wave_index==1 and arena().wave_state==FinalBattlefieldRoom.WaveState.WARNING,"first clear advances to explicit second-wave warning")
	check(arena().arrivals==2 and arena().get_node("Allies").get_child_count()==3,"first wave first Tian summons two regular survivors beside Ten")
	await ticks(65)
	quiet()
	check(arena().get_node("Enemies").get_child_count()==4 and arena().get_node("FinalPlatforms").get_child_count()==0,"second wave has three Tian and one monochrome without early platforms")
	await kill_wave()
	check(arena().wave_index==2 and arena().wave_state==FinalBattlefieldRoom.WaveState.WARNING,"second wave clear schedules last wave")
	await ticks(65)
	quiet()
	check(arena().get_node("Enemies").get_child_count()==6 and arena().get_node("FinalPlatforms").get_child_count()==3,"last wave has four Tian two monochrome and three platforms")
	check(arena().final_support_spawned and arena().get_node("Allies").get_child_count()==9,"last wave adds four extra survivors after two batches in each earlier wave")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await kill_wave()
	check(session._win_pending and not session.data["events"].get(FinalClock.WON,false),"failed final victory save rolls back permanent win")
	check((arena().get_node("LeftBoundary") as StaticBody2D).collision_layer==1,"failed save cannot open permanent return gate")
	remaining = session.data["final_remaining"]
	await ticks(8)
	check(session.data["final_remaining"]==remaining,"pending victory freezes timer while awaiting retry")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.data["events"].get(FinalClock.WON,false) and arena().victory,"E retries and persists final victory")
	check((arena().get_node("LeftBoundary") as StaticBody2D).collision_layer==0 and session.data["day"]==3 and session.player.possibility.maximum==10,"victory opens only existing return without growth or date changes")
	check(arena().get_node("Allies").get_child_count()==11,"last wave also awards its two ordinary reinforcements")
	remaining = session.data["final_remaining"]
	await ticks(12)
	check(session.data["final_remaining"]==remaining,"saved victory permanently stops countdown")
	session.player.position = Vector2(48,896)
	session.player.reset_kinematics()
	await ticks(4)
	quiet()
	check(session.room is TrenchPassageRoom and session.player.position.distance_to(Vector2(1784,944))<10,"victory allows actual return to existing safe passage entry")
	session.player.position = Vector2(1856,944)
	session.player.reset_kinematics()
	await ticks(4)
	check(arena()!=null and arena().victory and arena().get_node("Enemies").get_child_count()==0,"revisit preserves victory and does not regenerate final enemies")
	session.player.position = Vector2(950,896)
	session.player.reset_kinematics()
	await ticks(2)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session._final_talk and session.dialogue_ui.active and not session.player.is_physics_processing(),"near Ten interaction starts locked temporary victory dialogue")
	await ticks(12)
	check(session.intro_active and session.player.life.scripted_control_locked and not session.data["events"].has(StartRoomSession.BIRTH),"victory dialogue cannot run inherited birth sequence or unlock control")
	session.store.directory = real_directory.path_join("slot_1.json")
	for i: int in range(4):
		session.dialogue_ui.advance()
	check(not session.data["events"].get(FinalClock.TALK,false) and session.dialogue_ui.active,"failed dialogue completion save remains retryable without ending")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	check(session._ending_active and session.data["events"].get(FinalClock.TALK,false),"saved dialogue starts temporary ending once")
	session.store.directory = real_directory.path_join("slot_1.json")
	await ticks(185)
	check(session._ending_pending and not session.data["events"].get(FinalClock.END,false),"failed ending save cannot claim completed V0.1")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(paused and session.final_ui.mode=="finished" and session.data["events"].get(FinalClock.END,false),"retry finishes ending with persistent completion and end screen")
	check((session.ui.get("_error_label") as Label).text.is_empty() and not (session.ui.get("_health") as Label).visible,"finished screen clears stale save errors and hides combat HUD")
	check(session.store.load_slot(1)["events"].get(FinalClock.END,false),"ending completion survives storage")
	var completed_scene: int = session.get_instance_id()
	check(not session.start_slot(1,false),"completed slot cannot re-enter through Continue")
	await ticks(4)
	session = current_scene as FinalBattleSession
	check(session.get_instance_id()==completed_scene and paused and session.final_ui.mode=="finished" and not session.player.is_physics_processing(),"refused re-entry preserves the current ending screen without reload or free gameplay")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = directory.path_join("slot_1.json")+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("FINAL_BATTLE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
