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
func quiet() -> void:
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
	if session.room is FinalBattlefieldRoom:
		for child: Node in session.room.get_node("Allies").get_children():
			child.set_physics_process(false)
func enter() -> void:
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450,896)
	session.player.reset_kinematics()
	await ticks(4)
	quiet()
func run() -> void:
	directory = "user://tests/final_retry_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	snapshot["balance"] = -9
	snapshot["day3_remaining"] = 120.0
	snapshot["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false),"short remaining-day save loads")
	await enter()
	var budget: float = session.data["final_budget"]
	check(budget<=120 and budget>119 and session.data["final_remaining"]<=budget,"final budget is capped by actual remaining third day")
	await ticks(15)
	var remaining: float = session.data["final_remaining"]
	check(session.save_current() and session.start_slot(1,false),"running timer is saved before normal load")
	await ticks(4)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.room is TrenchPassageRoom and session.data["final_remaining"]<=remaining+0.000001 and is_equal_approx(float(session.data["final_budget"]),budget),"normal load returns checkpoint without restoring spent time")
	await enter()
	remaining = session.data["final_remaining"]
	session.player.life.take_hit(3)
	await ticks(90)
	check(session.data["final_remaining"]==remaining,"death animation and menu do not consume final timer")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.room is TrenchPassageRoom and session.player.life.health==5 and session.player.possibility.balance==0,"ordinary death retains established checkpoint health and debt rules")
	check(session.data["final_remaining"]<=remaining+0.000001 and is_equal_approx(float(session.data["final_budget"]),budget),"death retry keeps remaining time instead of granting new fifteen minutes")
	await enter()
	session.data["final_remaining"] = 0.01
	await ticks(2)
	check(paused and session._timeout_active and session.final_ui.mode=="timeout","timer expiry freezes encounter and presents explicit failure UI")
	check(session.data["events"].get(FinalClock.TIMEOUT,false) and not session.data["events"].get(FinalClock.WON,false),"timeout persists failure without awarding victory")
	var saved: Dictionary = session.store.load_slot(1)
	check(saved["final_remaining"]==0 and saved["events"].get(FinalClock.TIMEOUT,false),"zero remaining and timeout survive storage")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.retry_final_battle() and paused and session.data["final_remaining"]==0 and session._timeout_active,"failed explicit retry save retains timeout and zero budget")
	session.store.directory = real_directory
	check(session.retry_final_battle(),"explicit retry confirms and saves reset budget")
	await ticks(4)
	quiet()
	check(session.room is FinalBattlefieldRoom and not paused and session.data["final_remaining"]>budget-1 and is_equal_approx(float(session.data["final_budget"]),budget),"explicit retry restarts whole encounter with original budget")
	check(session.player.life.health==5 and session.player.possibility.balance==0 and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"explicit retry does not replay rescue or refill possibility")
	check((session.ui.get("_error_label") as Label).text.is_empty(),"successful explicit retry clears failed-save feedback")
	check((session.room as FinalBattlefieldRoom).wave_index==0 and session.room.get_node("FinalPlatforms").get_child_count()==0,"retry resets waves and final platforms")
	session.data["final_remaining"] = 0
	(session.room as FinalBattlefieldRoom).wave_index = 2
	session._on_stage_completed()
	check(session._timeout_active and not session.data["events"].get(FinalClock.WON,false),"same-frame zero time and final clear resolves as timeout")
	# A persisted timeout stays a failure on read; it cannot restart itself.
	check(session.start_slot(1,false),"timeout slot can be loaded")
	await ticks(4)
	session = current_scene as FinalBattleSession
	check(paused and session._timeout_active and session.data["final_remaining"]==0,"loading timeout does not silently reset time")
	var empty_budget: Dictionary = snapshot.duplicate(true)
	empty_budget["events"][FinalClock.STARTED] = true
	empty_budget["events"][FinalClock.TIMEOUT] = true
	empty_budget["final_remaining"] = 0.0
	empty_budget["final_budget"] = 0.0
	empty_budget["day3_remaining"] = 0.0
	check(session.store.save_slot(2,empty_budget) and session.start_slot(2,false),"zero original budget remains representable")
	await ticks(4)
	session = current_scene as FinalBattleSession
	check(not session.retry_final_battle() and paused,"no time can be invented for a zero original budget")
	check((session.final_ui.column.get_child(1) as Button).text.contains("存档槽"),"zero-budget UI offers slots instead of an impossible retry")
	# Timer-start transaction failure locks both teams until explicit retry.
	check(session.store.save_slot(3,snapshot) and session.start_slot(3,false),"independent unstarted slot remains loadable")
	await ticks(4)
	session = current_scene as FinalBattleSession
	quiet()
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	await enter()
	check(session._start_pending and not session.data["events"].get(FinalClock.STARTED,false) and not session.player.is_physics_processing(),"failed start save rolls back clock and freezes encounter")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	quiet()
	check(not session._start_pending and session.data["events"].get(FinalClock.STARTED,false) and session.player.is_physics_processing(),"E retries clock start and unlocks active battle")
	check(session.data["final_budget"]<=120 and session.player.possibility.balance==-9,"start retry preserves capped budget and negative resources")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("FINAL_RETRY_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
