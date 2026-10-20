# verify-suite: {"name": "medkit inventory version-one compatibility bounds and slot persistence", "path": "res://tests/test_medkit_store.gd", "marker": "MEDKIT_STORE_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var store: SlotStore = SlotStore.new()
	store.directory = "user://tests/medkit_store_%d" % Time.get_ticks_usec()
	var data: Dictionary = store.fresh()
	check(MedkitRules.count(data) == 0 and store.valid(data), "new game starts with zero")
	data.erase("medkits")
	check(store.valid(data) and store.save_slot(1, data), "old version-one save without inventory remains valid")
	check(store.load_slot(1)["medkits"] == 0, "old save migrates to zero without free inventory")
	for count: int in range(4):
		data["medkits"] = count
		check(store.save_slot(1, data), "legal count saves %d" % count)
		check(store.load_slot(1)["medkits"] == count, "legal count round trips %d" % count)
	for invalid: Variant in [-1, 4, 1.5, true, "2", null, INF, NAN]:
		data["medkits"] = invalid
		check(not store.save_slot(1, data), "invalid inventory cannot overwrite slot")
		check(store.load_slot(1)["medkits"] == 3, "failed validation retains previous inventory")
	data["medkits"] = 1
	check(store.save_slot(2, data) and store.load_slot(1)["medkits"] == 3 and store.load_slot(2)["medkits"] == 1, "two slots keep independent inventories")
	check(store.save_slot(2, store.fresh()) and store.load_slot(2)["medkits"] == 0, "new game clears previous slot inventory")
	for id: String in MedkitRules.CONFIG.placements:
		check(MedkitRules.key(id).length() <= 128 and MedkitRules.CONFIG.placements[id] is Vector2, "fixed pickup has valid persistent key and position")
	check(MedkitRules.CONFIG.placements.size() == 4 and MedkitRules.CONFIG.maximum == 3 and MedkitRules.CONFIG.healing == 2, "confirmed four sources cap and healing")
	for slot: int in [1, 2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = store.path_for(slot) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.directory))
	print("MEDKIT_STORE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
