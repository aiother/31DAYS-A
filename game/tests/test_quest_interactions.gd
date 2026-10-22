# verify-suite: {"name":"quest item and interaction data from real isolated sessions","path":"res://tests/test_quest_interactions.gd","marker":"QUEST_INTERACTIONS_TESTS checks=","fixed_fps":60,"timeout":180}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var quests: Array[Dictionary] = []
var items: Array[Dictionary] = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int = 2) -> void:
	for i: int in range(n):
		await physics_frame
		await process_frame
func quiet() -> void:
	session.set_physics_process(false)
	session.set_process(false)
	session.player.set_physics_process(false)
	session.player.life.protection_remaining = 1000.0
	session.player.life.hurt_remaining = 0.0
	for node: Node in session.room.find_children("*", "Node", true, false):
		if node is ColorlessEntity or node is RoomRockfall or node is OverlookBoss or node is ParasiteBoss: node.set_physics_process(false)
func fresh() -> Dictionary:
	var value: Dictionary = session.store.fresh()
	value["events"][StartRoomSession.BIRTH] = true
	value["events"][WorldDayRules.ENABLED] = true
	return value
func open(snapshot: Dictionary = {}) -> void:
	quests.clear()
	items.clear()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	session.quest_changed.connect(func(kind: String, state: Dictionary) -> void: quests.append({"kind":kind,"state":state.duplicate(true)}))
	session.item_obtained.connect(func(kind: String, display_name: String) -> void:
		items.append({"kind":kind,"name":display_name,"saved":session.store.load_slot(1).duplicate(true)}))
	root.add_child(session)
	current_scene = session
	check(session.quest_state()["state"] == "无" and session.interaction_targets().is_empty(), "no slot invents no quest or interaction")
	var value: Dictionary = fresh() if snapshot.is_empty() else snapshot
	check(session.store.save_slot(1,value) and session.start_slot(1,false), "isolated real save starts")
	quiet()
	await frames()
	check(quests.is_empty(), "restore emits no historical quest events")
func close() -> void:
	paused = false
	session.queue_free()
	current_scene = null
	await frames()
	OS.delay_msec(500)
func enter(id: String) -> void:
	session._mount_room(id)
	session._bind_room()
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	quiet()
	await frames()
func target(id: String) -> Dictionary:
	for value: Dictionary in session.interaction_targets():
		if value["id"] == id: return value
	return {}
func press() -> void:
	Input.action_press("interact")
	session._physics_process(0.0)
	Input.action_release("interact")
	await frames()
func quest_count(id: String, kind: String) -> int:
	var count: int = 0
	for event: Dictionary in quests:
		if event["state"]["id"] == id and event["kind"] == kind: count += 1
	return count
func quest_cases() -> void:
	for id: String in WorldDayRules.IDS:
		for ending: String in ["完成","放弃","过期"]:
			await open()
			var seen: String = FieldSession.HEAL_GUIDE if id == TownSession.TOWN_ID else "rescue:%s:seen" % id
			if id == OutskirtsSession.OUTSKIRTS_ID:
				for flag: String in [ParasiteSession.PARASITE_DEFEATED,ParasiteSession.DODGE_GROWTH,OutskirtsSession.SPIKES_OPEN]: session.data["events"][flag] = true
			check(session.record_event(seen), id + " starts via existing saved event")
			check(quest_count(id,"开始") == 1, id + " begins once")
			check(session.save_current(), "unchanged save succeeds")
			session._publish_quest_changes()
			check(quest_count(id,"开始") == 1 and quest_count(id,"进展") == 0, "unchanged state emits nothing")
			if ending == "过期":
				session.data["day"] = 3
				session.data["day3_remaining"] = 0.0
				check(session.save_current(), "natural day rules expire quest on save")
			else:
				check(session.record_event(WorldDayRules.completed(id) if ending == "完成" else WorldDayRules.failed(id)), "existing terminal event saves")
			check(quest_count(id,ending) == 1, id + " correct terminal signal once: " + ending)
			session.save_current()
			session._publish_quest_changes()
			check(quest_count(id,ending) == 1, "repeated save never repeats terminal signal")
			var saved: Dictionary = session.store.load_slot(1)
			await close()
			await open(saved)
			check(quests.is_empty(), "terminal restored state is query-only")
			if id != TownSession.TOWN_ID: await enter(id)
			var state: Dictionary = session.quest_state()
			check(state["id"] == id and state["state"] == {"完成":"已完成","放弃":"已放弃","过期":"已过期"}[ending] and state["objective"] == session.quest_status_text(), "query agrees with unchanged legacy objective")
			state["state"] = "tampered"
			check(session.quest_state()["state"] != "tampered", "query is detached")
			await close()
	# Real town dialogue and settlement (not just event flags).
	await open()
	session.record_event(FieldSession.FIELD_STORY)
	session.record_event(FieldSession.HEAL_GUIDE)
	await enter(TownSession.TOWN_ID)
	session.player.position = session.room.get_node("Survivor").position
	check(session.interact_survivor() and session._commit_rescue(), "real rescue dialogue commits completion")
	check(quest_count(TownSession.TOWN_ID,"完成") == 1, "real rescue emits completion once")
	await enter(FieldSession.FIELD_ID)
	session.player.position = session.room.get_node("Seven").position
	check(session.interact_seven(), "real Seven settlement starts")
	check(session._commit_gaze(), "real Seven settlement persists")
	await frames()
	check(quest_count(TownSession.TOWN_ID,"进展") == 1, "return-to-Seven settlement advances completed objective once")
	check(items.size() == 1 and items[0]["kind"] == "成长" and bool(items[0]["saved"]["events"].get(TownSession.GAZE,false)), "gaze obtained only after durable growth")
	await close()
