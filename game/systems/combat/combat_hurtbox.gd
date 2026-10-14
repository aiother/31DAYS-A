class_name CombatHurtbox
extends Area2D
## A health/AI component can subscribe later; this receiver owns no HP or rewards.
signal hit_received(damage: int, impulse: Vector2, source: Node2D, attack_id: int)
@export var accepts_hits: bool = true

func receive_attack(damage: int, impulse: Vector2, source: Node2D, attack_id: int) -> bool:
	if not accepts_hits:
		return false
	hit_received.emit(damage, impulse, source, attack_id)
	return true
