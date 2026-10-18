extends SceneTree
var checks: int = 0
var failures: int = 0
var session: RescueBattlefieldSession
var directory: String
var created: Array[String] = []
var initial_events: Dictionary = {}
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
func arena() -> RescueBattlefieldRoom:
	return session.room as RescueBattlefieldRoom
func quiet() -> void:
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
func clear_session() -> void:
	paused = false
	if is_instance_valid(session):
		session.queue_free()
		await ticks(2)
		await create_timer(0.2).timeout
func fresh() -> void:
	await clear_session()
	directory = "user://tests/ten_rescue_%d" % Time.get_ticks_usec()
	created.append(directory)
	session = (load("res://world/rescue_battlefield_session.tscn") as PackedScene).instantiate() as RescueBattlefieldSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	snapshot["balance"] = -9
	for key: String in [TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]:
		snapshot["events"][key] = true
	WorldDayRules.sync(snapshot)
	initial_events = snapshot["events"].duplicate()
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false),"fresh old-format checkpoint save loads")
	quiet()
	session.player.position = Vector2(1856,944)
	session.player.reset_kinematics()
	await ticks(4)
	check(arena()!=null and not arena().started,"real adjacent exit enters rescue-enabled room with safety area")
	session.player.position = Vector2(450,896)
	session.player.reset_kinematics()
	await ticks(3)
	quiet()
func dialogue_to_slash() -> void:
	await ticks(52)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.DIALOGUE and session.dialogue_ui.active,"falling entrance leads to temporary dialogue")
	check(session.dialogue_ui.speaker.text.contains("10") and session.dialogue_ui.speaker.text.contains("临时"),"temporary Ten dialogue is identified")
	for i: int in range(4):
		session.dialogue_ui.advance()
	check(session.cinematic==RescueBattlefieldSession.Cinematic.SLASH and session.rescue_overlay.slash.visible,"dialogue completion triggers full-screen slash")
	var living: int = 0
	for child: Node in arena().get_node("Enemies").get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			living += 1
	check(living==0,"scripted slash kills all current enemies including protected actions")
