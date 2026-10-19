extends SceneTree
## Capture real rendered UI with isolated test data; no production save changes.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
const LONG_ERROR: String = "存档写入失败：无法写入检查点存档文件，可能是磁盘空间不足或存档目录不可写。当前进度仍保留在本次游戏中，请释放磁盘空间后在检查点重试，或打开暂停菜单返回存档槽选择其他存档位置继续游戏。"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await process_frame
		await physics_frame

func capture(filename: String, size: Vector2i) -> void:
	root.size = size
	await ticks(4)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image != null and not image.is_empty(), "rendered image must exist")
	if image == null or image.is_empty():
		return
	check(image.get_size() == size, "capture must match requested window size")
	var destination: String = ProjectSettings.globalize_path("res://../codexandclaude/runs/hud-preview/" + filename)
	check(DirAccess.make_dir_recursive_absolute(destination.get_base_dir()) == OK, "capture directory must be writable")
	check(image.save_png(destination) == OK, "PNG must save successfully")
	print("CAPTURE ", destination)

func run() -> void:
	directory = "user://tests/hud_preview_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "isolated preview slot must start")
	await ticks(3)
	session = current_scene as FinalBattleSession
	session.data["events"][StartRoomSession.BIRTH] = true
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	paused = false
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
	if session.room.environment_hazard != null:
		session.room.environment_hazard.set_physics_process(false)
	session.player.set_physics_process(false)
	session.player.possibility.cancel()
	session.player.possibility.state = PlayerPossibility.State.HEALING
	session.player.possibility.remaining = session.player.possibility.config.heal_duration * 0.5
	session.data["medkits"] = 2
	session.player.combat.pearl_count = 2
	session.ui.save_failed("存档写入失败，请稍后重试")
	await ticks(3)
	var hud: Label = session.ui.get("_health") as Label
	check(hud.get_line_count() == 5 and hud.text.contains("恢复中"), "capture must show actual five-row healing HUD")
	await capture("short_1920.png", Vector2i(1920, 1080))
	await capture("short_1280.png", Vector2i(1280, 720))
	session.ui.save_failed(LONG_ERROR)
	await capture("long_1920.png", Vector2i(1920, 1080))
	await capture("long_1280.png", Vector2i(1280, 720))
	var error: Label = session.ui.get("_error_label") as Label
	check(error.get_line_count() > 1, "long error must wrap in the actual renderer")
	session.ui.show_pause()
	check(paused, "pause preview must use the actual paused menu")
	await capture("pause_1280.png", Vector2i(1280, 720))
	session.ui.show_settings()
	await capture("settings_1280.png", Vector2i(1280, 720))
	paused = false
	session.queue_free()
	await ticks(2)
	current_scene = null
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path):
				check(DirAccess.remove_absolute(path) == OK, "temporary preview save cleanup")
	check(DirAccess.remove_absolute(directory) == OK, "temporary preview directory cleanup")
	print("HUD_PREVIEW_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
