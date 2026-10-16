class_name FallingRock
extends Node2D
var speed: float = 700.0
var damage: int = 1
var lifetime: float = 3.0
var resolved: bool = false

func _physics_process(delta: float) -> void:
	if resolved:
		return
	lifetime -= delta
	if lifetime<=0:
		queue_free()
		return
	var end: Vector2 = global_position+Vector2(0,speed*delta)
	var nearest: Dictionary = {}
	var distance: float = INF
	# Three swept rays cover the rock's 32px width, including fast frame movement.
	for x: float in [-16.0,0.0,16.0]:
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position+Vector2(x,0),end+Vector2(x,0),1|16|64)
		query.collide_with_areas = true
		query.hit_from_inside = true
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and global_position.distance_squared_to(hit["position"])<distance:
			nearest = hit
			distance = global_position.distance_squared_to(hit["position"])
	if not nearest.is_empty():
		resolved = true
		var receiver: CombatHurtbox = nearest["collider"] as CombatHurtbox
		if receiver != null:
			receiver.receive_attack(damage,Vector2.DOWN*60,self,get_instance_id())
		queue_free()
		return
	global_position = end
	rotation += delta*3

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-16,-12),Vector2(8,-18),Vector2(18,6),Vector2(-4,16),Vector2(-18,4)]),Color(0.65,0.49,0.35))
