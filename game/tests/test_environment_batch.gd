extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var keys: Array[String] = []
const ROOMS: Array[String] = ["HD_20001_1","HD_20001_2","HD_20001_3","HD_20002_1"]

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
		session = current_scene as FinalBattleSession
		if is_instance_valid(session) and session.room.has_node("Enemies"):
			for child: Node in session.room.get_node("Enemies").get_children():
				child.set_physics_process(false)

func place(point: Vector2) -> void:
	session.player.life.start_new_run()
	session.player.life.health = 5
	session.player.position = point
	session.player.reset_kinematics()
	session.player.combat.interrupt()
	session.player.set_physics_process(true)
	await ticks(3)

func case_room(id: String) -> void:
	session._change_room(id)
	await ticks(2)
	var hazard: RoomRockfall = session.room.environment_hazard
	var config: RoomRockfallConfig = hazard.config
	session._set_balance(-9)
	keys.append(config.persistence_key)
	check(config.warning==0.6 and config.interval==1.8 and config.damage==1,id+" uses confirmed Resource tuning")
	check(not hazard.disabled and not hazard.warning_active and hazard.rocks.get_child_count()==0,id+" safe entry starts without instant falling damage")
	check(absf(session.room.config.entry_from_previous.x-config.lane)>96 and absf(session.room.config.entry_from_next.x-config.lane)>96,id+" both arrival points avoid hazard lane")
	check(not session.activate_environment_switch(),id+" distant switch interaction rejected")
	await place(Vector2(config.lane,config.floor_y))
	session.player.set_physics_process(false)
	hazard.clear_rocks()
	await ticks(1)
	check(hazard.warning_active and hazard.warning_remaining>0.5 and hazard.rocks.get_child_count()==0,id+" readable warning precedes first rock")
	await ticks(30)
	check(hazard.rocks.get_child_count()==0 and session.player.life.health==5,id+" warning cannot cause early damage")
	var remaining: float = hazard.warning_remaining
	paused = true
	await ticks(6)
	check(hazard.warning_remaining==remaining,id+" pause freezes warning countdown")
	paused = false
	await ticks(44)
	check(session.player.life.health==4,id+" actual falling collision deals exactly one existing light hit; health="+str(session.player.life.health)+" position="+str(session.player.position))
	await place(session.room.config.entry_from_previous)
	await ticks(2)
	check(not hazard.warning_active and hazard.rocks.get_child_count()==0,id+" leaving active zone cancels warning and in-flight rocks")
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2(config.lane-128,0),Vector2(config.lane-128,config.floor_y+400),1)
	var floor_hit: Dictionary = session.player.get_world_2d().direct_space_state.intersect_ray(ray)
	check(not floor_hit.is_empty(),id+" ordinary crossing starts on real collision-supported ground")
	await place(floor_hit.get("position",Vector2(config.lane-128,config.floor_y)))
	# Wait at a safe point until the first stone has passed, then use the
	# readable gap; arbitrary jumps into an incoming stone are not invulnerable.
	await ticks(70)
	Input.action_press("jump")
	Input.action_press("move_right")
	Input.action_press("run")
	var crossed: bool = false
	for frame: int in range(120):
		await ticks(1)
		if session.player.position.x>config.lane+128:
			crossed = true
			break
	for action: String in ["jump","move_right","run"]: Input.action_release(action)
	check(crossed and session.player.life.health==5 and session.player.possibility.balance==-9,id+" real run/jump crosses without damage or possibility spending; position="+str(session.player.position)+" health="+str(session.player.life.health)+" balance="+str(session.player.possibility.balance))
	if id!="HD_20001_2":
		var mono: MonochromeEntity
		for child: Node in session.room.get_node("Enemies").get_children():
			if child is MonochromeEntity: mono = child as MonochromeEntity
		mono.position = Vector2(config.lane,config.floor_y)
		mono.health = 1
		ray.from = Vector2(config.lane-96,0)
		ray.to = Vector2(config.lane-96,config.floor_y+400)
		floor_hit = session.player.get_world_2d().direct_space_state.intersect_ray(ray)
		await place(floor_hit["position"])
		hazard.clear_rocks()
		await ticks(80)
		check(mono.state==ColorlessEntity.State.DEAD and session.player.possibility.balance==-2,id+" actual emitted environmental kill pays normal +7 from negative balance; enemy="+str(mono.health)+" state="+str(mono.state)+" balance="+str(session.player.possibility.balance)+" position="+str(mono.position))
		check(session.store.load_slot(1)["balance"]==-2,id+" environmental reward is saved through production callback")
		await ticks(120)
		check(session.player.possibility.balance==-2,id+" later stones and corpse do not repeat kill reward")
	await place(config.switch_position+Vector2(0,44))
	check(hazard.prompt.visible,id+" nearby switch has interaction feedback")
	paused = true
	check(not session.activate_environment_switch(),id+" paused switch cannot mutate progress")
	paused = false
	session.player.combat._start_attack()
	check(not session.activate_environment_switch(),id+" active attack cannot operate switch")
	session.player.combat.interrupt()
	var original: String = session.store.directory
	session.store.directory = original.path_join("slot_1.json")
	check(not session.activate_environment_switch() and not hazard.disabled and not session.data["events"].has(config.persistence_key),id+" failed write rolls back switch and leaves hazard active")
	session.store.directory = original
	var old_balance: int = session.player.possibility.balance
	var in_flight: FallingRock = FallingRock.new()
	in_flight.position = hazard.to_local(session.player.global_position)-Vector2(0,96)
	in_flight.speed = 50000
	hazard.rocks.add_child(in_flight)
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(hazard.disabled and session.store.load_slot(1)["events"].get(config.persistence_key,false),id+" real E action permanently disables and saves")
	check(hazard.rocks.get_child_count()==0 and not hazard.warning_active and session.player.life.health==5,id+" successful switch clears an injected fast in-flight stone before it can hit")
	check(session.player.possibility.balance==old_balance and session.player.possibility.maximum==10,id+" switch grants no resource or growth")
	check(not session.activate_environment_switch(),id+" completed switch cannot repeat transaction")
	await place(Vector2(config.lane,config.floor_y))
	await ticks(150)
	check(hazard.rocks.get_child_count()==0 and not hazard.warning_active and session.player.life.health==5,id+" saved shutdown suppresses later warnings and damage")
	if id=="HD_20001_2": check(session.room.get_node("Enemies").get_child_count()==0,id+" rescue Room remains enemy-free")
	# Initializers from the hazard subtree cannot add transient navigation anchors.
	var anchors: Array[float] = []
	EnemyPlatformRoutes.new()._collect_anchors(hazard,anchors)
	check(anchors.is_empty(),id+" lever and falling rocks do not alter static pursuit graph anchors")

