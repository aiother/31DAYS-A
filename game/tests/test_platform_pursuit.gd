# verify-suite: {"name": "enemy multi-platform pursuit overhang wall and cliff safety", "path": "res://tests/test_platform_pursuit.gd", "marker": "PLATFORM_PURSUIT_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var world: Node2D
var target: Node2D
var actor: ColorlessEntity
var geometry: Array[Node] = []
const ACTORS: Dictionary = {
	"monochrome_entity": preload("res://enemies/monochrome_entity.tscn"),
	"tian_warrior": preload("res://enemies/tian_warrior.tscn")
}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func solid(point: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = point
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	world.add_child(body)
	geometry.append(body)
	return body

func clean() -> void:
	if is_instance_valid(actor): actor.queue_free()
	for body: Node in geometry: body.queue_free()
	geometry.clear()
	for child: Node in world.get_children():
		if child is ColorlessProjectile: child.queue_free()
	await ticks(2)

func spawn(kind: String, point: Vector2) -> void:
	actor = (ACTORS[kind] as PackedScene).instantiate() as ColorlessEntity
	actor.position = point
	actor.target = target
	world.add_child(actor)
	actor.alert_to_target()

func route(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	solid(Vector2(520,736),Vector2(256,32))
	solid(Vector2(744,560),Vector2(256,32))
	target.position = Vector2(744,544)
	spawn(kind,Vector2(300,896))
	var first_landing: bool = false
	var second_landing: bool = false
	var airborne: bool = false
	var physical: bool = true
	var pause_checked: bool = false
	for i: int in range(450):
		var before: Vector2 = actor.position
		var physics_before: int = Engine.get_physics_frames()
		await ticks(1)
		# Monochrome can still use its pre-existing 480px/s ground dash.
		# Headless process frames can include multiple fixed physics steps.
		var speed_limit: float = (actor.config as MonochromeConfig).dash_speed if actor is MonochromeEntity else actor.config.speed
		var physics_steps: int = Engine.get_physics_frames()-physics_before
		physical = physical and absf(actor.position.x-before.x)<=speed_limit*physics_steps/Engine.physics_ticks_per_second+2
		airborne = airborne or not actor.is_on_floor()
		if not pause_checked and not actor.is_on_floor() and actor.velocity.y < 0:
			pause_checked = true
			var point: Vector2 = actor.position
			var pursuit: EnemyPlatformPursuit = (actor as MonochromeEntity).platform_pursuit if actor is MonochromeEntity else (actor as TianWarrior).platform_pursuit
			var cooldown: float = pursuit.cooldown
			paused = true
			await ticks(3)
			check(actor.position==point and pursuit.cooldown==cooldown,kind+" pause freezes actual platform jump and cooldown")
			paused = false
		if actor.is_on_floor() and absf(actor.position.y-720)<4: first_landing = true
		if actor.is_on_floor() and absf(actor.position.y-544)<4:
			second_landing = true
			break
	check(first_landing,kind+" physically lands on intermediate platform toward much higher target")
	check(second_landing,kind+" jumps again and reaches target platform; actual "+str(actor.position))
	check(airborne and physical,kind+" uses continuous body movement without blink or teleport across height")
	await ticks(90)
	check(actor.is_on_floor() and absf(actor.position.y-544)<4,kind+" can resume combat on reached platform without walking off its edge")
	await clean()

func overhead(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	solid(Vector2(600,736),Vector2(256,32))
	target.position = Vector2(600,720)
	spawn(kind,Vector2(600,896))
	var stepped_out: bool = false
	var reached: bool = false
	for i: int in range(360):
		await ticks(1)
		stepped_out = stepped_out or (actor.is_on_floor() and absf(actor.position.x-600)>150 and actor.position.y>890)
		if actor.is_on_floor() and absf(actor.position.y-720)<4:
			reached = true
			break
	check(stepped_out and reached,kind+" walks clear of solid overhang then lands above it; actual "+str(actor.position))
	await clean()

func safety(kind: String) -> void:
	solid(Vector2(960,916),Vector2(2200,40))
	solid(Vector2(430,480),Vector2(40,832))
	solid(Vector2(700,736),Vector2(256,32))
	target.position = Vector2(700,720)
	spawn(kind,Vector2(300,896))
	await ticks(100)
	check(actor.position.x<388 and actor.position.y>890,kind+" cannot jump through tall solid wall")
	await clean()
	solid(Vector2(300,912),Vector2(256,32))
	solid(Vector2(1040,736),Vector2(256,32))
	target.position = Vector2(1040,720)
	spawn(kind,Vector2(300,896))
	await ticks(120)
	check(actor.is_on_floor() and actor.position.x<408 and actor.position.y<900,kind+" refuses unreachable gap and keeps cliff protection")
	await clean()

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	for kind: String in ["monochrome_entity","tian_warrior"]:
		await route(kind)
		await overhead(kind)
		await safety(kind)
	world.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	print("PLATFORM_PURSUIT_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
