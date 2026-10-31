# verify-suite: {"name": "formal HUD draws real life possibility time and final budgets", "path": "res://tests/test_formal_hud.gd", "marker": "FORMAL_HUD_TESTS checks=", "fixed_fps": 60, "timeout": 90}
extends SceneTree
## UI-002: the formal HUD is checked through what it actually drew (EXP-002
## "drawn record"), driven by the real player, real input and real sessions.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

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

func hud() -> FormalHud:
	return session.ui.get("_hud") as FormalHud

func drawn() -> Dictionary:
	return hud().drawn

func quiet() -> void:
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)

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

## The colours the user chose (EXP-002 sample two); identical on every day.
const CHOSEN: Dictionary = {"life": DuskStyle.LIFE, "possibility": DuskStyle.POSSIBILITY, "growth": DuskStyle.GROWTH, "growth_dim": Color(DuskStyle.GROWTH, 0.35), "overdraft": DuskStyle.OVERDRAFT}

## Key colours as actually passed to the draw calls: one frame with growth
## capacity (lit and dim outer segments), one in overdraft. No flash or pulse.
func key_colours() -> Dictionary:
	var actions: PlayerPossibility = session.player.possibility
	var base: int = actions.config.maximum
	var keep: Array[int] = [actions.balance, actions.maximum]
	actions.maximum = base + 2
	actions.balance = base + 1
	await frames(2)
	var record: Dictionary = drawn()
	var result: Dictionary = {"life": record.get("life_fill"), "possibility": record.get("possibility_fill"), "growth": record.get("growth_fill"), "growth_dim": record.get("growth_dim")}
	actions.balance = -3
	await frames(2)
	result["overdraft"] = drawn().get("overdraft_fill")
	actions.balance = keep[0]
	actions.maximum = keep[1]
	await frames(2)
	return result

