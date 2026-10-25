# verify-suite: {"name":"unified key cinematic flows with real sessions input pause and save recovery","path":"res://tests/test_cinematics.gd","marker":"CINEMATICS_TESTS checks=","fixed_fps":60,"timeout":240}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directories: Array[String] = []
var directory: String
var seen: Dictionary = {}
var serial: int = 910000
class PauseProbe:
	extends Node
	var flow: CinematicDirector
	func _physics_process(delta: float) -> void:
		# A real ALWAYS caller must not bypass the director's own pause guard.
		if get_tree().paused and flow != null: flow.advance(delta)
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func quiet() -> void:
	if not is_instance_valid(session) or not is_instance_valid(session.room): return
	for name: String in ["Enemies", "OrdinaryEnemies", "Allies"]:
		var container: Node = session.room.get_node_or_null(name)
		if container != null:
			for actor: Node in container.get_children(): actor.set_physics_process(false)
	if session.room.has_node("Boss"): session.room.get_node("Boss").set_physics_process(false)
func frames(count: int = 1) -> void:
	for i: int in range(count):
		quiet()
		await physics_frame
		await process_frame
		if is_instance_valid(current_scene) and current_scene is FinalBattleSession: session = current_scene as FinalBattleSession
		quiet()
		if is_instance_valid(session):
			for row: Dictionary in session.cinematics.history:
				if row["action"] == "begin": seen[row["id"]] = true
func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)
	await frames(8)
func close_scene() -> void:
	paused = false
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
	if is_instance_valid(session):
		session.queue_free()
		await physics_frame
		await process_frame
		await process_frame
		session = null
func fresh(checkpoint: String = "", events: Dictionary = {}, day: int = 1, balance: int = 3, replacement: bool = false) -> void:
	await close_scene()
	directory = "user://tests/sys012_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	directories.append(directory)
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	if replacement:
		var sequence: CinematicSequence = CinematicCatalog.sequence(&"opening")
		sequence.presentation = load("res://tests/fixtures/cinematic_content_probe.gd") as Script
		sequence.duration_override = 0.25
		session.cinematics.overrides[&"opening"] = sequence
	await frames(2)
	if checkpoint.is_empty():
		check(session.start_slot(1,true), "real new game starts in isolated directory")
	else:
		var snapshot: Dictionary = session.store.fresh()
		snapshot["checkpoint"] = checkpoint
		snapshot["day"] = day
		snapshot["balance"] = balance
		snapshot["health"] = 5
		snapshot["events"].merge(events,true)
		check(session.store.save_slot(1,snapshot) and session.start_slot(1,false), "real isolated checkpoint load starts " + checkpoint)
	await frames(2)
func policy(id: String) -> void:
	await frames(2)
	var view: Dictionary = session.cinematic_state()
	check(view["id"] == id and view["active"], id + " is driven by the common entry")
	check(session.player.life.scripted_control_locked == view["locks_control"], id + " control lock matches policy query")
	check((session.ui.get("_hud") as Control).visible == not bool(view["hides_hud"]), id + " formal HUD matches policy query")
	var audio: AudioEventService = root.get_node("AudioEvents") as AudioEventService
	check((audio.music == "story") == bool(view["story_music"]), id + " actual music context matches policy query")
	var day: float = DayClock.remaining(session.data)
	var final: float = float(session.data.get("final_remaining",900.0))
	await frames(3)
	check(DayClock.remaining(session.data) == day and float(session.data.get("final_remaining",900.0)) == final, id + " pauses actual day and final clocks")
	var left: float = session.cinematics.state()["remaining"]
	check(not session.cinematics.request_skip() and session.cinematics.state()["remaining"] == left, id + " has no new skip operation")
	var detached: Dictionary = session.cinematic_state()
	detached["remaining"] = 10000.0
	(detached["events"] as Array).append("invalid:ui_write")
	check(session.cinematic_state()["remaining"] != 10000.0 and not "invalid:ui_write" in session.cinematic_state()["events"], id + " query returns detached values")
func pause_case(id: String) -> void:
	var probe := PauseProbe.new()
	probe.flow = session.cinematics
	probe.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(probe)
	await key(KEY_ESCAPE)
	check(paused and session.ui.get("_mode") == "pause", id + " real Esc opens pause menu")
	var left: float = session.cinematics.state()["remaining"]
	var day: float = DayClock.remaining(session.data)
	await frames(12)
	check(session.cinematics.state()["remaining"] == left and DayClock.remaining(session.data) == day, id + " pause freezes even an ALWAYS physics caller")
	await key(KEY_ESCAPE)
	check(not paused, id + " Esc resumes the same flow")
	probe.queue_free()
	await frames(1)
