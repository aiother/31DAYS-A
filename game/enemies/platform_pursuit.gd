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
var graph_mode: bool = false
var no_path: bool = false
var intent: String = ""
var graph: EnemyPlatformRoutes
var route: Array[Dictionary] = []
var _clock: float = 0.0
var _last_chase: float = 0.0
var _last_progress: float = 0.0
var _observed: Vector2 = Vector2.INF
var _failed_for: float = 0.0
var _executing: bool = false
var _graph_target: Vector2
var _retry: float = 0.0
var _geometry_check: float = 0.0
var _blocked: Dictionary = {}
var _search_direction: float = 1.0
var _search_remaining: float = 0.0

func tick(delta: float) -> void:
	_clock += delta
	_retry = maxf(0,_retry-delta)
	_geometry_check = maxf(0,_geometry_check-delta)
	_search_remaining = maxf(0,_search_remaining-delta)
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
	graph_mode = false
	no_path = false
	intent = ""
	route.clear()
	_executing = false
	_failed_for = 0.0
	_last_progress = _clock
	_observed = Vector2.INF
	_blocked.clear()

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
			# The first body-width may also start partially over a platform edge.
			# Center support plus the full-body sweep permits walking inward, while
			# a departure into a void still fails the center ray immediately.
			var sample: Vector2 = start.lerp(end,i/float(count))
			if sample.distance_to(start)<=32 and actor.is_on_floor() and start.is_equal_approx(actor.global_position):
				var floor_hit: Dictionary = _floor_at(actor, sample.x, sample.y-3, sample.y+5)
				if not floor_hit.is_empty() and (floor_hit["normal"] as Vector2).y < -0.9 and absf((floor_hit["position"] as Vector2).y-sample.y)<3:
					continue
			return false
	return true

func _arc_speed(actor: ColorlessEntity, start: Vector2, end: Vector2, jump_speed: float, horizontal_limit: float = -1.0) -> float:
	var gravity: float = actor.config.gravity
	# A small height margin covers the engine's discrete gravity integration.
	var discriminant: float = jump_speed*jump_speed+2*gravity*(end.y-start.y-8)
	if discriminant <= 0:
		return INF
	var duration: float = (jump_speed+sqrt(discriminant))/gravity
	var vx: float = (end.x-start.x)/duration
	if absf(vx)>(actor.config.speed if horizontal_limit<0 else horizontal_limit):
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

func _drop_route(actor: ColorlessEntity, vx: float, max_drop: float, origin: Vector2 = Vector2.INF, target_limit: float = -INF) -> Dictionary:
	# Simulate walking across the current top surface, then falling naturally.
	# Floor contacts slide along the surface; walls and intermediate landings do
	# not get ignored. A deep gap never becomes permission to leave the edge.
	var start: Vector2 = actor.global_position if origin==Vector2.INF else origin
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
				if drop<=max_drop and point.y<=(actor.target.global_position.y+48 if target_limit == -INF else target_limit) and _supported(actor,point):
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
	if actor.flying or not is_instance_valid(actor.target) or not actor._seen:
		cancel()
		return false
	var dt: float = _clock-_last_chase
	if dt>0.1 or _observed==Vector2.INF or actor.global_position.distance_to(_observed)>2:
		_last_progress = _clock
		_observed = actor.global_position
	_last_chase = _clock
	if graph_mode:
		return _follow_graph(actor,jump_speed,jump_cooldown,max_drop)
	var handled: bool = _local_chase(actor,jump_speed,jump_cooldown,max_drop)
	var offset: Vector2 = actor.target.global_position-actor.global_position
	var needs_route: bool = absf(offset.y)>48 or actor.test_move(actor.global_transform,Vector2(offset.x,0)) or (absf(offset.x)>actor.config.melee_range and not _walkable(actor,actor.global_position,Vector2(actor.target.global_position.x,actor.global_position.y)))
	_failed_for = _failed_for+minf(dt,0.05) if not handled and needs_route and actor.is_on_floor() else 0.0
	if needs_route and (_failed_for>=0.25 or _clock-_last_progress>0.65):
		graph_mode = true
		active = false
		approaching = false
		descending = false
		_graph_target = actor.target.global_position
		return _follow_graph(actor,jump_speed,jump_cooldown,max_drop)
	return handled

func _route_failed() -> void:
	if not route.is_empty() and int(route[0].get("a",-1))>=0:
		var edge: Dictionary = route[0]
		_blocked["%d:%d:%s" % [edge["a"],edge["b"],edge["kind"]]] = _clock+2.0
	route.clear()
	active = false
	approaching = false
	descending = false
	_executing = false
	_retry = 0.0
	_last_progress = _clock

