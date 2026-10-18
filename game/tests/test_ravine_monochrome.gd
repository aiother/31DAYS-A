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
func mono() -> MonochromeEntity:
	return session.room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
func quiet() -> void:
	if session.room.has_node("Enemies"):
		for actor: Node in session.room.get_node("Enemies").get_children(): actor.set_physics_process(false)
func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(3)
func run() -> void:
	directory = "user://tests/ravine_monochrome_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = RavineSession.RAVINE_CHECKPOINT
	base["day"] = 2
	base["balance"] = -9
	check(session.store.save_slot(1,base) and session.start_slot(1,false),"old ravine checkpoint loads without new schema or flags")
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.room is RavineRoom and session.room.get_node("Enemies").get_child_count()==3,"existing ravine Room contains two colorless and one monochrome")
	check(mono().health==21 and mono().config.reward==7 and not mono().flying,"new placement reuses approved ground21HP/reward7")
	check((session.room.get_node("Enemies/LowerEntity") as ColorlessEntity).health==15 and (session.room.get_node("Enemies/UpperEntity") as ColorlessEntity).flying,"second-day down-attack practice and flying colorless remain intact")
	check(mono().target==session.player and mono().coordinator==session.room.get_node("AttackCoordinator"),"normal session binds player and shared attack budget")
	check(mono().position.is_equal_approx(Vector2(1696,1280)) and mono().is_on_floor(),"spawn rests on real TileMap floor away from checkpoint")
	check(session._all_checkpoints().size()==1 and session._pickups().is_empty() and session.data["checkpoint"]==RavineSession.RAVINE_CHECKPOINT,"composition adds no checkpoint or pickup")
	var before: Dictionary = session.data["events"].duplicate()
	# Use the actual Room platforms and unmodified production AI.
	await place(Vector2(1424,1136))
	session.player.set_physics_process(false)
	mono().alert_to_target()
	mono().set_physics_process(true)
	var landed: bool = false
	for i: int in range(240):
		await ticks(1)
		if mono().is_on_floor() and absf(mono().position.y-1136)<3:
			landed = true
			break
	check(landed,"actual ravine AI reaches first raised platform; position=%s" % mono().position)
	var point: Vector2 = mono().position
	var cooldown: float = mono().platform_pursuit.cooldown
	paused = true
	await ticks(5)
	check(mono().position==point and mono().platform_pursuit.cooldown==cooldown,"pause freezes actor and platform planning")
	paused = false
	session.player.position = Vector2(1800,1280)
	var descended: bool = false
	for i: int in range(240):
		await ticks(1)
		if mono().is_on_floor() and absf(mono().position.y-1280)<3:
			descended = true
			break
	check(descended,"same Room AI descends safely to main floor; position=%s" % mono().position)
	quiet()
	session.player.set_physics_process(true)
	await place(Vector2(300,1280))
	await ticks(20)
	check(mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,9100),"real hurtbox accepts lethal damage")
	check(session.player.possibility.balance==-2 and session.store.load_slot(1)["balance"]==-2,"kill saves+7 from negative balance")
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,9101)
	check(session.player.possibility.balance==-2 and session.data["events"]==before,"corpse cannot reward twice or create progress events")
	await place(Vector2(48,1280))
	check(session.room is TownRoom,"actual return trigger reaches existing town")
	await place(Vector2(1824,896))
	quiet()
	check(session.room is RavineRoom and mono().health==21 and mono().dodge_cooldown_remaining==0,"actual revisit respawns clean monochrome state")
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,9102)
	check(session.player.possibility.balance==5,"reset enemy again pays full7")
	session.player.life.protection_remaining = 0
	session.player.life.hurt_remaining = 0
	session.player.life.take_hit(5)
	await ticks(90)
	session.restart_challenge()
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	check(session.room is RavineRoom and mono().health==21 and session.player.life.health==5 and session.player.possibility.balance==2 and session.player.life.protection_remaining>2.8,"death resets enemy and preserves existing floor-half resource rule")
	check(session.start_slot(1,false),"normal load accepts current reward snapshot")
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	check(mono().health==21 and session.player.possibility.balance==2 and session.player.life.protection_remaining==0 and session.data["day"]==2,"normal load resets enemy without restoring old resources or changing date")
	var other: Dictionary = base.duplicate(true)
	other["balance"] = 0
	check(session.store.save_slot(2,other) and session.start_slot(2,false),"separate slot loads independently")
	await ticks(3)
	session = current_scene as FinalBattleSession
	quiet()
	mono().hurtbox.receive_attack(21,Vector2.ZERO,session.player,9103)
	check(session.player.possibility.balance==7 and session.store.load_slot(1)["balance"]==2,"per-slot kill rewards remain independent")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for selected: int in [1,2]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("RAVINE_MONOCHROME_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
