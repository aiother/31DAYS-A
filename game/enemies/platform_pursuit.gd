class_name EnemyPlatformPursuit
extends RefCounted
## Local, collision-checked ballistic steps. No teleport or collision bypass.
var active: bool = false
var airborne: bool = false
var goal: Vector2
var horizontal_speed: float = 0
var cooldown: float = 0
var repath: float = 0
var launch: Vector2
var approaching: bool = false
var descending: bool = false
var travel_remaining: float = 0

func tick(delta: float) -> void:
	cooldown = maxf(0, cooldown-delta)
	repath = maxf(0, repath-delta)
	travel_remaining = maxf(0, travel_remaining-delta)

func cancel() -> void:
	active = false
	airborne = false
	approaching = false
	descending = false
	travel_remaining = 0
	repath = 0

func _floor_at(actor: CharacterBody2D, x: float, top: float, bottom: float) -> Dictionary:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2(x,top), Vector2(x,bottom), 1)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray)

func _supported(actor: CharacterBody2D, point: Vector2) -> bool:
	for dx: float in [-27.0, 0.0, 27.0]:
		var hit: Dictionary = _floor_at(actor, point.x+dx, point.y-3, point.y+5)
		if hit.is_empty() or (hit["normal"] as Vector2).y > -0.9 or absf((hit["position"] as Vector2).y-point.y)>3:
			return false
	return true

func _walkable(actor: CharacterBody2D, start: Vector2, end: Vector2) -> bool:
	var transform: Transform2D = actor.global_transform
	transform.origin = start
	if actor.test_move(transform, end-start):
		return false
	var count: int = maxi(1, ceili(absf(end.x-start.x)/16))
	for i: int in range(count+1):
		if not _supported(actor, start.lerp(end, i/float(count))):
			return false
	return true

func _arc_speed(actor: ColorlessEntity, start: Vector2, end: Vector2, jump_speed: float) -> float:
	var gravity: float = actor.config.gravity
	# A small height margin covers the engine's discrete gravity integration.
	var discriminant: float = jump_speed*jump_speed+2*gravity*(end.y-start.y-8)
	if discriminant <= 0:
		return INF
	var duration: float = (jump_speed+sqrt(discriminant))/gravity
	var vx: float = (end.x-start.x)/duration
	if absf(vx)>actor.config.speed:
		return INF
	var transform: Transform2D = actor.global_transform
	transform.origin = start-Vector2(0,1)
	var vy: float = -jump_speed
	var step: float = 1.0/60.0
	for i: int in range(90):
		var motion: Vector2 = Vector2(vx,vy)*step
		var collision: KinematicCollision2D = KinematicCollision2D.new()
		if actor.test_move(transform,motion,collision,0.02):
			var landing: Vector2 = transform.origin+collision.get_travel()
			if vy>0 and collision.get_normal().y < -0.9 and absf(landing.y-end.y)<5 and absf(landing.x-end.x)<30:
				return vx
			return INF
		transform.origin += motion
		vy += gravity*step
		if vy>0 and transform.origin.y>end.y+8:
			return INF
	return INF

func _drop_route(actor: ColorlessEntity, vx: float, max_drop: float) -> Dictionary:
	# Simulate walking across the current top surface, then falling naturally.
	# Floor contacts slide along the surface; walls and intermediate landings do
	# not get ignored. A deep gap never becomes permission to leave the edge.
	var start: Vector2 = actor.global_position
	var transform: Transform2D = actor.global_transform
	transform.origin = start-Vector2(0,0.1)
	var vy: float = 0
	var step: float = 1.0/60.0
	for i: int in range(180):
		vy = minf(1500,vy+actor.config.gravity*step)
		var motion: Vector2 = Vector2(vx,vy)*step
		var collision: KinematicCollision2D = KinematicCollision2D.new()
		if actor.test_move(transform,motion,collision,0.02):
			var normal: Vector2 = collision.get_normal()
			if normal.y > -0.7:
				return {}
			transform.origin += collision.get_travel()
			var drop: float = transform.origin.y-start.y
			if drop>32:
				var point: Vector2 = transform.origin
				if drop<=max_drop and point.y<=actor.target.global_position.y+48 and _supported(actor,point):
					return {"point":point,"speed":vx}
				return {}
			var slide: Vector2 = collision.get_remainder().slide(normal)
			if actor.test_move(transform,slide):
				return {}
			transform.origin += slide
			vy = 0
		else:
			transform.origin += motion
		if transform.origin.y-start.y>max_drop+4:
			return {}
	return {}

