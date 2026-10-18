class_name BossOrdinaryEnemies
extends Node2D
## One ordinary combatant per attempt, separate from the replenishing summons.
@export var spawn_position: Vector2 = Vector2(1600, 1280)
@export var flying: bool = false
var started: bool = false

func start(player: PlayerController, coordinator: EnemyAttackCoordinator) -> MonochromeEntity:
	if started:
		return null
	started = true
	var enemy: MonochromeEntity = (preload("res://enemies/monochrome_entity.tscn") as PackedScene).instantiate() as MonochromeEntity
	enemy.position = spawn_position
	enemy.flying = flying
	enemy.ranged_only = flying
	enemy.target = player
	enemy.coordinator = coordinator
	add_child(enemy)
	enemy.alert_to_target()
	return enemy

func clear() -> void:
	# Keep started latched: victory/save retries cannot create another combatant.
	started = true
	for child: Node in get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED
		if child is ColorlessEntity:
			(child as ColorlessEntity).hurtbox.accepts_hits = false
		child.queue_free()
