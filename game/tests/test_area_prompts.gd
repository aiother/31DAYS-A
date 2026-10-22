# verify-suite: {"name": "area name banner, interaction prompts and key item highlight on real rooms", "path": "res://tests/test_area_prompts.gd", "marker": "AREA_PROMPTS_TESTS checks=", "fixed_fps": 60, "timeout": 180}
extends SceneTree
## UI-007: the area name (BL-045) and the interaction prompt with key item
## highlight (BL-049, A-019) on the real session, real Rooms and the SYS-009
## interaction query. Assertions read what was drawn.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
## Extra targets added on top of the real query, for cases no single Room
## has (two usable objects at once, screen edges, the HUD corner).
var extra: Array[Dictionary] = []

class WithExtras extends "res://world/final_battle_session.gd":
	var extras: Callable
	func interaction_targets() -> Array[Dictionary]:
		var result: Array[Dictionary] = super.interaction_targets()
		if extras.is_valid():
			result.append_array(extras.call())
		return result

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
	return ok

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func banner() -> AreaBanner:
	return session.ui.get("_area_banner") as AreaBanner

func prompt() -> InteractPrompt:
	return session.ui.get("_interact_prompt") as InteractPrompt

func hud() -> FormalHud:
	return session.ui.get("_hud") as FormalHud

func quiet() -> void:
	session.set_physics_process(false)
	session.player.set_physics_process(false)
	session.player.life.protection_remaining = 1000.0
	for node: Node in session.room.find_children("*", "Node", true, false):
		if node is ColorlessEntity or node is RoomRockfall or node is OverlookBoss or node is ParasiteBoss:
			node.set_physics_process(false)

func fresh() -> Dictionary:
	var value: Dictionary = session.store.fresh()
	value["events"][StartRoomSession.BIRTH] = true
	value["events"][WorldDayRules.ENABLED] = true
	return value

func open() -> void:
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	# Swapping the script resets exported values (e.g. ground_path); carry
	# every stored script property across.
	var kept: Dictionary = {}
	for property: Dictionary in session.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and property["usage"] & PROPERTY_USAGE_STORAGE:
			kept[property["name"]] = session.get(property["name"])
	session.set_script(WithExtras)
	for name: String in kept:
		session.set(name, kept[name])
	session.set("extras", func() -> Array[Dictionary]: return extra)
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	check(session.store.save_slot(1, fresh()) and session.start_slot(1, false), "isolated real save starts")
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	await frames(4)
	quiet()

func close() -> void:
	paused = false
	extra.clear()
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	OS.delay_msec(500)

## Mounts a Room the way the sessions do and frees the player to act.
func enter(id: String) -> void:
	session._mount_room(id)
	session._bind_room()
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	quiet()
	await frames(3)