func item_cases() -> void:
	await open()
	await enter(ExplorationSession.EXPLORATION_ID)
	var pickup: RoomPickup = session._pickups()[0]
	var key: String = pickup.config.persistence_key
	session.player.global_position = pickup.global_position + Vector2(0,44)
	var real: String = session.store.directory
	session.store.directory = real.path_join("slot_1.json")
	check(not session.collect_pickup(pickup), "failed pearl save rejected")
	await frames()
	check(items.is_empty() and not bool(session.data["events"].get(key,false)), "failed save emits no obtained item")
	session.store.directory = real
	check(session.collect_pickup(pickup), "pearl retry succeeds")
	await frames()
	check(items.size() == 1 and items[0]["kind"] == "珍珠" and bool(items[0]["saved"]["events"].get(key,false)), "pearl obtained after durable save exactly once")
	check(not session.collect_pickup(pickup) and items.size() == 1, "collected pearl cannot emit twice")
	# Generic configured pickups use their own display name, not save-message matching.
	var generic: RoomPickup = RoomPickup.new()
	generic.config = PickupConfig.new()
	generic.config.persistence_key = "item:sys009:fixture"
	generic.config.display_name = "测试拾取"
	session.room.add_child(generic)
	generic.position = session.player.position + Vector2(0,-44)
	check(session.collect_pickup(generic), "configured ordinary pickup succeeds")
	await frames()
	check(items.size() == 2 and items[1]["kind"] == "拾取" and items[1]["name"] == "测试拾取", "ordinary pickup uses actual configured name")
	var supply: MedkitSupply = session.medkit_supply()
	session.player.global_position = supply.global_position + Vector2(0,44)
	session.store.directory = real.path_join("slot_1.json")
	check(not session.collect_medkit(), "failed medkit save rejected")
	await frames()
	check(items.size() == 2, "failed medkit grants no item notification")
	session.store.directory = real
	check(session.collect_medkit(), "medkit retry succeeds")
	await frames()
	check(items.size() == 3 and items[2]["kind"] == "药包" and bool(items[2]["saved"]["events"].get(supply.persistence_key,false)), "medkit persisted before notification")
	check(not session.collect_medkit() and items.size() == 3, "medkit cannot duplicate")
	for flag: String in [BossSession.BOSS_DEFEATED,ParasiteSession.PARASITE_DEFEATED]:
		var old_size: int = items.size()
		session.data["events"][flag] = true
		session.store.directory = real.path_join("slot_1.json")
		check(not session.save_current(), "growth failed write rejected")
		await frames()
		check(items.size() == old_size, "growth failed write emits nothing")
		session.store.directory = real
		check(session.save_current(), "growth retry durable")
		await frames()
		var claimed: String = BossSession.COMBAT_GROWTH if flag == BossSession.BOSS_DEFEATED else ParasiteSession.DODGE_GROWTH
		check(items.size() == old_size+1 and items.back()["kind"] == "成长" and bool(items.back()["saved"]["events"].get(claimed,false)), "growth claimed exactly once after persistence")
		session.save_current()
		await frames()
		check(items.size() == old_size+1, "growth autosave not a second acquisition")
	await close()
