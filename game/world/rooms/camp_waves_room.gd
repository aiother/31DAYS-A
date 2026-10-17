class_name CampWavesRoom
extends WorldRoom
signal enemy_spawned(enemy: ColorlessEntity)
enum Phase { READY, WARNING, ACTIVE, INTERVAL, COMPLETE }
@export var waves: CampWaveConfig
var target: PlayerController
var phase: Phase = Phase.READY
var wave: int = 0
var remaining: float = 0.0
const ENEMY: PackedScene = preload("res://enemies/colorless_entity.tscn")

func _ready() -> void:
	super._ready()
	# Full-height barriers also prevent jumping around an exit trigger.
	for x: float in [112.0, 1776.0]:
		var gate: StaticBody2D = StaticBody2D.new()
		gate.name = "ReturnBattleGate" if x < 960 else "ForwardBattleGate"
		gate.position = Vector2(x, 768)
		gate.collision_layer = 1
		gate.collision_mask = 0
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = Vector2(32, 1536)
		shape.shape = rectangle
		gate.add_child(shape)
		add_child(gate)

func _open_exits() -> void:
	for gate: String in ["ReturnBattleGate", "ForwardBattleGate"]:
		(get_node(gate) as StaticBody2D).collision_layer = 0

func living() -> Array[ColorlessEntity]:
	var result: Array[ColorlessEntity] = []
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health > 0:
			result.append(child as ColorlessEntity)
	return result

func _on_encounter_entered(body: Node2D) -> void:
	if body is PlayerController and _currently_overlaps($Encounter,body):
		start_waves()

func start_waves() -> bool:
	if phase != Phase.READY or not is_instance_valid(target) or not target.life.is_alive():
		return false
	wave = 1
	phase = Phase.WARNING
	remaining = waves.warning
	queue_redraw()
	return true

func _spawn_wave() -> void:
	phase = Phase.ACTIVE
	for index: int in range(waves.counts[wave-1]):
		var enemy: ColorlessEntity = ENEMY.instantiate() as ColorlessEntity
		var airborne: bool = wave >= 2 and index == waves.counts[wave-1]-1
		enemy.position = waves.air_spawn if airborne else (waves.left_spawn if index == 0 else waves.right_spawn)
		enemy.flying = airborne
		enemy.ranged_only = airborne
		enemy.target = target
		enemy.coordinator = $AttackCoordinator as EnemyAttackCoordinator
		$Enemies.add_child(enemy)
		enemy.alert_to_target()
		enemy_spawned.emit(enemy)
		enemy.defeated.connect(_on_defeated)
	queue_redraw()

func _on_defeated(_reward: int) -> void:
	if phase != Phase.ACTIVE or not living().is_empty():
		return
	for child: Node in $Enemies.get_children():
		if child is ColorlessProjectile:
			child.queue_free()
	if wave >= waves.counts.size():
		phase = Phase.COMPLETE
		remaining = 0
		_open_exits()
	else:
		phase = Phase.INTERVAL
		remaining = waves.interval
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not target.life.is_alive():
		return
	if phase != Phase.WARNING and phase != Phase.INTERVAL:
		return
	remaining = maxf(0,remaining-delta)
	if remaining > 0:
		return
	if phase == Phase.INTERVAL:
		wave += 1
		phase = Phase.WARNING
		remaining = waves.warning
		queue_redraw()
	else:
		_spawn_wave()

func _draw() -> void:
	draw_rect(config.bounds,Color(0.075,0.065,0.07))
	if phase != Phase.COMPLETE:
		for x: float in [112.0, 1776.0]:
			draw_rect(Rect2(x-16, 0, 32, 1536), Color(0.7,0.28,0.12,0.8))
	for x: int in [320,960,1536]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-160,1280),Vector2(x,704),Vector2(x+160,1280)]),Color(0.19,0.17,0.15))
	if phase == Phase.WARNING:
		for index: int in range(waves.counts[wave-1]):
			var airborne: bool = wave >= 2 and index == waves.counts[wave-1]-1
			var point: Vector2 = waves.air_spawn if airborne else (waves.left_spawn if index == 0 else waves.right_spawn)
			draw_circle(point+Vector2(0,-44),52,Color(0.9,0.35,0.15,0.3))
			draw_line(point+Vector2(-40,0),point+Vector2(40,0),Color(1,0.55,0.2),5)
