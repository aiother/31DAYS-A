class_name EnemyAirPursuit
extends RefCounted
## Full-body free-space routing for advanced flying units; no wall bypass.
static var cache: Dictionary = {}
var intent: String = ""
var path: PackedVector2Array = PackedVector2Array()
var _data: Dictionary = {}
var _clock: float = 0
var _retry: float = 0
var _check: float = 0
var _last_progress: float = 0
var _observed: Vector2 = Vector2.INF
var _destination: Vector2
var _blocked: Dictionary = {}
var _search: int = 0

func tick(delta: float) -> void:
	_clock += delta
	_retry = maxf(0,_retry-delta)
	_check = maxf(0,_check-delta)

func cancel() -> void:
	path.clear()
	intent = ""
	_retry = 0
	_last_progress = _clock
	_observed = Vector2.INF
	_blocked.clear()

static func _release(id: int) -> void:
	cache.erase(id)

func _signature(root: Node) -> int:
	var rects: Array[Rect2] = []
	EnemyPlatformRoutes.new()._collect_shapes(root,rects)
	return hash(rects)

func _obtain(actor: ColorlessEntity) -> Dictionary:
	var root: Node = EnemyPlatformRoutes.room_root(actor)
	var id: int = root.get_instance_id()
	var cleanup: Callable = _release.bind(id)
	if not root.tree_exiting.is_connected(cleanup):
		root.tree_exiting.connect(cleanup,CONNECT_ONE_SHOT)
	if cache.has(id):
		return cache[id]
	var bounds: Rect2
	if root is WorldRoom:
		bounds = (root as WorldRoom).config.bounds
		bounds.position += (root as WorldRoom).global_position
	else:
		bounds = Rect2(actor.global_position,Vector2.ZERO).expand(actor.target.global_position).grow(512)
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO,Vector2i(maxi(1,ceili((bounds.size.x-64)/32)+1),maxi(1,ceili((bounds.size.y-128)/32)+1)))
	grid.cell_size = Vector2(32,32)
	grid.offset = bounds.position+Vector2(32,96)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var result: Dictionary = {"root":weakref(root),"grid":grid,"cursor":0,"ready":false,"signature":_signature(root),"frame":-1,"spent":0}
	cache[id] = result
	return result

func _advance(actor: ColorlessEntity) -> void:
	if _data["ready"]:
		return
	var frame: int = Engine.get_physics_frames()
	if _data["frame"]!=frame:
		_data["frame"] = frame
		_data["spent"] = 0
	if int(_data["spent"])>=1800:
		return
	var started: int = Time.get_ticks_usec()
	var deadline: int = started+1800-int(_data["spent"])
	var grid: AStarGrid2D = _data["grid"]
	var width: int = grid.region.size.x
	var count: int = width*grid.region.size.y
	var shape: CollisionShape2D = actor.get_node("BodyCollision") as CollisionShape2D
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.collision_mask = 1
	while int(_data["cursor"])<count:
		var index: int = _data["cursor"]
		_data["cursor"] = index+1
		var cell: Vector2i = Vector2i(index%width,index/width)
		query.transform = shape.global_transform
		query.transform.origin += grid.get_point_position(cell)-actor.global_position
		grid.set_point_solid(cell,not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())
		if Time.get_ticks_usec()>=deadline:
			break
	_data["spent"] = int(_data["spent"])+Time.get_ticks_usec()-started
	_data["ready"] = int(_data["cursor"])>=count

func _clear(actor: ColorlessEntity, from: Vector2, to: Vector2) -> bool:
	var transform: Transform2D = actor.global_transform
	transform.origin = from
	return not actor.test_move(transform,to-from)