## Waits until the banner has shown and gone, returning the area it drew.
func banner_shown(limit: int = 240) -> Dictionary:
	var seen: Dictionary = {}
	for i: int in range(limit):
		if banner().drawn.has("area") and seen.is_empty():
			seen = banner().drawn.duplicate(true)
		await frames(1)
	return seen

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_area_prompts_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	await open()
	await area_cases()
	await prompt_cases()
	await placement_cases()
	await highlight_cases()
	await close()
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("AREA_PROMPTS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func expected(id: String) -> PackedStringArray:
	return session.room.config.display_name.split(" · ", true, 1) if session.room.config.room_id == id else PackedStringArray()

func area_cases() -> void:
	var loaded: Dictionary = await banner_shown()
	var parts: PackedStringArray = session.room.config.display_name.split(" · ", true, 1)
	check(loaded.get("area", {}).get("text") == parts[0], "loading a slot shows its area name")
	check(parts.size() < 2 or loaded.get("place", {}).get("text") == parts[1], "with the Room's own part under it")
	var box: Rect2 = loaded.get("rect", Rect2())
	check(absf(box.get_center().x - 960.0) < 2.0 and box.position.y > 380.0 and box.end.y < 700.0, "in the middle of the screen")
	check(not banner().drawn.has("area"), "and fades out")
	await enter(TwoRoomSession.ENTRY_ID)
	var entry: Dictionary = await banner_shown()
	check(entry.get("area", {}).get("text") == session.room.config.display_name.split(" · ", true, 1)[0], "a Room of another area shows its name")
	await enter("HD_10002_2")
	var same: Dictionary = await banner_shown(120)
	check(same.is_empty() and session.room.config.scene_id == "Region_HD_Scene_10002", "a Room of the same area shows nothing")
	# Waits while a story scene holds the player, then shows.
	session._mount_room("HD_10003_1")
	session._bind_room()
	quiet()
	session.intro_active = true
	await frames(30)
	check(not banner().drawn.has("area") and not banner().pending.is_empty(), "a story scene keeps the name waiting")
	session.intro_active = false
	var after_story: Dictionary = await banner_shown(60)
	check(after_story.get("area", {}).get("text") == session.room.config.display_name.split(" · ", true, 1)[0], "it shows once the story scene ends")
	await frames(200)
	# A newer area replaces a name still on screen.
	await enter("HD_20002_1")
	await frames(20)
	var first: String = str(banner().drawn.get("area", {}).get("text", ""))
	session._mount_room(ExplorationSession.EXPLORATION_ID)
	session._bind_room()
	quiet()
	await frames(6)
	check(not first.is_empty() and banner().drawn.get("area", {}).get("text") == session.room.config.display_name.split(" · ", true, 1)[0] and first != banner().drawn["area"]["text"], "entering another area while a name shows replaces it")
	await frames(200)
	# Pausing holds it as well.
	session._mount_room("HD_20001_1")
	session._bind_room()
	quiet()
	paused = true
	await frames(10)
	var while_paused: bool = banner().drawn.has("area")
	paused = false
	var after_pause: Dictionary = await banner_shown(60)
	check(not while_paused and not after_pause.is_empty(), "pausing holds the name until play resumes")
	await frames(200)

func target_of(id: String) -> Dictionary:
	for value: Dictionary in session.interaction_targets():
		if value["id"] == id:
			return value
	return {}

func prompt_cases() -> void:
	await enter(ExplorationSession.EXPLORATION_ID)
	var pickup: RoomPickup = session._pickups()[0]
	var point: Vector2 = pickup.global_position
	var key: String = pickup.config.persistence_key
	session.player.global_position = point + Vector2(pickup.config.interaction_radius + 0.1, 44)
	await frames(2)
	check(prompt().drawn.is_empty() and not target_of(key)["in_range"], "outside the range there is no prompt")
	session.player.global_position = point + Vector2(pickup.config.interaction_radius * 0.6, 44)
	await frames(2)
	var drawn: Dictionary = prompt().drawn
	check(drawn.get("id") == key and drawn.get("action", {}).get("text") == "拾取" and drawn.get("keys", {}).get("text") == "E / RB", "in range the prompt names the key and the action")
	check(drawn.get("side") == "right" and (drawn["rect"] as Rect2).position.x > (drawn["target_screen"] as Vector2).x, "with the player on the right, it sits on the right")
	check(drawn.get("tone") == "light" and drawn.get("paper") != Color(0.05, 0.04, 0.04, 0.88), "a dark scene gets the light paper tag (A-019)")
	check(drawn.get("action", {}).get("color") == DuskStyle.INK, "with ink text")
	session.player.global_position = point + Vector2(-pickup.config.interaction_radius * 0.6, 44)
	await frames(2)
	drawn = prompt().drawn
	check(drawn.get("side") == "left" and (drawn["rect"] as Rect2).end.x < (drawn["target_screen"] as Vector2).x, "with the player on the left, it sits on the left")
	session.player.life.scripted_control_locked = true
	await frames(2)
	check(prompt().drawn.is_empty(), "a story lock hides it")
	session.player.life.scripted_control_locked = false
	paused = true
	await frames(2)
	check(prompt().drawn.is_empty(), "pausing hides it")
	paused = false
	await frames(2)
	check(not prompt().drawn.is_empty(), "and it returns afterwards")
	# The nearest of two usable targets wins.
	var near: Vector2 = session.player.global_position + Vector2(30, -44)
	extra = [{"id": "near", "kind": "交谈", "action": "交谈", "position": near, "radius": 80.0, "range_kind": "circle", "in_range": true, "available": true, "key_item": false}]
	await frames(2)
	check(prompt().drawn.get("id") == "near", "with two usable targets only the nearest shows")
	extra[0]["available"] = false
	await frames(2)
	check(prompt().drawn.get("id") == key, "an unavailable target never shows")
	extra.clear()
	# Collected: the query drops it and the prompt goes.
	session.player.global_position = point + Vector2(0, 44)
	check(session.collect_pickup(pickup), "the pearl is collected")
	await frames(3)
	check(prompt().drawn.is_empty(), "once collected there is no prompt")
	# Field Room: a dialogue hides the prompt (SYS-009 dialogue gate).
	await enter(FieldSession.FIELD_ID)
	var seven: Node2D = session.room.get_node("Seven") as Node2D
	session.player.position = seven.position
	await frames(2)
	check(prompt().drawn.get("action", {}).get("text") == "交谈", "next to 7 the prompt says 交谈")
	check(session.interact_seven(), "talking to 7 starts the dialogue")
	await frames(2)
	check(prompt().drawn.is_empty(), "during the dialogue the prompt hides")
	session._end_dialogue()
	await frames(2)

## Screen edges, the HUD corner, unlimited targets and both window sizes.
func placement_cases() -> void:
	var to_world: Transform2D = session.player.get_viewport().get_canvas_transform().affine_inverse()
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		await frames(2)
		to_world = session.player.get_viewport().get_canvas_transform().affine_inverse()
		var cases: Dictionary = {
			"left edge": to_world * Vector2(4, 600),
			"right edge": to_world * Vector2(1916, 600),
			"top": to_world * Vector2(960, 20),
			"HUD corner": to_world * Vector2(200, 230),
		}
		for name: String in cases:
			extra = [{"id": name, "kind": "交谈", "action": "交谈", "position": cases[name], "radius": 80.0, "range_kind": "circle", "in_range": true, "available": true, "key_item": false}]
			# Keep only the injected target in range.
			session.player.global_position = cases[name] + Vector2(0, 1)
			await frames(2)
			var rect: Rect2 = prompt().drawn.get("rect", Rect2())
			var ok: bool = prompt().drawn.get("id") == name and Rect2(Vector2.ZERO, prompt().size).grow(-InteractPrompt.MARGIN + 0.5).encloses(rect)
			for avoid: Rect2 in prompt().avoided():
				ok = ok and not rect.intersects(avoid)
			check(ok, "%dx%d %s: the prompt stays on screen and off the HUD" % [window.x, window.y, name])
		# The area name on screen is avoided too.
		banner().pending = "测试区域 · 测试房间"
		await frames(4)
		extra = [{"id": "middle", "kind": "交谈", "action": "交谈", "position": to_world * Vector2(960, 640), "radius": 80.0, "range_kind": "circle", "in_range": true, "available": true, "key_item": false}]
		session.player.global_position = to_world * Vector2(960, 641)
		await frames(2)
		var over: Rect2 = prompt().drawn.get("rect", Rect2())
		check(banner().drawn.has("rect") and prompt().drawn.get("id") == "middle" and not over.intersects(banner().drawn["rect"]), "%dx%d: the prompt keeps clear of the area name" % [window.x, window.y])
		await frames(200)
		extra = [{"id": "claim", "kind": "补领", "action": "补领", "position": session.player.global_position, "radius": null, "range_kind": "unlimited", "in_range": true, "available": true, "key_item": true}]
		session.player.global_position = to_world * Vector2(960, 700)
		extra[0]["position"] = session.player.global_position
		await frames(2)
		var above: Dictionary = prompt().drawn
		check(above.get("side") == "above" and (above["rect"] as Rect2).end.y < (above["player_screen"] as Vector2).y and absf((above["rect"] as Rect2).get_center().x - (above["player_screen"] as Vector2).x) < 2.0, "%dx%d: an unlimited target's prompt sits above the player" % [window.x, window.y])
	extra.clear()
	root.size = Vector2i(1920, 1080)
	await frames(2)

func highlight_cases() -> void:
	await enter("HD_20002_1")
	var key_pickup: RoomPickup = null
	for pickup: RoomPickup in session._pickups():
		if pickup.config.persistence_key.begins_with("keyitem:"):
			key_pickup = pickup
	check(key_pickup != null and key_pickup.visible and key_pickup.highlight() > 0.0 and key_pickup.key_item(), "a key item pulses on the map")
	check(target_of(key_pickup.config.persistence_key).get("key_item") == key_pickup.key_item(), "the same key-item rule as the SYS-009 query")
	var strengths: Array[float] = []
	for i: int in range(20):
		await frames(1)
		strengths.append(key_pickup.highlight())
	check(strengths.max() - strengths.min() > 0.1, "and the pulse moves")
	await enter(ExplorationSession.EXPLORATION_ID)
	var ordinary: RoomPickup = session._pickups()[0]
	check(not ordinary.key_item() and ordinary.highlight() == 0.0, "an ordinary pickup does not pulse")
	await enter("HD_20002_1")
	for pickup: RoomPickup in session._pickups():
		if pickup.config.persistence_key.begins_with("keyitem:"):
			key_pickup = pickup
	session.player.global_position = key_pickup.global_position + Vector2(0, 44)
	check(session.collect_pickup(key_pickup), "the key item is collected")
	await frames(3)
	check(not key_pickup.visible, "and its highlight goes with it")
