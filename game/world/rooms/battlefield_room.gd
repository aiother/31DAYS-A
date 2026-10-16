class_name BattlefieldRoom
extends WorldRoom
signal stage_completed
const ALLY: PackedScene = preload("res://allies/survivor_fighter.tscn")
@export var reinforcement_gap: float = 1.0
var target: PlayerController
var started: bool = false
var stopped: bool = false
var completed: bool = false
var arrivals: int = 0
var arrival_remaining: float = -1.0

func _ready() -> void:
	super._ready()
	process_physics_priority = -10
	for child: Node in $Enemies.get_children():
		var enemy: ColorlessEntity = child as ColorlessEntity
		enemy.set_physics_process(false)
		if enemy is TianWarrior:
			enemy.defeated.connect(_on_tian_defeated)

func _on_tian_defeated(_reward: int) -> void:
	if arrivals==0 and not stopped:
		_spawn_ally()
		arrival_remaining = reinforcement_gap

func _spawn_ally() -> SurvivorFighter:
	var ally: SurvivorFighter = ALLY.instantiate() as SurvivorFighter
	ally.opponents = $Enemies
	ally.position = Vector2(520+arrivals*112,896)
	$Allies.add_child(ally)
	arrivals += 1
	return ally

func _physics_process(delta: float) -> void:
	if stopped or completed or not is_instance_valid(target):
		return
	if not target.life.is_alive():
		stop_attempt()
		return
	if not started:
		if target.position.x<400:
			return
		started = true
		for child: Node in $Enemies.get_children():
			child.set_physics_process(true)
	if arrival_remaining>=0:
		arrival_remaining -= delta
		if arrival_remaining<=0:
			arrival_remaining = -1
			_spawn_ally()
	var living: int = 0
	for child: Node in $Enemies.get_children():
		if not child is ColorlessEntity:
			continue
		var enemy: ColorlessEntity = child as ColorlessEntity
		if enemy.health<=0:
			continue
		living += 1
		# Keep a committed strike's direction; choose anew while seeking or if its target dies.
		var lost: bool = not is_instance_valid(enemy.target) or (enemy.target is SurvivorFighter and (enemy.target as SurvivorFighter).health<=0)
		if lost or enemy.state in [ColorlessEntity.State.IDLE,ColorlessEntity.State.CHASE]:
			var selected: Node2D = target
			var distance: float = enemy.global_position.distance_squared_to(target.global_position)
			for actor: Node in $Allies.get_children():
				var ally: SurvivorFighter = actor as SurvivorFighter
				if ally.health>0 and enemy.global_position.distance_squared_to(ally.global_position)<distance:
					distance = enemy.global_position.distance_squared_to(ally.global_position)
					selected = ally
			# Target loss does not cancel a protected action.
			enemy.target = selected
			enemy.alert_to_target()
	if living==0 and arrivals==2:
		completed = true
		$StageLabel.text = "中心战场 · 首段完成\n完整战斗将在下一阶段接入\n返回通路尚未开启；可保存退出或读档返回检查点"
		stop_attempt()
		stage_completed.emit()

func stop_attempt() -> void:
	stopped = true
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity:
			(child as ColorlessEntity)._release_slot()
			child.set_physics_process(false)
		elif child is ColorlessProjectile:
			child.set_physics_process(false)
			child.queue_free()
	for child: Node in $Allies.get_children():
		child.set_physics_process(false)

func _draw() -> void:
	draw_rect(config.bounds,Color(0.15,0.09,0.08))
	draw_circle(Vector2(1500,380),140,Color(0.55,0.25,0.13))
	for x: int in [80,240,1580,1800]:
		draw_line(Vector2(x,896),Vector2(x+20,660),Color(0.27,0.22,0.2),12)
