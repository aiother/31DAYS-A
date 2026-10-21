# verify-suite: {"name":"title requests clean return save failures and read-only slot summaries","path":"res://tests/test_title_flow.gd","marker":"TITLE_FLOW_TESTS checks=","fixed_fps":60,"timeout":120}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

class TitleSpy extends "res://ui/menus/life_ui.gd":
	var requests: int = 0
	func show_title() -> void:
		requests += 1
		show_slots()

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
	if is_instance_valid(current_scene): session = current_scene as FinalBattleSession

func launch(spy: bool = false) -> void:
	if is_instance_valid(session):
		paused = false
		session.queue_free()
		current_scene = null
		await frames(2)
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	if spy: session.get_node("LifeUI").set_script(TitleSpy)
	root.add_child(session)
	current_scene = session
	await frames()

func rows() -> Array:
	return session.call("slot_summaries")

func write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func bytes_on_disk() -> Dictionary:
	var result: Dictionary = {}
	if DirAccess.dir_exists_absolute(directory):
		for file: String in DirAccess.get_files_at(directory):
			result[file] = FileAccess.get_file_as_bytes(directory.path_join(file))
	return result

func clear_slots() -> void:
	for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))

func fixture(kind: String = "normal") -> Dictionary:
	var data: Dictionary = session.store.fresh()
	data["events"][StartRoomSession.BIRTH] = true
	data["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	data["day"] = 2
	data["day_remaining"] = 450.0
	if kind in ["end","final_timeout","exploration_timeout"]:
		data["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
		data["day"] = 3
		data["day3_remaining"] = 600.0
		for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT,TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]:
			data["events"][flag] = true
	if kind in ["end","final_timeout"]:
		FinalClock.start(data)
	if kind == "end":
		data["events"][FinalClock.WON] = true
		data["events"][FinalClock.TALK] = true
	if kind == "final_timeout":
		data["events"][FinalClock.TIMEOUT] = true
		data["final_remaining"] = 0.0
	if kind == "exploration_timeout":
		data["day3_remaining"] = 0.0
		data["events"][DayClock.TIMEOUT] = true
	return data

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_sys008_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()])
	# Check missing APIs without attempting to invoke them on the baseline.
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	var available: bool = true
	for method: String in ["return_to_title","slot_summaries","has_any_save"]:
		check(session.has_method(method),method + " is available on the real session")
		available = available and session.has_method(method)
	check(session.get_node("LifeUI").has_method("show_title"),"LifeUI provides the temporary title entry")
	available = available and session.get_node("LifeUI").has_method("show_title")
	session.free()
	session = null
	if not available:
		finish()
		return
	await launch(true)
	check(session.ui.get("requests") == 1 and not session.has_session() and paused,"new launch requests the title exactly once without a save session")
	var before: Dictionary = bytes_on_disk()
	check(session.call("return_to_title") and session.ui.get("requests") == 2 and bytes_on_disk() == before,"returning with no active session requests title without a write")
	await summary_cases()
	for kind: String in ["normal","death","end","final_timeout","exploration_timeout"]:
		await return_case(kind)
	finish()

