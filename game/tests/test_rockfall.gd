extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var room: TrenchPassageRoom
var player: PlayerController
var hits: int = 0
var reward: int = 0
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
func reset_player(point: Vector2 = Vector2(224,2048)) -> void:
	player.life.start_new_run()
	player.life.health = 5
	player.position = point
	player.reset_kinematics()
	player.combat.interrupt()
	await ticks(4)
func rock(point: Vector2, speed: float = 700) -> FallingRock:
	var falling: FallingRock = FallingRock.new()
	falling.position = point
	falling.speed = speed
	world.add_child(falling)
	return falling
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	room = (load("res://world/rooms/nszc_10002_2.tscn") as PackedScene).instantiate() as TrenchPassageRoom
	world.add_child(room)
	player = (load("res://player/player.tscn") as PackedScene).instantiate() as PlayerController
	world.add_child(player)
	var receiver: CombatHurtbox = player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.monitorable = true
	(receiver.get_node("CollisionShape2D") as CollisionShape2D).disabled = false
	receiver.hit_received.connect(func(_d: int,_i: Vector2,_s: Node2D,_id: int) -> void: hits += 1)
	for enemy: ColorlessEntity in room.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
		enemy.defeated.connect(func(value: int) -> void: reward += value)
	await reset_player()
	var falling: FallingRock = rock(Vector2(224,1752))
	check(not falling.has_method("reflect") and falling.get_child_count()==0, "falling debris is not a reflectable thrown weapon")
	await ticks(30)
	check(player.life.health==4 and hits==1 and not is_instance_valid(falling), "one swept falling rock hits once for1 and disappears")
	await reset_player()
	var before: int = hits
	rock(Vector2(224,1752),50000)
	await ticks(2)
	check(player.life.health==4 and hits==before+1, "high-speed rock sweep cannot tunnel through player")
	await reset_player()
	rock(Vector2(224,1752),50000)
	rock(Vector2(224,1748),50000)
	await ticks(2)
	check(player.life.health==4, "simultaneous rocks respect existing player hit protection")
	await reset_player(Vector2(448,2048))
	falling = rock(Vector2(448,1700))
	await ticks(30)
	check(player.life.health==5 and not is_instance_valid(falling), "upper platform intercepts debris before player underneath")
	await reset_player()
	var mono: MonochromeEntity = room.get_node("Enemies/GroundMonochrome") as MonochromeEntity
	mono.health = 1
	rock(Vector2(1024,1850))
	await ticks(24)
	check(mono.state==ColorlessEntity.State.DEAD and reward==7, "environmental kill defeats monochrome and emits normal+7")
	var tian: TianWarrior = room.get_node("Enemies/TianLower") as TianWarrior
	tian.health = 1
	tian.target = player
	rock(Vector2(800,1850))
	await ticks(24)
	check(tian.state==ColorlessEntity.State.DEAD and reward==18, "vertical trap defeats Tian without guard and emits normal+11")
	await reset_player(Vector2(1648,944))
	var rubble: RubbleBarrier = room.rubble
	check(not rubble.hurtbox.receive_attack(5,Vector2.RIGHT,player,6000) and rubble.health==10, "locked rubble ignores attacks before prerequisites")
	rubble.refresh(true,false)
	player.facing = 1
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	await ticks(34)
	check(rubble.health==5 and not rubble.pending_break, "real player swing deals5 to unlocked10HP rubble")
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	await ticks(34)
	check(rubble.health==0 and rubble.pending_break and not rubble.broken and not rubble.get_node("CollisionShape2D").disabled, "second swing requests persistence but does not open unsaved wall")
	rubble.refresh(true,true)
	await ticks(2)
	Input.action_press("move_right")
	await ticks(35)
	Input.action_release("move_right")
	check(player.position.x>1760 and rubble.get_node("CollisionShape2D").disabled, "confirmed opening physically removes rubble collision")
	# Restore a safe waiting position and exercise the actual rotating scheduler.
	await reset_player(Vector2(928,944))
	room.target = player
	var frames: Array[int] = []
	var lanes: Array[float] = []
	room.get_node("Rocks").child_entered_tree.connect(func(node: Node) -> void:
		frames.append(Engine.get_physics_frames())
		lanes.append((node as Node2D).position.x))
	await ticks(2)
	check(room.warning_lane==0 and room.get_node("Rocks").get_child_count()==0, "first fixed lane warns before producing rock")
	await ticks(24)
	check(frames.is_empty(), "warning remains harmless for initial0.4s")
	var warning: float = room.warning_remaining
	paused = true
	await ticks(20)
	check(room.warning_remaining==warning and frames.is_empty(), "pause freezes warning and spawning")
	paused = false
	await ticks(16)
	check(frames.size()==1 and lanes[0]==1024, "first rock appears after0.6s warning at fixed lane")
	await ticks(170)
	check(lanes.size()>=3 and lanes.slice(0,3)==[1024.0,1248.0,1472.0], "three lanes rotate without tracking player's position")
	check(frames.size()>=3 and frames[1]-frames[0]>=83 and frames[1]-frames[0]<=86 and frames[2]-frames[1]>=83 and frames[2]-frames[1]<=86, "rock generation interval remains1.4s rather than interval plus warning")
	await reset_player(Vector2(1120,944))
	await ticks(240)
	check(player.life.health==5, "gap between fixed lanes provides a safe waiting point")
	player.life.take_hit(5)
	var count: int = frames.size()
	await ticks(90)
	check(room.warning_lane==-1 and room.get_node("Rocks").get_child_count()==0 and frames.size()==count, "player death removes debris and stops future warning or damage")
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("ROCKFALL_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