func dialogue(wait_for_failure: bool = false) -> void:
	for i: int in range(80):
		if not session.dialogue_ui.active: return
		await key(KEY_E)
		if wait_for_failure and session.cinematics.state()["status"] == "waiting_save": return
	check(false, "dialogue completes or reaches a save retry within bounded real input")
func history_count(id: String) -> int:
	return session.cinematics.history.filter(func(row: Dictionary) -> bool: return row["action"] == "begin" and row["id"] == id).size()
func reload_slot() -> void:
	check(session.start_slot(1,false), "actual Continue requests a scene reload")
	await frames(5)
func opening_case() -> void:
	await fresh()
	for i: int in range(180):
		await frames(1)
		if session._on_ground: break
	await policy("opening")
	await pause_case("opening")
	var good: String = session.store.directory
	session.store.directory = good.path_join("slot_1.json")
	await frames(120)
	check(session.cinematic_state()["id"] == "opening" and session.cinematic_state()["status"] == "waiting_save", "failed birth save keeps the flow at its save boundary")
	check(not bool(session.data["events"].get(StartRoomSession.BIRTH,false)), "failed birth save rolls back its completion marker")
	session.store.directory = good
	check(not bool(session.store.load_slot(1)["events"].get(StartRoomSession.BIRTH,false)), "failed birth save leaves disk completion unchanged")
	await key(KEY_E)
	check(not session.cinematics.active() and bool(session.store.load_slot(1)["events"].get(StartRoomSession.BIRTH,false)), "real E retries and commits birth once before unlocking")
	await reload_slot()
	check(not session.cinematics.active() and history_count("opening") == 0, "saved birth does not replay after a real load")
	check(not session.cinematics.begin(&"opening"), "common entry also rejects a saved birth replay request")
	session.cinematics.finish()
	session.cinematics.duration(&"opening",1.0)
	check(not session.cinematics.active(), "timer entry cannot bypass the saved birth guard")
	session.cinematics.finish()
func boss_case(checkpoint: String, id: String, intro_event: String) -> void:
	await fresh(checkpoint)
	await policy(id)
	await pause_case(id)
	check(bool(session.store.load_slot(1)["events"].get(intro_event,false)) and session.cinematic_state()["commit_point"] == "entry", id + " preserves the existing pre-content save boundary")
	await reload_slot()
	check(not session.cinematics.active() and history_count(id) == 0, id + " saved introduction does not replay")
	check(not session.cinematics.begin(StringName(id)), id + " rejects replay through the common entry")
	session.cinematics.finish()
func seven_case() -> void:
	var events: Dictionary = {}
	for name: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,BossSession.COMBAT_GROWTH]: events[name] = true
	await fresh(BossSession.BOSS_CHECKPOINT,events,1,-4)
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	await policy("seven.first")
	await pause_case("seven.first")
	await frames(125)
	var good: String = session.store.directory
	session.store.directory = good.path_join("slot_1.json")
	await dialogue(true)
	check(session.cinematics.active(&"seven.first") and not bool(session.data["events"].get(FieldSession.FIELD_STORY,false)) and session.player.possibility.balance == -4, "failed first story restores marker and reward together")
	session.store.directory = good
	await reload_slot()
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	check(session.cinematics.active(&"seven.first") and history_count("seven.first") == 1 and not bool(session.data["events"].get(FieldSession.FIELD_STORY,false)), "unsaved story replays from the real saved checkpoint on load")
	await frames(125)
	session.store.directory = good.path_join("slot_1.json")
	await dialogue(true)
	check(session.cinematic_state()["status"] == "waiting_save", "replayed unsaved story still has its normal retry boundary")
	session.store.directory = good
	await dialogue()
	check(bool(session.store.load_slot(1)["events"].get(FieldSession.FIELD_STORY,false)) and session.player.possibility.balance == 10 and not session.cinematics.active(), "first story commit fills once then releases the flow")
	await reload_slot()
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	check(not session.cinematics.active() and history_count("seven.first") == 0, "saved first story skips camera and forced dialogue")
	check(not session.cinematics.begin(&"seven.first"), "entry rejects saved Seven story replay")
	session.cinematics.finish()
	session.cinematics.set_phase(&"seven.first",1)
	check(not session.cinematics.active(), "phase entry cannot bypass a saved story guard")
	session.cinematics.finish()
	session.room.exit_requested.emit(TownSession.TOWN_ID)
	await frames(4)
	session.player.position = Vector2(928,896)
	session.player.reset_kinematics()
	await frames(15)
	await key(KEY_E)
	await dialogue()
	check(bool(session.data["events"].get(FieldSession.RESCUE_DONE,false)), "real free rescue dialogue earns the prerequisite")
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	session.player.position = Vector2(1680,896)
	session.player.reset_kinematics()
	await frames(15)
	await key(KEY_E)
	await policy("seven.gaze")
	await pause_case("seven.gaze")
	good = session.store.directory
	session.store.directory = good.path_join("slot_1.json")
	await dialogue(true)
	await frames(120)
	check(session.cinematics.active(&"seven.gaze") and not bool(session.data["events"].get(TownSession.GAZE,false)) and session.player.possibility.maximum == 10, "failed gaze restores cap and marker while retaining retry dialogue")
	session.store.directory = good
	await dialogue()
	await frames(5)
	check(not session.cinematics.active() and session.player.possibility.maximum == 12 and bool(session.store.load_slot(1)["events"].get(TownSession.GAZE,false)), "gaze commits growth and completion atomically once")
	await reload_slot()
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	check(not session.cinematics.active() and not session.cinematics.begin(&"seven.gaze"), "saved gaze does not replay on load or entry")
	session.cinematics.finish()