func run() -> void:
	await fresh()
	var front: TianWarrior = arena().get_node("Enemies/TianFront") as TianWarrior
	var mono: MonochromeEntity = arena().get_node("Enemies/Monochrome") as MonochromeEntity
	session.player.life.health = 1
	session.player.life.protection_remaining = 1
	check(not session.player.life.take_hit(99) and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"ordinary immunity is evaluated before lethal rescue")
	session.player.life.protection_remaining = 0
	front.position = Vector2(530,896)
	front.target = session.player
	front._start_attack(TianWarrior.Attack.HEAVY)
	mono.motion = MonochromeEntity.Motion.DODGE
	mono.hurtbox.accepts_hits = false
	await ticks(2)
	front._melee_hits()
	check(session.cinematic==RescueBattlefieldSession.Cinematic.DROP and arena().rescue_reason=="lethal","real enemy melee query triggers lethal interception")
	check(session.player.life.health==1 and session.player.life.is_alive() and not session._death_settled,"lethal blow never deducts health or enters death settlement")
	check(not front.is_physics_processing() and front.state==ColorlessEntity.State.IDLE and front.motion==TianWarrior.Motion.NONE,"cinematic explicitly interrupts protected attacks and freezes enemy physics")
	check(arena().ten!=null and not arena().ten.is_physics_processing() and not session.player.is_physics_processing(),"Ten entrance and player are frozen under cinematic control")
	check(session.player.life.scripted_control_locked and not session.player.life.take_hit(1),"additional hits during cinematic are intercepted")
	check(not session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false),"rescue is not permanently completed before performance finishes")
	var point: Vector2 = session.player.position
	var elapsed: float = float(session.data["play_seconds"])
	Input.action_press("move_right")
	Input.action_press("jump")
	await ticks(5)
	Input.action_release("move_right")
	Input.action_release("jump")
	check(session.player.position==point and float(session.data["play_seconds"])==elapsed,"cinematic freezes player position and elapsed session clock")
	var remaining: float = session.cinematic_remaining
	var ten_y: float = arena().ten.position.y
	paused = true
	await ticks(5)
	check(session.cinematic_remaining==remaining and arena().ten.position.y==ten_y,"pause freezes entrance time and falling position")
	paused = false
	await dialogue_to_slash()
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	await ticks(100)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.SAVE and session._rescue_commit_pending,"failed completion save leaves a retryable cinematic stage")
	check(not session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false) and session.player.possibility.balance==-9,"failed save atomically rolls back event and full-cap reward")
	check(session.player.life.health==1 and not session.player.is_physics_processing() and session.rescue_overlay.caption.text.contains("重试"),"failed save retains control lock and clear retry feedback")
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.REINFORCEMENTS,"saved clear is followed by a distinct reinforcement warning")
	await ticks(62)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.NONE and arena().phase==RescueBattlefieldRoom.Phase.COOP,"successful retry starts cooperative battle")
	check(session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false) and session.store.load_slot(1)["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false),"one-time rescue event is saved")
	check(session.player.possibility.balance==10 and session.store.load_slot(1)["balance"]==10 and session.player.life.health==1,"rescue fills possibility but does not heal health")
	check(session.player.life.protection_remaining==0 and session.player.is_physics_processing() and not session.player.life.scripted_control_locked,"cinematic ends without adding respawn invulnerability")
	check((session.ui.get("_error_label") as Label).text.is_empty() and not session.rescue_overlay.visible,"successful save clears error and cinematic overlay")
	quiet()
	var ten: TenFighter = arena().ten
	front = arena().get_node("Enemies").get_child(0) as TianWarrior
	front.guard_cooldown_remaining = 100
	var before: float = ten.position.x
	await ticks(155)
	check(ten.position.x>before+100 and ten.attacks>0 and front.health<=21,"Ten AI approaches and deals actual ten-damage melee strikes")
	check(ten.config.damage==10 and ten.config.windup==0.18 and ten.config.recovery==0.32,"Ten uses revised aggressive adjustable attack parameters")
	var ten_hp: int = ten.health
	ten.hurtbox.receive_attack(99,Vector2.ZERO,front,7000)
	check(ten.health==ten_hp and not ten.hurtbox.accepts_hits,"graybox Ten cannot be defeated")
	check(arena().get_node("Enemies").get_child_count()>=3 and front.coordinator.max_attackers==1,"cooperative test uses existing hostile roster and single attack budget")
	session.player.life.protection_remaining = 0
	session.player.life.hurt_remaining = 0
	check(session.player.life.take_hit(1) and not session.player.life.is_alive(),"after saved rescue later lethal damage follows normal death")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as RescueBattlefieldSession
	quiet()
	check(session.room is TrenchPassageRoom and session.player.life.health==5 and session.player.possibility.balance==5,"death returns to passage checkpoint with normal resource settlement")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	await ticks(3)
	check(arena().phase==RescueBattlefieldRoom.Phase.COOP and arena().ten!=null and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"re-entry after death skips saved rescue and goes directly to cooperation")
	check(session.player.possibility.balance==5 and not session.dialogue_ui.active,"re-entry does not refill possibility or replay dialogue")
	check(session.start_slot(1,false),"normal loading of rescued save remains available")
	await ticks(4)
	session = current_scene as RescueBattlefieldSession
	quiet()
	check(session.player.life.protection_remaining==0 and session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false),"normal load preserves rescue without revival immunity")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	await ticks(3)
	check(arena().phase==RescueBattlefieldRoom.Phase.COOP and session.player.possibility.balance==5,"normal load also skips entrance and grants no repeated refill")
	# Boundary: do not interpret one survivor out of two as less than half.
	await fresh()
	front = arena().get_node("Enemies/TianFront") as TianWarrior
	front.hurtbox.receive_attack(31,Vector2.ZERO,session.player,7100)
	var first: SurvivorFighter = arena().get_node("Allies").get_child(0) as SurvivorFighter
	first.hurtbox.receive_attack(10,Vector2.ZERO,front,7101)
	await ticks(3)
	check(arena().arrivals==1 and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"before both arrivals no loss-ratio rescue is triggered")
	await ticks(65)
	check(arena().arrivals==2 and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"one of two alive is exactly half and does not trigger")
	var second: SurvivorFighter = arena().get_node("Allies").get_child(1) as SurvivorFighter
	second.hurtbox.receive_attack(10,Vector2.ZERO,front,7102)
	await ticks(2)
	check(arena().rescue_reason=="allies_lost" and session.cinematic==RescueBattlefieldSession.Cinematic.DROP,"zero of two alive triggers deferred allied-loss rescue")
	# Same-frame lethal interception wins over the queued loss check.
	await fresh()
	front = arena().get_node("Enemies/TianFront") as TianWarrior
	front.hurtbox.receive_attack(31,Vector2.ZERO,session.player,7200)
	await ticks(65)
	for child: Node in arena().get_node("Allies").get_children():
		(child as SurvivorFighter).health = 0
	arena()._check_losses.call_deferred()
	session.player.life.health = 1
	check(not session.player.life.take_hit(1),"lethal hit requests rescue before queued non-lethal conditions settle")
	await ticks(2)
	check(arena().rescue_reason=="lethal" and arena().get_node("Allies").get_child_count()==3,"same-frame triggers share one event and create only one Ten")
	# If neither danger condition occurs, the second wave supplies the fallback.
	await fresh()
	for child: Node in arena().get_node("Enemies").get_children():
		var enemy: ColorlessEntity = child as ColorlessEntity
		enemy.hurtbox.receive_attack(enemy.health,Vector2.ZERO,session.player,7300)
	await ticks(65)
	check(arena().rescue_reason=="second_wave" and session.cinematic==RescueBattlefieldSession.Cinematic.DROP,"first clear produces second-wave fallback rescue")
	check(arena().get_node("Enemies").get_child_count()==3 and (arena().get_node("Enemies").get_child(0) as ColorlessEntity).health==31,"fallback consists of two Tian and one monochrome before slash")
	await dialogue_to_slash()
	await ticks(160)
	quiet()
	check(arena().phase==RescueBattlefieldRoom.Phase.COOP,"fallback rescue completion also starts cooperation")
	for child: Node in arena().get_node("Enemies").get_children():
		if child is ColorlessEntity:
			var enemy: ColorlessEntity = child as ColorlessEntity
			enemy.hurtbox.receive_attack(enemy.health,Vector2.ZERO,arena().ten,7400)
	await ticks(3)
	check(session.stage_notified and arena().completed,"cooperative roster clear produces stage completion")
	var expected_events: Dictionary = initial_events.duplicate()
	expected_events[RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	check(session.data["events"]==expected_events and session.data["day"]==3 and session.player.possibility.maximum==10,"only one rescue event is added to existing third-day deadlines without victory timer ending or growth")
	check((arena().get_node("LeftBoundary") as StaticBody2D).collision_layer==1 and session._all_checkpoints().is_empty(),"full-victory return lock and existing checkpoint policy remain")
	check(session.data["checkpoint"]==TrenchPassageSession.PASSAGE_CHECKPOINT,"rescue does not create a checkpoint")
	session._change_room(TrenchPassageSession.PASSAGE_ID)
	check(not session.player.life.hit_interceptor.is_valid(),"encounter interception is cleared outside its room")
	await clear_session()
	for folder: String in created:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = folder.path_join("slot_1.json")+suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(folder)
	print("TEN_RESCUE_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
