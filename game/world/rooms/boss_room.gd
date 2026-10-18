class_name BossRoom
extends WorldRoom
var opened: bool = false
var summoned: bool = false
var light_strength: float = 0.0
signal reinforcement_spawned(enemy: ColorlessEntity)
var summon_pending: bool = false
var summon_position: Vector2 = Vector2.ZERO

func living_reinforcements() -> Array[ColorlessEntity]:
	var result: Array[ColorlessEntity] = []
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health > 0:
			result.append(child as ColorlessEntity)
	return result

func prepare_reinforcement() -> void:
	var actor: OverlookBoss = $Boss as OverlookBoss
	if opened or actor.state == OverlookBoss.State.DEAD or not is_instance_valid(actor.target) or not actor.target.life.is_alive() or living_reinforcements().size() >= actor.config.max_reinforcements:
		return
	# Fixed ground anchors keep arrivals away from the player at warning start.
	summon_position = Vector2(1536 if actor.target.position.x < 984 else 432, actor.config.floor_y)
	summon_pending = true
	queue_redraw()

func spawn_reinforcement() -> void:
	if not summon_pending:
		return
	summon_pending = false
	queue_redraw()
	var actor: OverlookBoss = $Boss as OverlookBoss
	if opened or actor.state == OverlookBoss.State.DEAD or not actor.target.life.is_alive() or living_reinforcements().size() >= actor.config.max_reinforcements:
		return
	var enemy: ColorlessEntity = (preload("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
	enemy.position = summon_position
	enemy.target = actor.target
	enemy.coordinator = $AttackCoordinator as EnemyAttackCoordinator
	$Enemies.add_child(enemy)
	enemy.alert_to_target()
	reinforcement_spawned.emit(enemy)

func start_ordinary(player: PlayerController) -> void:
	if opened:
		return
	var enemy: MonochromeEntity = ($OrdinaryEnemies as BossOrdinaryEnemies).start(player, $AttackCoordinator as EnemyAttackCoordinator)
	if enemy != null:
		reinforcement_spawned.emit(enemy)

func clear_reinforcements() -> void:
	($OrdinaryEnemies as BossOrdinaryEnemies).clear()
	summon_pending = false
	($Boss as OverlookBoss).summon_remaining = -1.0
	for child: Node in $Enemies.get_children():
		child.set_physics_process(false)
		if child is ColorlessEntity:
			(child as ColorlessEntity).hurtbox.accepts_hits = false
		child.queue_free()
	queue_redraw()

func summon_platforms() -> void:
	if summoned:
		return
	summoned = true
	for point: Vector2 in [Vector2(608, 1152), Vector2(832, 1008), Vector2(1056, 864)]:
		var platform: Node2D = (preload("res://world/scenes/platform.tscn") as PackedScene).instantiate() as Node2D
		platform.position = point
		$SummonedPlatforms.add_child(platform)

func set_opened(value: bool) -> void:
	var changed: bool = opened != value
	opened = value
	$ExitLabel.text = "天窗已开启 · 向上前进" if value else "击败渴望俯视后开启"
	if value:
		($OrdinaryEnemies as BossOrdinaryEnemies).clear()
		summon_platforms()
		if changed:
			create_tween().tween_property(self, "light_strength", 1.0, 0.8)
	queue_redraw()

func _process(_delta: float) -> void:
	if opened:
		queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds, Color(0.065, 0.07, 0.10))
	if summon_pending:
		draw_arc(summon_position - Vector2(0, 8), 48, PI, TAU, 24, Color(0.8, 0.55, 1), 5)
		draw_line(summon_position - Vector2(0, 8), summon_position - Vector2(0, 104), Color(0.8, 0.55, 1, 0.65), 4)
	for x: int in [64, 480, 960, 1440, 1824]:
		draw_rect(Rect2(x, 80, 32, 1200), Color(0.12, 0.13, 0.17))
	draw_line(Vector2(48, 1280), Vector2(48, 1080), Color(0.4, 0.8, 0.5) if opened else Color(0.8, 0.4, 0.3), 6)
	if opened:
		draw_colored_polygon(PackedVector2Array([Vector2(1488, 0), Vector2(1616, 0), Vector2(1696, 848), Vector2(1408, 848)]), Color(0.95, 0.8, 0.3, 0.17 * light_strength))
	else:
		draw_line(Vector2(1488, 848), Vector2(1616, 848), Color(0.7, 0.45, 0.3), 8)
