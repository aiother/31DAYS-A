extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func quiet() -> void:
	for child: Node in session.room.get_node("Enemies").get_children(): child.set_physics_process(false)
func area() -> OutskirtsRoom:
	return session.room as OutskirtsRoom
func snapshot(upgraded: bool = true) -> Dictionary:
	var data: Dictionary = session.store.fresh()
	data["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	data["day"] = 3
	data["balance"] = 9
	data["events"][ParasiteSession.PARASITE_INTRO] = true
	if upgraded:
		for key: String in [ParasiteSession.PARASITE_DEFEATED,ParasiteSession.PARASITE_PASSAGE,ParasiteSession.DODGE_GROWTH]: data["events"][key] = true
	return data
func load_fixture(data: Dictionary) -> void:
	check(session.store.save_slot(1,data) and session.start_slot(1,false),"challenge fixture loads through normal slot")
	await ticks(3)
	session = current_scene as FinalBattleSession
	session._change_room(OutskirtsSession.OUTSKIRTS_ID)
	quiet()
	await ticks(3)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(3)
func reset_at_start(balance: int = 9) -> void:
	session.player.life.start_new_run()
	session._set_balance(balance)
	await place(Vector2(2196,848))
	session.player.facing = 1
func dodge() -> void:
	Input.action_press("dodge")
	await ticks(1)
	Input.action_release("dodge")
	await ticks(18)
func run() -> void:
	directory = "user://tests/outskirts_challenge_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	await load_fixture(snapshot())
	check(area().challenge.hazard.size==Vector2(80,96) and not area().opened and session._all_checkpoints().is_empty(),"approved 80px optional hazard adds no checkpoint")
	await reset_at_start()
	Input.action_press("move_right")
	Input.action_press("run")
	await ticks(18)
	Input.action_release("move_right")
	Input.action_release("run")
	check(session.player.life.health==2 and session.player.position.x<2220 and not area().opened,"running fails for1 damage and returns to entrance")
	await reset_at_start()
	Input.action_press("jump")
	await ticks(8)
	Input.action_release("jump")
	check(session.player.position.y>830 and not area().opened,"solid low roof prevents jumping over hazard")
	await reset_at_start(0)
	await dodge()
	check(not area().opened and session.player.life.health==2 and session.player.possibility.balance==-1,"poor upgraded dodge cannot cover hazard invulnerability span; paid cost remains")
	check(session.player.possibility.chain==1 and session.player.possibility.since_dodge<1.3,"challenge retry does not reset global dodge chain")
	await load_fixture(snapshot(false))
	# Fixture bypasses Boss route only to test the missing-ability rejection.
	await reset_at_start()
	await dodge()
	check(not area().opened and not session.player.possibility.dodge_upgraded and session.player.life.health==2,"base dodge cannot earn challenge even with resources")
	await load_fixture(snapshot())
	await reset_at_start()
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await dodge()
	check(session._spike_pending and area().pending_open and not session.data["events"].get(OutskirtsSession.SPIKES_OPEN,false),"failed completion write leaves earned challenge pending without permanent open")
	check(not session.player.is_physics_processing() and session.intro_active and not session.data["events"].has(StartRoomSession.BIRTH),"pending save freezes actors without invoking inherited birth sequence")
	var remaining: float = session.data["day3_remaining"]
	await ticks(10)
	check(session.data["day3_remaining"]==remaining,"pending challenge save freezes game clock")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(area().opened and not session._spike_pending and session.player.life.can_control() and session.player.is_physics_processing(),"E retries permanent opening and restores control")
	check(session.store.load_slot(1)["events"].get(OutskirtsSession.SPIKES_OPEN,false) and session.player.life.health==3 and session.player.possibility.balance==8,"success persists once with only actual dodge cost and no damage/reward")
	await place(Vector2(2196,848))
	Input.action_press("move_right")
	await ticks(45)
	Input.action_release("move_right")
	check(session.player.position.x>2326 and session.player.life.health==3,"permanent opening permits ordinary walking without repeated hazard")
	check(session.data["events"].get(OutskirtsSession.OUTSKIRTS_SEEN,false),"NPC is seen after entering chamber before close interaction")
	# Death must not abandon an unrescued NPC or reclose an earned gate.
	session.player.life.protection_remaining = 0
	session.player.life.take_hit(5)
	await ticks(90)
	session.restart_challenge()
	await ticks(4)
	session = current_scene as FinalBattleSession
	session._change_room(OutskirtsSession.OUTSKIRTS_ID)
	quiet()
	await ticks(3)
	check(area().opened and not session.data["events"].get(OutskirtsSession.OUTSKIRTS_FAILED,false),"death preserves earned gate and exempts permanent abandonment")
	await place(Vector2(2400,1280))
	session.room.exit_requested.emit(TrenchSession.TRENCH_ID)
	await ticks(2)
	check(session.dialogue_ui.confirming and area()!=null,"actual manual departure after sighting requires confirmation")
	session.cancel_departure()
	check(not session.dialogue_ui.active and session.player.life.can_control(),"cancelling departure keeps rescue available")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = directory.path_join("slot_1.json")+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("OUTSKIRTS_CHALLENGE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
