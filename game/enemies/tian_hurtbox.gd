extends CombatHurtbox

func receive_attack(damage: int, impulse: Vector2, source: Node2D, attack_id: int) -> bool:
	if not accepts_hits:
		return false
	var actor: Node = get_parent().get_parent()
	if damage>0 and bool(actor.call("try_block",impulse,source)):
		return false
	return super.receive_attack(damage,impulse,source,attack_id)
