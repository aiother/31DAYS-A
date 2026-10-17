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
func fixture(gaze: bool = true) -> Dictionary:
	var data: Dictionary = session.store.fresh()
	data["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	data["day"] = 3
	data["maximum"] = 14 if gaze else 10
	data["balance"] = -2
	for key: String in [ParasiteSession.PARASITE_INTRO,ParasiteSession.PARASITE_DEFEATED,ParasiteSession.PARASITE_PASSAGE,ParasiteSession.DODGE_GROWTH,OutskirtsSession.SPIKES_OPEN,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,RavineRescueSession.HELPED,RavineDepthSession.DEPTH_HELPED]: data["events"][key] = true
	if gaze: data["events"][TownSession.GAZE] = true
	return data
func load_fixture(data: Dictionary, selected: int = 1) -> void:
	check(session.store.save_slot(selected,data) and session.start_slot(selected,false),"rescue fixture loads through validated isolated slot")
	await ticks(3)
	session = current_scene as FinalBattleSession
	session._change_room(OutskirtsSession.OUTSKIRTS_ID)
	for actor: Node in session.room.get_node("Enemies").get_children(): actor.set_physics_process(false)
	await ticks(3)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(3)
func finish_dialogue() -> void:
	for i: int in range(12):
		if not session.dialogue_ui.active: break
		session.dialogue_ui.advance()
		await ticks(1)
func run() -> void:
	directory = "user://tests/outskirts_rescue_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = fixture()
	await load_fixture(base)
	check(not session.interact_outskirts_survivor() and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_SEEN,false),"distant main route does not see or interact with optional NPC")
	await place(Vector2(2576,848))
	check(session.data["events"].get(OutskirtsSession.OUTSKIRTS_SEEN,false),"entering chamber records encounter")
	session.player.combat.phase = PlayerCombat.Phase.WINDUP
	check(not session.interact_outskirts_survivor(),"rescue cannot cancel attack")
	session.player.combat.interrupt()
	await ticks(12)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	check(session.dialogue_ui.active and session.player.life.can_control(),"E starts temporary dialogue with free movement")
	session.ui.call("show_pause")
	var chars: int = session.dialogue_ui.text.visible_characters
	await ticks(4)
	check(session.dialogue_ui.text.visible_characters==chars,"pause freezes rescue dialogue")
	session.ui.call("resume_game")
	await place(Vector2(2350,848))
	check(not session.dialogue_ui.active and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"walking away cancels unfinished rescue without reward")
	await place(Vector2(2576,848))
	await ticks(12)
	check(session.interact_outskirts_survivor(),"nearby rescue restarts at negative balance")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await finish_dialogue()
	check(session.dialogue_ui.active and session.player.possibility.maximum==14 and session.player.possibility.balance==-2 and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"failed write rolls back rescue reward and growth atomically")
	session.store.directory = real_directory
	session.dialogue_ui.advance()
	await ticks(2)
	check(not session.dialogue_ui.active and session.player.possibility.maximum==15 and session.player.possibility.balance==2 and session.player.life.health==3,"free negative-balance rescue gives4 and independent cap15 without healing/refill")
	var completed: Dictionary = session.store.load_slot(1)
	check(completed["maximum"]==15 and completed["balance"]==2 and completed["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"growth and rescue persist together")
	check(session.room.get_node("Survivor/Name").text.contains("已救助") and session.quest_status_text().contains("15"),"visual and objective reflect rescued NPC")
	check(session.interact_outskirts_survivor(),"rescued NPC supports repeat dialogue")
	await finish_dialogue()
	check(session.player.possibility.maximum==15 and session.player.possibility.balance==2,"repeat dialogue grants neither reward twice")
	await load_fixture(completed)
	check(session.player.possibility.maximum==15 and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_FAILED,false),"normal load preserves rescue with no abandonment")
	var early: Dictionary = fixture(false)
	await load_fixture(early,2)
	await place(Vector2(2576,848))
	await ticks(12)
	check(session.interact_outskirts_survivor(),"pre-gaze rescue is available")
	await finish_dialogue()
	check(session.player.possibility.maximum==10 and session.player.possibility.balance==2 and session.data["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"pre-gaze rescue defers cap growth and still grants4")
	await load_fixture(session.store.load_slot(2),2)
	check(session.player.possibility.maximum==10 and session.data["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"deferred growth survives load")
	session._change_room(FieldSession.FIELD_ID)
	await place(Vector2(1680,896))
	await ticks(12)
	check(session.interact_seven(),"return to Seven starts actual first gaze")
	await finish_dialogue()
	await ticks(100)
	check(session.player.possibility.maximum==15 and session.player.possibility.balance==2 and session.store.load_slot(2)["maximum"]==15,"first gaze settles all three deferred NPC sources without refill")
	await load_fixture(base,3)
	await place(Vector2(2576,848))
	await place(Vector2(2400,1280))
	session._on_room_exit(TrenchSession.TRENCH_ID)
	check(session.dialogue_ui.confirming and not session.player.life.can_control(),"manual departure after seeing NPC requires permanent-loss confirmation")
	session.cancel_departure()
	check(not session.dialogue_ui.active and session.player.life.can_control(),"cancel keeps rescue available")
	session._on_room_exit(TrenchSession.TRENCH_ID)
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	check(not session.confirm_departure() and session.dialogue_ui.confirming and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_FAILED,false),"failed abandonment write keeps confirmation without permanent loss")
	session.store.directory = real_directory
	check(session.confirm_departure(),"explicit confirmed abandonment persists")
	await ticks(3)
	check(session.room.config.room_id==TrenchSession.TRENCH_ID and session.store.load_slot(3)["events"].get(OutskirtsSession.OUTSKIRTS_FAILED,false),"confirmed departure actually changes Room")
	var abandoned: Dictionary = session.store.load_slot(3)
	await load_fixture(abandoned,3)
	await place(Vector2(2576,848))
	await ticks(12)
	check(session.interact_outskirts_survivor(),"abandoned NPC has failure dialogue")
	await finish_dialogue()
	check(session.player.possibility.maximum==14 and session.player.possibility.balance==-2 and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_HELPED,false),"permanent abandonment cannot grant rewards later")
	for variant: int in range(5):
		var invalid: Dictionary = completed.duplicate(true)
		match variant:
			0: invalid["events"][OutskirtsSession.OUTSKIRTS_FAILED] = true
			1: invalid["events"].erase(OutskirtsSession.SPIKES_OPEN)
			2: invalid["events"].erase(ParasiteSession.DODGE_GROWTH)
			3: invalid["events"].erase(OutskirtsSession.OUTSKIRTS_HELPED)
			4: invalid["maximum"] = 14
		check(not session.store.valid(invalid),"contradictory or unsupported rescue/growth source rejected%d" % variant)
	check(session.store.load_slot(1)["maximum"]==15 and session.store.load_slot(3)["maximum"]==14,"growth remains isolated per slot")
	var full: Dictionary = base.duplicate(true)
	full["balance"] = 14
	await load_fixture(full,3)
	await place(Vector2(2576,848))
	await ticks(12)
	session.interact_outskirts_survivor()
	await finish_dialogue()
	check(session.player.possibility.maximum==15 and session.player.possibility.balance==15,"rescue overflow clips to newly raised cap")
	session.start_slot(3,true)
	await ticks(3)
	session = current_scene as FinalBattleSession
	check(session.player.possibility.maximum==10 and not session.data["events"].has(OutskirtsSession.SPIKES_OPEN) and not session.data["events"].has(OutskirtsSession.OUTSKIRTS_HELPED),"new game clears optional challenge and growth")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("OUTSKIRTS_RESCUE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