func interaction_cases() -> void:
	await open()
	await enter(ExplorationSession.EXPLORATION_ID)
	var pickup: RoomPickup = session._pickups()[0]
	var id: String = pickup.config.persistence_key
	var point: Vector2 = pickup.global_position
	session.player.global_position = point + Vector2(pickup.config.interaction_radius+0.1,44)
	check(not target(id)["in_range"] and not target(id)["available"], "pickup just outside exact chest-centered range")
	await press()
	check(not bool(session.data["events"].get(id,false)), "outside real E does not collect")
	session.player.global_position = point + Vector2(pickup.config.interaction_radius,44)
	check(target(id)["in_range"] and target(id)["available"] and target(id)["radius"] == pickup.config.interaction_radius, "pickup inclusive exact boundary shares source predicate")
	session.player.life.scripted_control_locked = true
	check(not target(id)["available"], "story lock makes pickup unavailable")
	await press()
	check(not bool(session.data["events"].get(id,false)), "locked E has no pickup effect")
	session.player.life.scripted_control_locked = false
	session.dialogue_ui.start(TownSession.SETTLEMENT, PackedStringArray(["临时对话"]))
	check(not target(id)["available"] and not session.collect_pickup(pickup), "approved ordinary dialogue gate blocks query and direct world action")
	await press()
	check(not bool(session.data["events"].get(id,false)), "dialogue E cannot collect a world item")
	session.dialogue_ui.dismiss()
	paused = true
	check(not target(id)["available"], "pause makes pickup unavailable")
	paused = false
	await press()
	check(bool(session.data["events"].get(id,false)) and target(id).is_empty(), "real E at boundary collects and removes query target")
	# Four NPC kinds use their original feet-radius and action guard.
	for row: Array in [[FieldSession.FIELD_ID,"Seven","interact_seven"],[TownSession.TOWN_ID,"Survivor","interact_survivor"],[RavineRescueSession.RESCUE_ID,"Survivor","interact_ravine_survivor"],[OutskirtsSession.OUTSKIRTS_ID,"Survivor","interact_outskirts_survivor"]]:
		await enter(row[0])
		if row[0] == OutskirtsSession.OUTSKIRTS_ID:
			for flag: String in [ParasiteSession.PARASITE_DEFEATED,ParasiteSession.DODGE_GROWTH,OutskirtsSession.SPIKES_OPEN]: session.data["events"][flag] = true
			session._refresh_outskirts()
		session.data["events"][FieldSession.FIELD_STORY] = true
		session._forced_dialogue = false
		session._interaction_cooldown = 0
		var actor: Node2D = session.room.get_node(row[1])
		id = str(row[0])+":"+str(row[1])
		var radius: float = target(id)["radius"]
		session.player.position = actor.position + Vector2(radius+0.1,0)
		check(not target(id)["available"] and not session.call(row[2]), "NPC outside query equals actual action: " + str(row[0]))
		session.player.position = actor.position
		session.player.life.scripted_control_locked = true
		check(not target(id)["available"] and not session.call(row[2]), "NPC lock query equals actual action")
		session.player.life.scripted_control_locked = false
		check(target(id)["available"], "NPC nearby query available")
		await press()
		check(session.dialogue_ui.active and not target(id)["available"], "real E starts NPC dialogue and query then unavailable")
		session._end_dialogue()
	# Four checkpoint retry kinds use feet coordinates and the original 96 radius.
	for row: Array in [[RavineSession.RAVINE_ID,RavineSession.RAVINE_CHECKPOINT],[CampWavesSession.WAVES_ID,CampWavesSession.WAVES_CHECKPOINT],[TrenchSession.TRENCH_ID,TrenchSession.TRENCH_CHECKPOINT],[TrenchPassageSession.PASSAGE_ID,TrenchPassageSession.PASSAGE_CHECKPOINT]]:
		await enter(row[0])
		session.data["checkpoint"] = StartRoomSession.CHECKPOINT
		session._end_dialogue()
		session._forced_dialogue = false
		session.intro_active = false
		session.player.life.scripted_control_locked = false
		var cp: Vector2 = session._checkpoint(row[1]).config.spawn_position
		session.player.position = cp+Vector2(96.1,0)
		check(not target(row[1])["available"], "checkpoint outside 96 unavailable")
		await press()
		check(session.data["checkpoint"] != row[1], "outside checkpoint E no effect")
		session.player.position = cp
		check(target(row[1])["available"], "checkpoint nearby available: %s control=%s dialogue=%s intro=%s" % [target(row[1]),session.player.life.can_control(),session._world_dialogue_blocked(),session.intro_active])
		await press()
		check(session.data["checkpoint"] == row[1] and not target(row[1])["available"], "checkpoint real E settles once")
	await close()