func gaze_death_case() -> void:
	var events: Dictionary = {}
	for name: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,BossSession.COMBAT_GROWTH,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE]: events[name] = true
	await fresh(BossSession.BOSS_CHECKPOINT,events)
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	session.player.position = Vector2(1680,896)
	session.player.reset_kinematics()
	await frames(15)
	await key(KEY_E)
	check(session.cinematics.active(&"seven.gaze"), "uncommitted gaze starts before the death test")
	check(session.player.life.take_hit(5), "actual lethal damage enters existing death flow")
	check(not session.cinematics.active() and not bool(session.data["events"].get(TownSession.GAZE,false)) and session.player.possibility.maximum == 10, "death cancels unearned gaze and leaves no claimed growth")
	await frames(110)
	check(paused and session.player.life.state == PlayerLife.State.DEATH_MENU, "existing death animation reaches the real death menu")
	session.ui.call("restart_challenge")
	await frames(5)
	check(bool(session.data["events"].get(FieldSession.RESCUE_DONE,false)) and not bool(session.data["events"].get(TownSession.GAZE,false)), "real death reload retains rescue without unearned gaze")
	session.room.exit_requested.emit(FieldSession.FIELD_ID)
	await frames(4)
	session.player.position = Vector2(1680,896)
	session.player.reset_kinematics()
	await frames(15)
	await key(KEY_E)
	check(session.cinematics.active(&"seven.gaze"), "unsaved gaze can be played again after death and checkpoint reload")
	var balance: int = session.player.possibility.balance
	await dialogue()
	await frames(120)
	check(bool(session.store.load_slot(1)["events"].get(TownSession.GAZE,false)) and session.player.possibility.maximum == 12 and session.player.possibility.balance == balance, "replayed gaze saves growth once without a refill")
func replacement_case() -> void:
	await fresh("",{},1,3,true)
	check(bool(session.get_meta("probe_begin",false)), "a replacement content resource receives the common start")
	check(session.cinematic_state()["duration"] == 0.25, "test-only content duration is supplied by data")
	await frames(220)
	check(int(session.get_meta("probe_ticks",0)) > 0 and bool(session.get_meta("probe_finish",false)), "replacement content receives real ticks and the common finish")
	check(bool(session.store.load_slot(1)["events"].get(StartRoomSession.BIRTH,false)) and session.player.life.can_control(), "replacement content keeps the same save and continuation")
	check(not session.store.load_slot(1).has("probe_ticks"), "presentation-only state is never added to the save format")
func clear_wave() -> void:
	for actor: Node in session.room.get_node("Enemies").get_children():
		if actor is ColorlessEntity and actor.health > 0:
			serial += 1
			actor.hurtbox.receive_attack(actor.health,Vector2.ZERO,session.player,serial)
	await frames(3)
