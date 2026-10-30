extends "res://tests/acceptance/acceptance_harness.gd"
## ART-003 player-scale proposal: capture real gameplay frames for the mockups.
## Runs with isolated temporary saves; changes nothing in the game. Usage in README.md.
const OUT_DIR: String = "res://../codexandclaude/proposals/ART-003/player_scale_v1/captures_ref"
var OUT: String = ProjectSettings.globalize_path(OUT_DIR)
const ZOOMS: Array[float] = [1.875]
const GROUND_Y: float = 950.0

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
	return {"id":"SCALE", "marker":"SCALE_CAPTURE", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:fixture(1, StartRoomSession.CHECKPOINT, []),
			2:fixture(3, TrenchPassageSession.PASSAGE_CHECKPOINT, [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD])},
		"enter":true}

func run(arguments: PackedStringArray) -> void:
	await super.run(arguments)
	DirAccess.make_dir_recursive_absolute(OUT)
	var slot: int = int(options["slot"])
	get_tree().root.size = Vector2i(1920, 1080)
	await settle(30)
	freeze_enemies(session)
	await get_tree().create_timer(3.6).timeout
	for zoom: float in ZOOMS:
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera != null:
			camera.zoom = Vector2(zoom, zoom)
			camera.reset_smoothing()
		await settle(20)
		var feet_y: float = session.player.get_global_transform_with_canvas().origin.y
		camera.offset.y -= (GROUND_Y - feet_y) / zoom
		camera.reset_smoothing()
		await settle(20)
		print("CAMERA limits ", camera.limit_top, " ", camera.limit_bottom, " drag ", camera.drag_vertical_enabled)
		await shoot("slot%d_zoom%.2f_with_placeholder" % [slot, zoom])
		var visual: CanvasItem = session.player.get_node_or_null("VisualRoot") as CanvasItem
		if visual != null: visual.visible = false
		await settle(4)
		await shoot("slot%d_zoom%.2f_no_player" % [slot, zoom])
		if visual != null: visual.visible = true
	await finish()

func settle(count: int) -> void:
	for i: int in range(count): await get_tree().process_frame

func shoot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(OUT.path_join(label + ".png"))
	var feet: Vector2 = session.player.get_global_transform_with_canvas().origin
	var camera: Camera2D = get_viewport().get_camera_2d()
	var info: Dictionary = {"image":[image.get_width(), image.get_height()], "visible_rect":[get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"feet_canvas":[feet.x, feet.y], "zoom": camera.zoom.x if camera else 0.0, "on_floor": session.player.is_on_floor()}
	var file: FileAccess = FileAccess.open(OUT.path_join(label + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(info))
	print("SHOT ", label, " ", info)

func freeze_enemies(node: Node) -> void:
	for child: Node in node.get_children():
		var script: Script = child.get_script() as Script
		if script != null and script.resource_path.contains("/enemies/"):
			child.process_mode = Node.PROCESS_MODE_DISABLED
			continue
		freeze_enemies(child)
