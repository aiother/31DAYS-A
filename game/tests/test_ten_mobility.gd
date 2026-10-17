extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var ten: TenFighter
var enemy: ColorlessEntity
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
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	var floor: StaticBody2D = StaticBody2D.new()
	floor.position = Vector2(900,912)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(1800,32)
	collision.shape = shape
	floor.add_child(collision)
	world.add_child(floor)
	var enemies: Node2D = Node2D.new()
	world.add_child(enemies)
	enemy = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
	enemy.config = enemy.config.duplicate() as ColorlessConfig
	enemy.config.max_health = 500
	enemy.position = Vector2(1200,896)
	enemies.add_child(enemy)
	enemy.set_physics_process(false)
	ten = (load("res://allies/ten_fighter.tscn") as PackedScene).instantiate() as TenFighter
	ten.opponents = enemies
	ten.position = Vector2(224,896)
	world.add_child(ten)
	await ticks(4)
	check(ten.config is TenConfig and ten.config.speed==420 and ten.config.windup==0.18 and ten.config.recovery==0.32,"Ten has faster data-driven movement and attack cadence")
	var before: float = ten.position.x
	await ticks(18)
	check(ten.position.x>before+125 and ten.dash_cooldown>0,"distant target triggers real physical dash faster than old walking")
	await ticks(120)
	check(ten.attacks>=1 and enemy.health<500,"dash closes distance and leads to actual melee damage")
	ten.position = Vector2(800,896)
	enemy.position = Vector2(1100,896)
	ten.state = SurvivorFighter.State.RECOVERY
	ten.remaining = 0.25
	ten.dash_remaining = 0
	await ticks(8)
	check(ten.position.x>830 and ten.state==SurvivorFighter.State.RECOVERY,"Ten chases during recovery without cancelling attack timing")
	ten.position = Vector2(1000,896)
	enemy.position = Vector2(1070,896)
	ten.state = SurvivorFighter.State.SEEK
	ten.remaining = 0
	await ticks(100)
	check(ten.attacks>=4,"shorter windup and recovery sustain repeated attacks")
	var other: ColorlessEntity = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
	other.position = ten.position+Vector2(-60,0)
	enemies.add_child(other)
	other.set_physics_process(false)
	enemy.position = Vector2(1600,896)
	ten.state = SurvivorFighter.State.RECOVERY
	ten.remaining = 0.2
	ten.retarget_remaining = 0
	await ticks(2)
	check(ten.target==other and ten.facing<0,"Ten switches promptly to a nearer rear target")
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2(700,746)
	var wall_shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(32,300)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	world.add_child(wall)
	ten.position = Vector2(600,896)
	other.position = Vector2(1000,896)
	ten.state = SurvivorFighter.State.SEEK
	ten.dash_cooldown = 0
	ten.dash_remaining = 0
	await ticks(40)
	check(ten.position.x<665,"dash cannot move through solid walls")
	check(not ten._can_step(-1,1000),"dash rejects a route with no ground at destination")
	var hp: int = ten.health
	ten.hurtbox.receive_attack(999,Vector2.ZERO,other,1000)
	check(ten.health==hp and ten.config.damage==10,"mobility tuning preserves Ten damage and invulnerability")
	var regular: SurvivorConfig = load("res://data/allies/survivor.tres") as SurvivorConfig
	check(regular.speed==220 and regular.windup==0.3 and regular.recovery==0.65,"ordinary survivors retain original tuning")
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("TEN_MOBILITY_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
