extends SceneTree
## EXP-003 screenshots for the delivery record. Needs a rendering display:
## Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-003/tests/capture.gd
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func shot(name: String) -> void:
	await frames(4)
	await RenderingServer.frame_post_draw
	# screenshots/ sits beside tests/ in this prototype folder.
	var folder: String = (get_script() as Script).resource_path.get_base_dir().get_base_dir().path_join("screenshots")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder.path_join(name + ".png")))

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-003/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(3)
	(preview.get("help") as Label).visible = false
	for i: int in range(3):
		preview.set("title_index", i)
		preview.call("open_title")
		await frames(20)
		await shot("title_%s" % ["a_dusk", "b_page", "c_haze"][i])
	preview.get("data").call("clear_all")
	preview.set("title_index", 0)
	preview.call("open_title")
	await shot("title_a_no_saves")
	preview.get("data").call("reset")
	preview.get("data").call("toggle_unreadable")
	for i: int in range(2):
		preview.set("slot_index", i)
		preview.call("open_slots", "continue")
		await frames(10)
		await shot("slots_%d_continue" % (i + 1))
		var view: Control = preview.get("screen") as Control
		(view.get("cards") as Array)[1].grab_focus()
		view.call("activate", 1)
		await shot("slots_%d_completed_prompt" % (i + 1))
		preview.call("open_slots", "new")
		await frames(10)
		view = preview.get("screen") as Control
		view.call("activate", 0)
		await shot("slots_%d_new_overwrite" % (i + 1))
	preview.call("start_game", 0)
	await frames(5)
	(preview.get("screen") as Control).call("open_page", "death")
	await shot("flow_death")
	(preview.get("screen") as Control).call("open_page", "end")
	await shot("flow_end")
	quit(0)
