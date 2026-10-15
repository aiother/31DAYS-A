extends SceneTree
var checks: int = 0
var failures: int = 0
var store: SlotStore = SlotStore.new()

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func write_text(path: String, value: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func run() -> void:
	store.directory = "user://tests/slots_%d" % Time.get_ticks_usec()
	check(store.load_slot(1).is_empty() and store.last_error.is_empty(), "missing slot is empty, not corrupt")
	var data: Dictionary = store.fresh()
	check(store.valid(data) and store.save_slot(1, data), "versioned fresh slot writes successfully")
	check(store.load_slot(1) == data and not store.used_backup, "JSON round trip preserves all fields")
	data["balance"] = -9
	data["health"] = 1
	data["events"]["fixture_event"] = true
	check(store.save_slot(1, data), "overdraft and permanent event save")
	var loaded: Dictionary = store.load_slot(1)
	check(loaded["balance"] == -9 and loaded["events"]["fixture_event"], "negative balance and event survive loading")
	check(not store.save_slot(0, data) and not store.save_slot(4, data), "slot bounds enforced")
	var other: Dictionary = store.fresh()
	other["balance"] = 8
	check(store.save_slot(2, other), "independent second slot writes")
	check(store.load_slot(1)["balance"] == -9 and store.load_slot(2)["balance"] == 8, "slots do not cross-contaminate")
	for pair: Array in [["version", 2], ["version", 0], ["health", 0], ["health", 6], ["balance", -10], ["balance", 11], ["balance", 1.5], ["balance", true], ["maximum", 15], ["checkpoint", "../escape"], ["events", []], ["play_seconds", -1], ["health", "3"]]:
		var invalid: Dictionary = store.fresh()
		invalid[pair[0]] = pair[1]
		check(not store.save_slot(2, invalid) and store.load_slot(2)["balance"] == 8, "invalid %s rejected without modifying slot" % str(pair))
	var invalid_event: Dictionary = store.fresh()
	invalid_event["events"]["event"] = "executable data"
	check(not store.valid(invalid_event), "event storage only accepts boolean states")
	check(store.save_slot(1, data), "creates previous valid backup")
	write_text(store.path_for(1), "{interrupted")
	check(store.load_slot(1)["balance"] == -9 and store.used_backup, "corrupt primary falls back to last valid backup")
	check(store.save_slot(1, data) and not store.load_slot(1).is_empty(), "recovered backup can repair primary")
	write_text(store.path_for(3), '{"version":99}')
	check(store.load_slot(3).is_empty() and not store.last_error.is_empty(), "future version is reported without loading")
	check(FileAccess.get_file_as_string(store.path_for(3)) == '{"version":99}', "incompatible file preserved for explicit overwrite decision")
	write_text(store.path_for(1), "[]")
	write_text(store.path_for(1) + ".bak", "null")
	check(store.load_slot(1).is_empty() and not store.last_error.is_empty(), "both invalid copies return visible error")
	var original_dir: String = store.directory
	var block_path: String = original_dir.path_join("blocked")
	write_text(block_path, "a file is not a directory")
	store.directory = block_path
	check(not store.save_slot(1, data) and not store.last_error.is_empty(), "unwritable destination returns failure")
	store.directory = original_dir
	check(store.load_slot(2)["balance"] == 8, "write failure leaves other slots intact")
	# Delete only this test's explicit files, never player saves or arbitrary paths.
	for slot: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(slot) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(block_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(original_dir))
	print("SLOT_STORE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
