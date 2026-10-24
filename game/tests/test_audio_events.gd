# verify-suite: {"name":"audio events from real actions and isolated sessions","path":"res://tests/test_audio_events.gd","marker":"AUDIO_EVENTS_TESTS checks=","fixed_fps":60,"timeout":180}
extends SceneTree
var checks: int = 0
var failures: int = 0
var audio: AudioEventService
var lab: Node2D
var body: PlayerController
var session: FinalBattleSession
var directory: String
var observed: Dictionary = {}
var routed: bool = true
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int = 2) -> void:
	for i: int in range(n):
		await physics_frame
		await process_frame
func seen(event: String) -> Array:
	return audio.history.filter(func(row: Dictionary) -> bool: return row.event == event)
func begin() -> void:
	audio.history.clear()
func act(action: StringName, n: int = 1) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames()
func reset(point: Vector2 = Vector2(224, 880)) -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
	body.life.start_new_run()
	body.reset_kinematics()
	body.position = point
	body.possibility.balance = 10
	await frames(20)
	begin()
func player_cases() -> void:
	lab = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	body = lab.get_node("Player") as PlayerController
	await reset()
	await act(&"jump", 5)
	await frames(80)
	check(seen("player.jump").size() == 1 and seen("player.land").size() == 1, "real jump and landing each emit once")
	await reset(Vector2(224, 200))
	await frames(100)
	check(seen("player.hard_land").size() == 1, "real long fall emits hard landing")
	await reset()
	await act(&"attack")
	check(seen("combat.swing").size() == 1, "attack input emits a swing")
	await frames(30)
	begin()
	await act(&"dodge")
	check(seen("possibility.spend").size() == 1, "actual dodge spends once, A slot stays silent")
	check(not seen("possibility.spend")[0].audible, "A possibility event intentionally has no C placeholder")
	await frames(40)
	body.life.health = 1
	body.possibility.balance = 10
	begin()
	await act(&"recover", 180)
	check(seen("heal.start").size() == 1 and seen("heal.done").size() == 1, "real held recovery starts and finishes once")
	check(body.life.health == 3 and body.possibility.balance == 7, "audio does not alter healing or cost")
	await reset()
	body.life.health = 1
	body.possibility.balance = 0
	await act(&"recover")
	check(seen("possibility.shortfall").size() == 1 and seen("heal.start").is_empty(), "failed recovery reports shortfall without starting")
	begin()
	body.possibility.gain(2)
	check(seen("possibility.gain").size() == 1, "successful gain emits actual gained event")
	begin()
	body.life.protection_remaining = 0
	check(body.life.take_hit(1), "real hit succeeds")
	check(seen("player.hurt").size() == 1 and seen("player.death").size() == 1, "damage and downed death emit once")
	lab.queue_free()
	await frames(3)

