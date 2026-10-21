# verify-suite: {"name":"UI data signals through real input rewards and session reloads","path":"res://tests/test_ui_data.gd","marker":"UI_DATA_TESTS checks=","fixed_fps":60,"timeout":60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var days: Array[int] = []
var shortfalls: Array[int] = []
var rewards: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
	if is_instance_valid(current_scene):
		session = current_scene as FinalBattleSession

func press(action: String) -> void:
	Input.action_press(action)
	await frames(1)
	Input.action_release(action)
	await frames(1)

func observe(node: Node) -> void:
	if node is FinalBattleSession:
		node.connect("day_changed", func(day: int) -> void: days.append(day))

func time_state() -> Dictionary:
	return session.call("ui_time_state")

func fixture(day: int, remaining: float) -> Dictionary:
	var result: Dictionary = session.store.fresh()
	result["events"][StartRoomSession.BIRTH] = true
	result["day"] = day
	result["day_remaining"] = remaining
	result["day3_remaining"] = remaining if day == 3 else 1800.0
	if day == 3:
		result["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
		for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
			result["events"][flag] = true
	return result

func run() -> void:
	directory = "user://tests/ui_data_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	var actions: PlayerPossibility = session.get_node("Player/GameplayRoot/Possibility") as PlayerPossibility
	# Fail clearly against the approved baseline, before connecting missing APIs.
	check(actions.has_signal("shortfall"), "shortfall signal exists")
	check(actions.has_signal("gained"), "gain signal exists")
	check(session.has_signal("day_changed") and session.has_method("ui_time_state"), "session date signal and read-only query exist")
	if failures:
		session.free()
		finish()
		return
	node_added.connect(observe)
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(not bool(time_state()["has_session"]) and days.is_empty(), "slot menu has no invented day or final battle")
	check(session.store.save_slot(1, fixture(1, 1800)) and session.start_slot(1, false), "real first-day slot loads")
	await frames(12)
	check(days == [1], "initial snapshot publishes its date once")
	actions = session.player.possibility
	actions.connect("shortfall", func(kind: int) -> void: shortfalls.append(kind))
	actions.connect("gained", func(amount: int, source: Vector2) -> void: rewards.append({"amount":amount,"source":source}))
	await player_cases(actions)
	await session_cases()
	paused = false
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	# Allow the audio thread to release playback after the real combat scene exits.
	# --fixed-fps advances SceneTree timers faster than the audio thread's wall time.
	OS.delay_msec(500)
	for selected: int in [1, 2, 3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	finish()

func player_cases(actions: PlayerPossibility) -> void:
	session.player.life.health = 3
	actions.balance = 2
	await press("recover")
	check(shortfalls == [0] and actions.balance == 2 and not actions.busy(), "real heal input below 3 emits one HEAL without charge")
	shortfalls.clear()
	session.player.life.health = 5
	await press("recover")
	check(shortfalls.is_empty(), "full health takes priority over insufficient balance")
	session.player.life.health = 3
	actions.balance = 3
	await press("recover")
	check(shortfalls.is_empty() and actions.balance == 0, "exact heal cost emits no shortfall")
	actions.reset_actions()
	session.player.life.hurt_remaining = 1
	await press("recover")
	check(shortfalls.is_empty(), "hurt lock suppresses heal shortfall")
	session.player.life.hurt_remaining = 0
	session.player.life.scripted_control_locked = true
	await press("recover")
	check(shortfalls.is_empty(), "script control lock suppresses heal shortfall")
	session.player.life.scripted_control_locked = false
	session.player.position.y -= 160
	await frames(1)
	await press("recover")
	check(shortfalls.is_empty(), "airborne heal input has no shortfall")
	session.player.position = session._checkpoint(StartRoomSession.CHECKPOINT).config.spawn_position
	session.player.reset_kinematics()
	await frames(15)
	actions.balance = 2
	await press("dodge")
	check(shortfalls.is_empty() and actions.balance == 1, "first dodge costs 1 with no shortfall")
	await frames(24)
	await press("dodge")
	check(shortfalls == [1] and actions.balance == -1 and actions.poor_dodge, "second real dodge costs 2 against balance 1 and emits DODGE once")
	shortfalls.clear()
	actions.reset_actions()
	actions.balance = 1
	await press("dodge")
	check(shortfalls.is_empty() and actions.balance == 0, "exact dodge cost has no shortfall")
	actions.reset_actions()
	actions.balance = actions.config.floor_balance
	await press("dodge")
	check(shortfalls.is_empty() and actions.balance == actions.config.floor_balance, "floor-rejected dodge does not report an executed overdraft")
	actions.reset_actions()
	actions.balance = 9
	actions.call("gain", 7, Vector2(12, 34))
	check(rewards.size() == 1 and rewards[0] == {"amount":1,"source":Vector2(12,34)}, "gain reports actual credited amount and explicit world source")
	actions.gain(2)
	actions.gain(0)
	actions.gain(-1)
	check(rewards.size() == 1, "capped zero and negative gains invent no reward effect")
	actions.balance = -3
	var position: Vector2 = session.player.global_position
	actions.gain(2)
	check(rewards.back() == {"amount":2,"source":position} and actions.balance == -1, "debt repayment defaults source to player world position")
	# Production enemy defeat wiring, not just a call to the new signal or query.
	var world: Node2D = (load("res://debug/enemy_lab.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(world)
	var fighter: PlayerController = world.get_node("Player") as PlayerController
	var kill_rewards: Array[int] = []
	fighter.possibility.connect("gained", func(amount: int, _source: Vector2) -> void: kill_rewards.append(amount))
	var receiver: CombatHurtbox = world.get_node("Enemies/GroundEntity/GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.receive_attack(20, Vector2.ZERO, fighter, 123)
	receiver.receive_attack(20, Vector2.ZERO, fighter, 124)
	check(kill_rewards == [2] and fighter.possibility.balance == 5, "real enemy defeat emits one gain despite repeated hit")
	fighter.life.take_hit(99)
	fighter.possibility.gain(2)
	check(kill_rewards == [2], "dead player receives no gain signal")
	world.queue_free()
	await process_frame

func session_cases() -> void:
	session.player.possibility.reset_actions()
	session.data["day_remaining"] = 180.0
	var before: Dictionary = session.data.duplicate(true)
	var state: Dictionary = time_state()
	check(state["day_warning"] and state["day_warning_remaining"] == 180.0 and is_equal_approx(state["day_progress"], 0.9), "three-minute threshold and normalized day progress use real clock")
	state["day"] = 99
	check(session.data == before and time_state()["day"] == 1, "query is detached and never mutates session or saves")
	session.data["day_remaining"] = 180.1
	check(not time_state()["day_warning"], "above three minutes is not imminent")
	paused = true
	var remaining: float = DayClock.remaining(session.data)
	await frames(4)
	check(DayClock.remaining(session.data) == remaining and days == [1], "pause freezes source clock without duplicate day signals")
	paused = false
	session.data["day_remaining"] = 0.01
	await frames(4)
	check(days == [1, 2] and time_state()["day"] == 2, "natural physics rollover emits new day exactly once")
	check(session.store.save_slot(2, fixture(3, 1500)) and session.start_slot(2, false), "cross-day slot loads through real reload path")
	await frames(6)
	check(days == [1, 2, 3] and time_state()["day"] == 3, "cross-day load emits restored day exactly once")
	check(not time_state()["day_warning"], "third day has no fictitious fourth-day warning")
	var death_time: float = DayClock.remaining(session.data)
	session.player.life.take_hit(99)
	await frames(90)
	check(session.player.life.state == PlayerLife.State.DEATH_MENU and days == [1, 2, 3], "death animation emits no stale date")
	session.ui.call("restart_challenge")
	await frames(6)
	check(days == [1, 2, 3, 3] and time_state()["day"] == 3, "new scene after death publishes restored day once")
	check(DayClock.remaining(session.data) <= death_time and DayClock.remaining(session.data) > death_time - 1, "death query retains real remaining clock without refill")
	# Enter final battle by its Room signal path; no synthetic final state field.
	session.set_physics_process(false)
	session.data["day3_remaining"] = 1500.0
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	await frames(2)
	state = time_state()
	check(state["final_active"] and state["final_remaining"] == 900.0 and state["final_start_day3_remaining"] == 1500.0 and state["final_start_known"], "actual battle-start path exposes exact original day3 balance and real 900 budget")
	check(state["final_acceleration"] and state["day_remaining"] == 1500.0, "long budget enables presentation without spending clock")
	var stored: Dictionary = session.store.load_slot(2)
	check(not stored.has("final_start_day3_remaining") and not stored.has("final_start_known"), "presentation history never enters save format")
	check(session.start_slot(2, false), "started battle save can reload")
	await frames(6)
	state = time_state()
	check(not state["final_start_known"] and state["final_start_day3_remaining"] == -1.0 and not state["final_acceleration"], "load marks unavailable historical balance unknown and never replays acceleration")
	check(state["final_active"] and state["final_remaining"] <= 900.0 and state["final_remaining"] > 899.0, "reloaded query still exposes real final budget")
	check(days == [1, 2, 3, 3, 3], "started-battle reload still publishes its snapshot date only once")
	session.set_physics_process(false)
	# New slot clears old runtime presentation, then a short-budget start stays short.
	check(session.store.save_slot(3, fixture(3, 552)) and session.start_slot(3, false), "independent short-budget slot loads")
	await frames(5)
	session.set_physics_process(false)
	session.data["day3_remaining"] = 552.0
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	await frames(2)
	state = time_state()
	check(state["final_start_known"] and state["final_start_day3_remaining"] == 552 and state["final_remaining"] == 552 and not state["final_acceleration"], "short-budget start has exact 552 and no acceleration")
	check(days == [1, 2, 3, 3, 3, 3], "slot switching emits one current snapshot without old-slot duplicates")

func finish() -> void:
	print("UI_DATA_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