func _resume_combat() -> bool:
	graph_mode = false
	no_path = false
	route.clear()
	intent = ""
	_failed_for = 0
	_executing = false
	active = false
	airborne = false
	approaching = false
	descending = false
	_last_progress = _clock
	return false

func _flat_contact(actor: ColorlessEntity) -> bool:
	var hit: Dictionary = _floor_at(actor,actor.global_position.x,actor.global_position.y-3,actor.global_position.y+5)
	return not hit.is_empty() and (hit["normal"] as Vector2).y < -0.9 and absf((hit["position"] as Vector2).y-actor.global_position.y)<3

func _repair_contact(actor: ColorlessEntity, jump: float, jump_cooldown: float) -> bool:
	if not actor.is_on_floor() or _executing or _flat_contact(actor):
		return false
	var best: Vector2 = Vector2.INF
	var best_speed: float = 0
	var best_jump: float = 0
	var distance: float = INF
	for up: float in [minf(jump,240),minf(jump,400),jump]:
		for point: Vector2 in graph.points:
			if absf(point.x-actor.global_position.x)>128 or absf(point.y-actor.global_position.y)>64:
				continue
			var score: float = point.distance_to(actor.global_position)
			if score>=distance:
				continue
			var speed: float = _arc_speed(actor,actor.global_position,point,up,graph.air_speed)
			if is_finite(speed):
				best = point
				best_speed = speed
				best_jump = up
				distance = score
		if best!=Vector2.INF:
			break
	if best==Vector2.INF:
		# A narrow pocket beside a pillar can forbid every upward arc. Leave
		# the rounded contact only if a full natural descent has a safe landing.
		var escape: Dictionary = {}
		var escape_distance: float = INF
		for side: float in [-1.0,1.0]:
			var candidate: Dictionary = _drop_route(actor,side*actor.config.speed*0.65,graph.max_drop,actor.global_position,INF)
			if not candidate.is_empty() and (candidate["point"] as Vector2).distance_to(actor.target.global_position)<escape_distance:
				escape = candidate
				escape_distance = (candidate["point"] as Vector2).distance_to(actor.target.global_position)
		if escape.is_empty():
			return false
		goal = escape["point"]
		horizontal_speed = escape["speed"]
		route.assign([{"a":-1,"b":-1,"kind":"drop","from":actor.global_position,"goal":goal,"speed":horizontal_speed}])
		actor.velocity.x = horizontal_speed
		active = true
		airborne = false
		descending = true
		approaching = false
		_executing = true
		no_path = false
		travel_remaining = 3.5
		_last_progress = _clock
		intent = "安全下撤后重选路线"
		return true
	actor.velocity.x = 0
	intent = "调整落脚点"
	if cooldown>0:
		_last_progress = _clock
		return true
	route.assign([{"a":-1,"b":-1,"kind":"jump","from":actor.global_position,"goal":best,"speed":best_speed}])
	goal = best
	horizontal_speed = best_speed
	actor.velocity = Vector2(best_speed,-best_jump)
	active = true
	airborne = false
	descending = false
	approaching = false
	_executing = true
	no_path = false
	travel_remaining = 3.5
	cooldown = jump_cooldown
	_last_progress = _clock
	return true

