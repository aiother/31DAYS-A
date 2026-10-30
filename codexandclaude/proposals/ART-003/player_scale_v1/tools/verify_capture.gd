extends "res://tests/acceptance/acceptance_harness.gd"
## ART-003 player-scale proposal: capture the shipped gameplay camera as-is
## (no zoom override) to verify the implemented framing. Usage in README.md.
const OUT_DIR: String = "res://../codexandclaude/proposals/ART-003/player_scale_v1/verify"
var OUT: String = ProjectSettings.globalize_path(OUT_DIR)

func fixture(day: int, checkpoint: String, extra: Array) -> Dictionary:
	var snapshot: Dictionary = SlotStore.new().fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["day"] = day
	snapshot["day_remaining"] = 1500.0
	snapshot["day3_remaining"] = 1500.0 if day == 3 else DayClock.CONFIG.day_seconds
	snapshot["balance"] = 6
	snapshot["checkpoint"] = checkpoint
	for flag: String in extra: snapshot["events"][flag] = true
	return snapshot

func configuration() -> Dictionary:
	return {"id":"SCALE", "marker":"SCALE_VERIFY", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:fixture(1, StartRoomSession.CHECKPOINT, []),
			2:fixture(3, TrenchPassageSession.PASSAGE_CHECKPOINT, [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD])},
		"enter":true}

func run(arguments: PackedStringArray) -> void:
	await super.run(arguments)
	DirAccess.make_dir_recursive_absolute(OUT)
	get_tree().root.size = Vector2i(1920, 1080)
	await get_tree().process_frame
	freeze_enemies(session)
	await get_tree().create_timer(3.6).timeout
	var camera: Camera2D = get_viewport().get_camera_2d()
	camera.reset_smoothing()
	for i: int in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var label: String = "slot%d_game_camera" % int(options["slot"])
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(OUT.path_join(label + ".png"))
	var feet: Vector2 = session.player.get_global_transform_with_canvas().origin
	var info: Dictionary = {"image":[image.get_width(), image.get_height()], "feet_canvas":[feet.x, feet.y],
		"zoom":camera.zoom.x, "camera_script":camera.get_script().resource_path, "on_floor":session.player.is_on_floor()}
	var file: FileAccess = FileAccess.open(OUT.path_join(label + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(info))
	print("SHOT ", label, " ", info)
	await finish()

func freeze_enemies(node: Node) -> void:
	for child: Node in node.get_children():
		var script: Script = child.get_script() as Script
		if script != null and script.resource_path.contains("/enemies/"):
			child.process_mode = Node.PROCESS_MODE_DISABLED
			continue
		freeze_enemies(child)