func special_interactions() -> void:
	await open()
	await enter(ConnectionSession.CONNECTION_ID)
	var area: ConnectionRoom = session.room as ConnectionRoom
	var id: String = area.forward_key
	var switch_point: Vector2 = area.get_node("Switch").global_position
	session.player.global_position = switch_point + Vector2(0,44)
	check(not target(id)["available"] and not session.activate_switch(), "connection switch still needs actual enemy clear")
	for actor: Node in area.get_node("Enemies").get_children():
		if actor is ColorlessEntity: actor.health = 0
	session.player.global_position = switch_point + Vector2(area.interaction_radius+0.1,44)
	check(not target(id)["in_range"] and not target(id)["available"], "connection switch outside exact chest radius")
	await press()
	check(not bool(session.data["events"].get(id,false)), "outside switch input unchanged")
	session.player.global_position = switch_point + Vector2(0,44)
	check(target(id)["available"], "cleared nearby switch available")
	session.dialogue_ui.start(TownSession.SETTLEMENT,PackedStringArray(["临时对话"]))
	check(not target(id)["available"] and not session.activate_switch(), "dialogue blocks switch query and action")
	session.dialogue_ui.dismiss()
	await press()
	check(bool(session.data["events"].get(id,false)) and not target(id)["available"], "real switch E persists and no longer offers opening")
	await enter(RavineRescueSession.RESCUE_ID)
	var hazard: RoomRockfall = session.room.environment_hazard
	id = hazard.config.persistence_key
	var point: Vector2 = hazard.to_global(hazard.config.switch_position)
	session.player.global_position = point + Vector2(hazard.config.interaction_radius+0.1,44)
	check(not target(id)["in_range"] and not target(id)["available"] and not session.activate_environment_switch(), "environment switch outside exact radius")
	session.player.global_position = point + Vector2(0,44)
	check(target(id)["available"], "near environment switch available")
	session.player.life.scripted_control_locked = true
	check(not target(id)["available"] and not session.activate_environment_switch(), "environment switch lock same source")
	session.player.life.scripted_control_locked = false
	await press()
	check(bool(session.data["events"].get(id,false)) and not target(id)["available"], "real E disables environment hazard permanently")
	# Global supplement keeps its original unlimited range, including in a different Room.
	session.data["events"][BossSession.BOSS_DEFEATED] = true
	var supplement: Dictionary = target(BossSession.COMBAT_GROWTH)
	check(supplement["range_kind"] == "unlimited" and supplement["radius"] == null and supplement["in_range"] and supplement["available"], "combat supplement exposes true unlimited range")
	session.player.position = Vector2(100000,100000)
	check(target(BossSession.COMBAT_GROWTH)["available"], "supplement has no invented proximity restriction")
	await press()
	check(bool(session.data["events"].get(BossSession.COMBAT_GROWTH,false)) and target(BossSession.COMBAT_GROWTH).is_empty(), "real E supplement commits from original unlimited location")
	await enter(TrenchSession.TRENCH_ID)
	session._tian_intro_retry = true
	var encounter: Area2D = session.room.get_node("Encounter") as Area2D
	var shape: CollisionShape2D = encounter.get_node("CollisionShape2D") as CollisionShape2D
	point = shape.global_position
	id = TianSession.TIAN_INTRO
	session.player.global_position = point + Vector2(10000,10000)
	check(target(id)["range_kind"] == "area" and target(id)["radius"] == null and target(id).has("bounds") and not target(id)["in_range"] and not target(id)["available"], "introduction retry exposes actual area rather than invented circle")
	await press()
	check(not bool(session.data["events"].get(id,false)), "outside encounter retry E does nothing")
	session.player.global_position = point
	check(target(id)["in_range"] == session.room._currently_overlaps(encounter,session.player) and target(id)["available"], "encounter query reuses original player-rectangle overlap")
	await press()
	check(bool(session.data["events"].get(id,false)) and target(id).is_empty(), "actual area E retry persists intro once")
	await close()

