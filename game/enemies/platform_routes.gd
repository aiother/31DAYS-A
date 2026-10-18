class_name EnemyPlatformRoutes
extends RefCounted
## Shared, incrementally collision-validated routes across the current Room.
static var cache: Dictionary = {}
const CLEARANCE: float = 28.0
const SAMPLE: float = 64.0
var points: Array[Vector2] = []
var surfaces: Array[Rect2] = []
var surface_ids: Array[int] = []
var edges: Array[Array] = []
var pending: Array[Dictionary] = []
var cursor: int = 0
var ready: bool = false
var signature: int = 0
var context: WeakRef
var built_frame: int = 0
var air_speed: float = 0.0
var jump_speed: float = 0.0
var max_drop: float = 0.0
var ground_speed: float = 0.0
var gravity: float = 0.0
var advance_frame: int = -1
var spent_usec: int = 0

static func room_root(actor: Node) -> Node:
	var node: Node = actor.get_parent()
	while node != null:
		if node is WorldRoom:
			return node
		node = node.get_parent()
	return actor.get_parent()

static func obtain(actor: ColorlessEntity, helper: EnemyPlatformPursuit, jump: float, drop: float) -> EnemyPlatformRoutes:
	var root: Node = room_root(actor)
	var cleanup: Callable = _release.bind(root.get_instance_id())
	if not root.tree_exiting.is_connected(cleanup):
		root.tree_exiting.connect(cleanup,CONNECT_ONE_SHOT)
	var speed: float = actor.config.speed
	if actor.config is MonochromeConfig:
		speed = (actor.config as MonochromeConfig).dash_speed
	elif actor.config is TianConfig:
		speed = (actor.config as TianConfig).dash_speed
	var key: String = "%d:%s:%s:%s:%s:%s" % [root.get_instance_id(), actor.config.speed, speed, jump, drop, actor.config.gravity]
	var graph: EnemyPlatformRoutes = cache.get(key) as EnemyPlatformRoutes
	if graph != null and graph.context.get_ref() != null:
		return graph
	for old: String in cache.keys():
		var item: EnemyPlatformRoutes = cache[old] as EnemyPlatformRoutes
		if item.context.get_ref() == null:
			cache.erase(old)
	graph = EnemyPlatformRoutes.new()
	graph.context = weakref(root)
	graph.air_speed = speed
	graph.jump_speed = jump
	graph.max_drop = drop
	graph.ground_speed = actor.config.speed
	graph.gravity = actor.config.gravity
	graph._collect(actor, helper, root)
	cache[key] = graph
	return graph

static func _release(root_id: int) -> void:
	var prefix: String = str(root_id)+":"
	for key: String in cache.keys():
		if key.begins_with(prefix):
			cache.erase(key)

static func invalidate(actor: ColorlessEntity) -> void:
	var prefix: String = str(room_root(actor).get_instance_id())+":"
	for key: String in cache.keys():
		if key.begins_with(prefix):
			cache.erase(key)

