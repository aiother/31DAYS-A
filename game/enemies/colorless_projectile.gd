class_name ColorlessProjectile
extends Node2D
## A thrown object, not a bullet: horizontal/up player attacks can reflect it.
var source: Node2D
var velocity: Vector2 = Vector2.LEFT * 300.0
var reflected: bool = false
var _life: float = 5.0
@onready var hurtbox: CombatHurtbox = $Hurtbox

func reflect(attacker: Node2D, impulse: Vector2) -> bool:
	if reflected or impulse.y > 0.0:
		return false
	reflected = true
	source = attacker
	velocity = -velocity.normalized() * 260.0
	_life = 1.2
	hurtbox.set_deferred("monitorable", false)
	queue_redraw()
	return true

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if reflected:
		velocity.y += 450.0 * delta
	var end: Vector2 = global_position + velocity * delta
	var mask: int = 1 | (16 if reflected else 64)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, end, mask)
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = [hurtbox.get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var receiver: CombatHurtbox = hit["collider"] as CombatHurtbox
		if receiver != null:
			receiver.receive_attack(5 if reflected else 1, velocity.normalized() * 100.0, source if is_instance_valid(source) else self, get_instance_id())
		queue_free()
		return
	global_position = end
	rotation += delta * 8.0

func _draw() -> void:
	var color: Color = Color(0.4, 0.92, 0.95) if reflected else Color(0.95, 0.66, 0.4)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(12, 0), Vector2(0, 9), Vector2(-12, 0)]), color)
