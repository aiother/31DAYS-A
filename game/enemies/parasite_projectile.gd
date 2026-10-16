class_name ParasiteProjectile
extends ColorlessProjectile
var leech_boss: Node2D

func _deliver_hit(receiver: CombatHurtbox) -> void:
	var victim: PlayerController = receiver.get_parent().get_parent() as PlayerController
	var before: int = victim.life.health if victim != null else 0
	var was_reflected: bool = reflected
	super._deliver_hit(receiver)
	if not was_reflected and victim != null and victim.life.health < before and is_instance_valid(leech_boss):
		leech_boss.call("leech")
