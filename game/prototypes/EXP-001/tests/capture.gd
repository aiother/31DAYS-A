extends SceneTree
## Renders each variant in two representative states to PNG for the delivery
## record. Needs a window (not --headless):
## Godot --path game --script res://prototypes/EXP-001/tests/capture.gd
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func shot(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(get_script().resource_path.get_base_dir().get_base_dir().path_join("screenshots/%s.png" % name))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("CAPTURE ", path)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-001/hud_preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	preview.get("help_label").visible = false
	var state: HudState = preview.get("state")
	for index: int in range(3):
		preview.call("press", KEY_1 + index)
		# Normal play: some possibility, one growth segment, two pearls, day 2.
		state.reset()
		state.balance = 7
		state.growth = 1
		state.pearls = 2
		state.show_medkit = true
		state.day = 2
		state.day_remaining = 700.0
		if index == 1:
			preview.get("variant").set("expanded", true)
		await shot("variant%d_normal" % (index + 1))
		preview.get("variant").set("expanded", false)
		# Pressure: last life, overdraft, flashing, final countdown under 15 minutes.
		state.reset()
		state.health = 1
		state.balance = -4
		state.pearls = 4
		state.start_final(552.0)
		state.deny_left = HudState.DENY_SECONDS
		state.clock = 0.056
		state.frozen = true
		await shot("variant%d_pressure" % (index + 1))
		state.frozen = false
	quit(0)
