# verify-suite: {"name": "deserter camp waves and formal checkpoint", "path": "res://tests/test_camp_waves.gd", "marker": "CAMP_WAVES_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: CampWavesSession
var directory: String
var attack_id: int = 4000
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func arena() -> CampWavesRoom:
	return session.room as CampWavesRoom
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func load_snapshot(snapshot: Dictionary, selected: int = 1) -> void:
	check(session.store.save_slot(selected,snapshot) and session.start_slot(selected,false), "valid existing snapshot loads")
	await ticks(4)
	session = current_scene as CampWavesSession
func enter_arena() -> void:
	await place(Vector2(2368,848))
	await place(Vector2(1824,1152))
	await place(Vector2(1824,1280))
	await place(Vector2(2928,1280))
func wait_phase(expected: CampWavesRoom.Phase, count: int = 110) -> bool:
	for i: int in range(count):
		if arena().phase == expected:
			return true
		await ticks(1)
	return false
func freeze_enemies() -> void:
	for enemy: ColorlessEntity in arena().living():
		enemy.set_physics_process(false)
func kill(enemy: ColorlessEntity, damage: int = -1) -> void:
	attack_id += 1
	enemy.hurtbox.receive_attack(enemy.health if damage<0 else damage,Vector2.ZERO,session.player,attack_id)
func clear_wave() -> void:
	for enemy: ColorlessEntity in arena().living():
		kill(enemy)
	await ticks(2)
