# verify-suite: {"name": "formal enemy cards (ordinary, elite, Boss) and battlefield banners on real encounters", "path": "res://tests/test_enemy_cards.gd", "marker": "ENEMY_CARDS_TESTS checks=", "fixed_fps": 60, "timeout": 240}
extends SceneTree
## UI-009: the EXP-004 variant 2 enemy card and the separate battle banner on
## the real campaign session, triggered by the real encounters. Assertions
## read what was drawn.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

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

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func card() -> EnemyCard:
	return session.ui.get("_enemy_intro") as EnemyCard

func banner() -> BattleBanner:
	return session.ui.get("_battle_banner") as BattleBanner

func place(point: Vector2) -> void:
	session.player.position = point
	session.player.reset_kinematics()
	await ticks(4)

## Each case gets its own session, as a player would load that save.
func load_slot(selected: int, snapshot: Dictionary) -> void:
	if is_instance_valid(session):
		paused = false
		session.queue_free()
		await ticks(2)
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	await ticks(2)
	check(session.store.save_slot(selected, snapshot) and session.start_slot(selected, false), "slot %d loads" % selected)
	await ticks(4)
	session = current_scene as FinalBattleSession

func fresh() -> Dictionary:
	var snapshot: Dictionary = session.store.fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["events"][StartRoomSession.GUIDE] = true
	return snapshot

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_enemy_cards_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	await ticks(2)
	await ordinary_cases()
	await elite_cases()
	await overlook_cases()
	await parasite_cases()
	await banner_cases()
	await layout_cases()
	await presence_cases()
	paused = false
	session.queue_free()
	await ticks(2)
	OS.delay_msec(500)
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("ENEMY_CARDS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

## First colorless encounter: ordinary card, slide in / stay / slide out,
## pause freezes it, hide_enemy_intro() takes it away at once.
func ordinary_cases() -> void:
	var snapshot: Dictionary = fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	await load_slot(1, snapshot)
	check(not card().visible and card().drawn.is_empty(), "no card before the encounter")
	session.player.position = Vector2(608, 896)
	session.player.reset_kinematics()
	for i: int in range(30):
		await ticks(1)
		if card().drawn.has("title"):
			break
	var drawn: Dictionary = card().drawn
	check(card().visible and drawn.get("title", {}).get("text") == "无色实体" and drawn.get("kind", {}).get("text") == "普通敌人" and str(drawn.get("tips", {}).get("text", "")).contains("观察攻击前摇"), "the first colorless encounter shows an ordinary card with name, kind and tips")
	check(drawn.get("title", {}).get("color") == DuskStyle.PAPER_DAY and drawn.get("band", {}).get("color") == EnemyCard.INK_BAND and drawn.has("under") and not drawn.has("seal"), "ink band with the name in paper colour, a block under it, no seal")
	check((drawn["rect"] as Rect2).position.x > card().settled_x() + 1.0, "it enters from the right")
	await ticks(16)
	var settled: Rect2 = card().drawn["rect"]
	check(is_equal_approx(settled.end.x, EnemyCard.RIGHT) and is_equal_approx(settled.position.y, EnemyCard.TOP), "and settles in the top-right corner")
	session.ui.call("show_pause")
	var remaining: float = session.ui.get("_enemy_intro_remaining")
	await ticks(30)
	check(session.ui.get("_enemy_intro_remaining") == remaining and card().drawn.get("rect") == settled, "pausing holds the card and its time")
	session.ui.call("resume_game")
	await ticks(ceili(float(session.ui.get("_enemy_intro_remaining")) * 60) + 2)
	check(card().visible and (card().drawn["rect"] as Rect2).position.x > settled.position.x, "when its time is up it slides out to the right")
	await ticks(20)
	check(not card().visible and card().drawn.is_empty(), "and is gone")
	# Review R2: paused halfway in, then halfway out.
	session.ui.call("show_enemy_intro", 1.0)
	await ticks(2)
	session.ui.call("show_pause")
	var halfway: float = card().position.x
	var left: float = session.ui.get("_enemy_intro_remaining")
	await ticks(30)
	check(halfway > card().settled_x() + 1.0 and halfway < 1920.0 and card().position.x == halfway and session.ui.get("_enemy_intro_remaining") == left, "pausing halfway in holds the card where it is and its time")
	session.ui.call("resume_game")
	await ticks(16)
	check(is_equal_approx(card().position.x, card().settled_x()), "resuming lets it finish sliding in")
	var out: bool = false
	for i: int in range(120):
		await ticks(1)
		if card().position.x > card().settled_x() + 1.0:
			out = true
			break
	session.ui.call("show_pause")
	var leaving: float = card().position.x
	await ticks(30)
	check(out and card().visible and leaving < 1920.0 and card().position.x == leaving, "pausing halfway out holds the card where it is")
	session.ui.call("resume_game")
	await ticks(20)
	check(not card().visible, "resuming lets it finish sliding out")
	session.ui.call("show_enemy_intro", 5.0)
	await ticks(6)
	session.ui.call("hide_enemy_intro")
	await ticks(1)
	check(not card().visible and card().drawn.is_empty(), "hide_enemy_intro() takes the card away at once")

func elite_cases() -> void:
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchSession.TRENCH_CHECKPOINT
	snapshot["balance"] = -9
	snapshot["day"] = 3
	snapshot["events"][ParasiteSession.DODGE_PENDING] = true
	await load_slot(1, snapshot)
	for enemy: Node in session.room.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
	await place(Vector2(704, 1792))
	var drawn: Dictionary = card().drawn
	check(drawn.get("title", {}).get("text") == "天人战士" and drawn.get("kind", {}).get("text") == "精英" and not drawn.has("seal") and str(drawn.get("tips", {}).get("text", "")).contains("格挡反击"), "the Tian warriors show an elite card without a seal")
	session.ui.call("hide_enemy_intro")

func seal_ok(drawn: Dictionary, name: String) -> bool:
	var seal: Dictionary = drawn.get("seal", {})
	var band: Rect2 = drawn.get("band", {}).get("rect", Rect2())
	return drawn.get("title", {}).get("text") == name and drawn.get("kind", {}).get("text") == "首领" and seal.get("text") == "首\n领" and seal.get("color") == Color(DuskStyle.LIFE, 0.95) and band.encloses(seal.get("rect", Rect2()))

func overlook_cases() -> void:
	var snapshot: Dictionary = fresh()
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	for key: String in [TwoRoomSession.ENCOUNTER, "gate:HD_10003_1:return", "gate:HD_10003_1:forward"]:
		snapshot["events"][key] = true
	await load_slot(1, snapshot)
	session._on_room_exit(TowerSession.TOWER_ID)
	await ticks(4)
	session._on_room_exit(ExplorationSession.EXPLORATION_ID)
	await ticks(4)
	session._on_room_exit(ConnectionSession.CONNECTION_ID)
	await ticks(4)
	await place(Vector2(1488, 896))
	check(session.room.config.room_id == BossSession.BOSS_ID and session.intro_active, "the overlook Boss introduction starts")
	await ticks(16)
	check(seal_ok(card().drawn, "渴望俯视"), "the overlook Boss gets the Boss card with the vermilion 首领 seal on its band")
	check(is_equal_approx((card().drawn["rect"] as Rect2).size.x, EnemyCard.BOSS_WIDTH) and is_equal_approx((card().drawn["rect"] as Rect2).end.x, EnemyCard.RIGHT), "the Boss card is the wider one and settles in the same corner")
	session.ui.call("hide_enemy_intro")

func parasite_cases() -> void:
	var base: Dictionary = session.store.fresh()
	base["checkpoint"] = CampWavesSession.WAVES_CHECKPOINT
	base["day"] = 2
	base["maximum"] = 14
	base["balance"] = 7
	for key: String in [BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE, TownSession.GAZE, RavineRescueSession.HELPED, RavineDepthSession.DEPTH_HELPED, RavineDepthRoom.GATES, RavineSession.RAVINE_CHECKPOINT]:
		base["events"][key] = true
	await load_slot(1, base)
	var camp: CampWavesRoom = session.room as CampWavesRoom
	camp.waves = camp.waves.duplicate(true) as CampWaveConfig
	camp.waves.warning = 0.01
	camp.waves.interval = 0.01
	camp.start_waves()
	for wave: int in range(3):
		for i: int in range(8):
			if camp.phase == CampWavesRoom.Phase.ACTIVE: break
			await ticks(1)
		for enemy: ColorlessEntity in camp.living():
			enemy.set_physics_process(false)
			enemy.hurtbox.receive_attack(enemy.health, Vector2.ZERO, session.player, 30000 + wave)
		await ticks(1)
	session.save_current()
	await place(Vector2(1824, 1280))
	check(session.room.config.room_id == ParasiteSession.PARASITE_ID and session.intro_active, "the parasite Boss introduction starts")
	await ticks(16)
	check(seal_ok(card().drawn, "寄生同伴者"), "the parasite Boss gets the Boss card with the seal")
	session.ui.call("hide_enemy_intro")

## Final battle wave warnings go to the banner, never the card corner.
func banner_cases() -> void:
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	snapshot["balance"] = -9
	snapshot["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	for key: String in [TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
		snapshot["events"][key] = true
	await load_slot(1, snapshot)
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	await place(Vector2(450, 896))
	var arena: FinalBattlefieldRoom = session.room as FinalBattlefieldRoom
	for child: Node in arena.get_node("Allies").get_children():
		child.set_physics_process(false)
	for child: Node in arena.get_node("Enemies").get_children():
		if child is ColorlessEntity:
			(child as ColorlessEntity).set_physics_process(false)
			(child as ColorlessEntity).hurtbox.receive_attack((child as ColorlessEntity).health, Vector2.ZERO, session.player, 8000)
	var seen: Dictionary = {}
	for i: int in range(120):
		await ticks(1)
		if banner().drawn.has("heading") and float(banner().drawn["alpha"]) > 0.5:
			seen = banner().drawn.duplicate(true)
			break
	check(str(seen.get("heading", {}).get("text", "")) == "敌方第2波即将进入" and str(seen.get("line", {}).get("text", "")).contains("最后一波"), "the real wave warning shows on the battle banner")
	var corner: Rect2 = Rect2(Vector2(EnemyCard.RIGHT - EnemyCard.BOSS_WIDTH, EnemyCard.TOP), Vector2(EnemyCard.BOSS_WIDTH, 300))
	var rect: Rect2 = seen.get("rect", Rect2())
	check(not card().visible and not rect.intersects(corner) and absf(rect.get_center().x - 960.0) < 1.0 and rect.position.y < 540.0, "at the top centre, not in the card's corner, and the card stays away")
	var ink: Color = Color(BattleBanner.INK_BAND, BattleBanner.INK_BAND.a * float(seen.get("alpha", 0.0)))
	check(seen.get("band", {}).get("rect") == rect and str(seen.get("band", {}).get("color")) == str(ink) and float(seen["alpha"]) > 0.0 and str(seen.get("heading", {}).get("color")) == str(Color(DuskStyle.PAPER_DAY, seen["alpha"])), "drawn as an ink band (the colour actually filled, at its alpha) with paper-coloured text")
	session.ui.call("show_battle_banner", 3.0, "新一波敌人进入战场\n\n刚才的敌人已被10全灭。")
	await ticks(30)
	session.ui.call("show_pause")
	var age: float = banner().age
	await ticks(30)
	check(banner().age == age and banner().drawn.has("heading"), "pausing holds the banner")
	session.ui.call("resume_game")
	await ticks(200)
	check(banner().drawn.is_empty() and not banner().showing(), "it fades out when its time is up")
	session.ui.call("show_battle_banner", 3.0, "中心战场 · 首段完成\n\n本提示不代表最终胜利。")
	await ticks(10)
	session.ui.call("hide_enemy_intro")
	await ticks(1)
	check(banner().drawn.is_empty(), "hide_enemy_intro() also clears a stage banner, as it cleared the shared card before")

## Both window sizes: card and banner on screen and clear of the HUD as
## drawn, the dialogue slip, the area name, the interaction prompt, the save
## error and each other.
func layout_cases() -> void:
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		session.ui.call("save_failed", "存档写入失败，请稍后重试")
		session.ui.call("show_enemy_card", 20.0, "渴望俯视", "首领", "留意落击提示。\n利用召唤平台接近高空目标。")
		session.ui.call("show_battle_banner", 20.0, "中心战场 · 10协同阶段完成\n\n最终波次、15分钟时限与结局将在下一阶段接入。\n本提示不代表最终胜利。")
		session.dialogue_ui.start(DialogueConfig.new(), PackedStringArray(["测试台词"]))
		var area: AreaBanner = session.ui.get("_area_banner") as AreaBanner
		area.pending = "测试区域"
		await ticks(30)
		var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(1920, 1080))
		var card_rect: Rect2 = card().drawn.get("rect", Rect2())
		var band: Rect2 = banner().drawn.get("rect", Rect2())
		var others: Dictionary = {}
		for key: String in ["emblem", "hint", "horizon", "warning", "final", "banner"]:
			if hud.drawn.has(key) and hud.drawn[key].has("rect"):
				others["hud " + key] = hud.drawn[key]["rect"]
		var slip: Dictionary = session.dialogue_ui.drawn
		if slip.has("box"):
			others["dialogue"] = (slip["box"] as Rect2).merge(slip.get("hint_rect", slip["box"]))
		for name: String in ["_area_banner", "_interact_prompt"]:
			var node: Object = session.ui.get(name)
			if node.get("drawn").has("rect"):
				others[name] = node.get("drawn")["rect"]
		var error: Label = session.ui.get("_error_label") as Label
		if error.is_visible_in_tree():
			others["error"] = error.get_global_rect()
		var clash: Array[String] = []
		for key: String in others:
			if card_rect.intersects(others[key]): clash.append("card/" + key)
			if band.size != Vector2.ZERO and band.intersects(others[key]): clash.append("banner/" + key)
		if card_rect.intersects(band): clash.append("card/banner")
		check(card_rect.size != Vector2.ZERO and screen.encloses(card_rect) and slip.has("box") and others.has("error"), "%dx%d: the card is up with the dialogue and the save error" % [window.x, window.y])
		check(band.size != Vector2.ZERO and screen.encloses(band), "%dx%d: the banner found a clear spot on screen" % [window.x, window.y])
		check(clash.is_empty(), "%dx%d: nothing overlaps %s" % [window.x, window.y, str(clash)])
		session.dialogue_ui.dismiss()
		session.ui.call("save_failed", "")
		session.ui.call("hide_enemy_intro")
		await ticks(2)
	root.size = Vector2i(1920, 1080)

## Review N1: with the area name and the interaction prompt really on screen
## (no dialogue), the card and banner stay clear of them; and when every
## banner height is taken the banner gives way without stopping its clock.
func presence_cases() -> void:
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		session.data["events"][FieldSession.FIELD_STORY] = true
		session._mount_room(FieldSession.FIELD_ID)
		session._bind_room()
		session.intro_active = false
		session.player.life.scripted_control_locked = false
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
		session.player.position = session.room.get_node("Seven").position
		session.player.reset_kinematics()
		var area: AreaBanner = session.ui.get("_area_banner") as AreaBanner
		area.pending = "测试区域"
		session.ui.call("show_enemy_card", 20.0, "渴望俯视", "首领", "留意落击提示。\n利用召唤平台接近高空目标。")
		session.ui.call("show_battle_banner", 20.0, "中心战场 · 首段完成\n\n本提示不代表最终胜利。")
		var prompt: InteractPrompt = session.ui.get("_interact_prompt") as InteractPrompt
		var both: bool = false
		for i: int in range(120):
			await ticks(1)
			if area.drawn.has("rect") and prompt.drawn.has("rect") and banner().drawn.has("rect") and card().drawn.has("rect") and is_equal_approx((card().drawn["rect"] as Rect2).end.x, EnemyCard.RIGHT):
				both = true
				break
		check(both, "%dx%d: the area name, the prompt, the card and the banner are all drawn" % [window.x, window.y])
		var shown: Array[Rect2] = [area.drawn.get("rect", Rect2()), prompt.drawn.get("rect", Rect2()), card().drawn.get("rect", Rect2()), banner().drawn.get("rect", Rect2())]
		var apart: bool = both
		for a: int in range(shown.size()):
			apart = apart and Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(shown[a])
			for b: int in range(a + 1, shown.size()):
				apart = apart and not shown[a].intersects(shown[b])
		check(apart, "%dx%d: area name, prompt, card and banner are on screen and apart" % [window.x, window.y])
		session.ui.call("hide_enemy_intro")
		await ticks(2)
	root.size = Vector2i(1920, 1080)
	var avoid: Callable = banner().avoid
	banner().avoid = func() -> Array[Rect2]: return [Rect2(Vector2.ZERO, Vector2(1920, 1080))]
	session.ui.call("show_battle_banner", 2.0, "敌方第3波即将进入")
	await ticks(30)
	check(banner().showing() and banner().drawn.is_empty() and banner().age > 0.4, "with every height taken the banner gives way and its clock keeps running")
	banner().avoid = avoid
	await ticks(2)
	check(banner().drawn.has("heading"), "and it shows as soon as a spot is free")
	session.ui.call("hide_enemy_intro")

