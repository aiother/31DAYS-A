extends CombatHurtbox
func receive_attack(damage: int, impulse: Vector2, source: Node2D, attack_id: int) -> bool:
	var life: PlayerLife = get_parent().get_node("Life") as PlayerLife
	if not accepts_hits or not life.take_hit(damage, impulse):
		return false
	hit_received.emit(damage, impulse, source, attack_id)
	return true