func _start_descent(actor: ColorlessEntity, max_drop: float) -> bool:
	if repath>0:
		return false
	repath = 0.25
	var direction: float = signf(actor.target.global_position.x-actor.global_position.x)
	if direction==0: direction = actor.facing
	var best: Dictionary = {}
	var score: float = INF
	for ratio: float in [1.0,0.65]:
		for side: float in [direction,-direction]:
			var route: Dictionary = _drop_route(actor,side*actor.config.speed*ratio,max_drop)
			if route.is_empty(): continue
			var distance: float = (route["point"] as Vector2).distance_to(actor.target.global_position)
			if distance<score:
				best = route
				score = distance
		if not best.is_empty(): break
	if best.is_empty():
		return false
	goal = best["point"]
	horizontal_speed = best["speed"]
	active = true
	airborne = false
	descending = true
	approaching = false
	travel_remaining = 3.5
	actor.velocity.x = horizontal_speed
	actor.facing = signf(horizontal_speed)
	return true

func chase(actor: ColorlessEntity, jump_speed: float, jump_cooldown: float, max_drop: float = 320.0) -> bool:
	if actor.flying or not is_instance_valid(actor.target):
		cancel()
		return false
	if active:
		if travel_remaining==0 or (descending and not airborne and actor.is_on_floor() and actor.target.global_position.y<=actor.global_position.y+48):
			cancel()
			return false
		if not actor.is_on_floor():
			airborne = true
		elif airborne:
			active = false
			airborne = false
			descending = false
			repath = 0
			return false
		actor.velocity.x = horizontal_speed if absf(actor.global_position.x-goal.x)>6 else 0.0
		actor.facing = signf(horizontal_speed) if absf(horizontal_speed)>1 else actor.facing
		return true
	if not actor.is_on_floor() or not actor._seen:
		approaching = false
		return false
	if actor.target.global_position.y>actor.global_position.y+48:
		approaching = false
		return _start_descent(actor,max_drop)
	if actor.target.global_position.y>=actor.global_position.y-48:
		approaching = false
		return false
	if approaching:
		if not _walkable(actor, actor.global_position, Vector2(launch.x,actor.global_position.y)):
			approaching = false
		elif absf(actor.global_position.x-launch.x)>5:
			actor.velocity.x = signf(launch.x-actor.global_position.x)*actor.config.speed
			actor.facing = signf(actor.velocity.x)
			return true
		else:
			approaching = false
			repath = 0
	if cooldown>0 or repath>0:
		return false
	repath = 0.25
	var start: Vector2 = actor.global_position
	var height: float = jump_speed*jump_speed/(2*actor.config.gravity)-12
	var reach: float = actor.config.speed*2*jump_speed/actor.config.gravity
	var candidates: Array[Vector2] = []
	for i: int in range(-ceili(reach/32), ceili(reach/32)+1):
		var x: float = start.x+i*32
		var hit: Dictionary = _floor_at(actor,x,start.y-height,start.y-40)
		if hit.is_empty() or (hit["normal"] as Vector2).y > -0.9:
			continue
		var point: Vector2 = hit["position"]
		if point.y < actor.target.global_position.y-16 or not _supported(actor,point):
			continue
		candidates.append(point)
	candidates.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.distance_to(actor.target.global_position)<b.distance_to(actor.target.global_position))
	# Prefer an immediate jump; only then consider walking clear of an overhang.
	for dx: float in [0.0,-96.0,96.0,-192.0,192.0]:
		var from: Vector2 = start+Vector2(dx,0)
		if dx!=0 and not _walkable(actor,start,from):
			continue
		for point: Vector2 in candidates.slice(0,8):
			var vx: float = _arc_speed(actor,from,point,jump_speed)
			if not is_finite(vx):
				continue
			if dx!=0:
				launch = from
				approaching = true
				actor.velocity.x = signf(dx)*actor.config.speed
				return true
			goal = point
			horizontal_speed = vx
			active = true
			airborne = false
			descending = false
			travel_remaining = 3.5
			cooldown = jump_cooldown
			actor.velocity = Vector2(vx,-jump_speed)
			return true
	return false
