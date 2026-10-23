extends "res://tests/acceptance/ui002_hud.gd"
## PLN-001 adapter: the M2 playthrough on three isolated slots, in story
## order. Slot 1 is day 1 after the overlook Boss, before 7's first scene;
## slot 2 day 2 at the ravine entrance (7's rescue settled); slot 3 day 3 at
## the trench passage with 10 already rescued and a long final budget.
## The title screen, pause, settings and death are checked by launching the
## game itself (see PLN-001 delivery).
func configuration() -> Dictionary:
	return {"id":"PLN-001", "marker":"PLN001_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:day_one(), 2:day_two(), 3:fixture(3, LONG_BUDGET)}, "enter":false,
		"instructions":"PLN-001 M2 整体通关验收 · 独立临时存档（关闭窗口自动清理）\n槽1 第1日·渴望俯视之后：田野7的剧情 → 麦秆镇救助 → 回7获得注视\n槽2 第2日·巢都沟壑入口：沟壑救助、珍珠、换日\n槽3 第3日·中心战场前（已救10）：最终战打到胜利与结局\n对照 PLN-001 的 T7-G 核对表逐项看"}

func base(day: int) -> Dictionary:
	var snapshot: Dictionary = fixture(day, DayClock.CONFIG.day_seconds)
	snapshot["events"][WorldDayRules.ENABLED] = true
	snapshot["events"][StartRoomSession.GUIDE] = true
	return snapshot

func day_one() -> Dictionary:
	var snapshot: Dictionary = base(1)
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	for key: String in [TwoRoomSession.ENCOUNTER, "gate:HD_10003_1:return", "gate:HD_10003_1:forward", BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, BossSession.COMBAT_GROWTH]:
		snapshot["events"][key] = true
	return snapshot

func day_two() -> Dictionary:
	var snapshot: Dictionary = day_one()
	snapshot["day"] = 2
	snapshot["checkpoint"] = "HD_20001_1_N001"
	for key: String in [FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE, TownSession.GAZE]:
		snapshot["events"][key] = true
	# The gaze raises the cap (SlotStore.valid).
	snapshot["maximum"] = 12
	return snapshot

func self_test() -> void:
	for selected: int in [1, 2, 3]:
		check(not session.store.load_slot(selected).is_empty(), "acceptance slot %d is written" % selected)
	check(session.start_slot(3, false), "acceptance slot 3 loads")
	await frames(8)
	session = get_tree().current_scene as CheckpointLab
	check(int(session.data.get("day", 0)) == 3 and str(session.data.get("checkpoint", "")) == TrenchPassageSession.PASSAGE_CHECKPOINT, "slot 3 is day 3 at the trench passage")
	await capture("final")
