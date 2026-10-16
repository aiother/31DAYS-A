extends SceneTree
var checks: int = 0
var failures: int = 0
var session: ParasiteSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func boss() -> ParasiteBoss:
	return session.room.get_node("Boss") as ParasiteBoss
func arena() -> ParasiteRoom:
	return session.room as ParasiteRoom
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)
func load_snapshot(snapshot: Dictionary, selected: int = 1) -> void:
	check(session.store.save_slot(selected,snapshot) and session.start_slot(selected,false), "valid prior checkpoint snapshot loads")
	await ticks(4)
	session = current_scene as ParasiteSession
func shot(point: Vector2, velocity: Vector2) -> ParasiteProjectile:
	var projectile: ParasiteProjectile = (load("res://enemies/parasite_projectile.tscn") as PackedScene).instantiate() as ParasiteProjectile
	projectile.position = point
	projectile.velocity = velocity
	projectile.source = boss()
	projectile.leech_boss = boss()
	arena().get_node("Enemies").add_child(projectile)
	return projectile
func clear_shots() -> void:
	arena().clear_projectiles()
	await ticks(2)
func reset_player() -> void:
	session.player.life.start_new_run()
	session.player.possibility.invincible_remaining = 0
	session.player.combat.interrupt()
	session.player.reset_kinematics()
