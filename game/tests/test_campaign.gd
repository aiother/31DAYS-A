extends SceneTree
# Continuous production-session integration. Travel requests and positioning are
# driven by the test; terrain physics and combat AI have separate regressions.
# No fabricated progress snapshot or event flags are used to unlock the route.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var visited: Dictionary = {}
var pearls: Array[String] = []
var attack_id: int = 20000

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func quiet() -> void:
	# Normal load replaces the complete session scene on the next frame.
	if is_instance_valid(current_scene) and current_scene is FinalBattleSession:
		session = current_scene as FinalBattleSession
	if not is_instance_valid(session):
		return
	for container: String in ["Enemies", "Allies"]:
		if session.room.has_node(container):
			for actor: Node in session.room.get_node(container).get_children():
				actor.process_mode = Node.PROCESS_MODE_DISABLED
	if session.room.has_node("Boss"):
		session.room.get_node("Boss").process_mode = Node.PROCESS_MODE_DISABLED

func ticks(count: int) -> void:
	for i: int in range(count):
		quiet()
		await physics_frame
		await process_frame
		quiet()

func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(3)

func travel(target: String) -> void:
	var old: String = session.room.config.room_id
	check(target == session.room.config.next_room_id or target == session.room.config.previous_room_id,
		"campaign uses declared neighbor %s -> %s" % [old, target])
	session.room.exit_requested.emit(target)
	await ticks(4)
	check(session.room.config.room_id == target, "production exit guards permit " + target)
	visited[session.room.config.room_id] = true
	check(session.store.valid(session.store.load_slot(1)), "persistent state remains valid after " + target)

func dialogue() -> void:
	for i: int in range(32):
		if not session.dialogue_ui.active:
			break
		session.dialogue_ui.advance()
		await ticks(1)

func clear() -> void:
	for actor: Node in session.room.get_node("Enemies").get_children():
		if actor is ColorlessEntity and (actor as ColorlessEntity).health > 0:
			var enemy: ColorlessEntity = actor as ColorlessEntity
			attack_id += 1
			check(enemy.hurtbox.receive_attack(enemy.health, Vector2.ZERO, session.player, attack_id),
				"campaign lethal damage uses live " + enemy.name + " hurtbox")
	await ticks(2)

func collect() -> void:
	for pickup: RoomPickup in session._pickups():
		# Hold position at optional collectibles; path accessibility is tested per Room.
		session.player.position = pickup.position
		session.player.reset_kinematics()
		check(session.collect_pickup(pickup), "campaign collects " + pickup.config.persistence_key)
		pearls.append(pickup.config.persistence_key)

