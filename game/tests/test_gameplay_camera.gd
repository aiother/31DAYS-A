# verify-suite: {"name": "gameplay camera framing from ART-003 player scale", "path": "res://tests/test_gameplay_camera.gd", "marker": "GAMEPLAY_CAMERA_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: TwoRoomSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	directory = "user://tests/gameplay_camera_%d" % Time.get_ticks_usec()
	session = (load("res://world/two_room_session.tscn") as PackedScene).instantiate() as TwoRoomSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for flag: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER]:
		snapshot["events"][flag] = true
	session.store.save_slot(1, snapshot)
	check(session.start_slot(1, false), "entry checkpoint loads")
	for actor: Node in session.room.get_node("Enemies").get_children():
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	var camera: GameplayCamera = session.player.get_node("Camera2D") as GameplayCamera
	await ticks(3)
	camera.reset_smoothing()
	await ticks(2)
	check(camera is GameplayCamera and camera.zoom == Vector2.ONE * camera.normal_zoom, "sessions use the exported normal zoom")
	check(camera.offset == Vector2.ZERO, "framing leaves offset free for cinematics and shake")
	check(is_equal_approx(camera.feet_lift(1080.0), (camera.ground_ratio - 0.5) * 1080.0 / camera.normal_zoom), "feet lift follows the instance defaults")
	var canvas: Transform2D = session.get_viewport().get_canvas_transform()
	var feet: Vector2 = canvas * session.player.global_position
	check(session.player.is_on_floor() and absf(feet.y - camera.get_viewport_rect().size.y * camera.ground_ratio) < 1.0, "standing feet follow the exported ratio (y %.1f)" % feet.y)
	var head: Vector2 = canvas * (session.player.global_position + Vector2(0, -112))
	check(absf((feet.y - head.y) - 112.0 * camera.normal_zoom) < 0.5, "player screen height follows the default zoom")
	var capsule: CapsuleShape2D = (session.player.get_node("BodyCollision") as CollisionShape2D).shape as CapsuleShape2D
	check(capsule.height == 88.0 and session.player.movement.jump_speed == 850.0, "collision and movement keep their world values")
	var view: Vector2 = camera.get_viewport_rect().size / camera.zoom
	var center: Vector2 = camera.get_screen_center_position()
	var bounds: Rect2 = session.room.config.bounds
	check(center.x - view.x * 0.5 >= bounds.position.x - 1 and center.x + view.x * 0.5 <= bounds.end.x + 1
		and center.y - view.y * 0.5 >= bounds.position.y - 1 and center.y + view.y * 0.5 <= bounds.end.y + 1,
		"the zoomed view stays inside Room bounds")
	var director: CombatEffectDirector = session.player.get_node("EffectDirector") as CombatEffectDirector
	director.call("_kick", director.config.hurt_shake)
	var peak: float = 0.0
	for i: int in range(40):
		await ticks(1)
		peak = maxf(peak, camera.offset.length() * camera.zoom.x)
	check(peak > 0.0 and peak <= director.config.hurt_shake + 0.01 and camera.offset == Vector2.ZERO,
		"hurt shake keeps its screen amplitude under the zoom (peak %.2f px)" % peak)
	var default_zoom: float = camera.normal_zoom
	var default_ratio: float = camera.ground_ratio
	camera.normal_zoom = 1.6
	camera.ground_ratio = 0.76
	await ticks(95)
	camera.reset_smoothing()
	await ticks(3)
	feet = session.get_viewport().get_canvas_transform() * session.player.global_position
	check(absf(camera.zoom.x - camera.normal_zoom) < 0.002, "normal zoom updates from instance configuration")
	check(absf(feet.y - camera.get_viewport_rect().size.y * camera.ground_ratio) < 1.0, "feet position updates from instance configuration")
	check(is_equal_approx(camera.world_length(160.0), 100.0) and is_equal_approx(camera.world_length(160.0, 2.0), 80.0), "distance helper uses instance zoom or an explicit framing zoom")
	check(is_equal_approx(camera.feet_lift(1000.0, 2.0), 130.0), "feet helper combines instance ratio and explicit zoom")
	camera.normal_zoom = default_zoom
	camera.ground_ratio = default_ratio
	session.queue_free()
	await process_frame
	await process_frame
	var cleanup: SlotStore = SlotStore.new()
	cleanup.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(cleanup.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("GAMEPLAY_CAMERA_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
