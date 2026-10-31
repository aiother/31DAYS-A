extends SceneTree
## Static viewport audit of production Rooms. No gameplay/save progression runs.
const OUTPUT: String = "res://../codexandclaude/tasks/SYS-013/captures"
var session: FinalBattleSession
var camera: GameplayCamera
var caption: Label
var report: Dictionary = {"viewport":[1920,1080], "method":"static production Room/platform probes; gameplay disabled; not a traversal or AI timing proof", "rooms":[], "bosses":[]}

func _initialize() -> void:
	run.call_deferred()

func point(value: Vector2) -> Array:
	return [value.x, value.y]

func rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

func view() -> Rect2:
	var size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size * 0.5, size)

func frame() -> void:
	await process_frame
	await process_frame
	camera.force_update_scroll()
	await RenderingServer.frame_post_draw

func screenshot(name: String, text: String) -> String:
	caption.text = text
	await frame()
	var path: String = OUTPUT.path_join(name + ".png")
	assert(root.get_texture().get_image().save_png(path) == OK)
	return "captures/" + name + ".png"

func run() -> void:
	assert(DisplayServer.get_name() != "headless", "rendering required for real screenshots")
	root.size = Vector2i(1920,1080)
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) == OK)
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	# Even unexpected code paths cannot write a real save. We do not start_slot
	# or change_room: only mount_room, with physics/session processing disabled.
	var temporary: String = OS.get_cache_dir().path_join("31days_sys013_audit_%d" % OS.get_process_id())
	session.save_directory = temporary
	session.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(session)
	current_scene = session
	session.slot = 1
	session.data = session.store.fresh()
	for child: Node in session.get_children():
		if child is CanvasLayer: (child as CanvasLayer).hide()
	camera = session.player.get_node("Camera2D") as GameplayCamera
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(20,20)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 8)
	layer.add_child(caption)
	var ids: Array = session._room_scenes().keys()
	ids.sort()
	for id: String in ids:
		session._mount_room(id)
		var room: WorldRoom = session.room
		if room.config.bounds.size.y <= 1080.0: continue
		var platforms: Array[Dictionary] = []
		for node: Node in room.find_children("*", "StaticBody2D", true, false):
			if absf((node as Node2D).rotation) < 0.01:
				var shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if shape != null and shape.shape is RectangleShape2D:
					var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
					if rectangle.size.x * shape.global_scale.x < rectangle.size.y * shape.global_scale.y: continue
					var top: Vector2 = shape.to_global(Vector2(0,-rectangle.size.y * 0.5))
					platforms.append({"name":String(room.get_path_to(node)), "point":top})
		var probes: Array[Dictionary] = [{"name":"entry", "point":room.to_global(room.config.entry_from_previous)}]
		probes.append_array(platforms)
		var item: Dictionary = {"id":id, "bounds":rect(room.config.bounds), "platforms":[], "samples":[]}
		for platform: Dictionary in platforms: item["platforms"].append({"name":platform["name"],"point":point(platform["point"])})
		var highest: int = 0
		for index: int in range(probes.size()):
			if Vector2(probes[index]["point"]).y < Vector2(probes[highest]["point"]).y: highest = index
		for index: int in range(probes.size()):
			var probe: Dictionary = probes[index]
			session.player.global_position = probe["point"]
			camera.zoom = Vector2(camera.normal_zoom,camera.normal_zoom)
			camera.position = Vector2(0,-camera.feet_lift(1080.0))
			camera.reset_smoothing()
			await frame()
			var visible: Rect2 = view()
			var sample: Dictionary = {"at":probe["name"], "feet":point(probe["point"]), "view":rect(visible), "above":[], "below":[]}
			for target: Dictionary in platforms:
				var destination: Vector2 = target["point"]
				if destination.y < visible.position.y: sample["above"].append(target["name"])
				elif destination.y > visible.end.y: sample["below"].append(target["name"])
			if index == 0 or index == highest:
				sample["screenshot"] = await screenshot(id + "_" + str(index), "%s | %s feet=%s | zoom=%s\nStatic platform probe: above=%s below=%s" % [id,probe["name"],str(probe["point"]),str(camera.normal_zoom),str(sample["above"]),str(sample["below"])])
			item["samples"].append(sample)
		report["rooms"].append(item)
	for id: String in [BossSession.BOSS_ID, ParasiteSession.PARASITE_ID]:
		session._mount_room(id)
		var actor: Node2D = session.room.get_node("Boss") as Node2D
		var floor_y: float = actor.config.floor_y
		for side: String in ["near", "far"]:
			var actor_x: float = 960.0 if side == "near" else 1760.0
			session.player.position = Vector2(800 if side == "near" else 160, floor_y)
			actor.position = Vector2(actor_x,floor_y - (360 if actor is OverlookBoss else 0))
			if actor is OverlookBoss:
				(actor as OverlookBoss).state = OverlookBoss.State.WINDUP
				(actor as OverlookBoss).impact_x = session.player.position.x
			else: (actor as ParasiteBoss).state = ParasiteBoss.State.WINDUP
			actor.queue_redraw()
			camera.zoom = Vector2(camera.battle_zoom,camera.battle_zoom)
			camera.position = Vector2((actor_x - session.player.position.x) * 0.35, -camera.feet_lift(1080.0, camera.battle_zoom))
			camera.reset_smoothing()
			await frame()
			var visible: Rect2 = view()
			var cue: Vector2 = actor.global_position + Vector2(0,-48)
			var item: Dictionary = {"id":id, "case":side, "feet":point(session.player.position), "actor":point(actor.position), "cue":point(cue), "view":rect(visible), "cue_visible":visible.has_point(cue), "zoom":camera.zoom.x}
			item["screenshot"] = await screenshot(id + "_" + side, "%s | %s windup boundary probe | zoom=%.3f\nPlayer=%s Boss=%s cue visible=%s" % [id,side,camera.zoom.x,str(session.player.position),str(actor.position),str(item["cue_visible"])])
			report["bosses"].append(item)
	var output: FileAccess = FileAccess.open(OUTPUT.path_join("audit.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  ") + "\n")
	output.close()
	session.queue_free()
	layer.queue_free()
	await process_frame
	await process_frame
	if DirAccess.dir_exists_absolute(temporary):
		for file: String in DirAccess.get_files_at(temporary): DirAccess.remove_absolute(temporary.path_join(file))
		DirAccess.remove_absolute(temporary)
	print("CAMERA_AUDIT rooms=%d boss_probes=%d failures=0" % [report["rooms"].size(),report["bosses"].size()])
	quit()