func _collect(actor: ColorlessEntity, helper: EnemyPlatformPursuit, root: Node) -> void:
	var rectangles: Array[Rect2] = []
	_collect_shapes(root, rectangles)
	signature = hash(rectangles)
	rectangles.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y if absf(a.position.y-b.position.y)>1 else a.position.x < b.position.x)
	for rect: Rect2 in rectangles:
		if rect.size.x<CLEARANCE*2:
			continue
		if not surfaces.is_empty() and absf(surfaces[-1].position.y-rect.position.y)<1 and rect.position.x<=surfaces[-1].end.x+1:
			var merged: Rect2 = surfaces[-1]
			merged.size.x = maxf(merged.end.x, rect.end.x)-merged.position.x
			surfaces[-1] = merged
		else:
			surfaces.append(Rect2(rect.position, Vector2(rect.size.x, 0)))
	var shape: CollisionShape2D = actor.get_node("BodyCollision") as CollisionShape2D
	var anchors: Array[float] = []
	_collect_anchors(root,anchors)
	if root is WorldRoom:
		anchors.append((root as WorldRoom).config.entry_from_previous.x+ (root as WorldRoom).global_position.x)
		anchors.append((root as WorldRoom).config.entry_from_next.x+ (root as WorldRoom).global_position.x)
	for sid: int in range(surfaces.size()):
		var span: Rect2 = surfaces[sid]
		var xs: Array[float] = [span.position.x+CLEARANCE, span.end.x-CLEARANCE, span.get_center().x]
		for anchor: float in anchors:
			if anchor>=span.position.x+CLEARANCE and anchor<=span.end.x-CLEARANCE:
				xs.append(anchor)
		var x: float = span.position.x+CLEARANCE+SAMPLE
		while x<span.end.x-CLEARANCE:
			xs.append(x)
			x += SAMPLE
		xs.sort()
		var previous: int = -1
		for px: float in xs:
			var point: Vector2 = Vector2(px, span.position.y)
			if previous>=0 and points[previous].distance_to(point)<2:
				continue
			if not helper._supported(actor, point):
				continue
			var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			query.shape = shape.shape
			query.transform = shape.global_transform
			query.transform.origin += point-actor.global_position-Vector2(0,0.2)
			query.collision_mask = 1
			if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
				continue
			var id: int = points.size()
			points.append(point)
			surface_ids.append(sid)
			edges.append([])
			if previous>=0 and helper._walkable(actor, points[previous], point):
				_add(previous,id,"walk",actor.config.speed,point)
				_add(id,previous,"walk",actor.config.speed,points[previous])
			previous = id
	var height: float = jump_speed*jump_speed/(2*actor.config.gravity)-12
	for a: int in range(points.size()):
		for b: int in range(points.size()):
			if surface_ids[a]==surface_ids[b]:
				continue
			var delta: Vector2 = points[b]-points[a]
			if delta.y < -height or delta.y>max_drop:
				continue
			var duration: float = (jump_speed+sqrt(maxf(0,jump_speed*jump_speed+2*actor.config.gravity*(delta.y-8))))/actor.config.gravity
			if absf(delta.x)<=air_speed*duration:
				pending.append({"a":a,"b":b,"kind":"jump"})
		# Natural edge departures also work below ceilings that forbid jumping.
		if a==0 or a==points.size()-1 or (a>0 and surface_ids[a-1]!=surface_ids[a]) or (a+1<points.size() and surface_ids[a+1]!=surface_ids[a]):
			for side: float in [-1.0,1.0]:
				for ratio: float in [1.0,0.65]:
					pending.append({"a":a,"kind":"drop","speed":side*actor.config.speed*ratio})
	built_frame = Engine.get_physics_frames()

func geometry_changed() -> bool:
	var root: Node = context.get_ref() as Node
	if root == null:
		return true
	var rectangles: Array[Rect2] = []
	_collect_shapes(root,rectangles)
	return hash(rectangles)!=signature

func matches_tuning(actor: ColorlessEntity, jump: float, drop: float) -> bool:
	var burst: float = actor.config.speed
	if actor.config is MonochromeConfig:
		burst = (actor.config as MonochromeConfig).dash_speed
	elif actor.config is TianConfig:
		burst = (actor.config as TianConfig).dash_speed
	return is_equal_approx(jump_speed,jump) and is_equal_approx(max_drop,drop) and is_equal_approx(ground_speed,actor.config.speed) and is_equal_approx(air_speed,burst) and is_equal_approx(gravity,actor.config.gravity)

func _collect_anchors(node: Node, anchors: Array[float]) -> void:
	if node is CharacterBody2D or node is ColorlessProjectile or node.is_in_group("navigation_transients"):
		return
	if node is Node2D and not node is CollisionShape2D:
		anchors.append((node as Node2D).global_position.x)
	for child: Node in node.get_children():
		_collect_anchors(child,anchors)

func _collect_shapes(node: Node, rectangles: Array[Rect2]) -> void:
	if node is TileMapLayer:
		var layer: TileMapLayer = node as TileMapLayer
		if layer.enabled and layer.collision_enabled and layer.tile_set != null:
			var tops: Dictionary = {}
			for cell: Vector2i in layer.get_used_cells():
				if not tops.has(cell.x) or cell.y<int(tops[cell.x]):
					tops[cell.x] = cell.y
			for column: int in tops:
				var size: Vector2 = Vector2(layer.tile_set.tile_size)
				var center: Vector2 = layer.map_to_local(Vector2i(column,int(tops[column])))
				var left: Vector2 = layer.to_global(center-size*0.5)
				var right: Vector2 = layer.to_global(center+Vector2(size.x*0.5,-size.y*0.5))
				rectangles.append(Rect2(Vector2(minf(left.x,right.x),left.y),Vector2(absf(right.x-left.x),size.y)))
	elif node is StaticBody2D and ((node as StaticBody2D).collision_layer & 1)!=0:
		for child: Node in node.get_children():
			if child is CollisionShape2D and not (child as CollisionShape2D).disabled and (child as CollisionShape2D).shape is RectangleShape2D:
				var collision: CollisionShape2D = child as CollisionShape2D
				var half: Vector2 = (collision.shape as RectangleShape2D).size*0.5
				var rect: Rect2 = Rect2(collision.to_global(-half),Vector2.ZERO)
				for corner: Vector2 in [Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)]:
					rect = rect.expand(collision.to_global(corner))
				rectangles.append(rect)
	for child: Node in node.get_children():
		_collect_shapes(child,rectangles)

