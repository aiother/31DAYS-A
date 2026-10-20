extends SceneTree
## Renders both samples to PNG (needs a window, not --headless):
## Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-002/tests/capture.gd
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

func normal(state: HudState, day_key: Key) -> void:
	state.frozen = false
	preview.call("press", KEY_R)
	preview.call("press", day_key)
	state.balance = 7
	state.growth = 1
	state.pearls = 2
	state.show_medkit = true
	await frames(2)
	state.frozen = true

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-002/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	preview.get("help_label").visible = false
	var state: HudState = preview.get("state")
	for sample: int in range(2):
		var tag: String = "sample%d" % (sample + 1)
		preview.call("press", KEY_1 + sample)
		await normal(state, KEY_5)
		await shot(tag + "_day1_hud")
		await normal(state, KEY_7)
		await shot(tag + "_day3_hud")
		# Pressure on day 3: last life, overdraft, flashing, distortion.
		state.frozen = false
		state.health = 1
		state.balance = -5
		state.deny_left = HudState.DENY_SECONDS
		for i: int in range(90):
			await process_frame
		state.clock = 0.056
		state.deny_left = HudState.DENY_SECONDS
		state.frozen = true
		await shot(tag + "_day3_pressure")
		state.frozen = false
		preview.call("press", KEY_R)
		preview.call("press", KEY_8)
		# Wait (bounded) for the spin-down to really finish, not a frame count.
		var waited: int = 0
		while state.accelerate_left > 0.0 and waited < 600:
			await process_frame
			waited += 1
		state.frozen = true
		await shot(tag + "_final_countdown")
		state.frozen = false
		preview.call("press", KEY_9)
		await frames(3)
		state.frozen = true
		await shot(tag + "_final_short")
		await normal(state, KEY_6)
		state.frozen = false
		preview.call("press", KEY_ESCAPE)
		await frames(3)
		state.frozen = true
		await shot(tag + "_pause_clock")
		preview.get("pause").call("show_settings")
		await shot(tag + "_pause_settings")
		preview.call("press", KEY_ESCAPE)
		preview.call("press", KEY_ESCAPE)
		state.frozen = false
		preview.call("press", KEY_K)
		await frames(3)
		await shot(tag + "_dialog")
		preview.call("press", KEY_ESCAPE)
	quit(0)
