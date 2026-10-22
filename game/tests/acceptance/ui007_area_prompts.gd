extends "res://tests/acceptance/ui002_hud.gd"
## UI-007 adapter: area names and interaction prompts on isolated slots.
## Slot 1 starts at the very beginning (walk right through the first areas),
## slot 2 at the rubble tower checkpoint (the pearl room is close), slot 3 at
## the ravine entrance (the camp with a key-item pearl lies ahead).
func configuration() -> Dictionary:
	return {"id":"UI-007", "marker":"UI007_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:at(StartRoomSession.CHECKPOINT), 2:at("HD_10002_1_N002"), 3:at("HD_20001_1_N001")}, "enter":false,
		"instructions":"UI-007 独立临时存档（关闭窗口自动清理）\n槽1 开局 · 槽2 瓦砾塔检查点 · 槽3 巢都沟壑入口\n进入其他区域：画面正中出现区域名；同一区域换房不出现\n靠近珍珠、开关、检查点、NPC：靠玩家一侧出现“E / RB · 动作”\n关键物品（营帐的珍珠）在地图上闪烁\n对话、暂停、剧情时提示隐藏"}

func at(checkpoint: String) -> Dictionary:
	var snapshot: Dictionary = fixture(1, DayClock.CONFIG.day_seconds)
	snapshot["checkpoint"] = checkpoint
	return snapshot

func self_test() -> void:
	check(session.start_slot(2, false), "acceptance slot 2 loads")
	var banner: AreaBanner = session.ui.get("_area_banner") as AreaBanner
	var seen: bool = false
	for i: int in range(120):
		await frames(1)
		seen = seen or banner.drawn.has("area")
	check(seen, "acceptance load shows the area name")
	await capture("area")
