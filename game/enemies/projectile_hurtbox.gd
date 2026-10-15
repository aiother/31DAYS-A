extends CombatHurtbox
func receive_attack(_damage: int, impulse: Vector2, source: Node2D, _id: int) -> bool:
	return (get_parent() as ColorlessProjectile).reflect(source, impulse)
