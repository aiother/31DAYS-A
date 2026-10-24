extends Node2D
@onready var actor: TianWarrior = get_parent() as TianWarrior
func _draw() -> void:
	if actor.state == ColorlessEntity.State.DEAD:
		for i: int in range(4):
			draw_rect(Rect2(-30+i*17,-8-(i%2)*6,12,8),Color(0.55,0.45,0.25))
		return
	var color: Color = Color(0.85,0.68,0.3).lerp(Color.WHITE,actor._flash)
	if actor.state == ColorlessEntity.State.WINDUP:
		color = Color(1,0.25,0.15) if actor.attack_kind == TianWarrior.Attack.HEAVY else Color(1,0.85,0.5)
		draw_line(Vector2(0,-40),Vector2(0,-40)+actor._attack_direction*(180 if actor.attack_kind == TianWarrior.Attack.HEAVY else 95),color,4)
	if actor.motion == TianWarrior.Motion.GUARD:
		draw_line(Vector2(actor.facing*34,-84),Vector2(actor.facing*34,-8),Color(0.5,0.9,1),7)
	if actor.motion == TianWarrior.Motion.BLINK_WARNING:
		draw_rect(Rect2(actor.blink_offset-24,-80,48,80),Color(1,0.85,0.5,0.3),false,3)
		draw_line(Vector2(0,-40),Vector2(actor.blink_offset,-40),Color(1,0.85,0.5,0.6),2)
	if actor.motion == TianWarrior.Motion.DASH:
		draw_line(Vector2(-actor.facing*90,-40),Vector2(0,-40),color,5)
	draw_colored_polygon(PackedVector2Array([Vector2(-24,0),Vector2(-28,-72),Vector2(-14,-88),Vector2(14,-88),Vector2(28,-72),Vector2(24,0)]),color)
	draw_line(Vector2(-24,-64),Vector2(24,-64),Color(0.2,0.12,0.04),3)
	draw_circle(Vector2(actor.facing*13,-60),4,Color(0.15,0.10,0.03))
	if actor.state == ColorlessEntity.State.ACTIVE and actor.attack_kind != TianWarrior.Attack.RANGED:
		var shape: RectangleShape2D = actor.hit_shape.shape as RectangleShape2D
		draw_rect(Rect2(actor.hitbox.position-shape.size*0.5,shape.size),Color(1,0.25,0.15,0.4))
