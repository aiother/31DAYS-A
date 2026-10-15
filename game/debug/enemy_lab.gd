extends "res://debug/movement_lab.gd"
var _incoming_hits: int = 0
var _defeats: int = 0
var _notice: Tween

func _ready() -> void:
	super._ready()
	var receiver: CombatHurtbox = player.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.hit_received.connect(_on_player_hit)
	for enemy: Node in $Enemies.get_children():
		(enemy as ColorlessEntity).defeated.connect(_on_defeated)

func _process(delta: float) -> void:
	super._process(delta)
	$Instructions/EnemyStatus.text = "敌方命中 %d 次（仅反馈，玩家生命待下一阶段） · 已击败 %d 只 · R 重置" % [_incoming_hits, _defeats]

func _on_player_hit(_damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	_incoming_hits += 1
	var sprite: Sprite2D = player.get_node("VisualRoot/PlaceholderSprite") as Sprite2D
	if _notice != null and _notice.is_valid():
		_notice.kill()
	sprite.modulate = Color(1.0, 0.45, 0.4)
	_notice = create_tween()
	_notice.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _on_defeated(_reward: int) -> void:
	# Reward signal is ready; resource credit waits for the possibility phase.
	_defeats += 1
