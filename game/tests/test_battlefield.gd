extends SceneTree
var checks: int = 0
var failures: int = 0
var session: BattlefieldSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: "+message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func quiet() -> void:
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func run() -> void:
	directory = "user://tests/battlefield_%d" % Time.get_ticks_usec()
	session = (load("res://world/battlefield_session.tscn") as PackedScene).instantiate() as BattlefieldSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["balance"] = -9
	snapshot["day"] = 3
	snapshot["events"][TrenchPassageRoom.CLEARED] = true
	snapshot["events"][TrenchPassageRoom.CHALLENGE] = true
	snapshot["events"][TrenchPassageRoom.FORWARD] = true
	WorldDayRules.sync(snapshot) # Current third-day NPC deadlines are not battlefield rewards.
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false),"existing passage save loads in new main")
	await ticks(4)
	quiet()
	await place(Vector2(1856,944))
	check(session.room is BattlefieldRoom,"real opened passage exit enters adjacent battlefield")
	var area: BattlefieldRoom = session.room as BattlefieldRoom
	check(area.config.previous_room_id==TrenchPassageSession.PASSAGE_ID and area.config.next_room_id=="","only frozen neighbor is connected")
	check(session.data["checkpoint"]==TrenchPassageSession.PASSAGE_CHECKPOINT and session._all_checkpoints().is_empty(),"no extra checkpoint; passage checkpoint remains active")
	check(not area.started and area.get_node("Allies").get_child_count()==0,"entry safety area does not start fight or pre-spawn allies")
	var front: TianWarrior = area.get_node("Enemies/TianFront") as TianWarrior
	var rear: TianWarrior = area.get_node("Enemies/TianRear") as TianWarrior
	var mono: MonochromeEntity = area.get_node("Enemies/Monochrome") as MonochromeEntity
	check(front.health==31 and rear.health==31 and mono.health==21,"first phase contains exactly two Tian and one monochrome")
	check(not front.is_physics_processing() and front.coordinator==rear.coordinator,"entry safety and shared single enemy attack budget")
	await place(Vector2(450,896))
	check(area.started and front.is_physics_processing(),"crossing safety area starts actual enemy AI")
	quiet()
	mono.hurtbox.receive_attack(21,Vector2.ZERO,session.player,8000)
	check(area.arrivals==0 and session.player.possibility.balance==-2,"monochrome defeat gives+7 but does not trigger Tian reinforcement")
	front.hurtbox.receive_attack(31,Vector2.ZERO,session.player,8001)
	check(area.arrivals==1 and area.get_node("Allies").get_child_count()==1,"first Tian defeat immediately brings first survivor")
	check(session.player.possibility.balance==9,"Tian pays+11 normally")
	var first: SurvivorFighter = area.get_node("Allies").get_child(0) as SurvivorFighter
	check(first.health==10 and first.config.damage==5,"survivor health10 damage5 are Resource driven")
	first.set_physics_process(false)
	var timer: float = area.arrival_remaining
	paused = true
	await ticks(8)
	check(area.arrivals==1 and area.arrival_remaining==timer,"pause freezes reinforcement delay")
	paused = false
	await ticks(65)
	check(area.arrivals==2 and area.get_node("Allies").get_child_count()==2,"second separate batch brings exactly one more survivor")
	var second: SurvivorFighter = area.get_node("Allies").get_child(1) as SurvivorFighter
	second.set_physics_process(false)
	front.hurtbox.receive_attack(31,Vector2.ZERO,session.player,8002)
	check(area.arrivals==2,"corpse hits cannot repeat reinforcement")
	# Real ally locomotion and delayed melee hit, without player's assistance.
	rear.position = Vector2(1000,896)
	rear.guard_cooldown_remaining = 100
	first.position = Vector2(700,896)
	first.set_physics_process(true)
	await ticks(100)
	check(first.position.x>850 and first.attacks>0 and rear.health<31,"survivor seeks hostile and deals actual melee damage after windup")
	check(session.player.life.health==3 and second.health==10,"ally attack never damages player or other ally")
	first.set_physics_process(false)
	# Enemy AI must actually target and hurt this nearer ally.
	first.position = Vector2(900,896)
	second.position = Vector2(600,896)
	rear.position = Vector2(980,896)
	rear.state = ColorlessEntity.State.CHASE
	rear.set_physics_process(true)
	await ticks(150)
	check(rear.target==first and first.health<10,"enemy selects nearest living survivor and AI attacks reduce ally health")
	rear.set_physics_process(false)
	var balance: int = session.player.possibility.balance
	first.hurtbox.receive_attack(10,Vector2.ZERO,rear,8100)
	await ticks(2)
	check(first.health==0 and first.state==SurvivorFighter.State.DEAD and session.player.possibility.balance==balance,"ally can die without possibility reward")
	check(rear.target!=first,"fallen target is replaced while protected strike may finish")
	var ally_health: int = second.health
	second.hurtbox.receive_attack(5,Vector2.ZERO,session.player,8101)
	check(second.health==ally_health,"direct player hit is rejected as friendly fire")
	second.hurtbox.receive_attack(5,Vector2.ZERO,first,8102)
	check(second.health==ally_health,"direct allied hit is rejected as friendly fire")
	# Protected enemy heavy actions still take ally damage without interruption.
	rear.state = ColorlessEntity.State.WINDUP
	rear.attack_kind = TianWarrior.Attack.HEAVY
	rear.motion = TianWarrior.Motion.NONE
	rear.counter_remaining = 0
	rear.position = Vector2(1000,896)
	second.position = Vector2(920,896)
	second.facing = 1
	await ticks(2)
	var hp: int = rear.health
	second._strike()
	check(rear.health==maxi(0,hp-5) and (rear.state==ColorlessEntity.State.WINDUP or rear.health==0),"ally damage preserves heavy protection and existing lethal priority")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	if rear.health>0:
		rear.hurtbox.receive_attack(31,Vector2.ZERO,second,8200)
	await ticks(3)
	check(area.completed and not session.stage_notified,"phase completes but failed save does not show saved-stage confirmation")
	check((area.get_node("LeftBoundary") as StaticBody2D).collision_layer==1,"first phase does not unlock final victory return gate")
	check(session.data["events"]==snapshot["events"] and session.data["day"]==3,"no final victory rescue ending growth or time events are invented")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.stage_notified and session.store.load_slot(1)["balance"]==10,"E retries stage resource save and ally kill pays normal reward")
	check((session.ui.get("_error_label") as Label).text.is_empty(),"successful retry clears stale save error feedback")
	check((session.ui.get("_enemy_intro") as Control).visible and not paused,"stage-only prompt leaves player operational")
	session._on_room_exit(TrenchPassageSession.PASSAGE_ID)
	check(session.room==area,"return remains locked pending full battle implementation")
	check(session.start_slot(1,false),"normal load remains available")
	await ticks(4)
	session = current_scene as BattlefieldSession
	quiet()
	check(session.room is TrenchPassageRoom and session.player.possibility.balance==10,"load returns to existing passage checkpoint with saved balance")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	await ticks(2)
	area = session.room as BattlefieldRoom
	check(not area.completed and area.arrivals==0 and (area.get_node("Enemies/TianFront") as TianWarrior).health==31,"new attempt resets enemies reinforcements and transient phase clear")
	await place(Vector2(450,896))
	quiet()
	(area.get_node("Enemies/TianFront") as TianWarrior).hurtbox.receive_attack(31,Vector2.ZERO,session.player,8300)
	check(area.arrivals==1,"new attempt permits reinforcement again")
	var death_ally: SurvivorFighter = area.get_node("Allies").get_child(0) as SurvivorFighter
	session.player.life.take_hit(3)
	await ticks(90)
	check(area.stopped and area.arrivals==1 and not death_ally.is_physics_processing(),"player death halts both teams and pending second arrival")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as BattlefieldSession
	quiet()
	check(session.room is TrenchPassageRoom and session.player.life.health==5 and session.player.possibility.balance==5,"death restarts passage checkpoint with standard half-balance settlement")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1]:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path: String = directory.path_join("slot_%d" % selected)+suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("BATTLEFIELD_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