func _follow_graph(actor: ColorlessEntity, jump: float, jump_cooldown: float, max_drop: float) -> bool:
	var offset: Vector2 = actor.target.global_position-actor.global_position
	var engage_range: float = (actor.config as TianConfig).heavy_range if actor.config is TianConfig else actor.config.melee_range
	if actor.is_on_floor() and (not _executing or not airborne) and _flat_contact(actor) and absf(offset.y)<5 and absf(offset.x)<=engage_range and actor._can_see_target():
		return _resume_combat()
	if graph!=null and (not graph.matches_tuning(actor,jump,max_drop) or graph.context.get_ref()!=EnemyPlatformRoutes.room_root(actor)):
		graph = null
		_route_failed()
		_blocked.clear()
	if graph == null:
		graph = EnemyPlatformRoutes.obtain(actor,self,jump,max_drop)
	if _geometry_check==0:
		_geometry_check = 0.5
		if graph.geometry_changed() and actor.is_on_floor():
			EnemyPlatformRoutes.invalidate(actor)
			graph = EnemyPlatformRoutes.obtain(actor,self,jump,max_drop)
			_route_failed()
			_blocked.clear()
	graph.advance(actor,self)
	if not graph.ready:
		intent = "规划路径"
		actor.velocity.x = 0
		return true
	if _repair_contact(actor,jump,jump_cooldown):
		return true
	if not _executing and actor.is_on_floor() and (absf(actor.target.global_position.y-_graph_target.y)>48 or absf(actor.target.global_position.x-_graph_target.x)>128):
		route.clear()
		_retry = 0
	if _executing:
		if not actor.is_on_floor():
			airborne = true
		elif airborne:
			if absf(actor.global_position.y-goal.y)<7 and absf(actor.global_position.x-goal.x)<64:
				route.pop_front()
				_executing = false
				active = false
				airborne = false
				descending = false
				_last_progress = _clock
			else:
				_route_failed()
		if _executing:
			if travel_remaining==0 or _clock-_last_progress>0.65:
				_route_failed()
			else:
				var dx: float = goal.x-actor.global_position.x
				actor.velocity.x = horizontal_speed if dx*horizontal_speed>0 and absf(dx)>3 else 0.0
				intent = "逐台下行" if descending else "跨台追击"
				return true
	if not actor.is_on_floor():
		intent = "等待安全落地"
		return true
	# Landing may finish an edge in this very call. Re-evaluate before taking
	# another edge, or a returned player can be ignored for an entire old route.
	if _flat_contact(actor) and absf(offset.y)<5 and absf(offset.x)<=engage_range and actor._can_see_target():
		return _resume_combat()
	if absf(actor.target.global_position.y-_graph_target.y)>48 or absf(actor.target.global_position.x-_graph_target.x)>128:
		route.clear()
		_retry = 0
	if route.is_empty() and _retry==0:
		for key: String in _blocked.keys():
			if float(_blocked[key])<=_clock:
				_blocked.erase(key)
		var result: Dictionary = graph.find(actor,self,actor.target.global_position,_blocked)
		route.assign(result["route"])
		no_path = result["status"]=="unreachable"
		_graph_target = actor.target.global_position
		_retry = 0.5
	for iteration: int in range(8):
		if route.is_empty():
			if not no_path:
				graph_mode = false
				intent = ""
				_failed_for = 0
				_last_progress = _clock
				return false
			# Keep a safe search/reposition decision alive when the target cannot
			# physically be reached. The caller may apply visible ranged pressure.
			intent = "搜索落点"
			if _search_remaining==0:
				_search_direction *= -1
				_search_remaining = 0.75
			var wanted: Vector2 = actor.global_position+Vector2(_search_direction*64,0)
			if not _walkable(actor,actor.global_position,wanted):
				_search_direction *= -1
				wanted = actor.global_position+Vector2(_search_direction*64,0)
			actor.velocity.x = _search_direction*actor.config.speed*0.5 if _walkable(actor,actor.global_position,wanted) else 0.0
			return false
		var edge: Dictionary = route[0]
		var point: Vector2 = edge["goal"] if edge["kind"]=="walk" else edge["from"]
		if absf(actor.global_position.y-point.y)>5:
			_route_failed()
			return true
		if absf(actor.global_position.x-point.x)>5:
			if not _walkable(actor,actor.global_position,point) or _clock-_last_progress>0.65:
				_route_failed()
				actor.velocity.x = 0
				return true
			approaching = true
			intent = "绕行起跳点"
			actor.velocity.x = signf(point.x-actor.global_position.x)*minf(actor.config.speed,absf(point.x-actor.global_position.x)*60)
			actor.facing = signf(actor.velocity.x)
			return true
		approaching = false
		if edge["kind"]=="walk":
			route.pop_front()
			continue
		if edge["kind"]=="jump" and cooldown>0:
			actor.velocity.x = 0
			_last_progress = _clock
			intent = "准备起跳"
			return true
		var speed: float = float(edge["speed"])
		if edge["kind"]=="jump":
			speed = _arc_speed(actor,actor.global_position,edge["goal"],jump,graph.air_speed)
			if not is_finite(speed):
				_route_failed()
				return true
			actor.velocity.y = -jump
			cooldown = jump_cooldown
		else:
			var checked: Dictionary = _drop_route(actor,speed,max_drop,actor.global_position,INF)
			if checked.is_empty() or (checked["point"] as Vector2).distance_to(edge["goal"])>64:
				_route_failed()
				return true
		goal = edge["goal"]
		horizontal_speed = speed
		actor.velocity.x = speed
		actor.facing = signf(speed) if absf(speed)>1 else actor.facing
		active = true
		airborne = false
		descending = edge["kind"]=="drop"
		_executing = true
		travel_remaining = 3.5
		_last_progress = _clock
		return true
	return true

func _local_chase(actor: ColorlessEntity, jump_speed: float, jump_cooldown: float, max_drop: float = 320.0) -> bool:
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
