# verify-suite: {"name":"first Seven cinematic under gameplay zoom","path":"res://tests/test_cinematic_camera_zoom.gd","marker":"CINEMATIC_CAMERA_ZOOM_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var host: FieldSession = (load("res://world/field_session.tscn") as PackedScene).instantiate() as FieldSession
	var directory: String = "user://tests/cinematic_camera_zoom_%d" % Time.get_ticks_usec()
	host.save_directory = directory
	root.add_child(host)
	current_scene = host
	host.slot = 1
	host.data = host.store.fresh()
	# This read-only presentation fixture mounts the actual adjacent Rooms.
	# It does not start/write a player slot or auto-complete any story events.
	host._mount_room(BossSession.BOSS_ID)
	paused = false
	host._change_room(FieldSession.FIELD_ID)
	for i: int in range(140):
		await physics_frame
		await process_frame
	var camera: Camera2D = host.player.get_node("Camera2D") as Camera2D
	var center: Vector2 = camera.get_screen_center_position()
	var npc: Vector2 = host.room.get_node("Seven").global_position
	var half_width: float = camera.get_viewport_rect().size.x / camera.zoom.x / 2.0
	check(host.cinematics.active(&"seven.first"), "first meeting cinematic is active")
	check(npc.x >= center.x - half_width + 60 and npc.x <= center.x + half_width - 60, "Seven and a visual margin are visible after the opening pan")
	check(absf(center.x - npc.x) < 30.0, "opening pans toward Seven using the actual zoom")
	check(center.x - half_width >= host.room.config.bounds.position.x - 1 and center.x + half_width <= host.room.config.bounds.end.x + 1, "cinematic pan stays inside Room bounds")
	host.queue_free()
	await process_frame
	await process_frame
	var absolute: String = ProjectSettings.globalize_path(directory)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute): DirAccess.remove_absolute(absolute.path_join(file))
		DirAccess.remove_absolute(absolute)
	print("CINEMATIC_CAMERA_ZOOM_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
