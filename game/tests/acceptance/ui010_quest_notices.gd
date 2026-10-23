extends "res://tests/acceptance/ui002_hud.gd"
## UI-010 adapter: the task slip and centre notices on isolated slots.
## Slot 1 is the overlook Boss checkpoint after the fight, before 7's first
## scene (walk right: the scene gives the rescue; then the town and back);
## slot 2 the rubble tower checkpoint (a pearl room is close); slot 3 the
## ravine entrance on day 2 (the ravine rescue lies ahead).
func configuration() -> Dictionary:
	return {"id":"UI-010", "marker":"UI010_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:field(), 2:tower(), 3:ravine()}, "enter":false,
		"instructions":"UI-010 任务纸签与中央提示 · 独立临时存档（关闭窗口自动清理）\n槽1 渴望俯视之后：向右到田野，看完与7的第一段剧情 → 中上“救助开始”，左侧任务纸签\n  再向右到麦秆镇救下幸存者 → “救助完成”（金色）；回7 → “救助进展”“获得 · 泥粪中的理想家的注视”\n槽2 瓦砾塔检查点：附近房间拾取珍珠 → “获得 · 珍珠”\n槽3 巢都沟壑入口（第2日）：向前找到幸存者 → 沟壑救助开始 / 完成\n看：提示一条接一条、不重叠；对话、暂停时隐藏；完成后纸签约6秒收起"}

func base(day: int) -> Dictionary:
	var snapshot: Dictionary = fixture(day, DayClock.CONFIG.day_seconds)
	snapshot["events"][WorldDayRules.ENABLED] = true
	snapshot["events"][StartRoomSession.GUIDE] = true
	return snapshot

func field() -> Dictionary:
	var snapshot: Dictionary = base(1)
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	for key: String in [TwoRoomSession.ENCOUNTER, "gate:HD_10003_1:return", "gate:HD_10003_1:forward", BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, BossSession.COMBAT_GROWTH]:
		snapshot["events"][key] = true
	return snapshot

func tower() -> Dictionary:
	var snapshot: Dictionary = base(1)
	snapshot["checkpoint"] = "HD_10002_1_N002"
	return snapshot

func ravine() -> Dictionary:
	var snapshot: Dictionary = field()
	snapshot["day"] = 2
	snapshot["checkpoint"] = "HD_20001_1_N001"
	for key: String in [FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE, TownSession.GAZE]:
		snapshot["events"][key] = true
	# The gaze raises the cap (SlotStore.valid).
	snapshot["maximum"] = 12
	return snapshot

func self_test() -> void:
	check(session.start_slot(2, false), "acceptance slot 2 loads")
	await frames(8)
	session = get_tree().current_scene as CheckpointLab
	var notice: CenterNotice = session.ui.get("_center_notice") as CenterNotice
	check(notice.history.is_empty(), "loading replays no notice")
	session.call("record_event", FieldSession.HEAL_GUIDE)
	var shown: bool = false
	for i: int in range(60):
		await frames(1)
		shown = shown or notice.drawn.get("title", {}).get("text") == "救助开始"
	check(shown and (session.ui.get("_quest_slip") as QuestSlip).drawn.has("objective"), "a started task shows the notice and the slip")
	await capture("quest")
