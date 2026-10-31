# verify-suite: {"name":"battle camera transitions and cinematic ownership","path":"res://tests/test_battle_camera.gd","marker":"BATTLE_CAMERA_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func inside(camera: Camera2D) -> bool:
	var half: Vector2 = camera.get_viewport_rect().size / camera.zoom * 0.5
	var center: Vector2 = camera.get_screen_center_position()
	var bounds: Rect2 = session.room.config.bounds
	return center.x - half.x >= bounds.position.x - 1.0 and center.x + half.x <= bounds.end.x + 1.0 and center.y - half.y >= bounds.position.y - 1.0 and center.y + half.y <= bounds.end.y + 1.0

func run() -> void:
	directory = "user://tests/battle_camera_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	for flag: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, BossSession.BOSS_INTRO, ParasiteSession.PARASITE_INTRO]: snapshot["events"][flag] = true
	check(session.store.save_slot(1, snapshot) and session.start_slot(1, false), "isolated boss checkpoint entered")
	session.room.process_mode = Node.PROCESS_MODE_DISABLED
	session.player.set_physics_process(false)
	var camera: Camera2D = session.player.get_node("Camera2D") as Camera2D
	var actor: OverlookBoss = session.room.get_node("Boss") as OverlookBoss
	actor.set_physics_process(false)
	var initial: float = camera.zoom.x
	await ticks(3)
	check(camera.zoom.x < initial and camera.zoom.x > 1.5, "battle enters smoothly, without snapping (%.3f -> %.3f)" % [initial, camera.zoom.x])
	await ticks(95)
	check(absf(camera.zoom.x - 1.5) < 0.002 and inside(camera), "overlook battle settles at x1.5 inside Room")
	camera.set("battle_zoom", 1.6)
	await ticks(95)
	check(absf(camera.zoom.x - 1.6) < 0.002, "battle zoom is configurable")
	camera.set("battle_zoom", 1.5)
	await ticks(95)
	var data_before: Dictionary = session.data.duplicate(true)
	for i: int in range(3): session.gameplay_camera_state()
	check(session.data == data_before, "camera policy queries preserve save data")
	camera.set("battle_zoom", 0.5)
	await ticks(95)
	check(camera.zoom.x >= 1.0 and inside(camera), "custom zoom cannot make a view larger than Room bounds")
	camera.set("battle_zoom", 1.5)
	await ticks(95)
	var zoom_before: Vector2 = camera.zoom
	var position_before: Vector2 = camera.position
	session.cinematics.begin(&"legacy.lock")
	camera.offset = Vector2(7, -11)
	await ticks(12)
	check(camera.zoom == zoom_before and camera.position == position_before and camera.offset == Vector2(7, -11), "cinematics own camera without framing or offset interference")
	session.cinematics.finish()
	camera.offset = Vector2.ZERO
	for point: Vector2 in [Vector2(32, 64), Vector2(1888, 1504)]:
		session.player.position = point
		camera.reset_smoothing()
		await ticks(3)
		check(inside(camera), "battle view stays within each edge after player moves")
	session.player.position = Vector2(480, 1280)
	var director: CombatEffectDirector = session.player.get_node("EffectDirector") as CombatEffectDirector
	director.call("_kick", director.config.hurt_shake)
	var peak: float = 0.0
	for i: int in range(35):
		await ticks(1)
		peak = maxf(peak, camera.offset.length() * camera.zoom.x)
	check(peak > 0.0 and peak <= director.config.hurt_shake + 0.01 and camera.offset == Vector2.ZERO, "battle zoom preserves shake amplitude in screen pixels")
	actor.mark_defeated()
	await ticks(1)
	check(camera.zoom.x > 1.5 and camera.zoom.x < 1.875, "battle exits smoothly")
	await ticks(95)
	check(absf(camera.zoom.x - 1.875) < 0.002, "defeated boss restores ordinary framing")
	session._change_room(CampWavesSession.WAVES_ID)
	session.room.process_mode = Node.PROCESS_MODE_DISABLED
	var camp: CampWavesRoom = session.room as CampWavesRoom
	check(camp.start_waves(), "real camp warning starts")
	await ticks(80)
	check(absf(camera.zoom.x - 1.5) < 0.005, "camp warning/active wave zooms out")
	camp.phase = CampWavesRoom.Phase.COMPLETE
	await ticks(80)
	check(absf(camera.zoom.x - 1.875) < 0.005, "completed camp returns to normal zoom")
	session._change_room(ParasiteSession.PARASITE_ID)
	session.room.process_mode = Node.PROCESS_MODE_DISABLED
	(session.room.get_node("Boss") as ParasiteBoss).set_physics_process(false)
	await ticks(80)
	check(absf(camera.zoom.x - 1.5) < 0.005, "parasite fight also zooms out")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	session.room.process_mode = Node.PROCESS_MODE_DISABLED
	session.cinematics.reset()
	var battlefield: FinalBattlefieldRoom = session.room as FinalBattlefieldRoom
	battlefield.set_physics_process(false)
	battlefield.started = true
	battlefield.stopped = false
	await ticks(80)
	check(absf(camera.zoom.x - 1.5) < 0.005, "final battlefield fight zooms out")
	battlefield.stopped = true
	battlefield.wave_state = FinalBattlefieldRoom.WaveState.WARNING
	await ticks(3)
	check(absf(camera.zoom.x - 1.5) < 0.005, "next-wave warning retains the battle view")
	paused = true
	zoom_before = camera.zoom
	await ticks(3)
	check(camera.zoom == zoom_before, "pause freezes framing")
	paused = false
	for scene: String in ["movement_lab", "enemy_lab", "combat_lab", "checkpoint_lab"]:
		var lab: Node = (load("res://debug/%s.tscn" % scene) as PackedScene).instantiate()
		root.add_child(lab)
		check(lab.get_node("Player/Camera2D") is GameplayCamera, scene + " inherits GameplayCamera")
		lab.queue_free()
		await ticks(2)
	session.queue_free()
	await ticks(2)
	var absolute: String = ProjectSettings.globalize_path(directory)
	for file: String in DirAccess.get_files_at(absolute): DirAccess.remove_absolute(absolute.path_join(file))
	DirAccess.remove_absolute(absolute)
	print("BATTLE_CAMERA_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