func final_case() -> void:
	var events: Dictionary = {}
	for name: String in [TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]: events[name] = true
	await fresh(TrenchPassageSession.PASSAGE_CHECKPOINT,events,3,-9)
	session.room.exit_requested.emit(BattlefieldSession.BATTLEFIELD_ID)
	await frames(4)
	session.player.position = Vector2(450,896)
	session.player.reset_kinematics()
	await frames(4)
	session.player.life.take_hit(session.player.life.health)
	await frames(2)
	await policy("ten.rescue")
	await pause_case("ten.rescue")
	await frames(55)
	var good: String = session.store.directory
	session.store.directory = good.path_join("slot_1.json")
	await dialogue()
	await frames(170)
	check(session.cinematic == RescueBattlefieldSession.Cinematic.SAVE and not bool(session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false)) and session.player.possibility.balance == -9, "failed rescue save keeps SAVE stage and rolls back full-cap reward")
	session.store.directory = good
	await key(KEY_E)
	check(session.cinematic == RescueBattlefieldSession.Cinematic.REINFORCEMENTS and session.player.possibility.balance == 10, "real E commits rescue and enters reinforcement warning")
	for i: int in range(160):
		if session.cinematic_remaining < 0.08: break
		await frames(1)
	session.store.directory = good.path_join("slot_1.json")
	await frames(10)
	await policy("final.start")
	check(not bool(session.data["events"].get(FinalClock.STARTED,false)), "failed final start keeps clock transaction uncommitted")
	session.store.directory = good
	await key(KEY_E)
	check(not session._start_pending and bool(session.data["events"].get(FinalClock.STARTED,false)), "real E retries final start without replaying rescue")
	for wave: int in range(3):
		for i: int in range(400):
			if session._final_arena().wave_index == wave and session._final_arena().wave_state == FinalBattlefieldRoom.WaveState.ACTIVE: break
			await frames(1)
		check(session._final_arena().wave_index == wave and session._final_arena().wave_state == FinalBattlefieldRoom.WaveState.ACTIVE, "real final wave arrives before it is cleared: " + str(wave))
		if wave == 2: session.store.directory = good.path_join("slot_1.json")
		await clear_wave()
	for i: int in range(400):
		if session._win_pending or bool(session.data["events"].get(FinalClock.WON,false)): break
		await frames(1)
	await policy("final.win")
	check(session._win_pending and not bool(session.data["events"].get(FinalClock.WON,false)), "failed final win keeps a retry boundary without a permanent win")
	session.store.directory = good
	await key(KEY_E)
	check(bool(session.data["events"].get(FinalClock.WON,false)), "real E commits actual final-wave victory")
	session.player.position = Vector2(950,896)
	session.player.reset_kinematics()
	await frames(4)
	await key(KEY_E)
	await policy("final.talk")
	good = session.store.directory
	session.store.directory = good.path_join("slot_1.json")
	await dialogue(true)
	check(not bool(session.data["events"].get(FinalClock.TALK,false)) and session.cinematics.active(&"final.talk"), "failed victory dialogue cannot start or mark the ending")
	session.store.directory = good
	await dialogue()
	await policy("ending")
	await pause_case("ending")
	session.store.directory = good.path_join("slot_1.json")
	await frames(185)
	check(session.cinematics.active(&"ending") and not bool(session.data["events"].get(FinalClock.END,false)), "failed ending save does not claim completion")
	session.store.directory = good
	await key(KEY_E)
	check(paused and session.final_ui.mode == "finished" and bool(session.store.load_slot(1)["events"].get(FinalClock.END,false)), "ending retry commits END before the finished sheet")
	check(session.cinematic_state()["id"] == "ending.finished" and not session.cinematic_state()["can_skip"], "saved ending terminates in a locked outcome, not a replayable clip")
func run() -> void:
	await opening_case()
	await boss_case(BossSession.BOSS_CHECKPOINT,"boss.overlook",BossSession.BOSS_INTRO)
	await boss_case(ParasiteSession.PARASITE_CHECKPOINT,"boss.parasite",ParasiteSession.PARASITE_INTRO)
	await seven_case()
	await gaze_death_case()
	await final_case()
	await replacement_case()
	for id: String in ["opening","boss.overlook","boss.parasite","seven.first","seven.gaze","ten.rescue","final.start","final.win","final.talk","ending","ending.finished"]:
		check(seen.has(id), "real session visited common flow " + id)
	await close_scene()
	(root.get_node("AudioEvents") as AudioEventService).stop_all()
	await process_frame
	OS.delay_msec(500)
	for path: String in directories:
		assert(path.begins_with("user://tests/sys012_"))
		var dir: DirAccess = DirAccess.open(path)
		if dir != null:
			for file: String in dir.get_files(): dir.remove(file)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CINEMATICS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
