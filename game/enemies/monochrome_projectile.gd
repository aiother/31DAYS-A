class_name MonochromeProjectile
extends ColorlessProjectile
var damage: int = 1

func _deliver_hit(receiver: CombatHurtbox) -> void:
	receiver.receive_attack(5 if reflected else damage, velocity.normalized() * 100.0, source if is_instance_valid(source) else self, get_instance_id())

func _draw() -> void:
	var color: Color = Color(0.4,0.92,0.95) if reflected else (Color(1,0.3,0.6) if damage == 2 else Color(0.75,0.45,1))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-10),Vector2(14,0),Vector2(0,10),Vector2(-14,0)]),color)
