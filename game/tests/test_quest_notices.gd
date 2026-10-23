# verify-suite: {"name": "formal quest slip and centre notices from SYS-009 signals on the real session", "path": "res://tests/test_quest_notices.gd", "marker": "QUEST_NOTICES_TESTS checks=", "fixed_fps": 60, "timeout": 240}
extends SceneTree
## UI-010: the task slip on the left and the centre notices, driven by the
## real session's quest_changed / item_obtained and FieldDialogue.show_notice.
## Assertions read what was drawn (and the notice history for ordering).
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

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func slip() -> QuestSlip:
	return session.ui.get("_quest_slip") as QuestSlip

func notices() -> CenterNotice:
	return session.ui.get("_center_notice") as CenterNotice

func quiet() -> void:
	session.player.set_physics_process(false)
	session.player.life.protection_remaining = 1000.0
	for node: Node in session.room.find_children("*", "Node", true, false):
		if node is ColorlessEntity or node is RoomRockfall:
			node.set_physics_process(false)

func fresh() -> Dictionary:
	var value: Dictionary = session.store.fresh()
	value["events"][StartRoomSession.BIRTH] = true
	value["events"][WorldDayRules.ENABLED] = true
	value["events"][FieldSession.FIELD_STORY] = true
	return value

func open(snapshot: Dictionary = {}) -> void:
	if is_instance_valid(session):
		await close()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	await frames(1)
	var value: Dictionary = fresh() if snapshot.is_empty() else snapshot
	check(session.store.save_slot(1, value) and session.start_slot(1, false), "isolated real save starts")
	await frames(3)
	quiet()

func close() -> void:
	paused = false
	session.queue_free()
	current_scene = null
	await frames(2)
	OS.delay_msec(300)

func enter(id: String) -> void:
	session._mount_room(id)
	session._bind_room()
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	quiet()
	await frames(3)

## Lets the queue run until it is empty (or `limit` frames pass).
func drain(limit: int = 1200) -> void:
	for i: int in range(limit):
		if not notices().showing():
			return
		await frames(1)

