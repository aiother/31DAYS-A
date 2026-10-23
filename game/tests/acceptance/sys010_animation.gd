extends SceneTree
## Save-free G4 lab. No SlotStore or session, no formal settings writes.
var world: Node2D
var body: PlayerController
var panel: Observer
var enemies: Array[ColorlessEntity] = []

class Observer extends CanvasLayer:
	var owner_tree: SceneTree
	var label: Label
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		layer = 100
		label = Label.new()
		label.position = Vector2(40, 420)
		label.add_theme_font_size_override("font_size", 20)
		add_child(label)
	func _process(_delta: float) -> void:
		if not is_instance_valid(owner_tree.body): return
		var text: String = "SYS-010 · 无存档实验室\n原键位移动、跳跃、攻击、闪避、恢复（可看实验室原说明）\nF1/F2/F3 放入无色/单色/天人（替换上一只）\nF4 受击 · F5 倒地消散 · F6 复活并补生命/可能性 · F8 暂停\n观察轻微姿态缩放，旧受击变色/无敌闪烁仍在\n"
		text += "玩家 %s\n暂停 %s" % [str(owner_tree.body.animation_state()), owner_tree.paused]
		for enemy: ColorlessEntity in owner_tree.enemies:
			if is_instance_valid(enemy): text += "\n敌人 " + str(enemy.animation_state())
		label.text = text
	func _unhandled_key_input(event: InputEvent) -> void:
		if not event is InputEventKey or not event.pressed or event.echo: return
		var key: Key = event.keycode
		if key == KEY_F8:
			owner_tree.paused = not owner_tree.paused
		elif not owner_tree.paused:
			if key in [KEY_F1, KEY_F2, KEY_F3]: owner_tree.spawn(key - KEY_F1)
			if key == KEY_F4: owner_tree.body.life.take_hit(1)
			if key == KEY_F5: owner_tree.body.life.take_hit(999)
			if key == KEY_F6:
				owner_tree.body.life.revive()
				owner_tree.body.possibility.balance = 10
		get_viewport().set_input_as_handled()

func _initialize() -> void:
	launch.call_deferred()

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func spawn(kind: int) -> void:
	for enemy: ColorlessEntity in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	var path: String = ["res://enemies/colorless_entity.tscn", "res://enemies/monochrome_entity.tscn", "res://enemies/tian_warrior.tscn"][kind]
	var enemy: ColorlessEntity = (load(path) as PackedScene).instantiate() as ColorlessEntity
	enemy.position = body.position + Vector2(280, 0)
	enemy.target = body
	world.add_child(enemy)
	enemies.append(enemy)

func launch() -> void:
	world = (load("res://debug/movement_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	current_scene = world
	body = world.get_node("Player") as PlayerController
	body.possibility.balance = 10
	body.life.health = 1
	panel = Observer.new()
	panel.owner_tree = self
	root.add_child(panel)
	await frames(20)
	if not "--self-test" in OS.get_cmdline_user_args(): return
	var checks: int = 0
	var failures: int = 0
	for kind: int in range(3):
		spawn(kind)
		await frames(3)
		checks += 1
		if enemies[0].animation_state().is_empty() or not enemies[0].has_node("VisualRoot/Animator"): failures += 1
	checks += 1
	if not body.is_on_floor() or panel.label.text.is_empty(): failures += 1
	panel.queue_free()
	world.queue_free()
	await frames(2)
	OS.delay_msec(500)
	print("SYS010_ACCEPTANCE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