func _visible(actor: ColorlessEntity, point: Vector2) -> bool:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(point-Vector2(0,40),actor.target.global_position-Vector2(0,44),1)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _plan(actor: ColorlessEntity) -> void:
	var grid: AStarGrid2D = _data["grid"]
	var starts: Array[Dictionary] = []
	var goals: Array[Dictionary] = []
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			var cell: Vector2i = Vector2i(x,y)
			if grid.is_point_solid(cell):
				continue
			var point: Vector2 = grid.get_point_position(cell)
			var distance: float = point.distance_to(actor.global_position)
			if distance<192:
				starts.append({"id":cell,"point":point,"score":distance})
			var target_distance: float = point.distance_to(actor.target.global_position)
			if target_distance<=actor.config.ranged_range:
				goals.append({"id":cell,"point":point,"score":distance+target_distance*0.2})
	starts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["score"]<b["score"])
	goals.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["score"]<b["score"])
	var start: Vector2i = Vector2i(-1,-1)
	for candidate: Dictionary in starts:
		if _clear(actor,actor.global_position,candidate["point"]):
			start = candidate["id"]
			break
	if start.x<0:
		return
	var restored: Array[Vector2i] = []
	for cell: Vector2i in _blocked.keys():
		if float(_blocked[cell])<=_clock:
			_blocked.erase(cell)
		elif grid.is_in_boundsv(cell) and not grid.is_point_solid(cell) and cell!=start:
			grid.set_point_solid(cell,true)
			restored.append(cell)
	var attempts: int = 0
	for goal: Dictionary in goals:
		if not _visible(actor,goal["point"]) or grid.is_point_solid(goal["id"]):
			continue
		attempts += 1
		var candidate: PackedVector2Array = grid.get_point_path(start,goal["id"])
		if not candidate.is_empty():
			path = candidate
			break
		if attempts>=32:
			break
	for cell: Vector2i in restored:
		grid.set_point_solid(cell,false)

func chase(actor: ColorlessEntity) -> bool:
	if not is_instance_valid(actor.target) or not actor._seen:
		cancel()
		return false
	var offset: Vector2 = actor.target.global_position-actor.global_position
	if actor._can_see_target():
		if offset.length()<=actor.config.ranged_range:
			path.clear()
			intent = ""
			return false
		# Finish an established detour: switching back to direct pursuit as soon
		# as the torso ray clears can repeatedly cut a body-sized platform corner.
		if path.is_empty() and _clear(actor,actor.global_position,actor.global_position+offset.normalized()*minf(64,offset.length())):
			actor.velocity = offset.normalized()*actor.config.speed
			intent = "飞行追击"
			return true
	var root: Node = EnemyPlatformRoutes.room_root(actor)
	if _data.is_empty() or _data["root"].get_ref()!=root:
		_data = _obtain(actor)
		path.clear()
	if _check==0:
		_check = 0.5
		if int(_data["signature"])!=_signature(root):
			cache.erase(root.get_instance_id())
			_data = _obtain(actor)
			path.clear()
	_advance(actor)
	if not _data["ready"]:
		actor.velocity = Vector2.ZERO
		intent = "规划空中路径"
		return true
	if _observed==Vector2.INF or actor.global_position.distance_to(_observed)>2:
		_observed = actor.global_position
		_last_progress = _clock
	if actor.target.global_position.distance_to(_destination)>64:
		path.clear()
		_retry = 0
	if not path.is_empty() and _clock-_last_progress>0.65:
		var grid: AStarGrid2D = _data["grid"]
		var cell: Vector2i = Vector2i((path[0]-grid.offset)/grid.cell_size)
		_blocked[cell] = _clock+2
		path.clear()
		_retry = 0
	if path.is_empty() and _retry==0:
		_plan(actor)
		_destination = actor.target.global_position
		_retry = 0.5
	while not path.is_empty() and actor.global_position.distance_to(path[0])<4:
		path.remove_at(0)
	if not path.is_empty():
		if not _clear(actor,actor.global_position,path[0]):
			path.clear()
			_retry = 0
		else:
			var delta: Vector2 = path[0]-actor.global_position
			actor.velocity = delta.normalized()*minf(actor.config.speed,delta.length()*60)
			intent = "绕开遮挡追击"
			return true
	intent = "搜索空中通路"
	var directions: Array[Vector2] = [Vector2.LEFT,Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
	_search = int(_clock/0.75)%4
	actor.velocity = Vector2.ZERO
	for i: int in range(4):
		var direction: Vector2 = directions[(_search+i)%4]
		if _clear(actor,actor.global_position,actor.global_position+direction*64):
			actor.velocity = direction*actor.config.speed*0.5
			break
	return true