func final_and_deferred_cases() -> void:
	await open()
	# Completed rescues recorded before gaze are paid only at successful gaze settlement.
	for flag: String in [FieldSession.FIELD_STORY,FieldSession.HEAL_GUIDE,FieldSession.RESCUE_DONE,RavineRescueSession.HELPED]: session.data["events"][flag] = true
	check(session.save_current(), "pre-gaze deferred rescue persists")
	await frames()
	check(items.is_empty(), "recorded pre-gaze growth not presented as already acquired")
	await enter(FieldSession.FIELD_ID)
	session.player.position = session.room.get_node("Seven").position
	check(session.interact_seven(), "deferred growth settlement starts")
	check(session._commit_gaze(), "deferred growth settlement commits")
	await frames()
	check(items.size() == 2 and items[1]["name"] == "沟壑救助成长" and items[1]["saved"]["maximum"] == 13, "deferred rescue growth emitted once with successful saved cap")
	session.save_current()
	await frames()
	check(items.size() == 2, "deferred growth cannot repeat")
	await close()
	await open()
	for flag: String in [FinalClock.STARTED,FinalClock.WON,RescueBattlefieldSession.RESCUE_DONE_EVENT]: session.data["events"][flag] = true
	await enter(BattlefieldSession.BATTLEFIELD_ID)
	var area: FinalBattlefieldRoom = session.room as FinalBattlefieldRoom
	session.player.position = area.ten.position + Vector2(110.1,0)
	check(not target("ten:victory")["in_range"] and not target("ten:victory")["available"], "final conversation outside original 110 feet radius")
	await press()
	check(not session._final_talk, "outside E cannot start final conversation")
	session.player.position = area.ten.position
	check(target("ten:victory")["available"] and target("battlefield:retry").is_empty(), "victory offers conversation without stale stage retry")
	await press()
	check(session._final_talk and session.dialogue_ui.active and not target("ten:victory")["available"], "actual E starts final talk and query follows lock")
	await close()
	await open()
	await enter(BattlefieldSession.BATTLEFIELD_ID)
	session.data["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	session._start_pending = true
	session.intro_active = true
	session.player.life.scripted_control_locked = true
	var retry: Dictionary = target("final:start")
	check(not retry["available"] and retry["retry_available"] and retry["radius"] == null, "settlement retry distinguished from locked world interaction")
	await press()
	check(not session._start_pending and bool(session.data["events"].get(FinalClock.STARTED,false)), "approved save-retry exemption still works while locked")
	await close()

func inherited_dispatch_case() -> void:
	await open()
	session.data["events"][BossSession.BOSS_DEFEATED] = true
	session.data["events"][FieldSession.FIELD_STORY] = true
	await enter(FieldSession.FIELD_ID)
	session.player.position = session.room.get_node("Seven").position
	session._interaction_cooldown = 0
	check(target(BossSession.COMBAT_GROWTH)["available"] and target(FieldSession.FIELD_ID + ":Seven")["available"], "lower-layer supplement does not suppress higher-layer NPC continuation")
	await press()
	check(bool(session.data["events"].get(BossSession.COMBAT_GROWTH,false)) and session.dialogue_ui.active, "same real E both saves lower-layer supplement and reaches higher-layer NPC")
	await close()

func run() -> void:
	directory = "user://tests/quest_interactions_%d" % Time.get_ticks_usec()
	await quest_cases()
	await item_cases()
	await interaction_cases()
	await special_interactions()
	await final_and_deferred_cases()
	await inherited_dispatch_case()
	for selected: int in [1,2,3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("QUEST_INTERACTIONS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