func enemy_cases() -> void:
	lab = (load("res://debug/enemy_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	body = lab.get_node("Player") as PlayerController
	await frames(4)
	body.life.protection_remaining = 1000
	for path: String in ["res://enemies/colorless_entity.tscn", "res://enemies/monochrome_entity.tscn", "res://enemies/tian_warrior.tscn"]:
		var enemy: ColorlessEntity = (load(path) as PackedScene).instantiate()
		lab.add_child(enemy)
		enemy.global_position = body.global_position + Vector2(120, 0)
		enemy.target = body
		begin()
		var started: Array[int] = []
		enemy.attack_started.connect(func(_ranged: bool) -> void: started.append(Engine.get_physics_frames()))
		for i: int in range(240):
			await frames(1)
			if not started.is_empty(): break
		check(not started.is_empty() and seen("enemy.windup").size() == 1, path + " actual windup emits exactly one warning")
		if not started.is_empty() and not seen("enemy.windup").is_empty():
			check(seen("enemy.windup")[0].physics_frame == started[0] and enemy.state == ColorlessEntity.State.WINDUP, path + " warning shares visual windup physics frame")
		enemy.set_physics_process(false)
		begin()
		enemy.hurtbox.receive_attack(1, Vector2.ZERO, body, 100)
		check(seen("enemy.hurt").size() == 1, path + " accepted damage reports hurt")
		begin()
		enemy.hurtbox.receive_attack(1000, Vector2.ZERO, body, 101)
		check(seen("enemy.death").size() == 1, path + " actual defeat reports death")
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion(): enemy.queue_free()
		await frames(2)
	# A real player hit against a real target and a real reflected projectile.
	body.life.start_new_run()
	body.reset_kinematics()
	var target: ColorlessEntity = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate()
	lab.add_child(target)
	target.position = body.position + Vector2(80, 0)
	target.set_physics_process(false)
	begin()
	await act(&"attack")
	await frames(8)
	check(seen("combat.hit").size() >= 1, "real attack collision emits hit, old visual sound removed")
	await frames(30)
	target.queue_free()
	var projectile: ColorlessProjectile = (load("res://enemies/colorless_projectile.tscn") as PackedScene).instantiate()
	lab.add_child(projectile)
	projectile.position = body.position + Vector2(75, -48)
	projectile.set_physics_process(false)
	begin()
	await act(&"attack")
	await frames(8)
	check(projectile.reflected and seen("combat.reflect").size() == 1, "real projectile reflection uses reflect instead of duplicate hit")
	projectile.queue_free()
	# A real Tian guard entry (no state or signal manually assigned).
	var tian: TianWarrior = (load("res://enemies/tian_warrior.tscn") as PackedScene).instantiate()
	lab.add_child(tian)
	tian.target = body
	tian.position = body.position + Vector2(100, 0)
	tian.facing = -1
	begin()
	check(tian.try_block(Vector2(100, 0), body) and seen("combat.block").size() == 1, "actual valid Tian block emits once")
	tian.queue_free()
	lab.queue_free()
	await frames(3)

func service_cases() -> void:
	audio.stop_game()
	begin()
	var first: Dictionary = audio.play(&"combat.hit")
	var voice: AudioStreamPlayer = first.voice.get_ref()
	check(voice.playing and voice.bus == &"效果音" and first.stream == voice.stream, "record derives from a playing effects voice and stream")
	paused = true
	await frames(3)
	var count: int = audio.history.size()
	audio.play(&"combat.swing")
	check(audio.history.size() == count and voice.stream_paused, "pause suspends game sound and refuses new game events")
	var ui: Dictionary = audio.play(&"ui.confirm")
	check(ui.audible and not (ui.voice.get_ref() as AudioStreamPlayer).stream_paused, "UI voice can play while paused")
	paused = false
	await frames()
	var original: AudioEventMap = audio.mapping
	audio.mapping = original.duplicate(true)
	var replacement: AudioStreamWAV = PlaceholderTone.make(1234)
	audio.mapping.clips["combat.hit"] = replacement
	var changed: Dictionary = audio.play(&"combat.hit")
	var untouched: Dictionary = audio.play(&"enemy.windup")
	check(changed.stream == replacement and untouched.stream != replacement, "one mapping replacement changes only its event")
	audio.mapping.placeholders = []
	audio.mapping.clips.erase("combat.hit")
	var missing: Dictionary = audio.play(&"combat.hit")
	check(not missing.audible and missing.stream == null, "missing resource stays silent without error")
	# Real background players fade between nonempty resource slots.
	audio.mapping.environments["Region_HD"] = replacement
	audio.mapping.environments["Region_TY"] = PlaceholderTone.make(200)
	audio.mapping.music["exploration"] = replacement
	audio.mapping.fade_seconds = 0.1
	audio.set_context("Region_HD", "exploration")
	await frames(5)
	check(audio._tracks.size() == 2 and (audio._tracks[0].player as AudioStreamPlayer).bus == &"背景音", "music and ambience use real background voices")
	var gain: float = audio._tracks[0].gain
	paused = true
	await frames(3)
	check(audio._tracks.all(func(track: Dictionary) -> bool: return (track.player as AudioStreamPlayer).stream_paused) and audio._tracks[0].gain == gain, "pause freezes background voices and fade progress")
	paused = false
	audio.set_context("Region_TY", "exploration")
	check(audio._tracks.size() == 3 and audio._tracks[0].target == 0, "switch starts new ambience while old fades out")
	await frames(8)
	check(audio._tracks.size() == 2 and gain > 0, "fade advances and removes the old slot")
	audio.set_context("", "")
	await frames(10)
	audio.mapping = original
	check(audio._tracks.is_empty(), "empty background slots fade to silence")
	var settings: Node = root.get_node("GameSettings")
	var previous: Dictionary = settings.call("get_values")
	var settings_path: String = settings.get("file_path")
	check(settings_path != "user://settings.cfg", "custom SceneTree settings are isolated from the player file")
	settings.call("set_value", "sfx_volume", 25.0)
	settings.call("set_value", "music_volume", 60.0)
	check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("效果音")), 0.25), "settings change the real effects bus")
	check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("背景音")), 0.6), "settings change the real background bus independently")
	settings.call("set_value", "sfx_volume", previous.sfx_volume)
	settings.call("set_value", "music_volume", previous.music_volume)
	var button := Button.new()
	button.text = "确认"
	root.add_child(button)
	button.position = Vector2(100, 100)
	button.size = Vector2(200, 60)
	begin()
	button.grab_focus()
	await frames()
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = down
		Input.parse_input_event(key)
		await frames()
	check(not seen("ui.focus").is_empty() and not seen("ui.confirm").is_empty(), "real focus and accept button input emit UI events")
	button.text = "返回"
	begin()
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = down
		Input.parse_input_event(key)
		await frames()
	check(seen("ui.back").size() == 1, "real return button emits back instead of confirm")
	button.queue_free()
	await frames()

