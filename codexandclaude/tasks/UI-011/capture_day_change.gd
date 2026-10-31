extends SceneTree
## UI-011: render the date-change animation at several moments for review.
## Usage (from the repository root, rendered, not headless):
##   Godot --path game --resolution 1920x1080 --script res://../codexandclaude/tasks/UI-011/capture_day_change.gd
## Uses an isolated cache save directory, never the player's slots, and quits by itself.
const OUT_DIR: String = "res://../codexandclaude/tasks/UI-011/captures"
const MOMENTS: Array[float] = [0.2, 0.45, 0.7, 1.0, 1.6, 3.4]
var directory: String

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var out: String = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920, 1080)
	directory = "user://ui011_capture_%d" % Time.get_ticks_usec()
	var session: FinalBattleSession = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var data: Dictionary = session.store.fresh()
	data["events"][StartRoomSession.BIRTH] = true
	data["day"] = 2
	data["day_remaining"] = 1700.0
	session.store.save_slot(1, data)
	session.start_slot(1, false)
	for i: int in range(20):
		await process_frame
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	var total: float = DayClock.CONFIG.announcement_seconds
	for moment: float in MOMENTS:
		hud.banner_day = 2
		hud.banner_left = total - moment
		# Freeze the announcement clock at this moment while the frame renders.
		hud.set_process(false)
		hud.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var name: String = "day_change_%04d.png" % int(round(moment * 1000.0))
		image.save_png(out.path_join(name))
		print("CAPTURE ", name, " ", hud.drawn.get("banner", {}).get("rect", Rect2()))
		hud.set_process(true)
	session.queue_free()
	await process_frame
	var absolute: String = ProjectSettings.globalize_path(directory)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
		DirAccess.remove_absolute(absolute)
	print("UI011_CAPTURE done=%d" % MOMENTS.size())
	quit(0)
