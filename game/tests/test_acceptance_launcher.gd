# verify-suite: {"name":"shared acceptance options isolated saves panel entry and cleanup","path":"res://tests/test_acceptance_launcher.gd","marker":"ACCEPTANCE_LAUNCHER_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
const COMPLETED: Script = preload("res://tests/acceptance/completed_slots.gd")
var checks: int = 0
var failures: int = 0

class EntryAdapter extends "res://tests/acceptance/acceptance_harness.gd":
	func configuration() -> Dictionary:
		var snapshot: Dictionary = SlotStore.new().fresh()
		snapshot["checkpoint"] = StartRoomSession.CHECKPOINT
		snapshot["events"][StartRoomSession.BIRTH] = true
		return {"scene":preload("res://world/final_battle_session.tscn"),"snapshots":{2:snapshot},"enter":true,"instructions":"entry test"}
	func self_test() -> void:
		check(session.has_session() and session.slot == 2 and session.data["checkpoint"] == StartRoomSession.CHECKPOINT, "adapter enters actual requested slot and checkpoint")
		check(status_fields()["health"] == session.player.life.health, "panel reads actual life without changing it")

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var adapter: Node = COMPLETED.new()
	var parsed: Dictionary = adapter.call("parse_options",PackedStringArray(["--acceptance-smoke","--no-panel","--slot=2","--checkpoint=abc","--capture","--capture-dir=res://../codexandclaude/runs/custom"]))
	check(parsed["self_test"] and not parsed["panel"] and parsed["slot"] == 2 and parsed["checkpoint"] == "abc", "acceptance arguments parsed")
	check(parsed["capture"] and str(parsed["capture_dir"]).ends_with("custom"), "screenshot mode and output parsed")
	for argument: String in ["--slot=0","--slot=4","--slot=oops","--unknown"]:
		check(not str(adapter.call("parse_options",PackedStringArray([argument]))["error"]).is_empty(), "invalid argument rejected: "+argument)
	var outcomes: Array[int] = []
	adapter.connect("finished",func(code: int) -> void: outcomes.append(code))
	root.add_child(adapter)
	await adapter.call("run",PackedStringArray(["--acceptance-smoke","--no-panel"]))
	var directory: String = str(adapter.get("directory"))
	check(outcomes == [0], "migrated real SYS-004 clicks pass")
	check(adapter.get("panel") == null, "panel can be disabled")
	check(directory.begins_with(OS.get_cache_dir()) and not DirAccess.dir_exists_absolute(directory), "cache temporary saves removed")
	# Independent cleanup fallback makes cleanup mutations safe to test.
	if DirAccess.dir_exists_absolute(directory):
		for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	adapter.queue_free()
	await process_frame
	var entry: Node = EntryAdapter.new()
	outcomes.clear()
	entry.connect("finished",func(code: int) -> void: outcomes.append(code))
	root.add_child(entry)
	await entry.call("run",PackedStringArray(["--self-test","--slot=2"]))
	check(outcomes == [0] and entry.get("panel") != null, "entry adapter with optional real status panel passes")
	directory = str(entry.get("directory"))
	check(not DirAccess.dir_exists_absolute(directory), "entry adapter also cleans saves")
	if DirAccess.dir_exists_absolute(directory):
		for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	entry.queue_free()
	await process_frame
	print("ACCEPTANCE_LAUNCHER_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
