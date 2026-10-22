extends SceneTree
## EXP-004 screenshots for the delivery record. Needs a rendering display:
## Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-004/tests/capture.gd
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder.path_join(name + ".png")))

func dialogue() -> Control:
	return preview.get("dialogue") as Control

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-004/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(3)
	(preview.get("help") as Label).visible = false
	for variant: int in range(3):
		var letter: String = ["a", "b", "c"][variant]
		preview.call("set_variant", variant)
		preview.call("talk")
		await frames(40)
		dialogue().call("press")
		await shot("dialogue_%s_line" % letter)
		dialogue().call("close")
		preview.call("leave_town")
		dialogue().call("press")
		dialogue().call("press")
		await shot("dialogue_%s_leave" % letter)
		dialogue().call("close")
	preview.call("set_variant", 0)
	preview.set("g08_mode", 0)
	preview.call("reach_missed")
	await frames(120)
	await shot("g08_1_line")
	dialogue().call("close")
	preview.set("g08_mode", 1)
	preview.call("reach_missed")
	await shot("g08_2_tag")
	await frames(300)
	for variant: int in range(2):
		preview.call("set_card_variant", variant)
		preview.call("ordinary_card")
		await frames(40)
		await shot("card_%d_enemy" % (variant + 1))
		await frames(300)
		preview.call("boss_card")
		await frames(40)
		await shot("card_%d_boss" % (variant + 1))
		await frames(300)
	preview.call("set_variant", 1)
	preview.call("talk")
	preview.call("boss_card")
	preview.call("wave")
	await frames(40)
	await shot("together_b")
	quit()
