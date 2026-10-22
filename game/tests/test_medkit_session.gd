# verify-suite: {"name": "medkit automatic supplies real Q Back input restrictions rollback and death reload", "path": "res://tests/test_medkit_session.gd", "marker": "MEDKIT_SESSION_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func quiet() -> void:
	if is_instance_valid(current_scene) and current_scene is FinalBattleSession:
		session = current_scene as FinalBattleSession
	if not is_instance_valid(session): return
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children(): enemy.set_physics_process(false)
	if session.room.environment_hazard != null: session.room.environment_hazard.set_physics_process(false)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
		quiet()

func enter(id: String) -> void:
	session._change_room(id)
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	quiet()
	await ticks(2)

func blocked(message: String) -> void:
	var count: int = session.medkit_count()
	var health: int = session.player.life.health
	check(not session.use_medkit() and session.medkit_count() == count and session.player.life.health == health, message)

func run() -> void:
	directory = "user://tests/medkit_session_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "fresh main session starts")
	check(session.medkit_count() == 0 and not session.use_medkit(), "opening cannot use or grant inventory")
	session.data["events"][StartRoomSession.BIRTH] = true
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	# All four supplies must stand above real existing surfaces, with no new collision.
	for id: String in MedkitRules.CONFIG.placements:
		await enter(id)
		var supply: MedkitSupply = session.medkit_supply()
		check(supply != null and supply.get_child_count() == 1 and supply.get_child(0) is Label, id + " supply is decorative with no collider")
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(supply.global_position + Vector2(0, 20), supply.global_position + Vector2(0, 80), 1)
		var hit: Dictionary = session.get_world_2d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf((hit.get("position", Vector2.ZERO) as Vector2).y - supply.global_position.y - 44) < 2, id + " supply is above existing reachable floor or platform")
		session.data["medkits"] = 0
		session.player.position = supply.position + Vector2(0, 44)
		session.player.reset_kinematics()
		var health: int = session.player.life.health
		var balance: int = session.player.possibility.balance
		await ticks(2)
		check(session.medkit_count() == 1 and not supply.visible, id + " proximity automatically collects once without interact")
		var saved: Dictionary = session.store.load_slot(1)
		check(saved["medkits"] == 1 and saved["events"].get(supply.persistence_key, false), id + " pickup and count persist together")
		check(session.player.life.health == health and session.player.possibility.balance == balance, id + " pickup does not auto-heal or alter possibility")
		check(not session.collect_medkit() and session.medkit_count() == 1, id + " repeated proximity cannot duplicate")
	# Restore one actual source for full-cap and disk-failure transactions.
	await enter(ExplorationSession.EXPLORATION_ID)
	var source: MedkitSupply = session.medkit_supply()
	var source_key: String = source.persistence_key
	session.data["events"].erase(source.persistence_key)
	session.data["medkits"] = 3
	session.player.position = source.position + Vector2(0, 44)
	session.player.reset_kinematics()
	await ticks(2)
	check(source.visible and source.prompt.is_visible_in_tree() and source.prompt.text == "药包已满 · 3 / 3" and not session.data["events"].has(source.persistence_key), "full inventory leaves supply visible and unclaimed")
	session.set_physics_process(false)
	session.player.set_physics_process(false)
	session.data["medkits"] = 2
	check(session.save_current(), "transaction baseline saved")
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.collect_medkit() and session.medkit_count() == 2 and not session.data["events"].has(source.persistence_key) and source.visible, "failed pickup rolls back count event and visibility")
	session.store.directory = real_directory
	check(session.store.load_slot(1)["medkits"] == 2 and session.collect_medkit() and session.medkit_count() == 3, "pickup can retry with one reward after write recovery")
	var events: Dictionary = session.data["events"].duplicate()
	session.player.life.health = 1
	var possibility: int = session.player.possibility.balance
	check(session.save_current(), "use baseline saved")
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.use_medkit() and session.medkit_count() == 3 and session.player.life.health == 1 and session.data["health"] == 1, "failed use rolls back health and inventory")
	session.store.directory = real_directory
	check(session.store.load_slot(1)["health"] == 1 and session.store.load_slot(1)["medkits"] == 3, "failed use leaves disk unchanged")
	check(session.use_medkit() and session.medkit_count() == 2 and session.player.life.health == 3, "successful retry consumes exactly one and heals two")
	check(session.player.life.protection_remaining == 0 and session.player.possibility.invincible_remaining == 0 and session.player.possibility.balance == possibility and session.data["events"] == events, "use grants no immunity possibility or permanent growth")
	session.player.life.health = 4
	check(session.use_medkit() and session.player.life.health == 5 and session.medkit_count() == 1, "healing clamps to five")
	blocked("full health never consumes")
	session.player.life.health = 1
	session.data["medkits"] = 0
	blocked("zero inventory never heals")
	session.data["medkits"] = 3
	for phase: int in [PlayerCombat.Phase.WINDUP, PlayerCombat.Phase.ACTIVE, PlayerCombat.Phase.RECOVERY]:
		session.player.combat.phase = phase as PlayerCombat.Phase
		blocked("attack phase blocks use %d" % phase)
	session.player.combat.interrupt()
	for state: int in [PlayerPossibility.State.DODGE_WINDUP, PlayerPossibility.State.DODGE_ACTIVE, PlayerPossibility.State.DODGE_RECOVERY, PlayerPossibility.State.HEALING]:
		session.player.possibility.state = state as PlayerPossibility.State
		blocked("dodge or L healing blocks use %d" % state)
	session.player.possibility.cancel()
	session.player.life.hurt_remaining = 0.2
	blocked("hurt stun blocks use")
	session.player.life.hurt_remaining = 0
	session.intro_active = true
	blocked("scripted intro blocks use")
	session.intro_active = false
	session.dialogue_ui.start(load("res://data/dialogue/ten_victory.tres") as DialogueConfig, PackedStringArray(["test"]))
	blocked("ordinary dialogue blocks use")
	session.dialogue_ui.dismiss()
	session.dialogue_ui.show_departure()
	blocked("departure confirmation blocks use")
	session.dialogue_ui.dismiss()
	paused = true
	blocked("menu pause blocks direct invocation")
	paused = false
	session.player.life.scripted_control_locked = true
	blocked("scripted control lock blocks use")
	session.player.life.scripted_control_locked = false
	for action: String in ["attack", "dodge", "recover"]:
		Input.action_press(action)
		blocked("same-frame existing action takes priority over Q: " + action)
		Input.action_release(action)
		await ticks(1)
	# Real Q input while airborne, then Back on the ground. Holding never repeats.
	session.player.position = Vector2(400, 1300)
	session.player.reset_kinematics()
	session.set_physics_process(true)
	session.player.set_physics_process(true)
	await ticks(2)
	check(not session.player.is_on_floor(), "Q test begins airborne")
	var q: InputEventKey = InputEventKey.new()
	q.physical_keycode = KEY_Q
	q.keycode = KEY_Q
	q.pressed = true
	Input.parse_input_event(q)
	await ticks(2)
	check(session.medkit_count() == 2 and session.player.life.health == 3, "real airborne Q action heals two")
	await ticks(5)
	check(session.medkit_count() == 2 and session.player.life.health == 3, "holding Q cannot consume repeatedly")
	q.pressed = false
	Input.parse_input_event(q)
	await ticks(1)
	session.player.position = Vector2(400, 1536)
	session.player.reset_kinematics()
	await ticks(4)
	check(session.player.is_on_floor(), "Back test begins grounded")
	var back: InputEventJoypadButton = InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_BACK
	back.pressed = true
	Input.parse_input_event(back)
	await ticks(2)
	check(session.medkit_count() == 1 and session.player.life.health == 5, "mapped Back event heals on ground")
	back.pressed = false
	Input.parse_input_event(back)
	await ticks(1)
	await ticks(1)
	var hud: Dictionary = (session.ui.get("_hud") as FormalHud).drawn
	check(hud["emblem"]["medkits"] == "× 1" and (session.ui.get("_health") as Label).text.contains("Q / Back 药包"), "HUD exposes actual inventory and use action")
	# Revisit and real death/reload preserve consumed supply keys and count.
	await enter(TowerSession.TOWER_ID)
	await enter(ExplorationSession.EXPLORATION_ID)
	check(not session.medkit_supply().visible and session.medkit_count() == 1, "Room revisit does not respawn claimed supply")
	session.player.life.health = 1
	session.player.life.take_hit(1)
	blocked("dead player cannot consume")
	await ticks(90)
	check(session.store.load_slot(1)["medkits"] == 1, "death settlement preserves inventory")
	session.ui.call("restart_challenge")
	await ticks(5)
	session = current_scene as FinalBattleSession
	check(session.medkit_count() == 1 and session.player.life.health == 5 and session.data["events"].get(source_key, false), "actual death reload keeps count and pickup keys")
	check(session.start_slot(2, true), "second slot new game starts")
	await ticks(5)
	session = current_scene as FinalBattleSession
	check(session.medkit_count() == 0 and not session.data["events"].has(MedkitRules.key(ExplorationSession.EXPLORATION_ID)) and session.store.load_slot(1)["medkits"] == 1, "new slot is independent of first inventory and claims")
	check(session.start_slot(1, false), "first slot normally resumes")
	await ticks(5)
	session = current_scene as FinalBattleSession
	check(session.medkit_count() == 1, "normal slot load preserves inventory")
	session.queue_free()
	await ticks(2)
	current_scene = null
	print("MEDKIT_SESSION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
