class_name ParasiteRoom
extends WorldRoom
signal support_spawned(enemy: ColorlessEntity)
var opened: bool = false
var support_pending: bool = false
var support_remaining: float = -1.0
var support_position: Vector2

func living_support() -> Array[ColorlessEntity]:
	var result: Array[ColorlessEntity] = []
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			result.append(child as ColorlessEntity)
	return result

func _physics_process(delta: float) -> void:
	var actor: ParasiteBoss = $Boss as ParasiteBoss
	if opened or not actor.is_physics_processing() or actor.state==ParasiteBoss.State.WAITING or actor.state==ParasiteBoss.State.DEAD or not is_instance_valid(actor.target) or not actor.target.life.is_alive():
		return
	if support_remaining<0:
		support_remaining = actor.config.support_initial_delay
	support_remaining = maxf(0,support_remaining-delta)
	if support_remaining>0:
		return
	if not support_pending:
		if living_support().size()>=actor.config.max_support:
			support_remaining = actor.config.support_interval
			return
		support_position = Vector2(1536 if actor.target.position.x<960 else 432,actor.config.floor_y-192)
		support_pending = true
		support_remaining = actor.config.support_warning
		queue_redraw()
		return
	support_pending = false
	support_remaining = actor.config.support_interval
	if living_support().size()<actor.config.max_support:
		var enemy: ColorlessEntity = (preload("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
		enemy.position = support_position
		enemy.flying = true
		enemy.ranged_only = true
		enemy.target = actor.target
		enemy.coordinator = $AttackCoordinator as EnemyAttackCoordinator
		$Enemies.add_child(enemy)
		enemy.alert_to_target()
		support_spawned.emit(enemy)
	queue_redraw()

func clear_projectiles() -> void:
	support_pending = false
	support_remaining = -1
	for child: Node in $Enemies.get_children():
		child.set_physics_process(false)
		if child is ColorlessEntity:
			(child as ColorlessEntity).hurtbox.accepts_hits = false
		child.queue_free()
	queue_redraw()

func set_opened(value: bool, animate: bool = false) -> void:
	var changed: bool = opened != value
	opened = value
	if value and changed and animate:
		var falling: Polygon2D = Polygon2D.new()
		falling.name = "FallingBoards"
		falling.polygon = $Boards.polygon
		falling.color = $Boards.color
		falling.position = $Boards.position
		add_child(falling)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(falling,"position",falling.position+Vector2(-32,300),0.65)
		tween.tween_property(falling,"rotation",0.6,0.65)
		tween.tween_property(falling,"modulate:a",0.0,0.65)
		tween.chain().tween_callback(falling.queue_free)
	$Boards.visible = not value
	$Corpse.visible = not value
	$ExitLabel.text = "木板已落下 · 通往逆时战场" if value else "击败寄生同伴者后开启"
	queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds,Color(0.065,0.06,0.075))
	for x: int in [80,400,720,1040,1360,1680,1840]:
		draw_line(Vector2(x,120),Vector2(x,1536),Color(0.16,0.17,0.18),9)
	if opened:
		draw_rect(Rect2(1480,816,144,240),Color(0.018,0.023,0.028))
	if support_pending:
		draw_circle(support_position+Vector2(0,-44),52,Color(0.65,0.35,0.9,0.3))