func last(source: String) -> Dictionary:
	for i: int in range(notices().history.size() - 1, -1, -1):
		if notices().history[i]["source"] == source:
			return notices().history[i]
	return {}

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_quest_notices_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	await quest_cases()
	await item_cases()
	await same_name_cases()
	await current_task_cases()
	await merge_cases()
	await hidden_cases()
	await load_cases()
	await layout_cases()
	await close()
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("QUEST_NOTICES_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

## 7's rescue: start, complete (real dialogue and commit), return to 7,
## abandon and expire on fresh saves.
func quest_cases() -> void:
	await open()
	check(slip().drawn.is_empty() and notices().history.is_empty(), "before any task: no slip and no notice")
	check(session.record_event(FieldSession.HEAL_GUIDE), "the rescue starts through its real saved event")
	await frames(3)
	var start: Dictionary = notices().drawn
	check(start.get("title", {}).get("text") == "救助开始" and str(start.get("line", {}).get("text", "")).contains("麦秆镇") and start.get("bar", {}).get("color") == Color(DuskStyle.INK, start["alpha"]), "a centre notice says the task began, in ink")
	check(slip().drawn.get("title", {}).get("text") == "救助" and str(slip().drawn.get("objective", {}).get("text", "")).contains("麦秆镇") and slip().drawn.get("state") == "进行中" and not slip().drawn.has("status"), "the left slip shows 救助 and the current objective")
	var rect: Rect2 = slip().drawn["rect"]
	check(rect.position.x < 200.0 and rect.position.y > 322.0 and rect.end.y < 700.0, "the slip sits at the left, a little above the middle, under the control hint")
	await drain()
	await frames(400)
	check(slip().drawn.has("objective"), "a running task stays on the slip")
	await enter(TownSession.TOWN_ID)
	session.player.position = session.room.get_node("Survivor").position
	check(session.interact_survivor() and session._commit_rescue(), "the real town rescue completes")
	session._end_dialogue()
	await frames(4)
	var done: Dictionary = last("quest")
	var texts: int = 0
	for entry: Dictionary in notices().history:
		if str(entry["title"]).contains("完成"):
			texts += 1
	check(done.get("title") == "救助完成" and done.get("merged", false) and str(done.get("line", "")).contains("可能性") and done.get("color") == DuskStyle.GROWTH and texts == 1, "completion: the signal and the session's text make one gold notice with its detail")
	check(slip().drawn.get("state") == "已完成" and slip().drawn.get("status", {}).get("text") == "已完成", "the slip shows the task as done")
	await drain()
	await frames(int(QuestSlip.SETTLED_SECONDS * 60) + 10)
	check(slip().drawn.is_empty(), "and folds away after about six seconds")
	await enter(FieldSession.FIELD_ID)
	session.player.position = session.room.get_node("Seven").position
	var before: int = notices().history.size()
	check(session.interact_seven() and session._commit_gaze(), "returning to 7 settles the rescue")
	session._end_dialogue()
	await frames(4)
	var added: Array = notices().history.slice(before)
	var titles: Array = added.map(func(entry: Dictionary) -> String: return entry["title"])
	check(titles.has("救助进展") and titles.has("获得 · 泥粪中的理想家的注视") and added.size() == 2, "the settlement gives one progress notice and one obtained notice (its text merged): %s" % str(titles))
	var gaze: Dictionary = added[titles.find("获得 · 泥粪中的理想家的注视")]
	check(gaze.get("merged", false) and str(gaze.get("line", "")).contains("上限") and gaze.get("color") == DuskStyle.GROWTH, "the gaze notice keeps the text's detail")
	await drain()
	for ending: String in ["放弃", "过期"]:
		await open()
		session.record_event(FieldSession.HEAL_GUIDE)
		await drain()
		if ending == "过期":
			session.data["events"][WorldDayRules.expired_key(TownSession.TOWN_ID)] = true
			check(session.save_current(), "the day rules expire the rescue")
		else:
			check(session.record_event(WorldDayRules.failed(TownSession.TOWN_ID)), "the rescue is given up through its real event")
		await frames(3)
		var title: String = "已放弃救助" if ending == "放弃" else "救助已过期"
		check(notices().drawn.get("title", {}).get("text") == title and notices().drawn.get("bar", {}).get("color") == Color(DuskStyle.LIFE, notices().drawn["alpha"]), "%s: a vermilion centre notice" % ending)
		var state: String = "已放弃" if ending == "放弃" else "已过期"
		check(slip().drawn.get("state") == state and slip().drawn.get("status", {}).get("color") == DuskStyle.LIFE, "%s: the slip shows the state in vermilion" % ending)

## Pearl, ordinary pickup, medkit and growth: one gold notice each, none when
## the save fails.
func item_cases() -> void:
	await open()
	await enter(ExplorationSession.EXPLORATION_ID)
	var pickup: RoomPickup = session._pickups()[0]
	session.player.global_position = pickup.global_position + Vector2(0, 44)
	var real: String = session.store.directory
	session.store.directory = real.path_join("slot_1.json")
	var before: int = notices().history.size()
	check(not session.collect_pickup(pickup), "a pearl whose save fails is refused")
	await frames(3)
	check(notices().history.size() == before and notices().drawn.is_empty(), "and no obtained notice appears")
	session.store.directory = real
	check(session.collect_pickup(pickup), "the retry succeeds")
	await frames(3)
	check(notices().drawn.get("title", {}).get("text") == "获得 · 珍珠" and notices().drawn.get("bar", {}).get("color") == Color(DuskStyle.GROWTH, notices().drawn["alpha"]), "获得 · 珍珠 in growth gold")
	var generic: RoomPickup = RoomPickup.new()
	generic.config = PickupConfig.new()
	generic.config.persistence_key = "item:ui010:fixture"
	generic.config.display_name = "测试拾取"
	session.room.add_child(generic)
	generic.position = session.player.position + Vector2(0, -44)
	check(session.collect_pickup(generic), "an ordinary pickup")
	var supply: MedkitSupply = session.medkit_supply()
	session.player.global_position = supply.global_position + Vector2(0, 44)
	check(session.collect_medkit(), "a medkit")
	session.data["events"][BossSession.BOSS_DEFEATED] = true
	check(session.save_current(), "a growth claim")
	await frames(3)
	var titles: Array = notices().history.slice(before).map(func(entry: Dictionary) -> String: return entry["title"])
	check(titles == ["获得 · 珍珠", "获得 · 测试拾取", "获得 · 应急药包", "获得 · 攻击范围强化"], "each obtained thing is one notice, in order: %s" % str(titles))
	# One at a time: the queue shows its head only.
	var seen: Array[String] = []
	var spots: Array[Rect2] = []
	for i: int in range(1400):
		await frames(1)
		var title: String = str(notices().drawn.get("title", {}).get("text", ""))
		if not title.is_empty() and (seen.is_empty() or seen.back() != title):
			seen.append(title)
			spots.append(notices().drawn["rect"])
		if not notices().showing():
			break
	check(seen == titles, "they show one after another, never together: %s" % str(seen))
	session.save_current()
	await frames(3)
	check(notices().history.size() == before + 4, "a later save repeats nothing")

## show_notice() texts on their own, and one event never twice.
func merge_cases() -> void:
	var before: int = notices().history.size()
	session.dialogue_ui.show_notice("第 2 日")
	await frames(2)
	check(notices().drawn.get("title", {}).get("text") == "第 2 日" and notices().drawn.get("bar", {}).get("color") == Color(DuskStyle.INK, notices().drawn["alpha"]), "a show_notice() text alone becomes an ink centre notice")
	check(not session.dialogue_ui.notice.is_visible_in_tree() and not session.dialogue_ui.quest.is_visible_in_tree() and session.dialogue_ui.notice.text == "第 2 日", "the graybox notice and task Labels no longer appear (their text stays as data)")
	session.dialogue_ui.show_notice("第 2 日")
	await frames(2)
	check(notices().history.size() == before + 1, "the same text twice in a moment is one notice")
	await drain()
	session.dialogue_ui.show_notice("第 2 日")
	await frames(2)
	check(notices().history.size() == before + 2, "later the same text is a new notice")
	await drain()

## Dialogue, story and pause hide both; the queue waits and then goes on.
func hidden_cases() -> void:
	await open()
	session.record_event(FieldSession.HEAL_GUIDE)
	await frames(10)
	check(slip().drawn.has("rect") and notices().drawn.has("rect"), "both are up")
	var age: float = notices().age
	session.dialogue_ui.start(DialogueConfig.new(), PackedStringArray(["测试台词"]))
	await frames(30)
	check(slip().drawn.is_empty() and notices().drawn.is_empty() and notices().age == age, "a dialogue hides both and the notice waits")
	session.dialogue_ui.dismiss()
	# The way story scenes hide the HUD (FieldSession._story_hud).
	session._story_hud(true)
	age = notices().age
	await frames(30)
	check(slip().drawn.is_empty() and notices().drawn.is_empty() and notices().age == age, "a story scene (HUD hidden) hides both")
	session._story_hud(false)
	paused = true
	age = notices().age
	await frames(30)
	check(slip().drawn.is_empty() and notices().drawn.is_empty() and notices().age == age, "pausing hides both")
	paused = false
	await frames(3)
	check(slip().drawn.has("rect") and notices().drawn.has("rect") and notices().age > age, "after that both come back and the notice goes on")
	await drain()

## Loading shows the current task but replays no old notice.
func load_cases() -> void:
	await open()
	session.record_event(FieldSession.HEAL_GUIDE)
	session.record_event(WorldDayRules.completed(TownSession.TOWN_ID))
	var saved: Dictionary = session.store.load_slot(1)
	await open(saved)
	await frames(10)
	check(notices().history.is_empty() and notices().drawn.is_empty(), "a loaded save replays no notice")
	check(slip().drawn.get("state") == session.quest_state()["state"] and slip().drawn.has("objective"), "but the slip shows the current task (%s)" % session.quest_state()["state"])
	var running: Dictionary = fresh()
	running["events"][FieldSession.HEAL_GUIDE] = true
	await open(running)
	await frames(10)
	check(notices().history.is_empty() and slip().drawn.get("state") == "进行中", "a running task loads onto the slip without a start notice")

## Both window sizes: slip and notice on screen and clear of the HUD as
## drawn, area name, interaction prompt, enemy card, battle banner, save
## error and each other.
func layout_cases() -> void:
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		await enter(FieldSession.FIELD_ID)
		session.player.position = session.room.get_node("Seven").position
		(session.ui.get("_area_banner") as AreaBanner).pending = "测试区域"
		session.ui.call("save_failed", "存档写入失败，请稍后重试")
		session.ui.call("show_enemy_card", 20.0, "渴望俯视", "首领", "留意落击提示。\n利用召唤平台接近高空目标。")
		session.ui.call("show_battle_banner", 20.0, "中心战场 · 首段完成\n\n本提示不代表最终胜利。")
		session.dialogue_ui.show_notice("第 3 日")
		var parts: Dictionary = {}
		for i: int in range(120):
			await frames(1)
			parts = {"slip": slip().drawn.get("rect", Rect2()), "notice": notices().drawn.get("rect", Rect2()),
				"area": (session.ui.get("_area_banner") as AreaBanner).drawn.get("rect", Rect2()),
				"prompt": (session.ui.get("_interact_prompt") as InteractPrompt).drawn.get("rect", Rect2()),
				"card": (session.ui.get("_enemy_intro") as EnemyCard).drawn.get("rect", Rect2()),
				"banner": (session.ui.get("_battle_banner") as BattleBanner).drawn.get("rect", Rect2())}
			if parts.values().all(func(value: Rect2) -> bool: return value.size != Vector2.ZERO) and is_equal_approx((parts["card"] as Rect2).end.x, EnemyCard.RIGHT):
				break
		var missing: Array = parts.keys().filter(func(key: String) -> bool: return (parts[key] as Rect2).size == Vector2.ZERO)
		check(missing.is_empty(), "%dx%d: slip, notice, area name, prompt, card and banner all drawn (missing %s)" % [window.x, window.y, str(missing)])
		var error: Label = session.ui.get("_error_label") as Label
		var others: Dictionary = parts.duplicate()
		others["error"] = error.get_global_rect()
		for key: String in ["emblem", "hint", "horizon", "warning", "final", "banner"]:
			if hud.drawn.has(key) and hud.drawn[key].has("rect"):
				others["hud " + key] = hud.drawn[key]["rect"]
		var clash: Array[String] = []
		for mine: String in ["slip", "notice"]:
			if not Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(parts[mine]):
				clash.append(mine + " off screen")
			for key: String in others:
				if key != mine and not (mine == "notice" and key == "slip") and (parts[mine] as Rect2).intersects(others[key]):
					clash.append(mine + "/" + key)
		check(error.is_visible_in_tree() and clash.is_empty(), "%dx%d: slip and notice clear of everything %s" % [window.x, window.y, str(clash)])
		session.ui.call("save_failed", "")
		session.ui.call("hide_enemy_intro")
		await drain()
	root.size = Vector2i(1920, 1080)

## Review R2: two different pickups with the same name, both saved, are two
## notices; one pickup and its own text stay one.
func same_name_cases() -> void:
	await open()
	await enter(ExplorationSession.EXPLORATION_ID)
	var before: int = notices().history.size()
	for key: String in ["item:ui010:same_a", "item:ui010:same_b"]:
		var pickup: RoomPickup = RoomPickup.new()
		pickup.config = PickupConfig.new()
		pickup.config.persistence_key = key
		pickup.config.display_name = "测试拾取"
		session.room.add_child(pickup)
		pickup.position = session.player.position + Vector2(0, -44)
		check(session.collect_pickup(pickup) and session.store.load_slot(1)["events"].get(key, false), "%s is picked up and saved" % key)
		await frames(2)
	var added: Array = notices().history.slice(before)
	check(added.size() == 2 and added.all(func(entry: Dictionary) -> bool: return entry["title"] == "获得 · 测试拾取" and entry["source"] == "item"), "two saved pickups with one name are two notices")
	# Count the distinct queue heads that were actually drawn.
	var heads: Array = []
	for i: int in range(600):
		await frames(1)
		if not notices().showing():
			break
		if notices().drawn.has("title") and not heads.any(func(known: Dictionary) -> bool: return is_same(known, notices().queue[0])):
			heads.append(notices().queue[0])
	var shown: int = heads.filter(func(entry: Dictionary) -> bool: return added.any(func(mine: Dictionary) -> bool: return is_same(mine, entry))).size()
	check(shown == 2, "and they show one after the other (%d)" % shown)
	# One event, one notice still: a pickup's own "获得…" text joins its signal.
	var third: RoomPickup = RoomPickup.new()
	third.config = PickupConfig.new()
	third.config.persistence_key = "item:ui010:same_c"
	third.config.display_name = "测试拾取"
	session.room.add_child(third)
	third.position = session.player.position + Vector2(0, -44)
	before = notices().history.size()
	session.dialogue_ui.show_notice("获得测试拾取 · 第三件")
	check(session.collect_pickup(third), "a third one with a session text")
	await frames(3)
	added = notices().history.slice(before)
	check(added.size() == 1 and added[0]["title"] == "获得 · 测试拾取" and added[0]["line"] == "第三件" and added[0].get("merged", false), "its text and its signal are one notice")
	await drain()
	# One text per signal: a second, different text about the same name does
	# not fold into a signal that already has its text.
	var fourth: RoomPickup = RoomPickup.new()
	fourth.config = PickupConfig.new()
	fourth.config.persistence_key = "item:ui010:same_d"
	fourth.config.display_name = "测试拾取"
	session.room.add_child(fourth)
	fourth.position = session.player.position + Vector2(0, -44)
	before = notices().history.size()
	check(session.collect_pickup(fourth), "a fourth one")
	await frames(2)
	session.dialogue_ui.show_notice("获得测试拾取 · 甲")
	session.dialogue_ui.show_notice("获得测试拾取 · 乙")
	await frames(2)
	added = notices().history.slice(before)
	var lines: Array = added.map(func(entry: Dictionary) -> String: return "%s/%s/%s" % [entry["source"], entry["line"], entry.get("merged", false)])
	check(added.size() == 2 and added[0]["source"] == "item" and added[0]["line"] == "甲" and added[1]["source"] == "notice" and added[1]["line"] == "乙", "one signal takes one text; the other text is its own notice: %s" % str(lines))
	await drain()

## Review R1: one save that changes several tasks leaves the slip on the
## current one -- the same as quest_state() and the pause menu.
func current_task_cases() -> void:
	await open()
	await enter(FieldSession.FIELD_ID)
	session.record_event(FieldSession.HEAL_GUIDE)
	await frames(3)
	var room: Node = session.room
	var data: Dictionary = session.data
	var before: int = notices().history.size()
	session.data["day"] = 3
	check(session.save_current(), "the day rules run on a real save")
	await frames(4)
	var expired: Array = notices().history.slice(before).filter(func(entry: Dictionary) -> bool: return entry["title"] == "救助已过期")
	var query: Dictionary = session.quest_state()
	check(expired.size() >= 2 and session.room == room and is_same(session.data, data), "one save sent several tasks' expiry in the same Room and save (%d)" % expired.size())
	check(slip().state.get("id") == query["id"] and slip().state.get("objective") == query["objective"] and slip().state.get("state") == query["state"], "the slip shows the current task %s, not the last event" % query["id"])
	check(slip().objective() == query["objective"].trim_prefix("救助：") and query["objective"] == session.quest_status_text(), "the same text as the pause menu's current task")
	await frames(2)
	check(slip().drawn.is_empty() or (slip().drawn.get("id") == query["id"] and str(slip().drawn.get("objective", {}).get("text", "")) == slip().objective()), "and that is what it draws")
	await drain()