func run() -> void:
	directory = "user://tests/camp_waves_%d" % Time.get_ticks_usec()
	session = (load("res://world/camp_waves_session.tscn") as PackedScene).instantiate() as CampWavesSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 14
	base["balance"] = -9
	for key: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,TownSession.GAZE,RavineRescueSession.HELPED,RavineDepthSession.DEPTH_HELPED,RavineDepthRoom.GATES,RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_snapshot(base)
	await enter_arena()
	# Capture legitimate old-save Boss reward migration before testing wave rewards.
	var wave_events: Dictionary = session.data["events"].duplicate()
	check(arena()!=null and arena().config.room_id=="HD_20002_2" and arena().config.next_room_id=="HD_20003_1", "actual camp road enters configured wave Room")
	check(session.data["checkpoint"]==CampWavesSession.WAVES_CHECKPOINT and session.store.load_slot(1)["checkpoint"]==CampWavesSession.WAVES_CHECKPOINT and session._all_checkpoints().size()==1, "entry records formally numbered wave checkpoint")
	check(session.player.possibility.balance==-9 and session.player.possibility.maximum==14 and session.data["day"]==2, "checkpoint activation does not refill resources or change date")
	await ticks(45)
	check(arena().phase==CampWavesRoom.Phase.READY and arena().wave==0 and arena().living().is_empty(), "safe entry waits indefinitely before first wave")
	session.room.exit_requested.emit(CampSession.CAMP_ID)
	session.room.exit_requested.emit(ParasiteSession.PARASITE_ID)
	await ticks(2)
	check(arena()!=null and arena().get_node("ReturnBattleGate").collision_layer==1 and arena().get_node("ForwardBattleGate").collision_layer==1, "both exits and full-height gates stay closed even before first wave")
	await place(Vector2(500,1280))
	check(arena().phase==CampWavesRoom.Phase.WARNING and arena().living().is_empty(), "actual safety-zone crossing warns before spawning")
	check(not arena().start_waves(), "repeated trigger cannot overlap another wave sequence")
	var remaining: float = arena().remaining
	session.ui.call("show_pause")
	await ticks(8)
	check(arena().remaining==remaining and arena().living().is_empty(), "pause freezes warning timer and prevents spawning")
	session.ui.call("resume_game")
	check(await wait_phase(CampWavesRoom.Phase.ACTIVE,50), "first wave starts after 0.6 second warning")
	freeze_enemies()
	check(arena().wave==1 and arena().living().size()==2 and not arena().living()[0].flying and not arena().living()[1].flying, "wave1 contains two ground colorless entities")
	check(arena().living()[0].target==session.player and arena().living()[0].coordinator==arena().get_node("AttackCoordinator") and arena().living()[0]._seen, "spawned enemies target player immediately with shared attack coordinator")
	Input.action_press("attack")
	await ticks(12)
	Input.action_release("attack")
	check(arena().living()[0].health==10 and arena().living()[0].config.max_health==15, "actual five-damage player attack hits second-day dynamically spawned enemy")
	kill(arena().living()[0],10)
	await ticks(2)
	check(arena().phase==CampWavesRoom.Phase.ACTIVE and arena().living().size()==1 and session.player.possibility.balance==-7, "partial clear pays exactly+2 and waits for final enemy")
	kill(arena().living()[0])
	await ticks(2)
	check(arena().phase==CampWavesRoom.Phase.INTERVAL and arena().wave==1 and arena().living().is_empty() and session.player.possibility.balance==-5, "clearing wave1 starts one-second interval")
	session.room.exit_requested.emit(CampSession.CAMP_ID)
	session.room.exit_requested.emit(ParasiteSession.PARASITE_ID)
	await ticks(2)
	check(arena()!=null and arena().phase==CampWavesRoom.Phase.INTERVAL, "empty inter-wave interval does not unlock either exit")
	remaining = arena().remaining
	session.ui.call("show_pause")
	await ticks(8)
	check(arena().remaining==remaining, "pause freezes inter-wave interval")
	session.ui.call("resume_game")
	await ticks(45)
	check(arena().phase==CampWavesRoom.Phase.INTERVAL and arena().living().is_empty(), "next wave never appears before one-second interval")
	check(await wait_phase(CampWavesRoom.Phase.WARNING,25) and arena().wave==2 and arena().living().is_empty(), "second wave receives its own warning after interval")
	check(await wait_phase(CampWavesRoom.Phase.ACTIVE,50), "second wave spawns after warning")
	freeze_enemies()
	check(arena().living().size()==2 and arena().living()[1].flying and arena().living()[1].ranged_only, "wave2 mixes existing ground and air ranged variants")
	await clear_wave()
	check(session.player.possibility.balance==-1 and arena().phase==CampWavesRoom.Phase.INTERVAL, "wave2 adds only two existing kill rewards")
	check(await wait_phase(CampWavesRoom.Phase.ACTIVE), "third wave follows interval and warning")
	freeze_enemies()
	check(arena().wave==3 and arena().living().size()==3 and arena().living()[2].flying and arena().living()[1] is MonochromeEntity and arena().living()[1].health==21, "wave3 retains three enemies with one ground monochrome and flying colorless")
	var last_monochrome: MonochromeEntity = arena().living()[1] as MonochromeEntity
	for enemy: ColorlessEntity in arena().living():
		if enemy!=last_monochrome: kill(enemy)
	await ticks(2)
	check(arena().phase==CampWavesRoom.Phase.ACTIVE and arena().living().size()==1 and arena().get_node("ReturnBattleGate").collision_layer==1 and arena().get_node("ForwardBattleGate").collision_layer==1, "living last monochrome prevents completion and keeps both exits locked")
	check(not arena().start_waves(), "wave3 cannot retrigger previous waves")
	kill(last_monochrome)
	# The corpse limiter may free the seventh corpse on the next frame.
	last_monochrome.hurtbox.receive_attack(21,Vector2.ZERO,session.player,9999)
	check(session.player.possibility.balance==10,"dead last monochrome cannot repeat kill or completion reward")
	await ticks(2)
	check(arena().phase==CampWavesRoom.Phase.COMPLETE and arena().living().is_empty(), "all three waves complete after seven total kills")
	check(session.player.possibility.balance==10 and session.store.load_slot(1)["balance"]==10, "six colorless plus one monochrome pay19 total from-9 to10 without bonus")
	await ticks(120)
	check(arena().phase==CampWavesRoom.Phase.COMPLETE and arena().wave==3 and arena().get_node("Enemies").get_child_count()<=6, "completion produces no extra waves and respects corpse limit")
	check(session.get_node("Instructions/Help").text.contains("完成") and session.data["events"]==wave_events, "completion shows feedback without inventing permanent clear or growth events")
	check(arena().get_node("ReturnBattleGate").collision_layer==0 and arena().get_node("ForwardBattleGate").collision_layer==0, "only completion opens both physical barriers")
	await place(Vector2(1824,1280))
	check(paused and session.ui.get("_mode")=="room_boundary", "completed waves allow forward travel to registered next-room boundary")
	session.ui.call("resume_game")
	await place(Vector2(48,1280))
	check(session.room is CampRoom and session.player.position.distance_to(Vector2(2752,1280))<2, "return uses safe camp landing")
	await place(Vector2(2928,1280))
	check(arena().phase==CampWavesRoom.Phase.READY and arena().wave==0, "revisit resets entire sequence to safe entry")
	await place(Vector2(500,1280))
	await wait_phase(CampWavesRoom.Phase.ACTIVE,50)
	freeze_enemies()
	kill(arena().living()[0])
	check(session.player.possibility.balance==12, "revisit enemy still pays+2 after mixed wave rewards")
	await place(Vector2(1824,1280))
	check(not paused and arena()!=null and arena().living().size()==1, "forward exit rejects active battle with living enemy")
	await place(Vector2(48,1280))
	check(arena()!=null, "active battle rejects actual return trigger")
	await place(Vector2(224,1280))
	Input.action_press("move_left")
	await ticks(30)
	Input.action_release("move_left")
	check(session.player.position.x>=149 and arena()!=null, "physical return barrier stops ordinary movement before exit")
	await load_snapshot(session.store.load_slot(1))
	await place(Vector2(500,1280))
	check(arena().phase==CampWavesRoom.Phase.WARNING, "new visit starts a fresh warning")
	session.player.life.take_hit(3)
	remaining = arena().remaining
	await ticks(90)
	check(arena().living().is_empty() and arena().remaining==remaining, "death during warning stops all pending spawns")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as CampWavesSession
	check(arena()!=null and arena().phase==CampWavesRoom.Phase.READY and arena().wave==0 and session.player.position.distance_to(Vector2(224,1280))<2, "death respawns at new checkpoint with fresh safe sequence")
	check(session.player.life.health==5 and session.player.possibility.balance==6 and session.player.possibility.maximum==14 and session.player.life.protection_remaining>2.8 and session.data["day"]==2, "respawn preserves floor-half resources full health protection cap and date")
	var continued: Dictionary = session.store.load_slot(1)
	await load_snapshot(continued)
	check(arena().phase==CampWavesRoom.Phase.READY and session.player.life.protection_remaining==0 and session.player.possibility.balance==6, "normal load resets waves but preserves actual resources without protection")
	await place(Vector2(500,1280))
	check(await wait_phase(CampWavesRoom.Phase.ACTIVE,50), "loaded run can spawn a fresh first wave")
	freeze_enemies()
	await load_snapshot(session.store.load_slot(1))
	check(arena().phase==CampWavesRoom.Phase.READY and arena().living().is_empty(), "loading an unfinished run never resumes partial wave state")
	await place(Vector2(500,1280))
	await place(Vector2(48,1280))
	await ticks(50)
	check(arena()!=null and arena().phase==CampWavesRoom.Phase.ACTIVE, "warning blocks retreat and continues spawning inside same Room")
	await load_snapshot(session.store.load_slot(1))
	check(arena().phase==CampWavesRoom.Phase.READY and arena().living().is_empty(), "normal reload cancels pending wave and closes barriers again")
	# Entry checkpoint uses rollback and a deliberate retry when the storage write fails.
	await load_snapshot(base,2)
	await place(Vector2(2368,848))
	await place(Vector2(1824,1152))
	await place(Vector2(1824,1280))
	session._mount_room(CampWavesSession.WAVES_ID)
	session.player.position = Vector2(224,1280)
	session.player.reset_kinematics()
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	check(not session.activate_checkpoint(CampWavesSession.WAVES_CHECKPOINT) and session.data["checkpoint"]==RavineSession.RAVINE_CHECKPOINT and not session._all_checkpoints()[0].active, "failed checkpoint save rolls back selected ID and flag")
	await ticks(4)
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.data["checkpoint"]==CampWavesSession.WAVES_CHECKPOINT and session.store.load_slot(2)["checkpoint"]==CampWavesSession.WAVES_CHECKPOINT and session._all_checkpoints()[0].active, "E retry records checkpoint after storage recovery")
	check(session.store.load_slot(1)["balance"]==6 and session.player.possibility.balance==-9, "wave resources remain isolated by slot")
	session.start_slot(2,true)
	await ticks(4)
	session = current_scene as CampWavesSession
	check(session.room.config.room_id==TwoRoomSession.START_ID and session.data["checkpoint"]==StartRoomSession.CHECKPOINT and session.player.possibility.maximum==10, "new game clears new checkpoint and starts normal first Room")
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
	print("CAMP_WAVES_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
