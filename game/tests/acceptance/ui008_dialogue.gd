extends "res://tests/acceptance/ui002_hud.gd"
## UI-008 adapter: the formal dialogue slip, the departure question and the
## G-08 tag on isolated slots. Slot 1 starts at the beginning (the field with
## 7 lies to the right), slot 2 at the ravine entrance with the ravine rescue
## already expired, slot 3 at the ravine entrance with every rescue still open.
func configuration() -> Dictionary:
	return {"id":"UI-008", "marker":"UI008_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:at(StartRoomSession.CHECKPOINT, false), 2:at("HD_20001_1_N001", true), 3:at("HD_20001_1_N001", false)}, "enter":false,
		"instructions":"UI-008 独立临时存档（关闭窗口自动清理）\n槽1 开局：向右到田野，与 7 的对话为黄昏色纸笺（撕边、墨字、左下名签）\n  按 E / RB 推进，长按加速；暂停时文字停住\n槽2 巢都沟壑入口（沟壑救助已过期）：走到幸存者附近，上方出现 G-08 短提示约 4 秒，不锁操作\n槽3 巢都沟壑入口（救助未过期）：进入沟壑深处后不清敌往回走，出现“留下 / 确认离开并放弃救助”，默认在留下"}

func at(checkpoint: String, expired: bool) -> Dictionary:
	var snapshot: Dictionary = fixture(1, DayClock.CONFIG.day_seconds)
	snapshot["checkpoint"] = checkpoint
	snapshot["events"][WorldDayRules.ENABLED] = true
	if checkpoint != StartRoomSession.CHECKPOINT:
		snapshot["day"] = 2
		snapshot["events"][RavineRescueSession.SEEN] = true
	if expired:
		snapshot["events"][WorldDayRules.expired_key(RavineRescueSession.RESCUE_ID)] = true
	return snapshot

func self_test() -> void:
	check(session.start_slot(2, false), "acceptance slot 2 loads")
	await frames(8)
	session = get_tree().current_scene as CheckpointLab
	session.call("_mount_room", RavineRescueSession.RESCUE_ID)
	session.call("_bind_room")
	session.player.position = (session.room.get_node("Survivor") as Node2D).position + Vector2(40, 0)
	var seen: bool = false
	for i: int in range(400):
		await frames(1)
		seen = seen or (session.dialogue_ui as FieldDialogue).missed_drawn.has("text")
		if seen:
			break
	check(seen, "the expired ravine rescue shows the G-08 tag")
	await capture("missed")