func summary_cases() -> void:
	check(rows().size() == 3 and rows().all(func(row: Dictionary) -> bool: return row["state"] == "empty") and not session.call("has_any_save"),"three missing slots are empty and do not offer continue")
	check(not DirAccess.dir_exists_absolute(directory),"empty summary query does not create its directory")
	var progress: Dictionary = fixture()
	progress["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	progress["health"] = 4
	progress["balance"] = -3
	progress["play_seconds"] = 5025.25
	for flag: String in ExplorationSession.PEARL_KEYS: progress["events"][flag] = true
	var backup: Dictionary = progress.duplicate(true)
	backup["health"] = 2
	check(session.store.save_slot(1,backup) and session.store.save_slot(1,progress),"progress and distinct backup fixtures are valid")
	var complete: Dictionary = fixture("end")
	complete["events"][FinalClock.END] = true
	check(session.store.save_slot(2,complete),"completed fixture is valid")
	write_text(session.store.path_for(3),"broken primary")
	write_text(session.store.path_for(3)+".bak","broken backup")
	write_text(session.store.path_for(3)+".tmp","uncommitted temporary file")
	var before: Dictionary = bytes_on_disk()
	session.store.last_error = "caller error sentinel"
	session.store.used_backup = true
	var result: Array = rows()
	check(result.size() == 3 and result[0]["slot"] == 1 and result[1]["slot"] == 2 and result[2]["slot"] == 3,"summaries have three stable one-based slot identifiers")
	var row: Dictionary = result[0]
	check(row["state"] == "progress" and row["state_text"] == "进行中" and row["day"] == 2 and is_equal_approx(row["day_progress"],0.75),"progress summary contains state and actual day progress")
	check(row["play_seconds"] == 5025.25 and row["health"] == 4 and row["max_health"] == 5 and row["balance"] == -3 and row["maximum"] == 10 and row["pearls"] == 4,"summary exposes saved time, health, possibility and pearl fields")
	check(row["checkpoint"] == RavineSession.RAVINE_CHECKPOINT and row["checkpoint_name"] == "巢都沟壑 · 入口","checkpoint display name comes from its resource")
	check(result[1]["state"] == "completed" and result[1]["state_text"] == "已通关" and result[1]["day"] == 3,"completed saves have a distinct summary")
	check(result[2]["state"] == "unreadable" and result[2]["state_text"] == "无法读取" and not str(result[2]["error"]).is_empty(),"corrupt primary and backup are unreadable rather than empty")
	check(session.call("has_any_save") and bytes_on_disk() == before,"summaries and has_any_save never rewrite rotate repair or remove files")
	check(session.store.last_error == "caller error sentinel" and session.store.used_backup,"read-only query preserves caller error and backup status")
	result[0]["health"] = 99
	check(rows()[0]["health"] == 4 and session.data.is_empty(),"returned summaries are detached from later queries and active session state")
	write_text(session.store.path_for(1),"damaged primary with readable backup")
	before = bytes_on_disk()
	row = rows()[0]
	check(row["state"] == "progress" and row["used_backup"] and row["health"] == 2,"readable backup follows normal load semantics without repair")
	check(bytes_on_disk() == before,"backup recovery query preserves all original bytes")
	clear_slots()
	write_text(session.store.path_for(3),'{"version":99}')
	check(session.call("has_any_save") and rows()[2]["state"] == "unreadable","an unsupported save still exists and must not be classified as empty")
	clear_slots()
	for config: String in SlotStore.CHECKPOINTS:
		var data: Dictionary = session.store.fresh()
		data["checkpoint"] = config
		check(session.store.save_slot(1,data) and not str(rows()[0]["checkpoint_name"]).is_empty(),"summary names every registered checkpoint: " + config)
	clear_slots()

func return_case(kind: String) -> void:
	await launch()
	check(session.store.save_slot(1,fixture(kind)) and session.start_slot(1,false),kind + " real slot can enter its pre-return state")
	if kind == "death":
		session.player.life.take_hit(5)
		await frames(100)
		check(session.player.life.state == PlayerLife.State.DEATH_MENU, "actual death feedback reaches the death menu")
	elif kind == "end":
		await frames(190)
		check(bool(session.data["events"].get(FinalClock.END,false)) and session.final_ui.mode == "finished","actual ending transition saves END and reaches the finished panel")
	elif kind in ["final_timeout","exploration_timeout"]:
		check(session.get("_timeout_active") and paused,kind + " real restore opens its timeout panel")
	else:
		await frames(2)
		session.ui.call("show_pause")
	# No resource signals: only return_to_title itself can persist these changes.
	if kind == "normal":
		session.player.life.health = 2
		session.player.possibility.balance = -4
		session.data["day_remaining"] = 222.0
		session.data["play_seconds"] = 321.5
	var expected: Dictionary = session.data.duplicate(true)
	var expected_health: int = session.player.life.health if session.player.life.is_alive() else int(expected["health"])
	var expected_balance: int = session.player.possibility.balance if session.player.life.is_alive() else int(expected["balance"])
	var old_scene: WeakRef = weakref(session)
	var old_player: WeakRef = weakref(session.player)
	var old_room: WeakRef = weakref(session.room)
	var old_id: int = session.get_instance_id()
	var store: SlotStore = session.store
	var real_directory: String = store.directory
	var panel: String = session.final_ui.mode
	store.directory = real_directory.path_join("slot_1.json")
	check(not session.call("return_to_title"),kind + " failed save refuses to leave")
	await frames(2)
	check(session.get_instance_id() == old_id and session.has_session() and paused and session.final_ui.mode == panel and not str((session.ui.get("_error_label") as Label).text).is_empty(),kind + " failure preserves scene state and reports the existing error")
	store.directory = real_directory
	check(session.call("return_to_title") and not session.call("return_to_title"),kind + " accepts one return only after a successful save")
	await frames(5)
	check(old_scene.get_ref() == null and old_player.get_ref() == null and old_room.get_ref() == null,kind + " old scene player and room are really released")
	check(session.get_instance_id() != old_id and not session.has_session() and session.slot == 0 and session.data.is_empty() and paused,kind + " reloads into the no-session title state")
	check(session.save_directory == directory and session.store.directory == directory and str(session.ui.get("_mode")) == "title" and (session.ui.get("_title") as Control).visible,kind + " isolated directory survives reload and the formal title shows")
	check(session.player.life.health == 3 and session.player.possibility.balance == 3 and session.player.possibility.maximum == 10 and session.player.combat.pearl_count == 0 and not session.player.life.scripted_control_locked,kind + " does not carry player resources or control locks into title")
	check(session.room.config.room_id == TwoRoomSession.START_ID and session.get("_final_resolution_room") == 0 and not session.get("_timeout_active") and not session.get("_ending_active") and not session.get("_final_talk") and not session.intro_active,kind + " old arena timer and cinematic state do not remain")
	check(not has_meta("checkpoint_reload") and not has_meta("checkpoint_title") and not session.ui_time_state()["has_session"],kind + " has no pending reload or active UI clock")
	var disk: Dictionary = store.load_slot(1)
	check(disk["health"] == expected_health and disk["balance"] == expected_balance and disk["checkpoint"] == expected["checkpoint"] and disk["events"] == expected["events"],kind + " saves the existing settlement and checkpoint without changing rules")
	check(DayClock.remaining(disk) == DayClock.remaining(expected),kind + " return does not reset day or final budgets")
	if expected.has("final_remaining"):
		check(disk["final_remaining"] == expected["final_remaining"] and disk["final_budget"] == expected["final_budget"],kind + " preserves the final budget and remainder exactly")
	if kind == "normal":
		check(disk["play_seconds"] == 321.5,"return saves unannounced play-time changes before leaving")
		check(session.start_slot(1,false),"normal slot re-enters through the existing start_slot API")
		await frames(2)
		check(session.player.life.health == 2 and session.player.possibility.balance == -4 and session.player.position.distance_to(Vector2.ZERO) > 100,"re-entry restores saved resources at the last checkpoint")
	elif kind == "end":
		var before: Dictionary = bytes_on_disk()
		check(not session.start_slot(1,false) and bytes_on_disk() == before,"completed slot still enforces A-013 without writing")
		check(session.start_slot(1,true),"completed slot still permits a new game")

func finish() -> void:
	paused = false
	if is_instance_valid(session): session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	if not directory.is_empty() and DirAccess.dir_exists_absolute(directory):
		clear_slots()
		DirAccess.remove_absolute(directory)
	OS.delay_msec(500)
	print("TITLE_FLOW_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