func run() -> void:
	directory = "user://tests/campaign_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	check(session.start_slot(1, true), "campaign begins from genuine new-game slot")
	await ticks(220)
	visited[session.room.config.room_id] = true
	check(not session.intro_active and session.player.life.can_control() and session.data["events"].get(StartRoomSession.BIRTH, false), "production final session completes opening birth")
	check(session.player.life.health == 3 and session.player.possibility.balance == 3 and session.data["day"] == 1, "new-game resources and day unchanged")
	await travel(TwoRoomSession.ENTRY_ID)
	await place(Vector2(288, 896))
	check(session.data["checkpoint"] == TwoRoomSession.ENTRY_CHECKPOINT, "tower entrance checkpoint activates in main session")
	await travel(TowerSession.TOWER_ID)
	await travel(ExplorationSession.EXPLORATION_ID)
	await collect()
	await travel(ConnectionSession.CONNECTION_ID)
	session.room.exit_requested.emit(BossSession.BOSS_ID)
	await ticks(2)
	check(session.room is ConnectionRoom, "campaign cannot skip uncleared connection mechanism")
	await clear()
	session.player.position = (session.room.get_node("Switch") as Node2D).position + Vector2(0, 44)
	session.player.reset_kinematics()
	check(session.activate_switch(), "campaign opens real connection switch after clear")
	await travel(BossSession.BOSS_ID)
	await ticks(310)
	var overlook: OverlookBoss = session.room.get_node("Boss") as OverlookBoss
	check(not session.intro_active and overlook.hurtbox.receive_attack(60, Vector2.ZERO, session.player, 30000), "actual first Boss intro and defeat work in final session")
	check(session.data["events"].get(BossSession.GROWTH_PENDING, false), "first Boss pending reward persists without invented upgrade")
	await travel(FieldSession.FIELD_ID)
	await ticks(125)
	await dialogue()
	check(session.data["events"].get(FieldSession.FIELD_STORY, false) and session.player.possibility.balance == 10 and not session.intro_active, "Seven first story completes and fills current cap")
	await travel(TownSession.TOWN_ID)
	await place(Vector2(928, 896))
	check(session.interact_survivor(), "campaign starts town rescue")
	await dialogue()
	check(session.data["events"].get(FieldSession.RESCUE_DONE, false), "town rescue committed")
	await travel(FieldSession.FIELD_ID)
	await place(Vector2(1680, 896))
	check(session.interact_seven(), "campaign starts gaze settlement")
	await dialogue()
	await ticks(110)
	check(session.player.possibility.maximum == 12 and not session.intro_active and not session.dialogue_ui.active, "gaze settlement reaches 12 and returns control")
	await travel(TownSession.TOWN_ID)
	await travel(RavineSession.RAVINE_ID)
	check(session.data["day"] == 2 and session.data["checkpoint"] == RavineSession.RAVINE_CHECKPOINT, "real story and entrance advance day two with checkpoint")
	await travel(RavineRescueSession.RESCUE_ID)
	session.player.set_physics_process(false)
	session.player.position = Vector2(1056, 720)
	check(session.interact_ravine_survivor(), "campaign starts elevated ravine rescue")
	await dialogue()
	session.player.set_physics_process(true)
	check(session.player.possibility.maximum == 13, "independent ravine rescue raises cap to 13")
	await travel(RavineDepthSession.DEPTH_ID)
	session.room.encounter_requested.emit()
	await clear()
	check(session.data["events"].get(RavineDepthSession.DEPTH_HELPED, false) and session.player.possibility.maximum == 14, "clear rescue in main session settles independent cap 14")
	await collect()
	await travel(CampSession.CAMP_ID)
	await collect()
	await travel(CampWavesSession.WAVES_ID)
	var camp: CampWavesRoom = session.room as CampWavesRoom
	check(camp.start_waves(), "campaign starts three-wave camp encounter")
	for wave: int in range(3):
		await ticks(105)
		check(camp.wave == wave + 1 and camp.phase == CampWavesRoom.Phase.ACTIVE, "camp wave arrives in continuous campaign")
		await clear()
	check(camp.phase == CampWavesRoom.Phase.COMPLETE, "camp waves finish without extra completion reward")
	await travel(ParasiteSession.PARASITE_ID)
	await ticks(310)
	var parasite: ParasiteBoss = session.room.get_node("Boss") as ParasiteBoss
	check(not session.intro_active and parasite.hurtbox.receive_attack(80, Vector2.ZERO, session.player, 30001), "second Boss intro and actual defeat work in main session")
	check(session.data["day"] == 3 and session.data["events"].get(ParasiteSession.DODGE_GROWTH, false) and session.player.possibility.dodge_upgraded, "second Boss advances day three and grants permanent dodge upgrade")
	await travel(OutskirtsSession.OUTSKIRTS_ID)
	check(session.player.possibility.maximum == 14, "closed optional ability gate grants no undefined NPC growth")
	await travel(TrenchSession.TRENCH_ID)
	await collect()
	await travel(TrenchPassageSession.PASSAGE_ID)
	await clear()
	await place(Vector2(880, 944))
	await place(Vector2(1600, 944))
	var passage: TrenchPassageRoom = session.room as TrenchPassageRoom
	check(passage.challenge_saved and passage.return_open, "actual challenge overlap chain and combat clear persist in campaign")
	check(passage.rubble.hurtbox.receive_attack(10, Vector2.ZERO, session.player, 30002), "campaign damages unlocked rubble through its hurtbox")
	await ticks(2)
	check(passage.forward_open, "campaign saves permanent rubble passage")
	await travel(BattlefieldSession.BATTLEFIELD_ID)
	await place(Vector2(450, 896))
	var hp: int = session.player.life.health
	session.player.life.take_hit(hp)
	await ticks(55)
	check(session.cinematic == RescueBattlefieldSession.Cinematic.DIALOGUE and session.player.life.health == hp, "first real lethal hit triggers rescue without death or damage")
	await dialogue()
	check(session._arena().rescue_kill_count == 3, "Ten slash clears actual opening enemies in continuous session")
	await ticks(165)
	check(session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT, false) and session.data["events"].get(FinalClock.STARTED, false), "rescue reward transitions directly into persisted final clock")
	check(session.player.possibility.maximum == 14 and session.player.possibility.balance == 14, "Ten fills grown cap without healing or extra growth")
	for wave: int in range(3):
		check(session._final_arena().wave_index == wave, "continuous final wave index %d" % wave)
		await clear()
		await ticks(130)
	check(session.data["events"].get(FinalClock.WON, false) and session._final_arena().victory, "same genuine slot reaches saved final victory")
	await place(Vector2(950, 896))
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session._final_talk and session.dialogue_ui.active, "campaign reaches Ten victory dialogue")
	await dialogue()
	await ticks(185)
	check(paused and session.final_ui.mode == "finished", "campaign reaches placeholder ending screen")
	var saved: Dictionary = session.store.load_slot(1)
	check(session.store.valid(saved) and saved["events"].get(FinalClock.END, false), "complete naturally earned event set passes slot validation")
	check(saved["checkpoint"] == TrenchPassageSession.PASSAGE_CHECKPOINT and saved["maximum"] == 14 and saved["day"] == 3, "ending preserves real checkpoint, growth and date")
	check(visited.size() == session._room_scenes().size() and visited.size() == 18, "continuous campaign visits all 18 delivered Rooms")
	check(pearls.size() == 4, "all four delivered pearl placeholders collected")
	for key: String in pearls:
		check(saved["events"].get(key, false), "ending retains earlier pearl " + key)
	check(not saved["events"].get(FieldSession.RESCUE_FAILED, false) and not saved["events"].get(RavineRescueSession.FAILED, false) and not saved["events"].get(RavineDepthSession.DEPTH_FAILED, false), "successful route does not accidentally abandon saved survivors")
	check(session.start_slot(1, false), "full campaign save reloads through normal production path")
	await ticks(4)
	session = current_scene as FinalBattleSession
	check(paused and session.final_ui.mode == "finished" and session.player.possibility.maximum == 14, "normal reload restores finished campaign and earned growth")
	paused = false
	session.queue_free()
	await physics_frame
	await process_frame
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = directory.path_join("slot_1.json") + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("CAMPAIGN_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
