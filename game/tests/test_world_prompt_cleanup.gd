# verify-suite: {"name":"gray world prompt cleanup preserves states and baseline interaction queries","path":"res://tests/test_world_prompt_cleanup.gd","marker":"WORLD_PROMPT_CLEANUP_TESTS checks=","fixed_fps":60,"timeout":60}
extends "res://tests/test_quest_interactions.gd"
## CLN-001: compare the same real-session queries captured on the approved
## baseline before changing presentation. --query-only creates that trace.
var query_only: bool = "--query-only" in OS.get_cmdline_user_args()
var expected_queries: Dictionary = {}
var trace: Dictionary = {}

func normalized(value: Variant) -> Variant:
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[key] = normalized(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(normalized(item))
		return result
	return value

func sample(name: String) -> void:
	var actual: Variant = normalized(session.interaction_targets())
	trace[name] = actual
	if not query_only:
		check(expected_queries.has(name) and actual == expected_queries.get(name), name + " entire SYS-009 query matches pre-cleanup baseline")

func no_key(label: Label, name: String) -> void:
	if not query_only:
		check(not label.text.contains("E / RB") and (label.text.is_empty() or not label.is_visible_in_tree()), name + " has no duplicate world key hint")

func pickup_cases() -> void:
	for id: String in [ExplorationSession.EXPLORATION_ID, "HD_20001_3", "HD_20002_1", "NSZC_10002_1"]:
		await enter(id)
		for pickup: RoomPickup in session._pickups():
			var key: String = pickup.config.persistence_key
			session.player.global_position = pickup.global_position + Vector2(0,44)
			pickup.refresh(session.player,false)
			sample(key + ":near")
			no_key(pickup.prompt,key)
			if not query_only: check(target(key).get("available",false), key + " still usable near player")
			paused = true
			sample(key + ":paused")
			paused = false
			session.player.global_position.x += pickup.config.interaction_radius + 1.0
			sample(key + ":far")
			session.data["events"][key] = true
			pickup.refresh(session.player,true)
			sample(key + ":collected")
			if not query_only: check(not pickup.visible and target(key).is_empty(), key + " collection still hides item and removes query")

func rockfall_cases() -> void:
	for id: String in ["HD_20001_1","HD_20001_2","HD_20001_3","HD_20002_1"]:
		await enter(id)
		var hazard: RoomRockfall = session.room.environment_hazard
		session.player.global_position = hazard.to_global(hazard.config.switch_position) + Vector2(0,44)
		hazard.refresh(session.player, session.data["events"])
		sample(id + ":rockfall-on")
		no_key(hazard.prompt,id + " active rockfall")
		if not query_only: check(target(hazard.config.persistence_key).get("available",false), id + " switch still available")
		session.data["events"][hazard.config.persistence_key] = true
		hazard.refresh(session.player, session.data["events"])
		sample(id + ":rockfall-off")
		if not query_only: check(hazard.prompt.is_visible_in_tree() and hazard.prompt.text == "落石已永久关闭", id + " permanent-off state remains readable")

func connection_cases() -> void:
	await enter(ConnectionSession.CONNECTION_ID)
	var area: ConnectionRoom = session.room as ConnectionRoom
	session.player.global_position = (area.get_node("Switch") as Node2D).global_position + Vector2(0,44)
	area.refresh(session.player,session.data["events"],false)
	sample("connection:locked")
	if not query_only: check((area.get_node("Switch/Prompt") as Label).is_visible_in_tree() and area.get_node("Switch/Prompt").text == "需要先清敌", "connection retains uncleared state")
	for enemy: Node in area.get_node("Enemies").get_children():
		if enemy is ColorlessEntity: enemy.health = 0
	area.refresh(session.player,session.data["events"],true)
	sample("connection:ready")
	no_key(area.get_node("Switch/Prompt") as Label,"ready connection")
	if not query_only: check(target(area.forward_key).get("available",false), "ready connection still usable")
	session.data["events"][area.forward_key] = true
	area.refresh(session.player,session.data["events"],true)
	sample("connection:open")
	if not query_only: check((area.get_node("Switch/Prompt") as Label).is_visible_in_tree() and area.get_node("Switch/Prompt").text == "已开启", "connection retains opened state")

func survivor_cases() -> void:
	for row: Array in [[FieldSession.FIELD_ID,"Seven"],[TownSession.TOWN_ID,"Survivor"],[RavineRescueSession.RESCUE_ID,"Survivor"],[OutskirtsSession.OUTSKIRTS_ID,"Survivor"]]:
		await enter(row[0])
		session.data["events"][FieldSession.FIELD_STORY] = true
		session._forced_dialogue = false
		session._interaction_cooldown = 0.0
		if row[0] == OutskirtsSession.OUTSKIRTS_ID:
			for flag: String in [ParasiteSession.PARASITE_DEFEATED,ParasiteSession.DODGE_GROWTH,OutskirtsSession.SPIKES_OPEN]: session.data["events"][flag] = true
		var actor: Node2D = session.room.get_node(row[1]) as Node2D
		session.player.global_position = actor.global_position
		for state: String in ["pending","completed","failed"]:
			if row[1] == "Seven":
				session._process(0.0)
			elif row[0] == OutskirtsSession.OUTSKIRTS_ID:
				session.room.call("refresh",true,state == "completed",state == "failed",true)
			else:
				session.room.call("refresh_rescue",state == "completed",state == "failed",true)
			sample(str(row[0]) + ":npc:" + state)
			no_key(actor.get_node("Prompt") as Label,str(row[0]) + " " + state)
			if not query_only and row[1] == "Survivor":
				var name: String = str(actor.get_node("Name").text)
				check(name.contains("已救助") if state == "completed" else (name.contains("救助机会已失去") if state == "failed" else name.ends_with("幸存者")), "NPC state name remains: " + state)

func medkit_cases() -> void:
	for id: String in MedkitRules.CONFIG.placements:
		await enter(id)
		var source: MedkitSupply = session.medkit_supply()
		session.player.global_position = source.global_position + Vector2(0,44)
		for count: int in [0,MedkitRules.CONFIG.maximum]:
			source.refresh(session.player,session.data["events"],count)
			sample(id + ":medkits:" + str(count))
			if not query_only:
				check(source.prompt.is_visible_in_tree() and source.prompt.text == ("药包已满 · %d / %d" % [count,MedkitRules.CONFIG.maximum] if count == MedkitRules.CONFIG.maximum else "靠近自动拾取 · 应急药包"), "medkit retains automatic pickup/full inventory information")

func initial_scene_cases() -> void:
	for row: Array in [
		["ty_10001_1",preload("res://world/rooms/ty_10001_1.tscn")],
		["ty_10002_1",preload("res://world/rooms/ty_10002_1.tscn")],
		["hd_20001_2",preload("res://world/rooms/hd_20001_2.tscn")],
		["nszc_10001_1",preload("res://world/rooms/nszc_10001_1.tscn")]
	]:
		var id: String = row[0]
		var room: Node = (row[1] as PackedScene).instantiate()
		no_key(room.get_node("Seven/Prompt" if id == "ty_10001_1" else "Survivor/Prompt") as Label,id + " initial scene")
		room.free()

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_world_prompt_cleanup_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()])
	if not query_only:
		expected_queries = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/cln001_interaction_queries.json"))
	initial_scene_cases()
	await open()
	await pickup_cases()
	await rockfall_cases()
	await connection_cases()
	await survivor_cases()
	await medkit_cases()
	if not query_only: check(trace.size() == expected_queries.size(), "all baseline query cases executed")
	await close()
	for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("CLN001_QUERY_TRACE=" + JSON.stringify(trace))
	print("WORLD_PROMPT_CLEANUP_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
