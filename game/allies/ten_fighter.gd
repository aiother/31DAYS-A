class_name TenFighter
extends SurvivorFighter

func _ready() -> void:
	super._ready()
	hurtbox.accepts_hits = false

func _on_hit(_damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	pass

func _refresh() -> void:
	$HealthLabel.text = "10 · " + ["接敌","攻击前摇","后摇","待机"][state]
