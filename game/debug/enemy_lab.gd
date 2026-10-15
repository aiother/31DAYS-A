class_name EnemyLab
extends "res://debug/movement_lab.gd"
var _incoming_hits: int = 0
var _defeats: int = 0

func _ready() -> void:
	super._ready()
	var receiver: CombatHurtbox = player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.hit_received.connect(_on_player_hit)
	for enemy: Node in $Enemies.get_children():
		(enemy as ColorlessEntity).defeated.connect(_on_defeated)
	if get_tree().has_meta("graybox_revive_pending"):
		get_tree().remove_meta("graybox_revive_pending")
		player.life.revive()

func _process(delta: float) -> void:
	super._process(delta)
	$Instructions/EnemyStatus.text = "实际受击 %d 次 · 已击败 %d 只 · Esc 暂停 / 设置 · R 开发重置" % [_incoming_hits, _defeats]

func _on_player_hit(_damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	_incoming_hits += 1

func restart_challenge() -> void:
	_restart_deferred.call_deferred()

func _restart_deferred() -> void:
	var tree: SceneTree = get_tree()
	tree.paused = false
	# Reload all transient enemies/corpses/projectiles, then revive the new player.
	tree.set_meta("graybox_revive_pending", true)
	var result: Error = tree.reload_current_scene()
	if result != OK:
		tree.remove_meta("graybox_revive_pending")
		push_error("Could not reload graybox challenge")

func _on_defeated(_reward: int) -> void:
	# Reward signal is ready; resource credit waits for the possibility phase.
	_defeats += 1
