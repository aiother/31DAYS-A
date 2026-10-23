extends "res://tests/acceptance/ui002_hud.gd"
## UI-009 adapter 1: enemy cards on isolated slots. Slot 1 is the second Room
## (the first colorless enemy is a few steps right), slot 2 the trench (walk
## on to the Tian warriors), slot 3 the overlook Boss checkpoint (its
## introduction plays on load). The parasite Boss and battlefield banners are
## in ui009_battle.gd.
func configuration() -> Dictionary:
	return {"id":"UI-009", "marker":"UI009_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:ordinary(), 2:elite(), 3:overlook()}, "enter":false,
		"instructions":"UI-009 介绍卡（一）· 独立临时存档（关闭窗口自动清理）\n槽1 第二个房间：向右几步遇到无色实体 → 普通敌人卡\n槽2 堑壕：向前遇到两名天人战士 → 精英卡\n槽3 渴望俯视检查点：读档即播放首领介绍 → 首领卡（朱红竖印）\n看：右上角墨条横幅滑入、停留、滑出；暂停时停住"}

func ordinary() -> Dictionary:
	var snapshot: Dictionary = fixture(1, DayClock.CONFIG.day_seconds)
	snapshot["events"][StartRoomSession.GUIDE] = true
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	return snapshot

func elite() -> Dictionary:
	var snapshot: Dictionary = fixture(3, DayClock.CONFIG.day_seconds)
	snapshot["checkpoint"] = TrenchSession.TRENCH_CHECKPOINT
	snapshot["events"][ParasiteSession.DODGE_PENDING] = true
	return snapshot

func overlook() -> Dictionary:
	var snapshot: Dictionary = fixture(1, DayClock.CONFIG.day_seconds)
	for key: String in [StartRoomSession.GUIDE, TwoRoomSession.ENCOUNTER, "gate:HD_10003_1:return", "gate:HD_10003_1:forward"]:
		snapshot["events"][key] = true
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	return snapshot

func self_test() -> void:
	check(session.start_slot(3, false), "acceptance slot 3 loads")
	var card: EnemyCard = session.ui.get("_enemy_intro") as EnemyCard
	var seal: bool = false
	for i: int in range(120):
		await frames(1)
		seal = seal or card.drawn.has("seal")
	check(seal and card.drawn.get("title", {}).get("text") == "渴望俯视", "the overlook Boss checkpoint shows the Boss card on load")
	await capture("boss")
