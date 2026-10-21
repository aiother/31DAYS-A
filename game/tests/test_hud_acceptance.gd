# verify-suite: {"name":"UI-002 acceptance adapter isolated slots reach warning and both final budgets","path":"res://tests/test_hud_acceptance.gd","marker":"HUD_ACCEPTANCE_TESTS checks=","fixed_fps":null,"timeout":90}
extends SceneTree
## Runs the UI-002 G4 adapter's own self-test through the shared launcher and
## confirms it cleans up its temporary saves.
const ADAPTER: Script = preload("res://tests/acceptance/ui002_hud.gd")
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
	var adapter: Node = ADAPTER.new()
	var outcomes: Array[int] = []
	adapter.connect("finished", func(code: int) -> void: outcomes.append(code))
	root.add_child(adapter)
	await adapter.call("run", PackedStringArray(["--self-test"]))
	var directory: String = str(adapter.get("directory"))
	check(outcomes == [0], "UI-002 adapter self-test passes on real slots")
	check(int(adapter.get("checks")) >= 10 and int(adapter.get("failures")) == 0, "adapter ran its slot checks")
	check(directory.begins_with(OS.get_cache_dir()) and not DirAccess.dir_exists_absolute(directory), "adapter temporary saves removed")
	if DirAccess.dir_exists_absolute(directory):
		for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	adapter.queue_free()
	await process_frame
	print("HUD_ACCEPTANCE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