func run() -> void:
	directory = "user://tests/formal_hud_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.store.save_slot(1, fixture(1, 1800)) and session.start_slot(1, false), "real first-day slot loads")
	await frames(12)
	await emblem_cases()
	await time_cases()
	await final_cases()
	paused = false
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	OS.delay_msec(500)
	for selected: int in [1, 2, 3]:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("FORMAL_HUD_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func emblem_cases() -> void:
	var player: PlayerController = session.player
	var actions: PlayerPossibility = player.possibility
	var hint: Label = session.ui.get("_health") as Label
	check(hud().is_visible_in_tree() and drawn()["font"] == UiTheme.FONT_PATH, "HUD is live and draws with the handwriting font")
	check(hint.get_theme_font("font").resource_path == UiTheme.FONT_PATH and hint.text.contains("K / B 滑步") and hint.text.contains("Q / Back 药包"), "kept control hint uses the theme font")
	check(drawn().has("hint") and (drawn()["hint"]["rect"] as Rect2).encloses(Rect2(hint.global_position, hint.size)), "hint sits on its own paper tag")
	check(not drawn().has("banner"), "SYS-005 N1: loading a session shows no day banner")
	player.life.health = 3
	actions.balance = 4
	player.combat.pearl_count = 2
	session.data["medkits"] = 2
	await frames(2)
	var emblem: Dictionary = drawn()["emblem"]
	check(emblem["life"] == 3 and emblem["filled"] == 4 and emblem["overdraft"] == 0, "emblem draws current life shards and filled possibility")
	check(emblem["pearls"] == 2 and emblem["reach"] == "范围 %d%%" % roundi(player.combat.range_multiplier() * 100) and emblem["medkits"] == "× 2", "pearls, reach tag and medkits follow real state (G-02)")
	check(not drawn().has("last_life") and drawn()["deny_flash"] == 0.0, "calm state has no edge pulse and no flash")
	# Requirement 2: a real heal input without enough possibility flashes the ring.
	actions.balance = 2
	await press("recover")
	var peak: float = 0.0
	var outline_hit: bool = false
	var fill_hit: bool = false
	for i: int in range(20):
		await frames(1)
		peak = maxf(peak, float(drawn()["deny_flash"]))
		outline_hit = outline_hit or (drawn()["ring_outline"] as Color).r > DuskStyle.INK.r + 0.25
		fill_hit = fill_hit or not (drawn()["possibility_fill"] as Color).is_equal_approx(DuskStyle.POSSIBILITY)
	check(actions.balance == 2 and peak > 0.5 and outline_hit and fill_hit, "real heal shortfall flashes the ring red (A-018)")
	await frames(60)
	check(drawn()["deny_flash"] == 0.0 and (drawn()["possibility_fill"] as Color).is_equal_approx(DuskStyle.POSSIBILITY), "flash ends and the ring returns to its key colour")
	# Real chained dodges into overdraft: flash, reverse dark-red ring, distortion.
	player.life.health = 5
	player.position = session._checkpoint(StartRoomSession.CHECKPOINT).config.spawn_position
	player.reset_kinematics()
	await frames(15)
	actions.balance = 1
	await press("dodge")
	await frames(24)
	await press("dodge")
	check(actions.balance == -2 and hud().deny_left > 0.0, "real second dodge overdraws and triggers the shortfall flash")
	await frames(30)
	emblem = drawn()["emblem"]
	check(emblem["overdraft"] == 2 and drawn().has("overdraft_fill"), "overdraft darkens two ring segments from the top")
	check(hud().filter_rect.visible and hud().distortion_strength > 0.3 and hud().filter.layer < (session.ui as CanvasLayer).layer and hud().filter.layer < session.dialogue_ui.layer, "game scene is distorted under every UI layer while overdrawn")
	var shallow: float = hud().distortion_target()
	actions.balance = actions.config.floor_balance
	await frames(2)
	check(hud().distortion_target() > shallow and is_equal_approx(hud().distortion_target(), 1.0), "distortion deepens with the overdraft")
	actions.balance = 3
	await frames(90)
	check(not hud().filter_rect.visible and hud().distortion_strength == 0.0, "distortion clears once the balance is back above zero")
	# Requirement 1: gained possibility flies from its world source into the ring.
	var source: Vector2 = player.global_position + Vector2(300, -120)
	actions.gain(2, source)
	await frames(1)
	check(drawn()["flyers"]["count"] == 2, "real gain spawns one flyer per credited point")
	var start: Vector2 = hud().get_viewport().get_canvas_transform() * source
	check((hud().flyers[0]["from"] as Vector2).is_equal_approx(start), "flyer starts at the gain source's screen position")
	await frames(50)
	check(hud().flyers.is_empty() and hud().gain_pulse > 0.0, "flyers land in the ring and pulse it")
	# Growth capacity as the outer arc.
	actions.maximum = actions.config.maximum + 2
	actions.balance = actions.config.maximum + 1
	await frames(2)
	emblem = drawn()["emblem"]
	check(emblem["growth"] == 2 and emblem["growth_lit"] == 1 and emblem["filled"] == actions.config.maximum, "growth capacity draws as outer arc segments")
	actions.maximum = actions.config.maximum
	actions.balance = 3
	# Requirement 3: last point of life pulses the screen edge vermilion.
	player.life.health = 1
	await frames(2)
	check(drawn().has("last_life") and drawn()["last_life"]["color"] == DuskStyle.LIFE and drawn()["emblem"]["life"] == 1, "last life pulses the edge vermilion")
	player.life.health = 5
	await frames(2)
	check(not drawn().has("last_life"), "edge pulse stops above one life")
	# Story scenes hide the HUD through the kept hint label.
	hint.hide()
	check(not hud().visible, "hiding the HUD row hides the formal HUD")
	hint.show()
	check(hud().visible, "showing it again restores the formal HUD")

func time_cases() -> void:
	var actions: PlayerPossibility = session.player.possibility
	actions.reset_actions()
	actions.balance = 3
	await frames(70)
	var day_one: Dictionary = await key_colours()
	check(day_one == CHOSEN, "day one draws life, possibility, growth and overdraft in the chosen colours")
	# UI-011 (user 2026-10-31): the horizon, time tag and date tag are hidden.
	check(not FormalHud.SHOW_HORIZON and not drawn().has("horizon"), "the time axis is hidden")
	session.data["day_remaining"] = 900.0
	await frames(2)
	check(not drawn().has("horizon") and hud().clock_text(hud().time_state()).begins_with("15:0"), "time of day still advances under the hidden axis")
	session.data["day_remaining"] = 180.0
	await frames(2)
	check(drawn().has("warning") and drawn()["warning"]["text"] == "即将进入第 2 日 · 3:00", "three minutes before the next day shows the lower-right warning")
	var early_dusk: float = drawn()["dusk"]
	session.data["day_remaining"] = 0.01
	await frames(4)
	check(int(session.data["day"]) == 2 and drawn().has("banner") and drawn()["banner"]["text"] == "第 二 日", "natural rollover starts the date-change animation")
	check(not drawn().has("warning"), "warning ends with the new day")
	# UI-011: the half sun rises first, the rings sweep open, then the day name settles.
	var opening: Dictionary = drawn()["banner"]
	check(float(opening["sun"]) < 1.0 and float(opening["title_alpha"]) < 0.05, "the animation opens with the sun still rising and no title yet")
	await frames(90)
	var settled: Dictionary = drawn()["banner"]
	check(is_equal_approx(float(settled["sun"]), 1.0) and float(settled["rings"]) > 0.95 and float(settled["title_alpha"]) > 0.95, "after a second and a half the sun, rings and day name are all shown")
	var area: Rect2 = settled["rect"]
	check(absf(area.get_center().x - 960.0) < 1.0 and area.position.y >= 0.0 and area.end.y <= 360.0, "the animation sits in the upper middle, above the save error line (%s)" % area)
	check(is_equal_approx(float(settled["scale"]), 2.0) and area.size.y > 340.0, "the animation is drawn at twice the first size (user 2026-10-31)")
	check(FormalHud.day_name(3) == "第 三 日" and FormalHud.day_name(12) == "第 12 日", "day names use Chinese numerals with a numeric fallback")
	await frames(160)
	check(not drawn().has("banner"), "banner leaves after the announcement time")
	check(await key_colours() == CHOSEN, "key colours are identical on day two")
	check(session.store.save_slot(2, fixture(3, 300)) and session.start_slot(2, false), "late third-day slot loads")
	await frames(70)
	quiet()
	check(not drawn().has("banner"), "slot switch to a later day is initialisation, not a new-day banner")
	check(float(drawn()["dusk"]) > early_dusk + 0.5 and not DuskStyle.paper_color(hud().time_state()).is_equal_approx(DuskStyle.paper_color({"day": 1})), "dusk deepens with the days")
	check(await key_colours() == CHOSEN, "key colours do not drift on the last day")
	check(not drawn().has("warning"), "third day has no next-day warning")

func start_final(slot: int, day3: float) -> void:
	check(session.store.save_slot(slot, fixture(3, day3)) and session.start_slot(slot, false), "third-day slot with %d s loads" % day3)
	await frames(5)
	session.set_physics_process(false)
	session.data["day3_remaining"] = day3
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	await frames(1)
	quiet()
	session.set_physics_process(true)
	await frames(1)

func final_cases() -> void:
	# Long budget: 25 minutes left, the countdown spins down to 15:00 on screen only.
	await start_final(3, 1500.0)
	var first: Dictionary = drawn()["final"]
	check(hud().time_state()["final_active"] and first["label"] == "时间加速……", "long budget starts with the spin-down")
	check(float(first["shown"]) > 1400.0 and float(first["real"]) <= 900.0, "spin-down starts near the third-day balance while the real budget is 15:00")
	var budget: float = float(first["real"])
	await frames(60)
	var middle: Dictionary = drawn()["final"]
	check(float(middle["shown"]) < float(first["shown"]) - 50.0 and float(middle["shown"]) > float(middle["real"]), "spin-down moves the displayed time, it is not a frozen clock")
	check(float(middle["real"]) < budget - 0.9, "real budget keeps running under the presentation")
	await frames(100)
	var settled: Dictionary = drawn()["final"]
	check(settled["label"] == "最终战倒计时" and settled["color"] == DuskStyle.INK and is_equal_approx(float(settled["shown"]), float(settled["real"])), "after the spin-down the real budget shows in ink")
	check(is_equal_approx(DuskStyle.glow_strength(hud().time_state()), DuskStyle.FINAL_GLOW_SCALE) and float(drawn()["dusk"]) == 1.0, "final battle uses full dusk with 30% softer glow")
	check(await key_colours() == CHOSEN, "key colours are unchanged in the final battle")
	session.set_physics_process(false)
	check(session.start_slot(3, false), "started final battle reloads")
	await frames(4)
	quiet()
	check(drawn()["final"]["label"] == "最终战倒计时", "reload never replays the spin-down")
	# Short budget: 9:12 left, shown directly in vermilion.
	await start_final(1, 552.0)
	var short: Dictionary = drawn()["final"]
	check(short["label"] == "最终战倒计时 · 余时不足" and short["color"] == DuskStyle.LIFE, "short budget warns in vermilion with no spin-down")
	check(short["digits"] == "09:12" or short["digits"] == "09:11", "short budget shows the real remainder")
	# UI-011: no new day can arrive during the final battle, so the date animation never shares the top with its countdown.
	hud().banner_day = 3
	hud().banner_left = 2.0
	await frames(2)
	check(not drawn().has("banner"), "the date-change animation does not play over the final countdown")
	hud().banner_left = 0.0
	var box: Rect2 = short["rect"]
	check(not box.intersects(drawn()["emblem"]["rect"]) and not box.intersects(drawn()["horizon"]["rect"]), "final countdown keeps clear of the emblem and horizon")
	# Exactly 15:00 left is neither "more than" (no spin-down) nor "less than" (no warning).
	await start_final(2, 900.0)
	var even: Dictionary = drawn()["final"]
	check(even["label"] == "最终战倒计时" and even["color"] == DuskStyle.INK and str(even["digits"]).begins_with("1"), "exactly fifteen minutes shows the real budget in ink without spin-down or warning")
	session.set_physics_process(false)
