extends "res://tests/pursuit_survey.gd"
var contact_records: Array[Dictionary] = []

func contact_layout(name: String, kind: String) -> void:
	var room: WorldRoom = await create_room(name)
	spawn(kind,room.config.entry_from_previous)
	actor.reparent(room)
	actor.set_physics_process(false)
	await ticks(2)
	var p: EnemyPlatformPursuit = navigation()
	var graph: EnemyPlatformRoutes = EnemyPlatformRoutes.obtain(actor,p,950,320)
	var build_frames: int = 0
	while not graph.ready and build_frames<120:
		# Use the production per-frame budget, not the survey's accelerated build.
		graph.advance(actor,p)
		build_frames += 1
		await ticks(1)
	if not graph.ready:
		check(false,name+" "+kind+" cold graph exceeds 120 frames")
		room.queue_free()
		await ticks(2)
		return
	actor.queue_free()
	await ticks(2)
	var results: Array[Dictionary] = []
	var skipped: int = 0
	for sid: int in range(graph.surfaces.size()):
		var surface: Rect2 = graph.surfaces[sid]
		for side: float in [-1.0,1.0]:
			var start: Vector2 = Vector2(surface.position.x-14 if side<0 else surface.end.x+14,surface.position.y+24-sqrt(24*24-14*14)-0.2)
			var destination: Vector2 = Vector2.INF
			for id: int in range(graph.points.size()):
				if graph.surface_ids[id]==sid and (destination==Vector2.INF or start.distance_to(graph.points[id])<start.distance_to(destination)):
					destination = graph.points[id]
			if destination==Vector2.INF:
				continue
			var probe: Node2D = Node2D.new()
			room.add_child(probe)
			actor = (ACTORS[kind] as PackedScene).instantiate() as ColorlessEntity
			actor.position = start
			actor.target = target
			probe.add_child(actor)
			actor.set_physics_process(false)
			var shape: CollisionShape2D = actor.get_node("BodyCollision") as CollisionShape2D
			var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			query.shape = shape.shape
			query.transform = shape.global_transform
			query.collision_mask = 1
			if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
				skipped += 1
				probe.queue_free()
				await ticks(2)
				continue
			target.position = destination
			actor.alert_to_target()
			var controller: EnemyPlatformPursuit = navigation()
			controller.graph = graph
			controller.graph_mode = true
			controller._graph_target = destination
			actor.set_physics_process(true)
			var settled: bool = false
			for frame: int in range(600):
				await ticks(1)
				if actor.is_on_floor() and controller._flat_contact(actor) and absf(actor.position.y-start.y)<=324:
					settled = true
					break
			results.append({"surface":sid,"side":side,"start":[start.x,start.y],"target":[destination.x,destination.y],"passed":settled,"position":[actor.position.x,actor.position.y],"intent":controller.intent})
			probe.queue_free()
			await ticks(2)
	var failed: Array = results.filter(func(result: Dictionary) -> bool: return not result["passed"])
	contact_records.append({"room":name,"kind":kind,"cases":results,"skipped_overlapping_geometry":skipped,"failures":failed,"cold_build_frames":build_frames})
	check(failed.is_empty(),name+" "+kind+" corner contact perturbations "+str(failed))
	print("CONTACTS ",name," ",kind," cases=",results.size()," skipped=",skipped," failed=",failed.size()," cold_frames=",build_frames)
	room.queue_free()
	await ticks(2)

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	target = Node2D.new()
	world.add_child(target)
	var layouts: Array[String] = ROOMS.duplicate()
	layouts.append_array(["hd_20002_2_open","nszc_10002_2_return","nszc_10002_2_open","final_battlefield_open"])
	for name: String in layouts:
		for kind: String in ["monochrome_entity","tian_warrior"]:
			await contact_layout(name,kind)
	var directory: String = ProjectSettings.globalize_path("res://").path_join("../outputs")
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(directory.path_join("pursuit_contacts.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"records":contact_records},"\t"))
	file.close()
	world.queue_free()
	await ticks(2)
	OS.delay_msec(250)
	print("PURSUIT_CONTACTS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