func jump_to(point: Vector2) -> bool:
	Input.action_release("jump")
	await ticks(2)
	Input.action_press("jump")
	var reached: bool = false
	for i: int in range(100):
		Input.action_release("move_left")
		Input.action_release("move_right")
		var dx: float = point.x-session.player.position.x
		if absf(dx)>10:
			Input.action_press("move_right" if dx>0 else "move_left")
		await ticks(1)
		if i>4 and session.player.is_on_floor():
			reached = absf(session.player.position.y-point.y)<2 and absf(session.player.position.x-point.x)<110
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	return reached
func run() -> void:
	directory = "user://tests/parasite_%d" % Time.get_ticks_usec()
	session = (load("res://world/parasite_session.tscn") as PackedScene).instantiate() as ParasiteSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = CampWavesSession.WAVES_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 14
	base["balance"] = 7
	for key: String in [BossSession.BOSS_INTRO,BossSession.BOSS_DEFEATED,BossSession.BOSS_PASSAGE,FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,TownSession.GAZE,RavineRescueSession.HELPED,RavineDepthSession.DEPTH_HELPED,RavineDepthRoom.GATES,RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_snapshot(base)
	await place(Vector2(1824,1280))
	check(arena()!=null and arena().config.room_id=="HD_20003_1" and arena().config.next_room_id=="NSZC_10001_1", "actual camp prison door enters configured parasite arena")
	check(session.data["checkpoint"]==ParasiteSession.PARASITE_CHECKPOINT and session.store.load_slot(1)["checkpoint"]==ParasiteSession.PARASITE_CHECKPOINT, "new formal entry checkpoint persists before introduction")
	check(session.intro_active and not session.player.life.can_control() and boss().state==ParasiteBoss.State.WAITING and arena().has_node("Chair") and boss().get_node("VisualRoot").scale.y<1, "first seated corpse and roar introduction restricts player until combat")
	check(not boss().hurtbox.receive_attack(5,Vector2.ZERO,session.player,1) and boss().health==80, "intro Boss cannot take gameplay damage")
	var remaining: float = session._parasite_intro_remaining
	session.ui.call("show_pause")
	await ticks(8)
	check(session._parasite_intro_remaining==remaining, "pause freezes parasite introduction")
	session.ui.call("resume_game")
	await ticks(310)
	check(not session.intro_active and session.player.life.can_control() and boss().state!=ParasiteBoss.State.WAITING and session.player.get_node("Camera2D").offset==Vector2.ZERO and boss().get_node("VisualRoot").scale==Vector2.ONE, "introduction completes standing with camera and control restored")
	check(session.data["events"].get(ParasiteSession.PARASITE_INTRO,false) and not arena().opened, "first introduction persists independently of victory")
	session._on_room_exit(CampWavesSession.WAVES_ID)
	session._on_room_exit("NSZC_10001_1")
	check(arena()!=null and not paused, "undefeated parasite locks both directions")
	boss().state = ParasiteBoss.State.WINDUP
	boss().remaining = boss().config.windup
	boss().shots_fired = 0
	await ticks(24)
	check(boss().shots_fired==0, "0.45-second windup produces no early projectile")
	await ticks(22)
	boss().set_physics_process(false)
	check(boss().shots_fired==3 and arena().get_node("Enemies").get_child_count()==3, "windup releases exactly three reflectable projectiles")
	await clear_shots()
	var old_x: float = boss().position.x
	boss().set_physics_process(true)
	await ticks(120)
	boss().set_physics_process(false)
	check(boss().shots_fired==6 and boss().position.x!=old_x, "Boss recovers repositions and repeats its next three-shot attack")
	await clear_shots()
	await place(Vector2(600,1536))
	boss().position = Vector2(840,1536)
	boss().health = 60
	reset_player()
	shot(Vector2(650,1492),Vector2.LEFT*300)
	await ticks(15)
	check(session.player.life.health==2 and boss().health==63, "actual projectile damage costs1HP and heals Boss3 once")
	session.player.life.protection_remaining = 1
	shot(Vector2(650,1492),Vector2.LEFT*300)
	await ticks(15)
	check(session.player.life.health==2 and boss().health==63, "protected collision cannot heal Boss")
	reset_player()
	session.player.possibility.invincible_remaining = 1
	shot(Vector2(650,1492),Vector2.LEFT*300)
	await ticks(15)
	check(session.player.life.health==3 and boss().health==63, "dodge invincibility prevents damage and lifesteal")
	reset_player()
	session.player.life.protection_remaining = 1
	var projectile: ParasiteProjectile = shot(Vector2(696,1492),Vector2.LEFT*100)
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	await ticks(9)
	check(is_instance_valid(projectile) and projectile.reflected, "actual horizontal player attack reflects parasite shot")
	await ticks(30)
	check(boss().health==58 and session.player.life.health==3, "reflected shot hits Boss for existing5 without player damage or healing")
	projectile = shot(Vector2(700,1400),Vector2.LEFT*100)
	check(not projectile.hurtbox.receive_attack(5,Vector2.DOWN,session.player,2), "down attack cannot reflect parasite projectile")
	check(projectile.hurtbox.receive_attack(5,Vector2.UP,session.player,3) and not projectile.hurtbox.receive_attack(5,Vector2.UP,session.player,4), "up attack reflects only once")
	await clear_shots()
	var old_health: int = boss().health
	projectile = shot(Vector2(1900,1492),Vector2.RIGHT*380)
	await ticks(8)
	check(not is_instance_valid(projectile) and boss().health==old_health, "projectile hitting wall expires without lifesteal")
	reset_player()
	boss().health = 79
	shot(Vector2(650,1492),Vector2.LEFT*300)
	await ticks(15)
	check(boss().health==80 and session.player.life.health==2, "lifesteal clamps at configured Boss maximum")
	session.player.life.protection_remaining = 0
	session.player.life.hurt_remaining = 0
	shot(Vector2(1200,1492),Vector2.LEFT*100)
	session.player.life.take_hit(5)
	await ticks(90)
	check(arena().get_node("Enemies").get_child_count()==0, "player death clears all transient parasite shots")
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as ParasiteSession
	check(arena()!=null and boss().health==80 and not session.intro_active and boss().state!=ParasiteBoss.State.WAITING, "undefeated retry restores full Boss and skips introduction")
	check(session.player.life.health==5 and session.player.life.protection_remaining>2.8 and session.player.possibility.balance==3 and session.data["day"]==2, "undefeated retry retains half resources full health and protection without date advance")
	boss().set_physics_process(false)
	var damage: int = session.player.combat.config.damage
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	boss().hurtbox.receive_attack(80,Vector2.ZERO,session.player,900)
	check(session._parasite_victory_pending and session.data["day"]==2 and not session.data["events"].get(ParasiteSession.PARASITE_DEFEATED,false) and not arena().opened, "failed victory write rolls back defeated passage day and reward marker")
	session.store.directory = real_directory
	session.player.life.protection_remaining = 0
	session.player.life.take_hit(5)
	check(session.store.load_slot(1)["day"]==3 and arena().opened and session.store.load_slot(1)["events"].get(ParasiteSession.PARASITE_DEFEATED,false), "same-frame player death retries and saves Boss victory with day3")
	check(session.data["events"].get(ParasiteSession.PARASITE_PASSAGE,false) and session.data["events"].get(ParasiteSession.DODGE_PENDING,false) and not arena().get_node("Boards").visible and arena().has_node("FallingBoards"), "victory saves passage and pending dodge reward then animates falling boards")
	check(session.player.combat.config.damage==damage and session.data["balance"]==1 and session.player.possibility.maximum==14, "victory adds no invented stats resource reward or max growth")
	await ticks(90)
	session.ui.call("restart_challenge")
	await ticks(4)
	session = current_scene as ParasiteSession
	check(boss().state==ParasiteBoss.State.DEAD and arena().opened and session.data["day"]==3 and not session.intro_active, "victory day and passage survive death")
	await place(Vector2(48,1536))
	check(session.room is CampWavesRoom and session.player.position.distance_to(Vector2(1728,1280))<2, "victory opens actual return to safe wave Room landing")
	await place(Vector2(1824,1280))
	check(boss().health==0 and arena().opened and session.data["day"]==3, "revisit neither respawns Boss nor changes day3")
	await load_snapshot(session.store.load_slot(1))
	check(boss().health==0 and arena().opened and session.player.life.protection_remaining==0 and not arena().has_node("FallingBoards"), "normal load preserves victory without replaying boards or granting revive protection")
	await place(Vector2(400,1536))
	for point: Vector2 in [Vector2(608,1344),Vector2(832,1200),Vector2(1056,1056)]:
		check(await jump_to(point), "ordinary jump reaches parasite exit platform %s; actual %s" % [point,session.player.position])
	Input.action_press("move_right")
	await ticks(120)
	Input.action_release("move_right")
	check(paused and session.ui.get("_mode")=="room_boundary", "climbing reaches newly opened reverse-time battlefield boundary")
	session.ui.call("resume_game")
	# Reverse simultaneous order and retry failure preserve already settled death resources.
	var second: Dictionary = base.duplicate(true)
	second["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	second["events"][ParasiteSession.PARASITE_INTRO] = true
	await load_snapshot(second,2)
	boss().set_physics_process(false)
	session.player.life.take_hit(3)
	boss().hurtbox.receive_attack(80,Vector2.ZERO,session.player,901)
	check(session.store.load_slot(2)["day"]==3 and session.store.load_slot(2)["balance"]==3 and session.store.load_slot(2)["health"]==5, "player-first simultaneous victory preserves death settlement and advances day")
	await ticks(90)
	for key: String in [ParasiteSession.PARASITE_DEFEATED,ParasiteSession.PARASITE_PASSAGE,ParasiteSession.DODGE_PENDING]:
		session.data["events"].erase(key)
	session.data["day"] = 2
	session._parasite_victory_pending = true
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_2.json")
	session.restart_challenge()
	await ticks(3)
	check(current_scene==session and session._parasite_victory_pending and session.data["day"]==2, "continued victory write failure blocks restart without losing only victory state")
	session.store.directory = real_directory
	session.restart_challenge()
	await ticks(4)
	session = current_scene as ParasiteSession
	check(boss().health==0 and arena().opened and session.data["day"]==3, "successful retry restores saved victory and day atomically")
	# Retry checkpoint failure before any intro or combat begins.
	await load_snapshot(base,3)
	session._mount_room(ParasiteSession.PARASITE_ID)
	session.player.position = Vector2(224,1536)
	session.player.reset_kinematics()
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_3.json")
	check(not session.activate_checkpoint(ParasiteSession.PARASITE_CHECKPOINT) and session.data["checkpoint"]==CampWavesSession.WAVES_CHECKPOINT and not session._all_checkpoints()[0].active, "failed parasite checkpoint write rolls back ID and flag")
	await ticks(4)
	session.store.directory = real_directory
	Input.action_press("interact")
	await ticks(1)
	Input.action_release("interact")
	await ticks(2)
	check(session.store.load_slot(3)["checkpoint"]==ParasiteSession.PARASITE_CHECKPOINT and session.intro_active, "E retry saves checkpoint and begins first intro")
	check(session.store.load_slot(1)["day"]==3 and session.data["day"]==2, "dates and Boss victories remain isolated by slot")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	var store: SlotStore = SlotStore.new()
	store.directory = directory
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(store.path_for(selected)+suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("PARASITE_BOSS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
