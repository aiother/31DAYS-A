# verify-suite: {"name": "NPC deadline real sessions cross-day save rollback legacy rescue and dynamic spawns", "path": "res://tests/test_world_day_session.gd", "marker": "WORLD_DAY_SESSION_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var attack_id: int = 90000

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func freeze() -> void:
	session.set_physics_process(false)
	session.player.set_physics_process(false)
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children(): enemy.set_physics_process(false)
	if session.room.environment_hazard != null: session.room.environment_hazard.set_physics_process(false)

func enter(id: String) -> void:
	session._change_room(id)
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	freeze()

func run() -> void:
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = "user://tests/world_day_%d" % Time.get_ticks_usec()
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "fresh session starts")
	session.intro_active = false
	session.data["events"][StartRoomSession.BIRTH] = true
	session.data["events"][FieldSession.FIELD_STORY] = true
	session.data["events"][FieldSession.HEAL_GUIDE] = true
	session.player.life.scripted_control_locked = false
	freeze()
	enter(RavineRescueSession.RESCUE_ID)
	session.data["day"] = 2
	session.data["day_remaining"] = 0.01
	session.data["events"][RavineRescueSession.SEEN] = true
	check(session._rescue_pending(), "seen second-day NPC available")
	var balance: int = session.player.possibility.balance
	var maximum: int = session.player.possibility.maximum
	paused = true
	session._clock_tick(1)
	check(session._rescue_pending(), "pause cannot expire NPC")
	paused = false
	session._clock_tick(0.01)
	check(session.data["day"] == 3 and not session._rescue_pending(), "natural boundary expires current Room immediately")
	check(session.store.load_slot(1)["events"].get(WorldDayRules.expired_key(RavineRescueSession.RESCUE_ID), false), "date and expiry saved together")
	check(not session.data["events"].get(RavineRescueSession.FAILED, false), "no abandonment event invented")
	session.player.position = (session.room.get_node("Survivor") as Node2D).position
	check(session.interact_ravine_survivor(), "expired NPC retains explanatory interaction")
	check(session.dialogue_ui.text.text.contains("太晚"), "expired dialogue explains earlier opportunity")
	session._on_dialogue_finished()
	check(not session.data["events"].get(RavineRescueSession.HELPED, false) and session.player.possibility.balance == balance and session.player.possibility.maximum == maximum, "expired interaction grants no rescue resource or growth")
	session._end_dialogue()
	session._process(0)
	check((session.room.get_node("Survivor/Name") as Label).text.contains("过期"), "NPC visibly distinguishes expiry")
	enter(RavineDepthSession.DEPTH_ID)
	session.data["events"][RavineDepthSession.DEPTH_SEEN] = true
	for actor: Node in session.room.get_node("Enemies").get_children():
		if actor is ColorlessEntity:
			var enemy: ColorlessEntity = actor as ColorlessEntity
			attack_id += 1
			enemy.hurtbox.receive_attack(enemy.health, Vector2.ZERO, session.player, attack_id)
	check(session.data["events"].get(RavineDepthRoom.GATES, false) and not session.data["events"].get(RavineDepthSession.DEPTH_HELPED, false), "expired depth clear still opens gates without rescue")
	enter(TownSession.TOWN_ID)
	session.player.position = (session.room.get_node("Survivor") as Node2D).position
	check(not session._can_rescue() and session.interact_survivor(), "late town cannot rescue but can explain")
	session._on_dialogue_finished()
	check(not session.data["events"].get(FieldSession.RESCUE_DONE, false), "town never grants expired reward")
	session._end_dialogue()
	# Story crossing is a transaction: failed Boss write cannot expire anyone.
	session.data = session.store.fresh()
	session.data["day"] = 2
	session.data["day_remaining"] = 20.0
	session._parasite_victory_pending = true
	var directory: String = session.store.directory
	session.store.directory = directory.path_join("slot_1.json")
	check(not session.save_current() and session.data["day"] == 2 and not session.rescue_expired(TownSession.TOWN_ID), "failed Boss cross-day restores opportunity and date")
	session.store.directory = directory
	check(session.save_current() and session.data["day"] == 3 and session.rescue_expired(TownSession.TOWN_ID), "successful Boss cross-day expires immediately")
	check(session.store.load_slot(1)["events"].get(WorldDayRules.expired_key(TownSession.TOWN_ID), false), "Boss date and expiry atomic on disk")
	# New spawn day is fixed, across rebinds and natural crossings.
	enter(TwoRoomSession.ENTRY_ID)
	var enemy: ColorlessEntity = session.room.get_node("Enemies").get_child(0) as ColorlessEntity
	check(enemy.health == 17 and is_equal_approx(enemy.config.speed, 144), "third-day Room spawns strengthened ordinary enemy")
	enemy.health -= 5
	session._bind_room()
	check(enemy.health == 12, "repeat bind never heals")
	enter(TownSession.TOWN_ID)
	session.data["day"] = 2
	enter(TwoRoomSession.ENTRY_ID)
	enemy = session.room.get_node("Enemies").get_child(0) as ColorlessEntity
	check(enemy.health == 15, "revisit spawns with current second-day health")
	session.data["day_remaining"] = 0.01
	session._clock_tick(0.01)
	session._bind_room()
	check(enemy.health == 15 and is_equal_approx(enemy.config.speed, 132), "crossing does not strengthen generated enemy")
	session._set_balance(-5)
	attack_id += 1
	check(enemy.hurtbox.receive_attack(5, Vector2.ZERO, session.player, attack_id) and enemy.health == 10, "strengthened enemy takes actual frozen five-damage hit")
	attack_id += 1
	check(enemy.hurtbox.receive_attack(10, Vector2.ZERO, session.player, attack_id), "strengthened enemy dies through real hurtbox")
	check(session.player.possibility.balance == -3 and session.store.load_slot(1)["balance"] == -3, "strengthened enemy still pays exactly two and persists")
	attack_id += 1
	enemy.hurtbox.receive_attack(50, Vector2.ZERO, session.player, attack_id)
	check(session.player.possibility.balance == -3, "dead strengthened instance cannot reward twice")
	enter(CampWavesSession.WAVES_ID)
	var camp: CampWavesRoom = session.room as CampWavesRoom
	camp.wave = 1
	camp._spawn_wave()
	freeze()
	check(camp.living()[0].health == 17, "dynamic camp wave uses actual spawn date")
	enter(BossSession.BOSS_ID)
	var boss_room: BossRoom = session.room as BossRoom
	boss_room.prepare_reinforcement()
	boss_room.spawn_reinforcement()
	freeze()
	check((boss_room.get_node("Enemies").get_child(0) as ColorlessEntity).config.max_health == 13, "Boss summoned colorless excluded")
	# Expiry survives exploration retry even if spike path has not been opened.
	session.intro_active = false
	session.data["day3_remaining"] = 0.01
	session._clock_tick(0.02)
	check(session._timeout_active and session.rescue_expired(OutskirtsSession.OUTSKIRTS_ID), "third-day zero immediately expires unseen outskirts")
	check(session.retry_final_battle(), "exploration timeout retry succeeds with expiry save")
	freeze()
	check(session.rescue_expired(OutskirtsSession.OUTSKIRTS_ID) and DayClock.remaining(session.data) == 1800, "retry refills clock without reviving expired NPC")
	# A legacy known pending opportunity migrates before any load-time autosave.
	var legacy: Dictionary = session.store.fresh()
	legacy["events"].erase(WorldDayRules.ENABLED)
	legacy["events"][RavineRescueSession.SEEN] = true
	legacy["day"] = 3
	session._restore(legacy, false)
	session.intro_active = false
	freeze()
	check(not session.rescue_expired(RavineRescueSession.RESCUE_ID) and session.rescue_expired(TownSession.TOWN_ID), "legacy seen protected while unseen expires")
	check(session.save_current(), "migration saves")
	var saved: Dictionary = session.store.load_slot(1)
	check(saved["events"].get(WorldDayRules.grace_key(RavineRescueSession.RESCUE_ID), false), "legacy grace persists in slot")
	check(session.store.save_slot(2, session.store.fresh()) and not session.store.load_slot(2)["events"].has(WorldDayRules.grace_key(RavineRescueSession.RESCUE_ID)), "second disk slot receives no migrated exemption")
	enter(RavineRescueSession.RESCUE_ID)
	session.player.position = (session.room.get_node("Survivor") as Node2D).position
	check(session.interact_ravine_survivor(), "protected legacy NPC can interact after deadline")
	session._on_dialogue_finished()
	check(session.data["events"].get(RavineRescueSession.HELPED, false), "protected legacy NPC really rescues")
	session._end_dialogue()
	session.data["day3_remaining"] = 0.0
	session.save_current()
	check(not session.rescue_expired(RavineRescueSession.RESCUE_ID) and session.rescue_expired(TownSession.TOWN_ID), "successful legacy rescue and other expired source remain independent")
	session.data["day3_remaining"] = 10.0
	session.player.life.take_hit(session.player.life.health)
	var death: Dictionary = session.store.load_slot(1)
	check(death["events"].get(WorldDayRules.expired_key(TownSession.TOWN_ID), false) and death["events"].get(RavineRescueSession.HELPED, false), "real death settlement preserves expired and rescued sources")
	check(not session.store.fresh()["events"].has(WorldDayRules.grace_key(RavineRescueSession.RESCUE_ID)), "new game and other fresh slots inherit no exemption")
	paused = false
	session.free()
	current_scene = null
	await process_frame
	print("WORLD_DAY_SESSION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
