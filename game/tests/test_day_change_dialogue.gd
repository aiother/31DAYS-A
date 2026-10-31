# verify-suite: {"name": "date-change animation holds during field dialogue", "path": "res://tests/test_day_change_dialogue.gd", "marker": "DAY_CHANGE_DIALOGUE_TESTS checks=", "fixed_fps": 60, "timeout": 90}
extends SceneTree
## UI-011 review R1: a natural new day followed at once by talking to Seven must
## not draw the date animation over the dialogue slip. The animation waits at its
## start while the dialogue is open and then plays in full.
var checks: int = 0
var failures: int = 0
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	# Labs and test hosts own a HUD without intro_active or dialogue_ui.
	var bare: FormalHud = FormalHud.new()
	bare.session = Node.new()
	check(not bare.day_change_held(), "a host without intro or dialogue never holds the date animation")
	bare.session.free()
	bare.free()
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await case(window)
	print("DAY_CHANGE_DIALOGUE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func case(window: Vector2i) -> void:
	var label: String = "%dx%d" % [window.x, window.y]
	root.size = window
	directory = "user://tests/day_change_dialogue_%d" % Time.get_ticks_usec()
	var host: FinalBattleSession = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	host.save_directory = directory
	root.add_child(host)
	current_scene = host
	var snapshot: Dictionary = host.store.fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["events"][FieldSession.FIELD_STORY] = true
	snapshot["day"] = 2
	snapshot["day_remaining"] = 900.0
	check(host.store.save_slot(1, snapshot) and host.start_slot(1, false), label + ": isolated second-day slot loads")
	host._change_room(FieldSession.FIELD_ID)
	host.player.position = Vector2(1728, 896)
	host.player.set_physics_process(false)
	host.room.process_mode = Node.PROCESS_MODE_DISABLED
	await ticks(4)
	var hud: FormalHud = host.ui.get("_hud") as FormalHud
	var total: float = DayClock.CONFIG.announcement_seconds
	# A real, natural rollover: the day clock runs out and advances the day itself.
	host.data["day_remaining"] = 0.01
	await ticks(4)
	check(int(host.data["day"]) == 3 and hud.banner_day == 3 and hud.banner_left > 0.0, label + ": the natural rollover starts the date animation")
	check(host.interact_seven(), label + ": talking to Seven right after the new day opens the dialogue")
	await ticks(96)
	var talk: FieldDialogue = host.dialogue_ui
	check(talk.active and talk.drawn.has("box"), label + ": the dialogue slip is on screen")
	check(not hud.drawn.has("banner"), label + ": the date animation is not drawn over the open dialogue")
	check(is_equal_approx(hud.banner_left, total), label + ": the date animation waits at its start while the dialogue is open")
	talk.dismiss()
	await ticks(3)
	check(not talk.active, label + ": the dialogue closes")
	check(hud.drawn.has("banner") and float(hud.drawn["banner"]["elapsed"]) < 0.2 and float(hud.drawn["banner"]["title_alpha"]) < 0.05, label + ": the date animation then starts from the beginning")
	await ticks(90)
	check(hud.drawn.has("banner") and float(hud.drawn["banner"]["title_alpha"]) > 0.95 and hud.drawn["banner"]["text"] == "第 三 日", label + ": the full date animation plays after the dialogue")
	# Independent review: an intro interrupting a live banner must also hold
	# its drawing and restart the full animation when the intro ends.
	host.intro_active = true
	await ticks(6)
	check(not hud.drawn.has("banner") and is_equal_approx(hud.banner_left, total), label + ": opening intro hides and resets an in-progress date animation")
	host.intro_active = false
	await ticks(3)
	check(hud.drawn.has("banner") and float(hud.drawn["banner"]["elapsed"]) < 0.2, label + ": the date animation restarts after the opening intro")
	host.queue_free()
	await ticks(2)
	var absolute: String = ProjectSettings.globalize_path(directory)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
		DirAccess.remove_absolute(absolute)
