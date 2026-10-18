class_name EnemyPlatformPursuit
extends RefCounted
## Local, collision-checked ballistic steps. No teleport or collision bypass.
const APPROACH_STEP: float = 96.0
const APPROACH_STEPS: int = 10
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
			# At a wall contact the extra-wide side probe may start inside the
			# raised tile. A real supported body can still walk away from it.
			# Only relax the origin; every subsequent sample and landing stays strict.
			if i == 0 and actor.is_on_floor() and start.is_equal_approx(actor.global_position):
				var floor_hit: Dictionary = _floor_at(actor, start.x, start.y-3, start.y+5)
				if not floor_hit.is_empty() and (floor_hit["normal"] as Vector2).y < -0.9 and absf((floor_hit["position"] as Vector2).y-start.y)<3:
					continue
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
	var offset: Vector2 = actor.target.global_position-actor.global_position
	# Same-level targets can be separated by a solid step. Check the full
	# horizontal segment so backing away does not cancel the obstacle route.
	var crossing_obstacle: bool = absf(offset.y)<=48 and absf(offset.x)>1 and actor.test_move(actor.global_transform, Vector2(offset.x, 0))
	if actor.target.global_position.y>=actor.global_position.y-48 and not crossing_obstacle:
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
	var best_score: float = INF
	var best_point: Vector2
	var best_from: Vector2
	var best_speed: float = 0.0
	# A target directly overhead can require walking away across several solid
	# overhangs before the first lower step becomes reachable. Search launch
	# positions on the connected floor; never relax support or arc collision.
	for index: int in range(APPROACH_STEPS * 2 + 1):
		var dx: float = 0.0 if index == 0 else ceilf(index / 2.0) * APPROACH_STEP * (-1.0 if index % 2 == 1 else 1.0)
		if absf(dx)*0.25 >= best_score:
			break
		var from: Vector2 = start + Vector2(dx, 0)
		if dx != 0 and not _walkable(actor, start, from):
			continue
		var candidates: Array[Vector2] = []
		# Scan from this launch, rather than starving a detour of landing points
		# outside the jump radius of the actor's original position.
		for i: int in range(-ceili(reach / 32), ceili(reach / 32) + 1):
			var x: float = from.x + i * 32
			var hit: Dictionary = _floor_at(actor, x, start.y - height, start.y - 40)
			if hit.is_empty() or (hit["normal"] as Vector2).y > -0.9:
				continue
			var point: Vector2 = hit["position"]
			if not _supported(actor, point):
				continue
			if crossing_obstacle:
				# Climb a supported intermediate top toward the blocked target,
				# then use the existing safe descent after reaching its top.
				if (point.x-start.x)*signf(offset.x)<=0 or absf(point.x-actor.target.global_position.x)>=absf(offset.x):
					continue
			elif point.y < actor.target.global_position.y - 16:
				continue
			candidates.append(point)
		candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(actor.target.global_position) < b.distance_to(actor.target.global_position))
		for point: Vector2 in candidates:
			# Compare the useful landing, not just the first possible jump.
			# A platform behind us must not win over a short backstep onto
			# the actual obstacle separating us from the target.
			var score: float = point.distance_to(actor.target.global_position)+absf(dx)*0.25
			if score >= best_score:
				continue
			var vx: float = _arc_speed(actor,from,point,jump_speed)
			if not is_finite(vx):
				continue
			best_score = score
			best_point = point
			best_from = from
			best_speed = vx
	if is_finite(best_score):
		if absf(best_from.x-start.x)>1:
			launch = best_from
			approaching = true
			actor.velocity.x = signf(launch.x-start.x)*actor.config.speed
			return true
		goal = best_point
		horizontal_speed = best_speed
		active = true
		airborne = false
		descending = false
		travel_remaining = 3.5
		cooldown = jump_cooldown
		actor.velocity = Vector2(horizontal_speed,-jump_speed)
		return true
	return false
