extends "res://tests/acceptance/ui002_hud.gd"
## UI-009 adapter 2: the parasite Boss card and the battlefield banners.
## Slot 1 is the parasite Boss checkpoint (its introduction plays on load),
## slot 2 the trench passage before rescuing 10 (after 10's slash comes the
## "新一波敌人进入战场" banner), slot 3 the same passage with 10 already
## rescued (clearing a final wave shows "敌方第 N 波即将进入").
func configuration() -> Dictionary:
	return {"id":"UI-009", "marker":"UI009_BATTLE_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:parasite(), 2:passage(false), 3:passage(true)}, "enter":false,
		"instructions":"UI-009 介绍卡（二）与战场横幅 · 独立临时存档（关闭窗口自动清理）\n槽1 寄生同伴者检查点：读档即播放首领介绍 → 首领卡（朱红竖印）\n槽2 中心战场前（未救10）：进入战场救下10后 → 画面中上“新一波敌人进入战场”横幅\n槽3 中心战场前（已救10）：进入战场清掉一波 → “敌方第 2 波即将进入”横幅\n看：横幅在画面中上、不占右上角卡位，淡入淡出，暂停时停住"}

func parasite() -> Dictionary:
	var snapshot: Dictionary = fixture(2, DayClock.CONFIG.day_seconds)
	snapshot["checkpoint"] = ParasiteSession.PARASITE_CHECKPOINT
	snapshot["maximum"] = 14
	snapshot["balance"] = 7
	for key: String in [StartRoomSession.GUIDE, BossSession.BOSS_INTRO, BossSession.BOSS_DEFEATED, BossSession.BOSS_PASSAGE, FieldSession.FIELD_STORY, FieldSession.HEAL_GUIDE, FieldSession.RESCUE_DONE, TownSession.GAZE, RavineRescueSession.HELPED, RavineDepthSession.DEPTH_HELPED, RavineDepthRoom.GATES, RavineSession.RAVINE_CHECKPOINT]:
		snapshot["events"][key] = true
	return snapshot

func passage(rescued: bool) -> Dictionary:
	var snapshot: Dictionary = fixture(3, LONG_BUDGET)
	if not rescued:
		snapshot["events"].erase(RescueBattlefieldSession.RESCUE_DONE_EVENT)
	return snapshot

func self_test() -> void:
	check(session.start_slot(1, false), "acceptance slot 1 loads")
	var card: EnemyCard = session.ui.get("_enemy_intro") as EnemyCard
	var seal: bool = false
	for i: int in range(120):
		await frames(1)
		seal = seal or card.drawn.has("seal")
	check(seal and card.drawn.get("title", {}).get("text") == "寄生同伴者", "the parasite Boss checkpoint shows the Boss card on load")
	await capture("parasite")
