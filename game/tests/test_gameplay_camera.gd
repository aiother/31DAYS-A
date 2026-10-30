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
	var camera: Camera2D = session.player.get_node("Camera2D") as Camera2D
	await ticks(3)
	camera.reset_smoothing()
	await ticks(2)
	check(camera is GameplayCamera and camera.zoom == Vector2(1.875, 1.875), "sessions use the gameplay camera at x1.875")
	check(camera.offset == Vector2.ZERO, "framing leaves offset free for cinematics and shake")
	check(is_equal_approx(GameplayCamera.feet_lift(1080.0), 218.88), "camera sits 218.88 world px above the feet")
	var canvas: Transform2D = session.get_viewport().get_canvas_transform()
	var feet: Vector2 = canvas * session.player.global_position
	check(session.player.is_on_floor() and absf(feet.y - 950.4) < 1.0, "standing feet sit at 88%% of a 1080p screen (y %.1f)" % feet.y)
	var head: Vector2 = canvas * (session.player.global_position + Vector2(0, -112))
	check(absf((feet.y - head.y) - 210.0) < 0.5, "the 112 px player reads 210 px tall on screen")
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