func quiet_session() -> void:
	session.set_process(false)
	session.set_physics_process(false)
	session.player.set_physics_process(false)
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	session.player.life.hurt_remaining = 0
	session.player.life.protection_remaining = 1000
	for node: Node in session.room.find_children("*", "Node", true, false):
		if node is ColorlessEntity or node is OverlookBoss or node is ParasiteBoss or node is RoomRockfall:
			node.set_physics_process(false)

func enter(id: String) -> void:
	session._mount_room(id)
	session._bind_room()
	quiet_session()
	await frames(2)
	begin()

func session_cases() -> void:
	directory = OS.get_user_data_dir().path_join("audio_test_" + str(OS.get_process_id()))
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate()
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "real session uses an isolated temporary slot")
	quiet_session()
	await frames()
	for id: String in ["HD_10001_1", "TY_10001_1", "NSZC_10002_1", "HD_10004_1", "HD_20003_1", "NSZC_10003_1"]:
		await enter(id)
		check(audio.region == session.room.config.region_id, id + " selects the actual region slot")
		if id in ["HD_10004_1", "HD_20003_1", "NSZC_10003_1"]:
			check(audio.music == "large_battle", id + " selects large battle music on entering")
	for id: String in ["HD_10004_1", "HD_20003_1"]:
		await enter(id)
		var boss: Node2D = session.room.get_node("Boss")
		boss.start_combat()
		boss.set_physics_process(true)
		for i: int in range(400):
			await frames(1)
			if not seen("enemy.windup").is_empty(): break
		var windups: Array = seen("enemy.windup")
		check(windups.size() == 1 and int(boss.get("state")) == (OverlookBoss.State.WINDUP if boss is OverlookBoss else ParasiteBoss.State.WINDUP), id + " real boss warning begins with visual windup")
		begin()
		(boss.get_node("GameplayRoot/Hurtbox") as CombatHurtbox).receive_attack(1000, Vector2.ZERO, session.player, 350)
		check(seen("boss.defeated").size() == 1, id + " real boss defeat emits once")
		await frames()
	await enter("HD_10002_3")
	var pickup: RoomPickup = session._pickups()[0]
	session.player.global_position = pickup.global_position + Vector2(0,44)
	var real: String = session.store.directory
	session.store.directory = real.path_join("slot_1.json")
	check(not session.collect_pickup(pickup), "failed pearl save rejected")
	await frames()
	check(seen("interaction.pickup").is_empty(), "failed pearl save emits no sound")
	session.store.directory = real
	check(session.collect_pickup(pickup), "real pearl pickup saves")
	await frames()
	check(seen("interaction.pickup").size() == 1, "saved pearl emits one pickup sound")
	begin()
	var supply: MedkitSupply = session.medkit_supply()
	session.player.global_position = supply.global_position + Vector2(0,44)
	check(session.collect_medkit(), "real medkit pickup saves")
	await frames()
	check(seen("interaction.pickup").size() == 1, "saved medkit emits one pickup sound")
	await enter(ConnectionSession.CONNECTION_ID)
	for enemy: Node in session.room.get_node("Enemies").get_children():
		if enemy is ColorlessEntity: enemy.health = 0
	session.player.global_position = session.room.get_node("Switch").global_position + Vector2(0,44)
	check(session.activate_switch(), "real connection switch opens persisted gates")
	check(seen("interaction.gate").size() == 2, "two newly persisted gates emit two events")
	begin()
	session.activate_switch()
	check(seen("interaction.gate").is_empty(), "an already open gate does not replay")
	await enter(RavineRescueSession.RESCUE_ID)
	var hazard: RoomRockfall = session.room.environment_hazard
	session.player.global_position = hazard.to_global(hazard.config.switch_position) + Vector2(0,44)
	check(session.activate_environment_switch(), "real hazard switch persists")
	check(seen("interaction.mechanism").size() == 1, "saved mechanism emits once")
	await enter(TwoRoomSession.ENTRY_ID)
	session.player.position = Vector2(320, 880)
	check(audio.music == "exploration", "leaving Boss returns to exploration")
	# A genuine enemy seek/attack selects combat music without changing game state.
	var enemy: ColorlessEntity = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate()
	session.room.get_node("Enemies").add_child(enemy)
	enemy.target = session.player
	enemy.position = session.player.position + Vector2(120,0)
	await frames(15)
	check(audio.music == "combat", "live enemy engagement selects combat")
	enemy.queue_free()
	await frames(2)
	check(audio.music == "exploration", "no engaged enemy returns to exploration")
	var dialogue: FieldDialogue = session.get_node("FieldDialogue")
	dialogue.start(TownSession.SETTLEMENT, PackedStringArray(["第一句", "第二句"]))
	begin()
	dialogue.advance()
	await frames()
	check(seen("interaction.dialogue").size() == 1 and audio.music == "story", "real dialogue advance selects story and emits once")
	dialogue.dismiss()
	await frames()
	check(audio.music == "exploration", "dialogue end restores exploration")
	# Record bus identity for every category exercised above; silence is not fake playback.
	var row: Dictionary = audio.play(&"combat.hit", Vector2.ZERO, session.player)
	check(row.audible and (row.voice.get_ref() as AudioStreamPlayer).get_parent() == audio, "only central service owns the hit sound")
	session.queue_free()
	current_scene = null
	await frames(3)
	check(audio.voices.filter(func(v: AudioStreamPlayer) -> bool: return not bool(v.get_meta("ui", false))).is_empty(), "scene destruction clears game voices")
	var dir := DirAccess.open(directory)
	if dir != null:
		for file: String in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(directory)

func run() -> void:
	audio = root.get_node("AudioEvents") as AudioEventService
	audio.event_emitted.connect(func(row: Dictionary) -> void:
		observed[row.event] = true
		if row.voice != null:
			var voice: AudioStreamPlayer = row.voice.get_ref()
			routed = routed and voice != null and voice.bus == &"效果音" and row.bus == voice.bus and row.stream == voice.stream and voice.playing)
	await player_cases()
	await enemy_cases()
	await service_cases()
	await session_cases()
	for id: String in audio.mapping.clips.keys():
		check(observed.has(id), "real scenario coverage: " + id)
	check(routed, "every audible event was observed on its actual playing effects voice")
	paused = false
	audio.stop_all()
	audio.history.clear()
	await frames(3)
	OS.delay_msec(500)
	print("AUDIO_EVENTS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
