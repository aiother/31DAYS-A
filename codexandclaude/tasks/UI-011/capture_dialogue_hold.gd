extends SceneTree
## UI-011 review R1: render a natural new day followed at once by talking to Seven,
## at both supported resolutions: during the dialogue (no date animation) and after
## it closes (the animation plays from its start).
## Usage (from the repository root, rendered, not headless):
##   Godot --path game --script res://../codexandclaude/tasks/UI-011/capture_dialogue_hold.gd
## Uses an isolated cache save directory, never the player's slots, and quits by itself.
const OUT_DIR: String = "res://../codexandclaude/tasks/UI-011/captures"

func _initialize() -> void:
	run.call_deferred()

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT_DIR).path_join(name))
	print("CAPTURE ", name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		var directory: String = "user://ui011_dialogue_%d" % Time.get_ticks_usec()
		var host: FinalBattleSession = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
		host.save_directory = directory
		root.add_child(host)
		current_scene = host
		var snapshot: Dictionary = host.store.fresh()
		snapshot["events"][StartRoomSession.BIRTH] = true
		snapshot["events"][FieldSession.FIELD_STORY] = true
		snapshot["day"] = 2
		snapshot["day_remaining"] = 900.0
		host.store.save_slot(1, snapshot)
		host.start_slot(1, false)
		host._change_room(FieldSession.FIELD_ID)
		host.player.position = Vector2(1728, 896)
		host.player.set_physics_process(false)
		host.room.process_mode = Node.PROCESS_MODE_DISABLED
		await ticks(4)
		host.data["day_remaining"] = 0.01
		await ticks(4)
		host.interact_seven()
		await ticks(96)
		await shot("dialogue_hold_%d_talking.png" % window.x)
		host.dialogue_ui.dismiss()
		await ticks(96)
		await shot("dialogue_hold_%d_after.png" % window.x)
		host.queue_free()
		await ticks(2)
		var absolute: String = ProjectSettings.globalize_path(directory)
		if DirAccess.dir_exists_absolute(absolute):
			for file: String in DirAccess.get_files_at(absolute):
				DirAccess.remove_absolute(absolute.path_join(file))
			DirAccess.remove_absolute(absolute)
	print("UI011_DIALOGUE_CAPTURE done")
	quit(0)