func run() -> void:
	directory = "user://tests/environment_%d"%Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var base: Dictionary = session.store.fresh()
	base["balance"] = -9
	base["health"] = 5
	base["events"][StartRoomSession.BIRTH] = true
	check(session.store.save_slot(1,base) and session.start_slot(1,false),"legacy slot without hazard flags starts normally")
	for id: String in ROOMS: await case_room(id)
	for id: String in ROOMS:
		session._change_room(id)
		await ticks(2)
		check(session.room.environment_hazard.disabled,"revisit preserves independent shutdown "+id)
	check(session.player.life.take_hit(5),"real death starts after all shutdowns are saved")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	check(session.player.life.health==5 and session.room.environment_hazard.disabled and keys.all(func(key: String) -> bool: return bool(session.data["events"].get(key,false))),"actual checkpoint death retry preserves all four shutdowns")
	check(session.save_current() and session.start_slot(1,false),"shutdown states survive normal load")
	await ticks(4)
	for key: String in keys: check(session.data["events"].get(key,false),"loaded shutdown preserved "+key)
	check(session.store.save_slot(2,base) and session.start_slot(2,false),"separate old slot loads")
	await ticks(4)
	for id: String in ROOMS:
		session._change_room(id)
		await ticks(2)
		check(not session.room.environment_hazard.disabled,"old other slot initializes active trap without inheriting shutdown "+id)
	check(session.start_slot(1,true),"explicit new game resets first slot")
	await ticks(4)
	for key: String in keys: check(not session.data["events"].has(key),"new game clears shutdown "+key)
	paused = false
	session.queue_free()
	await ticks(2)
	OS.delay_msec(250)
	for selected: int in [1,2]:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String = directory.path_join("slot_%d.json"%selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("ENVIRONMENT_BATCH_TESTS checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