func _add(a: int, b: int, kind: String, speed: float, landing: Vector2) -> void:
	var time: float = points[a].distance_to(landing)/maxf(absf(speed),1)+0.2
	edges[a].append({"a":a,"b":b,"kind":kind,"speed":speed,"from":points[a],"goal":landing,"cost":time})

func advance(actor: ColorlessEntity, helper: EnemyPlatformPursuit, budget_usec: int = 1800) -> void:
	if ready:
		return
	var frame: int = Engine.get_physics_frames()
	if advance_frame!=frame:
		advance_frame = frame
		spent_usec = 0
	if spent_usec>=budget_usec:
		return
	var started: int = Time.get_ticks_usec()
	var deadline: int = started+budget_usec-spent_usec
	while cursor<pending.size():
		var entry: Dictionary = pending[cursor]
		cursor += 1
		var a: int = entry["a"]
		if entry["kind"]=="jump":
			var b: int = entry["b"]
			var speed: float = helper._arc_speed(actor,points[a],points[b],jump_speed,air_speed)
			if is_finite(speed):
				_add(a,b,"jump",speed,points[b])
		else:
			var route: Dictionary = helper._drop_route(actor,entry["speed"],max_drop,points[a],INF)
			if not route.is_empty():
				var point: Vector2 = route["point"]
				var nearest: int = -1
				var distance: float = INF
				for b: int in range(points.size()):
					if absf(points[b].y-point.y)<4 and points[b].distance_to(point)<distance and helper._walkable(actor,point,points[b]):
						nearest = b
						distance = points[b].distance_to(point)
				if nearest>=0:
					_add(a,nearest,"drop",entry["speed"],point)
		if Time.get_ticks_usec()>=deadline:
			spent_usec += Time.get_ticks_usec()-started
			return
	spent_usec += Time.get_ticks_usec()-started
	ready = true

func find(actor: ColorlessEntity, helper: EnemyPlatformPursuit, destination: Vector2, blocked: Dictionary = {}) -> Dictionary:
	if not ready:
		return {"status":"building","route":[]}
	var costs: Array[float] = []
	var previous: Array[Dictionary] = []
	var open: Array[int] = []
	for id: int in range(points.size()):
		costs.append(INF)
		previous.append({})
		if absf(points[id].y-actor.global_position.y)<4 and helper._walkable(actor,actor.global_position,points[id]):
			costs[id] = actor.global_position.distance_to(points[id])/actor.config.speed
			open.append(id)
	var floor_hit: Dictionary = helper._floor_at(actor,destination.x,destination.y-3,destination.y+1024)
	var target_floor: Vector2 = floor_hit.get("position",destination)
	var goal_ids: Array[int] = []
	var anchor: int = -1
	var anchor_distance: float = INF
	for id: int in range(points.size()):
		var span: Rect2 = surfaces[surface_ids[id]]
		if absf(points[id].y-target_floor.y)<4 and target_floor.x>=span.position.x-2 and target_floor.x<=span.end.x+2:
			var distance: float = points[id].distance_to(target_floor)
			if distance<anchor_distance:
				anchor = id
				anchor_distance = distance
	# A wall can partition one collinear floor span into separate components.
	# Target the nearest safe point itself, never any point on that whole span.
	if anchor>=0:
		goal_ids.append(anchor)
	while not open.is_empty():
		open.sort_custom(func(a: int,b: int) -> bool: return costs[a]<costs[b])
		var a: int = open.pop_front()
		for edge: Dictionary in edges[a]:
			var key: String = "%d:%d:%s" % [a,edge["b"],edge["kind"]]
			if blocked.has(key):
				continue
			var b: int = edge["b"]
			var next: float = costs[a]+float(edge["cost"])
			if next<costs[b]:
				costs[b] = next
				previous[b] = edge
				if not open.has(b):
					open.append(b)
	var goal: int = -1
	var best: float = INF
	for id: int in goal_ids:
		var score: float = costs[id]+points[id].distance_to(target_floor)/actor.config.speed
		if score<best:
			best = score
			goal = id
	var reachable: bool = goal>=0 and target_floor.y-destination.y<=48
	if not reachable:
		for id: int in range(points.size()):
			if not is_finite(costs[id]):
				continue
			var score: float = points[id].distance_to(destination)+costs[id]*4
			if score<best:
				best = score
				goal = id
	if goal<0:
		return {"status":"unreachable","route":[]}
	var route: Array[Dictionary] = []
	var at: int = goal
	while not previous[at].is_empty():
		var edge: Dictionary = previous[at]
		route.push_front(edge)
		at = edge["a"]
	route.push_front({"a":-1,"b":at,"kind":"walk","from":actor.global_position,"goal":points[at],"speed":actor.config.speed})
	return {"status":"route" if reachable else "unreachable","route":route,"target_floor":target_floor}
